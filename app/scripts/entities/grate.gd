extends StaticBody2D
## Grade quebrável: bloqueia a passagem até ser destruída por uma carga de vapor.

const Fx := preload("res://scripts/fx.gd")

var rect := Rect2()


func setup(r: Rect2) -> void:
	rect = r
	position = r.position


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 2
	add_to_group("breakable")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(rect.size.x - 6, rect.size.y)
	cs.shape = shape
	cs.position = rect.size * 0.5
	add_child(cs)


func distance_to_point(p: Vector2) -> float:
	var q := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
	return q.distance_to(p)


func on_rivet_hit(_dir: int) -> void:
	Sfx.play("clang", -8.0)


func destroy() -> void:
	for i in int(rect.size.y / 20.0):
		Fx.debris(get_parent(), rect.position + Vector2(10, 10 + i * 20))
	Sfx.play("crash")
	queue_free()


func _draw() -> void:
	var w := rect.size.x
	var h := rect.size.y
	draw_rect(Rect2(3, 0, w - 6, 3), Color("6e4a2c"))
	draw_rect(Rect2(3, h - 3, w - 6, 3), Color("6e4a2c"))
	for i in 4:
		var x := 4.0 + i * (w - 8.0) / 3.0
		draw_line(Vector2(x, 0), Vector2(x, h), Color("7a6a60"), 2.0)
	var y := 8.0
	while y < h:
		draw_line(Vector2(3, y), Vector2(w - 3, y), Color("5a4a44"), 1.5)
		y += 12.0
