extends CanvasLayer
## Controles de toque (Android e telas sensíveis ao toque). Cada botão aciona a
## mesma ação do teclado, então as dicas do jogo (Z, X, C, A, S, Q) continuam
## valendo: o botão mostra a letra e o nome da ação. No Android ficam sempre
## visíveis; no PC aparecem só depois de um toque de verdade na tela e somem
## ao usar teclado ou controle.

## [ação, centro, raio, letra, nome, segurar-e-deslizar]
const BUTTONS := [
	["move_left", Vector2(42, 306), 24.0, "◀", "", true],
	["move_right", Vector2(112, 306), 24.0, "▶", "", true],
	["move_up", Vector2(77, 262), 20.0, "▲", "", true],
	["move_down", Vector2(77, 340), 18.0, "▼", "", true],
	["jump", Vector2(598, 300), 27.0, "Z", "pular", false],
	["shoot", Vector2(538, 324), 23.0, "X", "atirar", false],
	["roll", Vector2(546, 266), 20.0, "C", "rolar", false],
	["interact", Vector2(600, 236), 19.0, "A", "usar", false],
	["use_tool", Vector2(488, 296), 18.0, "S", "ferram.", false],
	["swap_tool", Vector2(488, 250), 15.0, "Q", "trocar", false],
	["pause", Vector2(446, 22), 13.0, "II", "", false],
]

static var _cache: Dictionary = {}


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in BUTTONS:
		_add(b[0], b[1], b[2], b[3], b[4], b[5])
	visible = OS.has_feature("mobile") or OS.has_feature("android")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		visible = true
	elif not OS.has_feature("mobile") and (event is InputEventKey or event is InputEventJoypadButton):
		visible = false


static func circle_texture(r: int, fill: Color, ring: Color) -> ImageTexture:
	var key := "%d_%s_%s" % [r, fill.to_html(), ring.to_html()]
	if _cache.has(key):
		return _cache[key]
	var size := r * 2 + 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size * 0.5, size * 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r:
				var col := fill
				if d > r - 2.0:
					col = ring
				col.a *= clampf(r - d + 0.5, 0.0, 1.0)
				img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


func _add(action: String, center: Vector2, radius: float, letter: String, caption: String, passby: bool) -> void:
	var r := int(radius)
	var b := TouchScreenButton.new()
	b.texture_normal = circle_texture(r, Color(0.08, 0.07, 0.065, 0.35), Color(0.75, 0.48, 0.25, 0.6))
	b.texture_pressed = circle_texture(r, Color(0.75, 0.48, 0.25, 0.45), Color(1.0, 0.8, 0.5, 0.85))
	var shape := CircleShape2D.new()
	shape.radius = radius + 4.0
	b.shape = shape
	b.shape_centered = true
	b.action = action
	b.passby_press = passby
	b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	b.position = center - Vector2(r + 1, r + 1)
	add_child(b)
	var l := Label.new()
	l.text = letter
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(r * 2 + 2, r * 2 + 2 - (8 if caption != "" else 0))
	l.add_theme_font_size_override("font_size", 14 if r > 16 else 10)
	l.modulate = Color(1, 0.92, 0.82, 0.85)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	if caption != "":
		var n := Label.new()
		n.text = caption
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.position = Vector2(0, r + 3)
		n.size = Vector2(r * 2 + 2, 10)
		n.add_theme_font_size_override("font_size", 7)
		n.modulate = Color(1, 0.85, 0.7, 0.7)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(n)
