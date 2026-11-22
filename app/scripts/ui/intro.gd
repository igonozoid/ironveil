extends Control
## Introdução animada (cutscene desenhada por código): a cidade, a explosão
## da Caldeira Sul, a acusação e a fuga. Z / A / Enter avançam a cena;
## Esc / Start ou o botão "Pular" pulam a introdução inteira.

const W := 640.0
const H := 360.0
const BAR := 38.0
const CHARS_PER_SEC := 38.0

const SHOTS := [
	{"dur": 7.0, "text": "Ironveil. Uma cidade vertical, lacrada dentro da montanha há duzentos anos."},
	{"dur": 8.0, "text": "No alto, o Mercado Suspenso vive na luz. Lá embaixo, as Caldeiras mantêm a cidade respirando."},
	{"dur": 7.5, "text": "Até a noite em que a Caldeira Sul explodiu."},
	{"dur": 8.5, "text": "O Diretório precisava de um culpado. Escolheu a engenheira-chefe de manutenção: Sera Vael."},
	{"dur": 7.0, "text": "Não há tempo para provar a inocência. Só para correr."},
	{"dur": 6.5, "text": "A única saída é subir."},
	{"dur": 4.5, "text": ""},
]

const SUIT := Color("7fd4ff")
const SUIT_D := Color("3d93c2")
const SKIN := Color("e8c6a0")
const HAIR := Color("2b2f3a")
const COPPER := Color("b87333")
const RUST := Color("6e2f18")
const IRON := Color("3d3735")
const GUARD := Color("8a1e1e")
const GUARD_D := Color("5e1414")
const GOLD := Color("ffd27a")

var shot := 0
var t := 0.0
var typed := 0.0
var shake := 0.0
var finished := false
var parts: Array = []   # [pos, vel, life, max_life, size, color, grav]
var label: Label
var skip_btn: Button
var flags: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	Music.play("menu")
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	rng.seed = 7
	Sfx.start_ambient()

	label = Label.new()
	label.position = Vector2(60, H - BAR + 4)
	label.size = Vector2(W - 120, BAR - 8)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	add_child(label)

	skip_btn = Button.new()
	skip_btn.text = "Pular ▶▶"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.position = Vector2(W - 92, 8)
	skip_btn.add_theme_font_size_override("font_size", 10)
	skip_btn.pressed.connect(_finish)
	add_child(skip_btn)

	var hint := Label.new()
	hint.text = "Esc / Start: pular · Z / A: avançar"
	hint.position = Vector2(10, 12)
	hint.add_theme_font_size_override("font_size", 8)
	hint.modulate = Color(1, 0.85, 0.7, 0.55)
	add_child(hint)
	_start_shot(0)


func _start_shot(i: int) -> void:
	shot = i
	t = 0.0
	typed = 0.0
	flags.clear()
	parts.clear()
	label.text = String(SHOTS[i]["text"])
	label.visible_characters = 0
	if i == 6:
		Sfx.play("door", -4.0, 0.7)


func _next() -> void:
	if shot + 1 >= SHOTS.size():
		_finish()
	else:
		_start_shot(shot + 1)


func _finish() -> void:
	if finished:
		return
	finished = true
	Sfx.play("menu")
	Game.intro_finished()


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_finish()
		if is_inside_tree():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump") or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		var total := label.text.length()
		if typed < total:
			typed = float(total)
		else:
			_next()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- partículas

func emit(pos: Vector2, vel: Vector2, life: float, size: float, col: Color, grav: float = 0.0) -> void:
	if parts.size() > 900:
		parts.pop_front()
	parts.append([pos, vel, life, life, size, col, grav])


func _update_parts(delta: float) -> void:
	var i := 0
	while i < parts.size():
		var p: Array = parts[i]
		p[2] = float(p[2]) - delta
		if float(p[2]) <= 0.0:
			parts.remove_at(i)
			continue
		var v: Vector2 = p[1]
		v.y += float(p[6]) * delta
		p[1] = v
		p[0] = (p[0] as Vector2) + v * delta
		i += 1


