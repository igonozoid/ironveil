extends Node
## Estado global do jogo (autoload "Game"): fase atual, vida, inventário,
## checkpoint por fase, salvamento e mapa de controles.

const TILE := 20
const SCREEN_W := 32
const SCREEN_H := 18
const MAX_HP := 4
const PHASE_COUNT := 9
## Atos e suas fases (índices globais de fase).
const ACTS := [
	{"title": "Ato 1 — As Caldeiras", "short": "As Caldeiras", "phases": [0, 1, 2]},
	{"title": "Ato 2 — O Mercado Suspenso", "short": "O Mercado Suspenso", "phases": [3, 4, 5]},
	{"title": "Ato 3 — A Torre do Diretório", "short": "A Torre do Diretório", "phases": [6, 7, 8]},
]
const PHASE_NAMES := ["Caldeira Norte", "Sala das Bombas", "Poço do Guindaste",
	"Docas de Carga", "Bazar das Correntes", "Telhados do Diretório",
	"Átrio de Bronze", "Engrenagem Mestra", "Gabinete do Diretor"]
const SAVE_PATH := "user://ironveil_save.json"
const TOOLS: Array[String] = ["charge", "sealant", "card"]
const TOOL_NAMES := {
	"charge": "Carga de vapor",
	"sealant": "Selante",
	"card": "Cartão de acesso",
}

var phase: int = 0
var hp: int = MAX_HP
var inv: Dictionary = {"charge": 0, "sealant": 0, "card": 0}
var tool_index: int = 0
var checkpoint: Dictionary = {}
## Progresso permanente: fases já concluídas (índices) e se o ato foi terminado.
## Não é apagado por "Novo jogo".
var progress: Dictionary = {"completed": [], "act1_complete": false, "acts_complete": []}
## Opções do jogador (salvas junto com o progresso).
var settings: Dictionary = {"gore": true, "fx": true}
var show_story: bool = false
var intro_to_menu: bool = false
## Repetição de uma fase já concluída (pelo mapa): não mexe no checkpoint salvo.
var replay: bool = false
var replay_cp: Dictionary = {}
## Mapa de fases: "browse" (aberto pelo menu) ou "travel" (entre fases).
var map_mode: String = "browse"
var map_from: int = -1
## Ato cuja tela de conclusão deve ser mostrada.
var end_act: int = 0
## Sangue e sujeira na roupa de Sera (só nesta sessão; some ao fim de cada ato).
var sera_splats: Array = []
var sera_grime: float = 0.0
## Referência para o nó do mundo em jogo (scripts/game.gd). Sem tipo estático
## de propósito: o acesso aos membros é dinâmico.
var world = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	load_save()


# ---------------------------------------------------------------- controles

