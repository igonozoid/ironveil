extends Node2D
## Peças animadas do fundo de uma tela (engrenagens, brilhos pulsando,
## vapor, lanternas, luzes de aviso, raios). Cada peça desenha uma vez e se
## anima só com rotação/transparência. O conjunto só roda na tela atual.

var active := false


func _ready() -> void:
	set_active(false)


func set_active(on: bool) -> void:
	active = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	for c in get_children():
		if c is CPUParticles2D:
			c.emitting = on


func build(list: Array) -> void:
	for it in list:
		var kind: String = it[0]
		var d: Dictionary = it[1]
		var n: Node2D = null
		match kind:
			"gear":
				n = Gear.new()
				n.radius = d["r"]
				n.col = d["col"]
				n.speed = d["speed"]
				n.spokes = d.get("spokes", true)
			"pulse":
				n = Pulse.new()
				n.radius = d["r"]
				n.col = d["col"]
				n.alpha = d["a"]
				n.speed = d["speed"]
			"lantern":
				n = Lantern.new()
				n.length = d["len"]
				n.t = d["phase"]
			"blink":
				n = Blink.new()
				n.col = d["col"]
				n.period = d["period"]
				n.t = float(d["phase"]) * float(d["period"])
			"hand":
				n = Hand.new()
				n.length = d["len"]
				n.speed = d["speed"]
				n.width = d["w"]
			"capsule":
				n = Capsule.new()
				n.top = d["top"]
				n.bottom = d["bottom"]
				n.speed = d["speed"]
				n.position = Vector2(float(d["x"]), 0)
				n.pos_y = n.top + randf() * (n.bottom - n.top)
			"lightning":
				n = Lightning.new()
				n.area = d["rect"]
			"steam":
				add_child(_steam(d["pos"], d["dir"], d.get("big", false)))
				continue
		if n == null:
			continue
		if d.has("pos"):
			n.position = d["pos"]
		add_child(n)


func _steam(pos: Vector2, dir: Vector2, big: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = 10 if big else 6
	p.lifetime = 2.6 if big else 1.4
	p.direction = dir
	p.spread = 14.0
	p.initial_velocity_min = 10.0 if big else 14.0
	p.initial_velocity_max = 22.0 if big else 30.0
	p.gravity = Vector2(4, -6)
	p.scale_amount_min = 4.0 if big else 2.0
	p.scale_amount_max = 9.0 if big else 5.0
	var g := Gradient.new()
	var c := Color(0.85, 0.85, 0.85) if not big else Color(1.0, 0.7, 0.5)
	g.set_color(0, Color(c, 0.0))
	g.add_point(0.15, Color(c, 0.22))
	g.set_color(g.get_point_count() - 1, Color(c, 0.0))
	p.color_ramp = g
	p.emitting = false
	return p


## Engrenagem: desenhada uma vez, gira pela rotação do nó.
class Gear extends Node2D:
	var radius := 30.0
	var col := Color(0.2, 0.17, 0.16)
	var speed := 0.3
	var spokes := true

	func _process(delta: float) -> void:
		rotation += speed * delta

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, col)
		var teeth := int(radius / 3.2)
		for k in teeth:
			var a := k * TAU / teeth
			draw_line(Vector2.from_angle(a) * radius, Vector2.from_angle(a) * (radius + 6.0), col, 6.0)
		draw_circle(Vector2.ZERO, radius * 0.62, col.darkened(0.35))
		if spokes:
			for k in 5:
				var a := k * TAU / 5.0 + 0.3
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * radius * 0.64, col, 5.0)
		draw_arc(Vector2.ZERO, radius - 1.0, -2.4, -1.2, 8, col.lightened(0.18), 1.5)
		draw_circle(Vector2.ZERO, radius * 0.18, Color(0.45, 0.36, 0.2))


## Brilho que pulsa (fornalha, lava, cadinho).
class Pulse extends Node2D:
	var radius := 40.0
	var col := Color(1, 0.5, 0.2)
	var alpha := 0.15
	var speed := 1.5
	var t := 0.0

	func _ready() -> void:
		t = randf() * 10.0

	func _process(delta: float) -> void:
		t += delta
		modulate.a = 0.55 + 0.3 * sin(t * speed * TAU * 0.5) + 0.15 * sin(t * speed * 7.3)

	func _draw() -> void:
		for i in 5:
			draw_circle(Vector2.ZERO, radius * (1.0 - i * 0.18), Color(col, alpha * 0.35))