func _draw_parts() -> void:
	for p in parts:
		var k: float = float(p[2]) / float(p[3])
		var c: Color = p[5]
		draw_circle(p[0], float(p[4]) * (0.6 + 0.4 * k), Color(c, c.a * k))


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if finished:
		return
	t += delta
	typed = minf(typed + delta * CHARS_PER_SEC, float(label.text.length()))
	label.visible_characters = int(typed)
	shake = maxf(0.0, shake - delta * 12.0)
	_shot_logic(delta)
	_update_parts(delta)
	if t >= float(SHOTS[shot]["dur"]):
		_next()
	queue_redraw()


func _once(key: String) -> bool:
	if flags.has(key):
		return false
	flags[key] = true
	return true


func _shot_logic(delta: float) -> void:
	match shot:
		0:
			if randf() < delta * 30.0:
				emit(Vector2(320 + randf_range(-14, 14), 92), Vector2(randf_range(-6, 6), randf_range(-18, -8)), 4.0, randf_range(4, 9), Color(0.6, 0.6, 0.62, 0.25))
		1:
			if randf() < delta * 50.0:
				emit(Vector2(randf_range(40, 600), 1030), Vector2(randf_range(-5, 5), randf_range(-40, -20)), 3.0, randf_range(5, 10), Color(0.95, 0.95, 0.95, 0.18))
			if randf() < delta * 40.0:
				emit(Vector2(randf_range(40, 600), 1050), Vector2(randf_range(-8, 8), randf_range(-60, -30)), 2.5, 1.2, Color(1.0, 0.55, 0.2, 0.9))
		2:
			var blast := 3.6
			if t < blast:
				if randf() < delta * 25.0:
					emit(Vector2(320 + randf_range(-60, 60), 120), Vector2(randf_range(-10, 10), randf_range(-50, -20)), 1.5, randf_range(4, 8), Color(1, 1, 1, 0.3))
				if int(t * 2.5) != int((t - delta) * 2.5):
					Sfx.play("alert", -6.0, 0.8)
			elif _once("boom"):
				shake = 12.0
				Sfx.play("explosion", 2.0, 0.7)
				Sfx.play("crash", 0.0, 0.8)
				for i in 220:
					var a := randf() * TAU
					var sp := randf_range(60, 420)
					var col := Color(1.0, randf_range(0.4, 0.9), 0.15) if i % 3 != 0 else Color(0.3, 0.27, 0.25, 0.8)
					emit(Vector2(320, 190), Vector2.from_angle(a) * sp, randf_range(0.6, 2.2), randf_range(1.5, 5.0), col, 260.0)
			if t > blast and randf() < delta * 40.0:
				emit(Vector2(320 + randf_range(-80, 80), 200), Vector2(randf_range(-10, 10), randf_range(-40, -15)), 3.0, randf_range(6, 14), Color(0.25, 0.22, 0.2, 0.5))
		3:
			if randf() < delta * 20.0:
				emit(Vector2(randf_range(0, 640), 330), Vector2(randf_range(-6, 6), randf_range(-30, -10)), 3.0, 1.3, Color(1.0, 0.5, 0.2, 0.9))
			if t > 3.2 and _once("poster"):
				Sfx.play("clunk", 0.0, 0.8)
		4:
			if int(t * 3.0) != int((t - delta) * 3.0):
				Sfx.play("eshot", -8.0)
				flags["tracer_t"] = t
			if randf() < delta * 12.0:
				Sfx.play("steam", -14.0)
				var x := randf_range(200, 600)
				for i in 14:
					emit(Vector2(x, 300), Vector2(randf_range(-15, 15), randf_range(-160, -80)), 0.9, randf_range(4, 8), Color(1, 1, 1, 0.35))
			if randf() < delta * 8.0:
				var sx := randf_range(260, 620)
				for i in 8:
					emit(Vector2(sx, randf_range(120, 280)), Vector2(randf_range(-120, 120), randf_range(-120, 40)), 0.4, 1.2, Color(1.0, 0.8, 0.4), 400.0)
		5:
			if randf() < delta * 25.0:
				emit(Vector2(randf_range(250, 390), randf_range(40, 300)), Vector2(randf_range(-4, 4), randf_range(-8, -2)), 4.0, 1.0, Color(1.0, 0.88, 0.55, 0.7))
		6:
			if randf() < delta * 30.0:
				emit(Vector2(randf_range(170, 470), 175), Vector2(randf_range(-60, 60), randf_range(-90, -20)), 1.2, 1.3, Color(1.0, 0.7, 0.3), 120.0)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	draw_rect(Rect2(0, 0, W, H), Color("0b0909"))
	draw_set_transform(off, 0.0, Vector2.ONE)
	match shot:
		0:
			_draw_mountain()
		1:
			_draw_city()
		2:
			_draw_boiler()
		3:
			_draw_accusation()
		4:
			_draw_chase()
		5:
			_draw_shaft()
		6:
			_draw_title()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Barras de cinema
	draw_rect(Rect2(0, 0, W, BAR), Color.BLACK)
	draw_rect(Rect2(0, H - BAR, W, BAR), Color.BLACK)
	# Fade de entrada/saída de cada cena
	var dur: float = SHOTS[shot]["dur"]
	var a := 0.0
	if t < 0.7:
		a = 1.0 - t / 0.7
	elif t > dur - 0.6:
		a = (t - (dur - 0.6)) / 0.6
	if a > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf(a, 0.0, 1.0)))


