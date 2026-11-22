extends Control
## Menu inicial: Novo jogo, Continuar (checkpoint por fase), Mapa de fases,
## introdução, Configurações e Sair.

var t := 0.0
var continue_btn: Button
var new_btn: Button
var controls: Label


func _ready() -> void:
	get_tree().paused = false
	Sfx.start_ambient()
	Music.play("menu")
	Music.preload_all()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.text = "IRONVEIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 62)
	title.size = Vector2(640, 50)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("d9965a"))
	add_child(title)

	var sub := Label.new()
	sub.text = "Caldeiras · Mercado Suspenso · Torre · Fundições · Véu de Ferro"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 116)
	sub.size = Vector2(640, 20)
	sub.add_theme_font_size_override("font_size", 13)
	sub.modulate = Color(0.9, 0.85, 0.8, 0.85)
	add_child(sub)

	var vb := VBoxContainer.new()
	vb.position = Vector2(210, 140)
	vb.custom_minimum_size = Vector2(220, 0)
	vb.add_theme_constant_override("separation", 4)
	add_child(vb)

	new_btn = _button(vb, "Novo jogo", func(): Game.new_game())
	continue_btn = _button(vb, "Continuar", func(): Game.continue_game())
	var row1 := _row(vb)
	var map_btn := _button(row1, "Mapa de fases", func(): Game.open_map("browse"))
	_button(row1, "Introdução", func(): Game.watch_intro())
	var cfg_btn := _button(vb, "Configurações", Callable())
	cfg_btn.pressed.connect(func(): _open_settings(cfg_btn))
	for r in [row1]:
		for btn in r.get_children():
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_font_size_override("font_size", 11)
	_button(vb, "Sair", func(): get_tree().quit())

	if Game.load_save():
		var ph := int(Game.checkpoint.get("phase", 0))
		continue_btn.text = "Continuar — %s" % Game.PHASE_NAMES[clampi(ph, 0, Game.PHASE_COUNT - 1)]
		continue_btn.grab_focus()
	else:
		continue_btn.disabled = true
		map_btn.disabled = true
		new_btn.grab_focus()

	# Progresso registrado
	var prog := Label.new()
	var parts := PackedStringArray()
	for a in Game.ACTS.size():
		var n := 0
		for i in Game.ACTS[a]["phases"]:
			if Game.is_phase_complete(int(i)):
				n += 1
		var mark := "★" if Game.is_act_complete(a) else "·"
		parts.append("%s Ato %d: %d/3 fases" % [mark, a + 1, n])
	prog.text = "      ".join(parts)
	if Game.is_act_complete(0):
		prog.add_theme_color_override("font_color", Color("ffd27a"))
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog.position = Vector2(0, 282)
	prog.size = Vector2(640, 36)
	prog.add_theme_font_size_override("font_size", 10)
	add_child(prog)

	controls = Label.new()
	controls.text = Game.fmt("[move_left] [move_right]: mover · [jump]: pular · [shoot]: atirar · [roll]: rolar · [run]: trotar/correr\n[move_up] na parede: encostar · [interact]: interagir · [use_tool]: usar ferramenta · [swap_tool]: trocar · [pause]: pausa · F11: tela cheia")
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.position = Vector2(0, 306)
	controls.size = Vector2(640, 40)
	controls.add_theme_font_size_override("font_size", 9)
	controls.modulate = Color(1, 0.85, 0.7, 0.7)
	add_child(controls)


func _open_settings(from: Button) -> void:
	var s = load("res://scripts/ui/settings_menu.gd").new()
	s.on_close = func():
		controls.text = Game.fmt("[move_left] [move_right]: mover · [jump]: pular · [shoot]: atirar · [roll]: rolar · [run]: trotar/correr\n[move_up] na parede: encostar · [interact]: interagir · [use_tool]: usar ferramenta · [swap_tool]: trocar · [pause]: pausa · F11: tela cheia")
		from.grab_focus()
	add_child(s)


func _gore_label() -> String:
	return "Gore: " + ("Ligado" if Game.gore_enabled() else "Desligado")


func _fx_label() -> String:
	return "Efeitos: " + ("Ligados" if Game.fx_enabled() else "Desligados")


func _row(parent: Node) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	parent.add_child(h)
	return h


func _button(parent: Node, label: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = label
	if cb.is_valid():
		b.pressed.connect(cb)
	b.focus_entered.connect(func(): Sfx.play("menu", -8.0))
	parent.add_child(b)
	return b


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var w := 640.0
	var h := 360.0
	draw_rect(Rect2(0, 0, w, h), Color("141112"))
	# Paredes da montanha e silhuetas da cidade vertical
	for i in 9:
		var x := i * 80.0 + 10.0
		var top := 40.0 + float((i * 37) % 90)
		draw_rect(Rect2(x, top, 46, h - top), Color("1e1a1a"))
		var y := top + 12.0
		while y < h - 20.0:
			var on := int(t * 0.7 + i * 1.7 + y * 0.03) % 5 != 0
			if on:
				draw_rect(Rect2(x + 8, y, 6, 4), Color(0.85, 0.45, 0.2, 0.35))
				draw_rect(Rect2(x + 28, y + 6, 6, 4), Color(0.85, 0.45, 0.2, 0.25))
			y += 22.0
	# Brilho das caldeiras embaixo
	for k in 8:
		draw_rect(Rect2(0, h - 70 + k * 9, w, 9), Color(0.8, 0.3, 0.1, 0.03 + k * 0.025))
	# Luz do Mercado Suspenso no alto
	for k in 6:
		draw_rect(Rect2(260 - k * 10, 0, 120 + k * 20, 40 - k * 6), Color(1.0, 0.82, 0.45, 0.04))
	# Vapor subindo
	for i in 14:
		var px := fmod(i * 47.0 + sin(t * 0.5 + i) * 20.0, w)
		var py := h - fmod(t * (14.0 + i * 2.0) + i * 31.0, h + 40.0)
		draw_circle(Vector2(px, py), 10.0 + (i % 4) * 4.0, Color(0.95, 0.95, 0.95, 0.035))
	draw_rect(Rect2(150, 108, 340, 2), Color("8a5a2b"))
