extends Node
## Estado global do jogo (autoload "Game"): fase atual, vida, inventário,
## checkpoint por fase, salvamento e mapa de controles.

const TILE := 20
const SCREEN_W := 32
const SCREEN_H := 18
## Vida base; o upgrade "vida" (Martelo-de-Vapor) soma 1. Use max_hp().
const MAX_HP := 4
## Upgrades ganhos ao derrotar cada chefão: id -> [fase do chefão, nome, descrição]
const UPGRADES := {
	"vida": [2, "Válvula do Martelo", "+1 quadrado de vida"],
	"arpao": [5, "Arpão de mão", "Segure o tiro para carregar um arpão que atravessa escudos e inimigos"],
	"couraca": [8, "Couraça do Regulador", "Uma placa de latão absorve um golpe e se recarrega com o tempo"],
	"botas": [11, "Botas de Pressão", "No ar, aperte [roll] para dar um impulso na direção em que está olhando"],
}
## Ações que o jogador pode reconfigurar: [ação, nome na tela]
const REBINDABLE := [
	["move_left", "Mover para a esquerda"], ["move_right", "Mover para a direita"],
	["move_up", "Cima / encostar"], ["move_down", "Agachar"],
	["jump", "Pular"], ["shoot", "Atirar"], ["roll", "Rolar"], ["run", "Trotar / correr"],
	["interact", "Interagir"], ["use_tool", "Usar ferramenta"], ["swap_tool", "Trocar ferramenta"],
	["pause", "Pausa"],
]
## Dificuldades. Intenso e Insano (Novo Jogo+) liberam ao terminar o jogo.
## gore: multiplica sangue e pedaços; hp: vida dos inimigos comuns; boss: vida
## dos chefões; extra: inimigos a mais por posição; shake: tremor de tela;
## fx: exagero visual (0 normal, 1 intenso, 2 insano).
const DIFFICULTIES := [
	{"id": "normal", "name": "Normal", "gore": 1.0, "hp": 1.0, "boss": 1.0, "extra": 0, "shake": 1.0, "fx": 0},
	{"id": "intenso", "name": "Intenso", "gore": 2.6, "hp": 1.5, "boss": 1.35, "extra": 1, "shake": 1.5, "fx": 1},
	{"id": "insano", "name": "Insano", "gore": 5.0, "hp": 2.0, "boss": 1.75, "extra": 2, "shake": 2.2, "fx": 2},
]

## Idiomas disponíveis: [código, nome no próprio idioma]. Os textos ficam em
## i18n/<código>.po (o português é o idioma-fonte).
const LANGUAGES := [["pt_BR", "Português (Brasil)"], ["en", "English"]]
const DEFAULT_KEYS := {
	"move_left": KEY_LEFT, "move_right": KEY_RIGHT, "move_up": KEY_UP, "move_down": KEY_DOWN,
	"jump": KEY_Z, "shoot": KEY_X, "roll": KEY_C, "run": KEY_SHIFT, "interact": KEY_A,
	"use_tool": KEY_S, "swap_tool": KEY_Q, "pause": KEY_ESCAPE,
}
const PHASE_COUNT := 15
## Atos e suas fases (índices globais de fase).
const ACTS := [
	{"title": "Ato 1 — As Caldeiras", "short": "As Caldeiras", "phases": [0, 1, 2]},
	{"title": "Ato 2 — O Mercado Suspenso", "short": "O Mercado Suspenso", "phases": [3, 4, 5]},
	{"title": "Ato 3 — A Torre do Diretório", "short": "A Torre do Diretório", "phases": [6, 7, 8]},
	{"title": "Ato 4 — As Fundições Profundas", "short": "As Fundições Profundas", "phases": [9, 10, 11]},
	{"title": "Ato 5 — O Véu de Ferro", "short": "O Véu de Ferro", "phases": [12, 13, 14]},
]
const PHASE_NAMES := ["Caldeira Norte", "Sala das Bombas", "Poço do Guindaste",
	"Docas de Carga", "Bazar das Correntes", "Telhados do Diretório",
	"Átrio de Bronze", "Engrenagem Mestra", "Gabinete do Diretor",
	"Poço de Escória", "Cadinhos", "Coração da Montanha",
	"Passarelas do Véu", "Doca da Frota", "A Coroa"]
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
var progress: Dictionary = {"completed": [], "act1_complete": false, "acts_complete": [], "upgrades": []}
## Opções do jogador (salvas junto com o progresso).
var settings: Dictionary = {"gore": true, "fx": true, "fullscreen": false, "keys": {}, "music": 0.7, "sfx": 1.0, "lang": ""}
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
## A próxima fase carregada começa com a animação de entrada (Sera chega e o
## jogador aperta uma tecla). Morrer e recarregar não repete a entrada.
var phase_intro: bool = false
## Modo corrida (alternado pela tecla de trotar/correr).
var run_mode: bool = false
## Dificuldade da partida atual (índice em DIFFICULTIES); vai no checkpoint.
var difficulty: int = 0
## Console de testes: invencibilidade.
var god_mode: bool = false
## Sangue e sujeira na roupa de Sera (só nesta sessão; some ao fim de cada ato).
var sera_splats: Array = []
var sera_grime: float = 0.0
## Referência para o nó do mundo em jogo (scripts/game.gd). Sem tipo estático
## de propósito: o acesso aos membros é dinâmico.
var world = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_import_external_save()
	load_save()
	apply_language()
	apply_keys()
	apply_fullscreen()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- controles