func _draw_mountain() -> void:
	var k := t / float(SHOTS[0]["dur"])
	for i in 12:
		var c := Color(0.04 + i * 0.006, 0.05 + i * 0.006, 0.09 + i * 0.008)
		draw_rect(Rect2(0, i * 30, W, 30), c)
	rng.seed = 11
	for i in 90:
		var p := Vector2(rng.randf_range(0, W), rng.randf_range(BAR, 230))
		var tw := 0.5 + 0.5 * sin(t * rng.randf_range(1, 4) + i)
		draw_circle(p, rng.randf_range(0.4, 1.1), Color(1, 1, 1, 0.3 + 0.6 * tw))
	var z := 1.0 + k * 0.12
	draw_set_transform(Vector2(320, 360) * (1.0 - z), 0.0, Vector2(z, z))
	draw_colored_polygon(PackedVector2Array([Vector2(-40, 360), Vector2(120, 200), Vector2(210, 150), Vector2(290, 90), Vector2(350, 95), Vector2(430, 160), Vector2(540, 220), Vector2(700, 360)]), Color("1b1716"))
	draw_colored_polygon(PackedVector2Array([Vector2(290, 90), Vector2(350, 95), Vector2(380, 130), Vector2(330, 120), Vector2(300, 125)]), Color("2a2321"))
	# Janelas subindo pelo coração da montanha
	rng.seed = 5
	for i in 70:
		var y := rng.randf_range(110, 340)
		var spread := (y - 90.0) * 0.45
		var x := 320.0 + rng.randf_range(-spread, spread) * 0.5
		var on := sin(t * 0.8 + i * 1.3) > -0.6
		var col := Color(1.0, 0.75, 0.35, 0.9) if y < 160 else Color(1.0, 0.5, 0.2, 0.75)
		if on:
			draw_rect(Rect2(x, y, 2.5, 2), col)
	# Brilho das caldeiras na base
	for i in 6:
		draw_circle(Vector2(320, 360), 60.0 + i * 25.0, Color(1.0, 0.35, 0.1, 0.05))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_parts()