func _setup_input() -> void:
	_add_action("move_left", [KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_action("move_right", [KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_action("move_up", [KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add_action("move_down", [KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add_action("jump", [KEY_Z], [JOY_BUTTON_A], [])
	_add_action("shoot", [KEY_X], [JOY_BUTTON_X], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_add_action("roll", [KEY_C], [JOY_BUTTON_LEFT_SHOULDER], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_add_action("interact", [KEY_A], [JOY_BUTTON_B], [])
	_add_action("use_tool", [KEY_S], [JOY_BUTTON_Y], [])
	_add_action("swap_tool", [KEY_Q], [JOY_BUTTON_RIGHT_SHOULDER], [])
	_add_action("pause", [KEY_ESCAPE], [JOY_BUTTON_START], [])
	# Z também confirma nos menus.
	var z := InputEventKey.new()
	z.keycode = KEY_Z
	InputMap.action_add_event("ui_accept", z)


func _add_action(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.3)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)
	for a in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = a[0]
		jm.axis_value = a[1]
		InputMap.action_add_event(action, jm)


# ---------------------------------------------------------------- fluxo

func new_game() -> void:
	phase = 0
	hp = MAX_HP
	inv = {"charge": 0, "sealant": 0, "card": 0}
	tool_index = 0
	show_story = false
	replay = false
	clean_sera()
	save_checkpoint()
	get_tree().paused = false
	intro_to_menu = false
	get_tree().change_scene_to_file("res://scenes/intro.tscn")


## Mostra só a introdução e volta ao menu.
func watch_intro() -> void:
	intro_to_menu = true
	get_tree().change_scene_to_file("res://scenes/intro.tscn")


## Chamado pela introdução ao terminar (ou ao pular).
func intro_finished() -> void:
	if intro_to_menu:
		intro_to_menu = false
		go_to_menu()
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func continue_game() -> void:
	if not load_save():
		new_game()
		return
	show_story = false
	replay = false
	restore_checkpoint()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ---------------------------------------------------------------- atos e mapa

func act_of(phase_index: int) -> int:
	for a in ACTS.size():
		if (ACTS[a]["phases"] as Array).has(phase_index):
			return a
	return ACTS.size() - 1


func is_last_of_act(phase_index: int) -> bool:
	var ph: Array = ACTS[act_of(phase_index)]["phases"]
	return ph[ph.size() - 1] == phase_index


func act_done(a: int) -> bool:
	for i in ACTS[a]["phases"]:
		if not is_phase_complete(int(i)):
			return false
	return true


## Fase pode ser jogada pelo mapa: já concluída, a do checkpoint ou a seguinte
## a uma concluída.
func is_phase_unlocked(i: int) -> bool:
	if i == 0 or is_phase_complete(i) or is_phase_complete(i - 1):
		return true
	return not checkpoint.is_empty() and int(checkpoint.get("phase", 0)) == i


## Começa (ou repete) uma fase a partir do mapa.
func play_from_map(i: int) -> void:
	get_tree().paused = false
	if not checkpoint.is_empty() and int(checkpoint.get("phase", -1)) == i and not is_phase_complete(i):
		replay = false
		restore_checkpoint()
	elif is_phase_complete(i):
		# Repetição: começa com a vida cheia e um kit básico.
		replay = true
		phase = i
		hp = MAX_HP
		inv = {"charge": 1 if i >= 3 else 0, "sealant": 0, "card": 0}
		tool_index = 0
		save_checkpoint()
	else:
		replay = false
		phase = i
		hp = MAX_HP
		inv = {"charge": 0, "sealant": 0, "card": 0}
		tool_index = 0
		save_checkpoint()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func open_map(mode: String, from_phase: int = -1) -> void:
	map_mode = mode
	map_from = from_phase
	get_tree().paused = false
	Engine.time_scale = 1.0
	world = null
	get_tree().change_scene_to_file("res://scenes/progress_map.tscn")


func go_to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	world = null
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------- checkpoint

func save_checkpoint() -> void:
	var cp := {
		"phase": phase,
		"hp": hp,
		"inv": inv.duplicate(),
		"tool_index": tool_index,
	}
	if replay:
		replay_cp = cp
		return
	checkpoint = cp
	write_save()


## Checkpoint em uso (o da repetição, se for o caso).
func cp() -> Dictionary:
	return replay_cp if replay else checkpoint


func write_save() -> void:
	var data := checkpoint.duplicate()
	data["progress"] = progress
	data["settings"] = settings
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


## Registra que a fase `index` foi concluída (chamado ao chegar ao elevador final).
func mark_phase_complete(index: int) -> void:
	var done: Array = progress.get("completed", [])
	if not done.has(index):
		done.append(index)
		done.sort()
	progress["completed"] = done
	var acts: Array = progress.get("acts_complete", [])
	for a in ACTS.size():
		if act_done(a) and not acts.has(a):
			acts.append(a)
	acts.sort()
	progress["acts_complete"] = acts
	progress["act1_complete"] = acts.has(0)
	write_save()


func gore_enabled() -> bool:
	return bool(settings.get("gore", true))


## Pós-processamento (gradação, brilho, vinheta, grão).
func fx_enabled() -> bool:
	return bool(settings.get("fx", true))


func toggle_fx() -> void:
	settings["fx"] = not fx_enabled()
	write_save()


func toggle_gore() -> void:
	settings["gore"] = not gore_enabled()
	write_save()


func is_phase_complete(index: int) -> bool:
	return (progress.get("completed", []) as Array).has(index)


func is_act_complete(a: int = 0) -> bool:
	return (progress.get("acts_complete", []) as Array).has(a) or (a == 0 and bool(progress.get("act1_complete", false)))


func restore_checkpoint() -> void:
	var c := cp()
	if c.is_empty():
		return
	phase = int(c.get("phase", 0))
	hp = int(c.get("hp", MAX_HP))
	var saved_inv: Dictionary = c.get("inv", {})
	inv = {"charge": 0, "sealant": 0, "card": 0}
	for k in saved_inv.keys():
		inv[String(k)] = int(saved_inv[k])
	tool_index = int(c.get("tool_index", 0))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_save() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	checkpoint = parsed
	var prog = checkpoint.get("progress", null)
	checkpoint.erase("progress")
	var sett = checkpoint.get("settings", null)
	checkpoint.erase("settings")
	if typeof(sett) == TYPE_DICTIONARY:
		settings["gore"] = bool(sett.get("gore", true))
		settings["fx"] = bool(sett.get("fx", true))
	if typeof(prog) == TYPE_DICTIONARY:
		var done: Array = []
		for v in prog.get("completed", []):
			done.append(int(v))
		var acts: Array = []
		for v in prog.get("acts_complete", []):
			acts.append(int(v))
		if bool(prog.get("act1_complete", false)) and not acts.has(0):
			acts.append(0)
		progress = {"completed": done, "act1_complete": acts.has(0), "acts_complete": acts}
	checkpoint["phase"] = clampi(int(checkpoint.get("phase", 0)), 0, PHASE_COUNT - 1)
	# Save antigo parado no fim de um ato já concluído (de antes de existir o
	# ato seguinte): o checkpoint passa para o começo do próximo ato.
	var cp_phase := int(checkpoint["phase"])
	if is_phase_complete(cp_phase) and is_last_of_act(cp_phase) and cp_phase + 1 < PHASE_COUNT \
			and not is_phase_complete(cp_phase + 1):
		checkpoint = {"phase": cp_phase + 1, "hp": MAX_HP, "inv": checkpoint.get("inv", {}),
			"tool_index": int(checkpoint.get("tool_index", 0))}
	return true


## Roupa limpa (início de jogo e começo de cada ato).
func clean_sera() -> void:
	sera_splats = []
	sera_grime = 0.0


# ---------------------------------------------------------------- inventário

func current_tool() -> String:
	return TOOLS[tool_index]


func tool_count(kind: String) -> int:
	return int(inv.get(kind, 0))


func add_item(kind: String, amount: int) -> void:
	inv[kind] = tool_count(kind) + amount
	if tool_count(current_tool()) <= 0:
		tool_index = TOOLS.find(kind)


func consume(kind: String) -> void:
	inv[kind] = maxi(0, tool_count(kind) - 1)
	if tool_count(kind) <= 0:
		cycle_tool()


func cycle_tool() -> void:
	for i in range(1, TOOLS.size() + 1):
		var idx := (tool_index + i) % TOOLS.size()
		if tool_count(TOOLS[idx]) > 0:
			tool_index = idx
			return
