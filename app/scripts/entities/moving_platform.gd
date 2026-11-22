extends AnimatableBody2D
## Plataforma de engrenagem da Torre (Ato 3). Vai e volta entre dois pontos,
## parando um instante em cada ponta. Leva Sera (e guardas) junto.

const W := 40.0
const H := 8.0
const SPEED := 46.0
const PAUSE := 0.7

var a := Vector2.ZERO
var b := Vector2.ZERO
var k := 0.0
var dir := 1.0
var wait := 0.0
var t := 0.0
var length := 1.0


## `from`/`to` = centro do topo da plataforma nas duas pontas.
func setup(from: Vector2, to: Vector2, offset: float) -> void:
	a = from
	b = to
	length = maxf(1.0, a.distance_to(b))
	k = clampf(offset, 0.0, 1.0)
	position = a.lerp(b, k)
	z_index = 2


func _ready() -> void:
	add_to_group("platform")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(W, H)
	cs.shape = shape
	cs.position = Vector2(0, H * 0.5)
	add_child(cs)


func _physics_process(delta: float) -> void:
	t += delta
	if wait > 0.0:
		wait -= delta
	else:
		k += dir * SPEED * delta / length
		if k >= 1.0 or k <= 0.0:
			k = clampf(k, 0.0, 1.0)
			dir = -dir
			wait = PAUSE
	position = a.lerp(b, k)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-W * 0.5, 0, W, H)
	draw_rect(r, Color("4a3e30"))
	draw_rect(Rect2(r.position, Vector2(W, 2)), Color("d8a850"))
	draw_rect(Rect2(r.position + Vector2(0, H - 2), Vector2(W, 2)), Color("2a2420"))
	# Engrenagens nas pontas, girando com o movimento
	var rot := k * length / 6.0
	for side in [-1.0, 1.0]:
		var c := Vector2(side * (W * 0.5 - 4.0), H * 0.5)
		draw_circle(c, 4.5, Color("8a6a2a"))
		for i in 6:
			var ang: float = rot * side + i * TAU / 6.0
			draw_line(c, c + Vector2.from_angle(ang) * 5.5, Color("8a6a2a"), 1.6)
		draw_circle(c, 1.5, Color("2a2420"))
	# Haste até o trilho (para cima)
	draw_line(Vector2(0, 0), Vector2(0, -6), Color("3a3330"), 2.0)
