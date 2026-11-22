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
	# Primeira vez: escolher o idioma antes de qualquer coisa.
	if Game.language() == "":
		_language_picker()
		return

	_build_logo()

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
		continue_btn.text = tr("Continuar — %s") % tr(Game.PHASE_NAMES[clampi(ph, 0, Game.PHASE_COUNT - 1)])
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
		parts.append(tr("%s Ato %d: %d/3 fases") % [mark, a + 1, n])
	prog.text = "      ".join(parts)
	if Game.is_act_complete(0):
		prog.add_theme_color_override("font_color", Color("ffd27a"))
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog.position = Vector2(0, 282)
	prog.size = Vector2(640, 36)
	prog.add_theme_font_size_override("font_size", 10)
	add_child(prog)

	controls = Label.new()
	controls.text = Game.fmt(tr("[move_left] [move_right]: mover · [jump]: pular · [shoot]: atirar · [roll]: rolar · [run]: trotar/correr\n[move_up] na parede: encostar · [interact]: interagir · [use_tool]: usar ferramenta · [swap_tool]: trocar · [pause]: pausa · F11: tela cheia"))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.position = Vector2(0, 306)
	controls.size = Vector2(640, 40)
	controls.add_theme_font_size_override("font_size", 9)
	controls.modulate = Color(1, 0.85, 0.7, 0.7)
	add_child(controls)


const LOGO_SHADER := """
shader_type canvas_item;
varying float ly;
void vertex() { ly = VERTEX.y; }
void fragment() {
	float k = clamp((ly - 8.0) / 44.0, 0.0, 1.0);
	vec3 top = vec3(1.0, 0.93, 0.62);
	vec3 mid = vec3(0.86, 0.56, 0.24);
	vec3 bot = vec3(0.42, 0.22, 0.09);
	vec3 g = k < 0.5 ? mix(top, mid, k * 2.0) : mix(mid, bot, (k - 0.5) * 2.0);
	g += vec3(0.25) * smoothstep(0.47, 0.5, k) * (1.0 - smoothstep(0.5, 0.56, k));
	COLOR = vec4(g, COLOR.a);
}
"""


## Logo: o emblema (engrenagem com o Véu rachado de luz) e o nome em latão.
func _build_logo() -> void:
	var emblem := TextureRect.new()
	emblem.texture = load("res://icons/icon_192.png")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.position = Vector2(296, 6)
	emblem.size = Vector2(48, 48)
	add_child(emblem)
	var spacing := FontVariation.new()
	spacing.base_font = ThemeDB.fallback_font
	spacing.spacing_glyph = 6
	spacing.variation_embolden = 0.6
	for layer in 2:
		var title := Label.new()
		title.text = "IRONVEIL"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.position = Vector2(0, 52)
		title.size = Vector2(640, 56)
		title.add_theme_font_override("font", spacing)
		title.add_theme_font_size_override("font_size", 44)
		if layer == 0:
			# Sombra e contorno escuros por trás
			title.add_theme_color_override("font_color", Color(0.1, 0.06, 0.04))
			title.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.03))
			title.add_theme_constant_override("outline_size", 8)
			title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
			title.add_theme_constant_override("shadow_offset_y", 3)
		else:
			var sh := Shader.new()
			sh.code = LOGO_SHADER
			var mat := ShaderMaterial.new()
			mat.shader = sh
			title.material = mat
		add_child(title)


## Escolha de idioma na primeira abertura do jogo.
func _language_picker() -> void:
	var emblem := TextureRect.new()
	emblem.texture = load("res://icons/icon_192.png")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.position = Vector2(280, 40)
	emblem.size = Vector2(80, 80)
	add_child(emblem)
	var l := Label.new()
	l.text = "Escolha o idioma  ·  Choose your language"
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, 140)
	l.size = Vector2(640, 24)
	l.add_theme_font_size_override("font_size", 14)
	add_child(l)
	var vb := VBoxContainer.new()
	vb.position = Vector2(230, 180)
	vb.custom_minimum_size = Vector2(180, 0)
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)
	var first: Button = null
	for lang in Game.LANGUAGES:
		var code := String(lang[0])
		var b := _button(vb, String(lang[1]), func():
			Game.set_language(code)
			get_tree().reload_current_scene())
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		if first == null:
			first = b
	first.grab_focus()


func _open_settings(from: Button) -> void:
	var lang_before := Game.language()
	var s = load("res://scripts/ui/settings_menu.gd").new()
	s.on_close = func():
		if Game.language() != lang_before:
			get_tree().reload_current_scene.call_deferred()
			return
		controls.text = Game.fmt(tr("[move_left] [move_right]: mover · [jump]: pular · [shoot]: atirar · [roll]: rolar · [run]: trotar/correr\n[move_up] na parede: encostar · [interact]: interagir · [use_tool]: usar ferramenta · [swap_tool]: trocar · [pause]: pausa · F11: tela cheia"))
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