func _draw_city() -> void:
	var k := clampf(t / float(SHOTS[1]["dur"]), 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var oy := -e * 720.0
	draw_set_transform(Vector2(0, oy), 0.0, Vector2.ONE)
	# Mercado Suspenso
	for i in 10:
		draw_rect(Rect2(0, i * 30, W, 30), Color(0.25 + i * 0.01, 0.17, 0.08).darkened(0.5 + i * 0.03))
	for i in 8:
		draw_circle(Vector2(320, 0), 80.0 + i * 30.0, Color(1.0, 0.82, 0.45, 0.05))
	for i in 7:
		var x := 40.0 + i * 85.0
		var y := 120.0 + sin(i * 1.7) * 30.0 + sin(t + i) * 2.0
		draw_line(Vector2(x + 10, 0), Vector2(x + 10, y), Color("5a4a3a"), 1.0)
		draw_line(Vector2(x + 50, 0), Vector2(x + 50, y), Color("5a4a3a"), 1.0)
		draw_rect(Rect2(x, y, 60, 6), COPPER)
		draw_rect(Rect2(x + 6, y - 18, 20, 18), Color("4a3020"))
		draw_rect(Rect2(x + 32, y - 14, 22, 14), Color("5a3a22"))
		draw_rect(Rect2(x + 10, y - 13, 6, 4), Color(1.0, 0.85, 0.4))
		draw_rect(Rect2(x + 38, y - 10, 5, 3), Color(1.0, 0.85, 0.4))
		for j in 3:
			draw_circle(Vector2(x + 12 + j * 14, y - 2), 1.3, Color(0.9, 0.8, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(0, 250), "MERCADO SUSPENSO", HORIZONTAL_ALIGNMENT_CENTER, W, 14, Color(GOLD, 0.8))
	# Níveis intermediários
	for lv in 10:
		var y := 290.0 + lv * 45.0
		draw_rect(Rect2(0, y, W, 45), Color(0.12, 0.11, 0.11).lerp(Color(0.16, 0.1, 0.08), lv / 10.0))
		draw_rect(Rect2(0, y + 40, W, 5), IRON)
		rng.seed = lv * 31
		for w in 14:
			var wx := rng.randf_range(10, 620)
			if sin(t * 1.3 + w + lv) > -0.3:
				draw_rect(Rect2(wx, y + 15, 5, 6), Color(1.0, 0.6, 0.25, 0.6))
		var ex := fmod(t * (30.0 + lv * 7.0) + lv * 90.0, 700.0) - 30.0
		draw_rect(Rect2(ex, y + 28, 18, 12), Color("5a3a24"))
	for x in [90.0, 260.0, 470.0]:
		draw_rect(Rect2(x, 290, 6, 450), Color("4a3020"))
	# Caldeiras
	for i in 8:
		draw_rect(Rect2(0, 740 + i * 40, W, 40), Color(0.2 + i * 0.03, 0.08, 0.04))
	for i in 4:
		var bx := 50.0 + i * 150.0
		draw_rect(Rect2(bx, 830, 90, 200), Color("4a2a1a"))
		draw_circle(Vector2(bx + 45, 830), 45.0, Color("4a2a1a"))
		draw_rect(Rect2(bx + 25, 900, 40, 30), Color(1.0, 0.45, 0.1, 0.6 + 0.3 * sin(t * 6.0 + i)))
		draw_rect(Rect2(bx, 960, 90, 4), COPPER)
	draw_string(ThemeDB.fallback_font, Vector2(0, 790), "AS CALDEIRAS", HORIZONTAL_ALIGNMENT_CENTER, W, 14, Color(1.0, 0.6, 0.3, 0.8))
	_draw_parts()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_boiler() -> void:
	var blast := 3.6
	draw_rect(Rect2(0, 0, W, H), Color("1a1312"))
	for i in 8:
		draw_rect(Rect2(i * 80, 0, 40, H), Color("221a18"))
	draw_rect(Rect2(0, 300, W, 60), IRON)
	draw_rect(Rect2(0, 300, W, 4), COPPER)
	var alarm := int(t * 4.0) % 2 == 0
	if t < blast + 1.5:
		var a := 0.25 if alarm else 0.0
		draw_rect(Rect2(0, 0, W, H), Color(0.8, 0.05, 0.05, a))
		draw_circle(Vector2(80, 70), 8, Color(1, 0.15, 0.1) if alarm else Color(0.3, 0.05, 0.05))
		draw_circle(Vector2(560, 70), 8, Color(1, 0.15, 0.1) if not alarm else Color(0.3, 0.05, 0.05))
	if t < blast:
		var sh := (t / blast) * 4.0
		var o := Vector2(randf_range(-sh, sh), randf_range(-sh * 0.5, sh * 0.5))
		var c := Vector2(320, 190) + o
		draw_rect(Rect2(c + Vector2(-90, -60), Vector2(180, 170)), Color("5a3a24"))
		draw_circle(c + Vector2(0, -60), 90.0, Color("5a3a24"))
		draw_rect(Rect2(c + Vector2(-90, 40), Vector2(180, 6)), COPPER)
		draw_rect(Rect2(c + Vector2(-90, -20), Vector2(180, 6)), COPPER)
		for r in 6:
			draw_circle(c + Vector2(-80 + r * 32, 43), 2.0, Color("2a1a12"))
		# Manômetro
		var g := c + Vector2(0, -70)
		draw_circle(g, 26, Color("2a2523"))
		draw_circle(g, 23, Color("d8ccb4"))
		draw_arc(g, 19, PI * 0.15, PI * 0.45, 10, Color(0.8, 0.1, 0.1), 4.0)
		var ang := lerpf(PI * 0.85, PI * 0.25 + sin(t * 30.0) * 0.05, minf(t / (blast * 0.9), 1.0)) + PI
		draw_line(g, g + Vector2.from_angle(ang) * 18.0, Color("1a1a1a"), 2.0)
		draw_circle(g, 3, Color("1a1a1a"))
		# Rachaduras
		if t > blast * 0.55:
			draw_polyline(PackedVector2Array([c + Vector2(-30, -20), c + Vector2(-20, 0), c + Vector2(-34, 20), c + Vector2(-22, 38)]), Color(1.0, 0.6, 0.2), 1.5)
		if t > blast * 0.75:
			draw_polyline(PackedVector2Array([c + Vector2(40, -100), c + Vector2(28, -80), c + Vector2(44, -56)]), Color(1.0, 0.6, 0.2), 1.5)
	else:
		var lt := t - blast
		# Restos retorcidos
		draw_colored_polygon(PackedVector2Array([Vector2(230, 300), Vector2(240, 240), Vector2(270, 260), Vector2(290, 210), Vector2(320, 250), Vector2(350, 200), Vector2(380, 255), Vector2(410, 230), Vector2(415, 300)]), Color("3a2418"))
		for i in 5:
			draw_circle(Vector2(260 + i * 30, 290), 14.0 + sin(t * 8 + i) * 3.0, Color(1.0, 0.45, 0.1, 0.35))
		_draw_parts()
		if lt < 0.8:
			draw_rect(Rect2(0, 0, W, H), Color(1, 0.95, 0.85, 1.0 - lt / 0.8))
		return
	_draw_parts()


func _draw_accusation() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("16100f"))
	for i in 5:
		draw_circle(Vector2(180 + i * 70, 120), 70.0, Color(0.2, 0.17, 0.16, 0.35))
	draw_rect(Rect2(0, 300, W, 60), IRON)
	draw_rect(Rect2(0, 300, W, 4), COPPER)
	_draw_parts()
	# Sera de pé, assustada
	_sera(Vector2(170, 300), 3.0, 1, "stand", 0.0)
	# Guardas entrando pela direita, com mira laser
	var enter := clampf(t / 2.5, 0.0, 1.0)
	for i in 3:
		var gx := lerpf(720.0 + i * 50.0, 380.0 + i * 70.0, enter * enter * (3.0 - 2.0 * enter))
		var gy := 300.0
		if enter >= 1.0:
			var a := 0.4 + 0.3 * sin(t * 20.0 + i)
			draw_line(Vector2(gx - 30, gy - 63 + i * 2), Vector2(190, 300 - 60 + i * 6), Color(1, 0.15, 0.1, a), 1.2)
		_guard(Vector2(gx, gy), 3.0, -1, enter >= 1.0)
	# Cartaz de procurada
	if t > 3.2:
		var k := clampf((t - 3.2) / 0.6, 0.0, 1.0)
		var py := lerpf(-200.0, 60.0, 1.0 - pow(1.0 - k, 3.0))
		var r := Rect2(Vector2(400, py), Vector2(170, 210))
		draw_set_transform(Vector2(485, py + 105), -0.06, Vector2.ONE)
		var lr := Rect2(Vector2(-85, -105), r.size)
		draw_rect(lr, Color("d9cba8"))
		draw_rect(lr, Color("6a5a40"), false, 2.0)
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(-85, -82), "PROCURADA", HORIZONTAL_ALIGNMENT_CENTER, 170, 18, Color("7a1a14"))
		draw_rect(Rect2(-40, -70, 80, 80), Color("bcae8c"))
		draw_circle(Vector2(0, -32), 22, Color("8a7a60"))
		draw_circle(Vector2(-3, -40), 22, Color("4a4038"))
		draw_circle(Vector2(2, -28), 17, Color("a89878"))
		draw_line(Vector2(-22, -40), Vector2(-34, 8), Color("4a4038"), 5.0)
		draw_rect(Rect2(-24, -6, 48, 16), Color("6a8aa0"))
		draw_string(f, Vector2(-85, 30), "SERA VAEL", HORIZONTAL_ALIGNMENT_CENTER, 170, 15, Color("2a2018"))
		draw_string(f, Vector2(-85, 50), "Sabotagem da Caldeira Sul", HORIZONTAL_ALIGNMENT_CENTER, 170, 9, Color("2a2018"))
		draw_string(f, Vector2(-85, 66), "Ordem do Diretório de Ironveil", HORIZONTAL_ALIGNMENT_CENTER, 170, 8, Color("5a4a38"))
		if t > 4.2:
			draw_set_transform(Vector2(530, py + 192), -0.3, Vector2.ONE)
			draw_rect(Rect2(-40, -12, 80, 24), Color(0.75, 0.1, 0.08, 0.85), false, 3.0)
			draw_string(f, Vector2(-40, 6), "CULPADA", HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color(0.75, 0.1, 0.08, 0.85))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_chase() -> void:
	var scroll := t * 260.0
	draw_rect(Rect2(0, 0, W, H), Color("1c1716"))
	for i in 12:
		var x := fmod(i * 120.0 - scroll * 0.4, 1440.0) - 120.0
		draw_rect(Rect2(x, 0, 14, H), Color("3a2618"))
		draw_rect(Rect2(x + 40, 140 + (i % 3) * 30, 50, 26), Color(1.0, 0.45, 0.15, 0.25))
	for i in 3:
		var y := 110.0 + i * 50.0
		draw_rect(Rect2(0, y, W, 6), Color("4a3020"))
	for i in 14:
		var x := fmod(i * 60.0 - scroll, 840.0) - 60.0
		draw_rect(Rect2(x, 300, 60, 60), IRON if i % 2 == 0 else Color("443d3a"))
		draw_rect(Rect2(x, 300, 60, 4), COPPER)
	_draw_parts()
	var ph := t * 14.0
	var bob := absf(sin(ph)) * 3.0
	_sera(Vector2(330, 300 - bob), 2.6, 1, "run", ph)
	for i in 2:
		var gx := 90.0 + i * 70.0 + sin(t * 2.0 + i) * 10.0
		_guard(Vector2(gx, 300), 2.6, 1, true, t * 12.0 + i)
	# Traçantes
	if flags.has("tracer_t"):
		var tt: float = t - float(flags["tracer_t"])
		if tt < 0.25:
			var x0 := 160.0 + tt * 1800.0
			draw_line(Vector2(x0, 245), Vector2(x0 + 40, 245), Color(1, 0.6, 0.3, 0.9), 2.0)


