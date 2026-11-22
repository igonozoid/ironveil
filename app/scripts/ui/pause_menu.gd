extends CanvasLayer
## Menu de pausa (Esc / Start).

var root: Control
var first_button: Button
var controls: Label
var cfg_button: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 90)
	title.size = Vector2(640, 30)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)
	var vb := VBoxContainer.new()
	vb.position = Vector2(215, 122)
	vb.custom_minimum_size = Vector2(210, 0)
	vb.add_theme_constant_override("separation", 6)
	root.add_child(vb)
	first_button = _button(vb, "Continuar", _resume)
	_button(vb, "Reiniciar fase", _restart)
	cfg_button = _button(vb, "Configurações", _settings)
	_button(vb, "Mapa de fases", func(): Game.open_map("browse", Game.phase))
	_button(vb, "Menu principal", _menu)
	_button(vb, "Sair", _quit)
	controls = Label.new()
	controls.text = Game.fmt(tr("[move_left] [move_right]: mover · [jump]: pular · [shoot]: atirar · [roll]: rolar · [run]: trotar/correr\n[move_up] na parede: encostar · [interact]: interagir · [use_tool]: usar ferramenta · [swap_tool]: trocar · [pause]: pausa · F11: tela cheia"))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.position = Vector2(0, 290)
	controls.size = Vector2(640, 40)
	controls.add_theme_font_size_override("font_size", 9)
	controls.modulate = Color(1, 0.85, 0.7, 0.8)
	root.add_child(controls)


func _button(parent: Node, label: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = label
	if cb.is_valid():
		b.pressed.connect(cb)
	b.focus_entered.connect(func(): Sfx.play("menu", -8.0))
	parent.add_child(b)
	return b


func _settings() -> void:
	var s = load("res://scripts/ui/settings_menu.gd").new()
	s.on_close = func():
		controls.text = Game.fmt(tr("[move_left] [move_right]: mover · [jump]: pular · [shoot]: atirar · [roll]: rolar · [run]: trotar/correr\n[move_up] na parede: encostar · [interact]: interagir · [use_tool]: usar ferramenta · [swap_tool]: trocar · [pause]: pausa · F11: tela cheia"))
		cfg_button.grab_focus()
	root.add_child(s)


func _unhandled_input(event: InputEvent) -> void:
	if root.visible and root.get_children().any(func(c): return c.has_method("close")):
		return
	if event.is_action_pressed("pause"):
		if root.visible:
			_resume()
		elif Game.world != null and not Game.world.finishing:
			_open()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


func _open() -> void:
	root.visible = true
	get_tree().paused = true
	first_button.grab_focus()


func _resume() -> void:
	root.visible = false
	get_tree().paused = false
	if Game.world:
		Game.world.input_lock = 0.2


func _restart() -> void:
	root.visible = false
	Game.world.restart_phase()


func _menu() -> void:
	Game.go_to_menu()


func _quit() -> void:
	get_tree().quit()