## Lanterna pendurada que balança.
class Lantern extends Node2D:
	var length := 16.0
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		rotation = sin(t * 1.3) * 0.12 + sin(t * 0.47) * 0.06

	func _draw() -> void:
		var p := Vector2(0, length)
		draw_line(Vector2.ZERO, p, Color(0.3, 0.27, 0.27, 0.8), 1.0)
		draw_circle(p, 16.0, Color(1.0, 0.7, 0.3, 0.05))
		draw_circle(p, 8.0, Color(1.0, 0.7, 0.3, 0.09))
		draw_rect(Rect2(p + Vector2(-3, -1), Vector2(6, 8)), Color(0.25, 0.18, 0.12))
		draw_rect(Rect2(p + Vector2(-2, 0), Vector2(4, 6)), Color(1.0, 0.8, 0.42, 0.9))
		draw_rect(Rect2(p + Vector2(-3.5, -2), Vector2(7, 1.5)), Color(0.35, 0.25, 0.15))


## Luz de aviso piscando.
class Blink extends Node2D:
	var col := Color(1, 0.2, 0.1)
	var period := 1.5
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		var on := fmod(t, period) < period * 0.35
		var a := 1.0 if on else 0.15
		if modulate.a != a:
			modulate.a = a

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 9.0, Color(col, 0.08))
		draw_circle(Vector2.ZERO, 5.0, Color(col, 0.18))
		draw_circle(Vector2.ZERO, 2.2, col)


## Ponteiro de relógio.
class Hand extends Node2D:
	var length := 30.0
	var speed := 0.1
	var width := 2.0

	func _process(delta: float) -> void:
		rotation += speed * delta

	func _draw() -> void:
		draw_line(Vector2.ZERO, Vector2(0, -length), Color(0.15, 0.1, 0.08), width)
		draw_circle(Vector2.ZERO, 3.0, Color("8a6a2a"))


## Cápsula subindo pelo tubo pneumático.
class Capsule extends Node2D:
	var top := 0.0
	var bottom := 360.0
	var speed := 90.0
	var pos_y := 0.0

	func _process(delta: float) -> void:
		pos_y -= speed * delta
		if pos_y < top - 12.0:
			pos_y = bottom + 12.0
		position.y = pos_y

	func _draw() -> void:
		draw_rect(Rect2(0, -5, 6, 10), Color("a07a38"))
		draw_rect(Rect2(0, -5, 6, 2), Color("d0a858"))


## Raios: de vez em quando o céu clareia e um raio corta as nuvens.
class Lightning extends Node2D:
	var area := Rect2()
	var wait := 3.0
	var flash := 0.0
	var bolt := PackedVector2Array()

	func _ready() -> void:
		wait = randf_range(2.0, 6.0)
		modulate.a = 0.0

	func _process(delta: float) -> void:
		if flash > 0.0:
			flash -= delta
			modulate.a = clampf(flash / 0.35, 0.0, 1.0) * (0.6 + 0.4 * float(int(flash * 30.0) % 2))
			if flash <= 0.0:
				modulate.a = 0.0
			return
		wait -= delta
		if wait <= 0.0:
			wait = randf_range(3.5, 9.0)
			flash = 0.35
			_new_bolt()
			queue_redraw()

	func _new_bolt() -> void:
		bolt = PackedVector2Array()
		var p := Vector2(area.position.x + randf_range(40, area.size.x - 40), area.position.y)
		bolt.append(p)
		while p.y < area.position.y + area.size.y * randf_range(0.35, 0.6):
			p += Vector2(randf_range(-18, 18), randf_range(10, 24))
			bolt.append(p)

	func _draw() -> void:
		draw_rect(area, Color(0.75, 0.8, 1.0, 0.1))
		if bolt.size() > 1:
			draw_polyline(bolt, Color(0.75, 0.8, 1.0, 0.35), 4.0)
			draw_polyline(bolt, Color(0.95, 0.97, 1.0, 0.95), 1.5)