func _draw_shaft() -> void:
	var k := t / float(SHOTS[5]["dur"])
	draw_rect(Rect2(0, 0, W, H), Color("0e0b0b"))
	var top := lerpf(40.0, 70.0, k)
	for i in 20:
		var y := i * 18.0
		var a := 0.3 * (1.0 - i / 20.0) * minf(1.0, t)
		var wdt := 70.0 + i * 9.0
		draw_rect(Rect2(320 - wdt * 0.5, y, wdt, 18), Color(1.0, 0.82, 0.45, a))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(285, 0), Vector2(230, 360), Vector2(0, 360)]), Color("241d1b"))
	draw_colored_polygon(PackedVector2Array([Vector2(355, 0), Vector2(640, 0), Vector2(640, 360), Vector2(410, 360)]), Color("241d1b"))
	draw_line(Vector2(285, 0), Vector2(230, 360), COPPER, 2.0)
	draw_line(Vector2(355, 0), Vector2(410, 360), COPPER, 2.0)
	for i in 8:
		var y := fmod(i * 50.0 + t * 6.0, 360.0)
		var lx := lerpf(285.0, 230.0, y / 360.0)
		var rx := lerpf(355.0, 410.0, y / 360.0)
		draw_line(Vector2(lx - 30, y), Vector2(lx, y), Color("3a2e2a"), 3.0)
		draw_line(Vector2(rx, y), Vector2(rx + 30, y), Color("3a2e2a"), 3.0)
	draw_circle(Vector2(320, top), 10.0, Color(1.0, 0.92, 0.7, 0.9))
	_draw_parts()
	_sera(Vector2(320, 312), 2.2, 1, "look_up", 0.0)