func _setup_input() -> void:
	_add_action("move_left", [KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_action("move_right", [KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_action("move_up", [KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add_action("move_down", [KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add_action("jump", [KEY_Z], [JOY_BUTTON_A], [])
	_add_action("shoot", [KEY_X], [JOY_BUTTON_X], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_add_action("roll", [KEY_C], [JOY_BUTTON_LEFT_SHOULDER], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_add_action("run", [KEY_SHIFT], [JOY_BUTTON_LEFT_STICK], [])
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


## Aplica as teclas salvas (só os eventos de teclado; controle e toque ficam).
func apply_keys() -> void:
	var saved: Dictionary = settings.get("keys", {})
	for a in DEFAULT_KEYS.keys():
		var code: int = int(saved.get(a, DEFAULT_KEYS[a]))
		for ev in InputMap.action_get_events(a):
			if ev is InputEventKey:
				InputMap.action_erase_event(a, ev)
		var k := InputEventKey.new()
		k.keycode = code as Key
		InputMap.action_add_event(a, k)


func rebind(action: String, keycode: int) -> void:
	var keys: Dictionary = settings.get("keys", {})
	# Tira a tecla de outra ação que já a usava (troca as duas).
	var old: int = int(keys.get(action, DEFAULT_KEYS[action]))
	for a in DEFAULT_KEYS.keys():
		if a != action and int(keys.get(a, DEFAULT_KEYS[a])) == keycode:
			keys[a] = old
	keys[action] = keycode
	settings["keys"] = keys
	apply_keys()
	write_save()


func reset_keys() -> void:
	settings["keys"] = {}
	apply_keys()
	write_save()


func keycode_of(action: String) -> int:
	return int((settings.get("keys", {}) as Dictionary).get(action, DEFAULT_KEYS.get(action, 0)))


## Nome curto da tecla de uma ação, para dicas e menus.
func key_name(action: String) -> String:
	var code := keycode_of(action)
	match code:
		KEY_LEFT: return "←"
		KEY_RIGHT: return "→"
		KEY_UP: return "↑"
		KEY_DOWN: return "↓"
		KEY_ESCAPE: return "Esc"
	return OS.get_keycode_string(code)


## Troca marcas como [jump] pelo nome da tecla atual.
func fmt(text: String) -> String:
	var out := text
	for a in DEFAULT_KEYS.keys():
		out = out.replace("[%s]" % a, key_name(a))
	return out


## Sobe o volume em 10% (volta a 0 depois de 100%).
func cycle_volume(key: String) -> void:
	var v := float(settings.get(key, 1.0)) + 0.1
	if v > 1.05:
		v = 0.0
	settings[key] = snappedf(v, 0.1)
	Music.apply_volumes()
	write_save()


## Idioma escolhido ("" = ainda não escolheu: o menu pergunta antes de tudo).
func language() -> String:
	return String(settings.get("lang", ""))


func language_name() -> String:
	var code := language()
	for l in LANGUAGES:
		if l[0] == code:
			return String(l[1])
	return String(LANGUAGES[0][1])


func apply_language() -> void:
	var code := language()
	TranslationServer.set_locale(code if code != "" else "pt_BR")


func set_language(code: String) -> void:
	settings["lang"] = code
	apply_language()
	write_save()


func cycle_language() -> void:
	var codes: Array = LANGUAGES.map(func(l): return l[0])
	var i := codes.find(language())
	set_language(String(codes[(i + 1) % codes.size()]))


func toggle_fullscreen() -> void:
	settings["fullscreen"] = not bool(settings.get("fullscreen", false))
	apply_fullscreen()
	write_save()


func apply_fullscreen() -> void:
	if OS.has_feature("mobile") or DisplayServer.get_name() == "headless":
		return
	var fs := bool(settings.get("fullscreen", false))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)


# ---------------------------------------------------------------- dificuldade

func diff() -> Dictionary:
	return DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)]


## Novo Jogo+ (Intenso e Insano): liberado depois de vencer o Tecelão.
func is_game_complete() -> bool:
	return is_act_complete(ACTS.size() - 1)


func gore_mult() -> float:
	return float(diff()["gore"])


func fx_level() -> int:
	return int(diff()["fx"])


func shake_mult() -> float:
	return float(diff()["shake"])


func extra_enemies() -> int:
	return int(diff()["extra"])


## Vida de um inimigo comum na dificuldade atual.
func enemy_hp(base: int) -> int:
	return maxi(base, int(ceil(base * float(diff()["hp"]))))


func boss_hp(base: int) -> int:
	return int(round(base * float(diff()["boss"])))


# ---------------------------------------------------------------- upgrades

func max_hp() -> int:
	return MAX_HP + (1 if has_upgrade("vida") else 0)


func has_upgrade(id: String) -> bool:
	return (progress.get("upgrades", []) as Array).has(id)


func grant_upgrade(id: String) -> void:
	var u: Array = progress.get("upgrades", [])
	if not u.has(id):
		u.append(id)
	progress["upgrades"] = u
	write_save()


# ---------------------------------------------------------------- fluxo

func new_game(diff: int = 0) -> void:
	phase_intro = true
	difficulty = clampi(diff, 0, DIFFICULTIES.size() - 1)
	phase = 0
	hp = max_hp()
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
	phase_intro = true
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
	phase_intro = true
	get_tree().paused = false
	if not checkpoint.is_empty() and int(checkpoint.get("phase", -1)) == i and not is_phase_complete(i):
		replay = false
		restore_checkpoint()
	elif is_phase_complete(i):
		# Repetição: começa com a vida cheia e um kit básico.
		replay = true
		phase = i
		hp = max_hp()
		inv = {"charge": 1 if i >= 3 else 0, "sealant": 0, "card": 0}
		tool_index = 0
		save_checkpoint()
	else:
		replay = false
		phase = i
		hp = max_hp()
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
		"diff": difficulty,
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
	difficulty = clampi(int(c.get("diff", 0)), 0, DIFFICULTIES.size() - 1)
	hp = mini(int(c.get("hp", max_hp())), max_hp())
	var saved_inv: Dictionary = c.get("inv", {})
	inv = {"charge": 0, "sealant": 0, "card": 0}
	for k in saved_inv.keys():
		inv[String(k)] = int(saved_inv[k])
	tool_index = int(c.get("tool_index", 0))


## Sem save aqui, mas existe um de outra instalação do jogo nesta máquina
## (ex.: o jogo rodado pelo Godot Flatpak e a versão baixada usam pastas
## diferentes)? Copia para cá, para não começar do zero.
func _import_external_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		return
	var home := OS.get_environment("HOME")
	var appdata := OS.get_environment("APPDATA")
	var candidates: Array[String] = []
	if home != "":
		candidates.append(home + "/.var/app/org.godotengine.Godot/data/godot/app_userdata/Ironveil/ironveil_save.json")
		candidates.append(home + "/.local/share/godot/app_userdata/Ironveil/ironveil_save.json")
		candidates.append(home + "/Library/Application Support/Godot/app_userdata/Ironveil/ironveil_save.json")
	if appdata != "":
		candidates.append(appdata + "/Godot/app_userdata/Ironveil/ironveil_save.json")
	var mine := ProjectSettings.globalize_path(SAVE_PATH)
	for c in candidates:
		if c != mine and FileAccess.file_exists(c):
			var data := FileAccess.get_file_as_string(c)
			if data.strip_edges().begins_with("{"):
				var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
				if f:
					f.store_string(data)
					f.close()
				return


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
		settings["fullscreen"] = bool(sett.get("fullscreen", false))
		settings["music"] = clampf(float(sett.get("music", 0.7)), 0.0, 1.0)
		settings["lang"] = String(sett.get("lang", ""))
		settings["sfx"] = clampf(float(sett.get("sfx", 1.0)), 0.0, 1.0)
		var keys: Dictionary = {}
		var sk = sett.get("keys", {})
		if typeof(sk) == TYPE_DICTIONARY:
			for a in sk.keys():
				if DEFAULT_KEYS.has(String(a)):
					keys[String(a)] = int(sk[a])
		settings["keys"] = keys
	if typeof(prog) == TYPE_DICTIONARY:
		var done: Array = []
		for v in prog.get("completed", []):
			done.append(int(v))
		var acts: Array = []
		for v in prog.get("acts_complete", []):
			acts.append(int(v))
		if bool(prog.get("act1_complete", false)) and not acts.has(0):
			acts.append(0)
		var ups: Array = []
		for v in prog.get("upgrades", []):
			ups.append(String(v))
		# Chefões vencidos antes de existirem os upgrades também dão o prêmio.
		for id in UPGRADES.keys():
			if done.has(int(UPGRADES[id][0])) and not ups.has(id):
				ups.append(id)
		progress = {"completed": done, "act1_complete": acts.has(0), "acts_complete": acts, "upgrades": ups}
	checkpoint["phase"] = clampi(int(checkpoint.get("phase", 0)), 0, PHASE_COUNT - 1)
	# Save antigo parado no fim de um ato já concluído (de antes de existir o
	# ato seguinte): o checkpoint passa para o começo do próximo ato.
	var cp_phase := int(checkpoint["phase"])
	if is_phase_complete(cp_phase) and is_last_of_act(cp_phase) and cp_phase + 1 < PHASE_COUNT \
			and not is_phase_complete(cp_phase + 1):
		checkpoint = {"phase": cp_phase + 1, "hp": max_hp(), "inv": checkpoint.get("inv", {}),
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
