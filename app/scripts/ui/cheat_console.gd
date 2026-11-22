extends CanvasLayer
## Console de testes (tecla =). Uma linha de comando por cima do jogo, que
## pausa enquanto está aberta. "ajuda" lista os comandos.

const HELP := [
	"god — liga/desliga a invencibilidade",
	"vida — vida cheia",
	"municao — 9 cargas, 9 selantes e 3 cartões",
	"escudo — recarrega a couraça (dá a couraça se não tiver)",
	"upgrades — todos os upgrades dos chefões",
	"tudo — god + vida + munição + escudo + upgrades",
	"liberar — marca todas as fases como concluídas",
	"fase N — vai para a fase N (1 a 15)",
	"chefao — vai para a arena do chefão desta fase",
	"matar — derrota os inimigos da tela",
	"chefao_vida N — deixa o chefão com N de vida",
	"vento N — força do vento (0 desliga)",
	"dificuldade normal|intenso|insano — muda a dificuldade e reinicia a fase",
	"limpar — limpa o console",
	"fechar — fecha (ou = / Esc)",
]

var root: Control
var log_label: Label
var input: LineEdit
var lines: Array[String] = []
var history: Array[String] = []
var hist_i := 0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.position = Vector2(0, 0)
	root.size = Vector2(640, 150)
	root.visible = false
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.04, 0.92)
	bg.size = Vector2(640, 150)
	root.add_child(bg)
	var edge := ColorRect.new()
	edge.color = Color(0.75, 0.48, 0.25)
	edge.position = Vector2(0, 149)
	edge.size = Vector2(640, 1)
	root.add_child(edge)
	log_label = Label.new()
	log_label.position = Vector2(8, 4)
	log_label.size = Vector2(624, 118)
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	log_label.clip_text = true
	log_label.add_theme_font_size_override("font_size", 9)
	log_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.75))
	root.add_child(log_label)
	input = LineEdit.new()
	input.position = Vector2(6, 124)
	input.size = Vector2(628, 22)
	input.add_theme_font_size_override("font_size", 11)
	input.placeholder_text = "comando (ajuda)"
	input.text_submitted.connect(_on_submit)
	root.add_child(input)
	_print("Console de testes. Digite \"ajuda\".")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_EQUAL or event.unicode == 61:
		toggle()
		get_viewport().set_input_as_handled()
	elif root.visible and event.keycode == KEY_ESCAPE:
		toggle()
		get_viewport().set_input_as_handled()
	elif root.visible and (event.keycode == KEY_UP or event.keycode == KEY_DOWN) and not history.is_empty():
		hist_i = clampi(hist_i + (-1 if event.keycode == KEY_UP else 1), 0, history.size())
		input.text = history[hist_i] if hist_i < history.size() else ""
		input.caret_column = input.text.length()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	root.visible = not root.visible
	if root.visible:
		get_tree().paused = true
		input.text = ""
		input.grab_focus()
	else:
		input.release_focus()
		get_tree().paused = false
		if Game.world:
			Game.world.input_lock = 0.2


func _print(s: String) -> void:
	lines.append(s)
	while lines.size() > 9:
		lines.pop_front()
	log_label.text = "\n".join(lines)


func _on_submit(text: String) -> void:
	var cmd := text.strip_edges()
	input.text = ""
	if cmd == "":
		return
	history.append(cmd)
	hist_i = history.size()
	_print("> " + cmd)
	_print(run(cmd))


## Executa um comando e devolve a resposta (também usado pelos testes).
func run(cmd: String) -> String:
	var parts := cmd.to_lower().split(" ", false)
	var c := parts[0]
	var arg := parts[1] if parts.size() > 1 else ""
	var w = Game.world
	var p = w.player if w else null
	match c:
		"ajuda", "help", "?":
			return "\n".join(HELP)
		"god", "godmode":
			Game.god_mode = not Game.god_mode
			return "Invencibilidade: " + ("LIGADA" if Game.god_mode else "desligada")
		"vida", "fullhealth", "hp":
			Game.hp = Game.max_hp()
			return "Vida cheia (%d)." % Game.hp
		"municao", "fullammo", "ammo":
			Game.inv = {"charge": 9, "sealant": 9, "card": 3}
			return "9 cargas, 9 selantes, 3 cartões."
		"escudo", "fullshield", "shield":
			if not Game.has_upgrade("couraca"):
				Game.grant_upgrade("couraca")
			if p != null:
				p.on_upgrade("couraca")
			return "Couraça carregada."
		"upgrades":
			for id in Game.UPGRADES.keys():
				Game.grant_upgrade(id)
			if p != null:
				p.on_upgrade("couraca")
			Game.hp = Game.max_hp()
			return "Todos os upgrades: " + ", ".join(Game.UPGRADES.keys())
		"tudo", "all":
			Game.god_mode = true
			for id in Game.UPGRADES.keys():
				Game.grant_upgrade(id)
			if p != null:
				p.on_upgrade("couraca")
			Game.hp = Game.max_hp()
			Game.inv = {"charge": 9, "sealant": 9, "card": 3}
			return "God, vida, munição, escudo e upgrades."
		"liberar", "unlockall":
			for i in Game.PHASE_COUNT:
				Game.mark_phase_complete(i)
			return "Todas as %d fases liberadas no mapa." % Game.PHASE_COUNT
		"fase", "phase", "goto":
			var n := int(arg)
			if n < 1 or n > Game.PHASE_COUNT:
				return "Use: fase 1 a %d" % Game.PHASE_COUNT
			toggle()
			Game.replay = false
			Game.phase = n - 1
			Game.hp = Game.max_hp()
			Game.phase_intro = true
			Game.save_checkpoint()
			get_tree().change_scene_to_file("res://scenes/game.tscn")
			return "Indo para a fase %d." % n
		"chefao", "boss":
			if w == null or w.boss == null:
				return "Esta fase não tem chefão."
			toggle()
			Game.save_checkpoint()
			Game.cp()["boss"] = true
			Game.cp()["boss_seen"] = true
			get_tree().reload_current_scene()
			return "Indo para o chefão."
		"matar", "kill", "killall":
			if w == null:
				return "Fora do jogo."
			var k := 0
			for g in get_tree().get_nodes_in_group("guard"):
				if g.is_alive() and w.is_active(g.global_position):
					g.blast_hit(9, g.global_position + Vector2(0, -40))
					k += 1
			for d in get_tree().get_nodes_in_group("drone"):
				if w.is_active(d.global_position):
					d.call_deferred("explode")
					k += 1
			return "%d inimigos derrotados." % k
		"chefao_vida", "bosshp":
			if w == null or w.boss == null:
				return "Sem chefão."
			var hv := maxi(1, int(arg))
			w.boss.hp = mini(hv, int(w.boss.hp))
			return "Chefão com %d de vida." % w.boss.hp
		"vento", "wind":
			if w == null:
				return "Fora do jogo."
			w.set_wind(float(arg))
			return "Vento: %s" % arg
		"dificuldade", "difficulty":
			var names := ["normal", "intenso", "insano"]
			var di := names.find(arg)
			if di < 0:
				return "Use: dificuldade normal | intenso | insano"
			Game.difficulty = di
			if w != null:
				toggle()
				Game.save_checkpoint()
				get_tree().reload_current_scene()
			return "Dificuldade: " + arg
		"limpar", "clear":
			lines.clear()
			log_label.text = ""
			return ""
		"fechar", "close", "exit":
			toggle()
			return ""
	return "Comando desconhecido. Digite \"ajuda\"."