func _draw_title() -> void:
	var a := clampf(t / 1.5, 0.0, 1.0)
	for i in 6:
		draw_circle(Vector2(320, 175), 60.0 + i * 30.0, Color(1.0, 0.5, 0.2, 0.03 * a))
	_draw_parts()
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(0, 190), "IRONVEIL", HORIZONTAL_ALIGNMENT_CENTER, W, 52, Color(0.85, 0.59, 0.35, a))
	draw_rect(Rect2(170, 200, 300 * a, 2), Color(0.55, 0.35, 0.17, a))
	var b := clampf((t - 1.2) / 1.2, 0.0, 1.0)
	draw_string(f, Vector2(0, 224), "Ato 1 — As Caldeiras", HORIZONTAL_ALIGNMENT_CENTER, W, 15, Color(0.9, 0.85, 0.8, b))


# ---------------------------------------------------------------- personagens

## Sera simplificada para a introdução. Origem = pés.
func _sera(pos: Vector2, s: float, facing: int, pose: String, ph: float) -> void:
	draw_set_transform(pos, 0.0, Vector2(s * facing, s))
	var hip := Vector2(0, -13)
	var lean := 0.0
	var l1 := 0.08
	var l2 := -0.1
	var b1 := 0.0
	var b2 := 0.0
	var arm := 0.3
	var head_up := 0.0
	match pose:
		"run":
			lean = 0.28
			l1 = sin(ph) * 0.85
			l2 = -l1
			b1 = maxf(0.0, -cos(ph)) * 1.1
			b2 = maxf(0.0, cos(ph)) * 1.1
			arm = -l1
		"look_up":
			head_up = -0.5
			lean = -0.08
		_:
			var br := sin(t * 2.2) * 0.25
			hip.y += br
			arm = 0.5
	var u := Vector2(sin(lean), -cos(lean))
	var neck := hip + u * 9.5
	for leg in [[l2, b2, SUIT_D], [l1, b1, SUIT]]:
		var knee: Vector2 = hip + Vector2(sin(leg[0]), cos(leg[0])) * 6.5
		var foot: Vector2 = knee + Vector2(sin(leg[0] - leg[1]), cos(leg[0] - leg[1])) * 6.5
		draw_line(hip, knee, leg[2], 3.4, true)
		draw_line(knee, foot, leg[2], 3.0, true)
		draw_line(knee.lerp(foot, 0.45), foot, Color("3a2a22"), 3.2, true)
	# rabo de cavalo
	var hc := neck + u * 3.3 + Vector2(0.6, 0)
	var sway := sin(t * 6.0) * 1.2 + (4.0 if pose == "run" else 0.0)
	draw_line(hc + Vector2(-3, -1), hc + Vector2(-6 - sway, 3), HAIR, 2.6, true)
	draw_line(hc + Vector2(-6 - sway, 3), hc + Vector2(-8 - sway * 1.4, 7), HAIR, 1.8, true)
	draw_line(hip, neck, SUIT, 7.0, true)
	draw_line(hip + Vector2(-3.4, 0.6), hip + Vector2(3.4, 0.6), COPPER, 2.0)
	draw_line(neck + Vector2(-2.6, 0.6), hip + Vector2(2.3, -3), COPPER, 1.1, true)
	var hand := neck + Vector2(sin(arm), cos(arm)) * 9.0
	draw_line(neck + Vector2(0, 1.5), hand, SUIT, 2.4, true)
	draw_circle(hand, 1.5, Color("2e2a28"))
	draw_set_transform(pos + (hc * s * Vector2(facing, 1)), head_up * facing, Vector2(s * facing, s))
	draw_circle(Vector2(-0.9, -0.3), 3.7, HAIR)
	draw_circle(Vector2(0.4, 0.4), 3.2, SKIN)
	draw_colored_polygon(PackedVector2Array([Vector2(-3.7, 0.4), Vector2(-3.3, -2.6), Vector2(-1.1, -4.2), Vector2(1.7, -4.0), Vector2(3.5, -2.3), Vector2(3.3, -1.2), Vector2(1.8, -2.0), Vector2(0.4, -1.4), Vector2(-0.6, 0.4), Vector2(-1.5, 1.8)]), HAIR)
	draw_circle(Vector2(1.8, -3.3), 1.15, Color("d08a4a"))
	draw_circle(Vector2(2.1, -0.15), 0.6, Color("1a1c24"))
	draw_line(Vector2(2.3, 2.0), Vector2(3.1, 1.9), Color("b4605a"), 0.7)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _guard(pos: Vector2, s: float, facing: int, aiming: bool, walk: float = 0.0) -> void:
	draw_set_transform(pos, 0.0, Vector2(s * facing, s))
	var sw := sin(walk) * 3.0
	draw_line(Vector2(-2, -13), Vector2(-2 + sw, 0), GUARD_D, 3.5)
	draw_line(Vector2(2, -13), Vector2(2 - sw, 0), GUARD_D, 3.5)
	draw_rect(Rect2(-6, -25, 12, 13), GUARD)
	draw_rect(Rect2(-6, -14, 12, 2), Color("3e3434"))
	draw_rect(Rect2(-4.5, -31, 9, 7), Color("3e3434"))
	draw_rect(Rect2(0, -29, 4.5, 2), Color("f0c040"))
	if aiming:
		draw_rect(Rect2(0, -23, 13, 3), Color("2a2626"))
	else:
		draw_line(Vector2(-3, -22), Vector2(6, -14), Color("2a2626"), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
