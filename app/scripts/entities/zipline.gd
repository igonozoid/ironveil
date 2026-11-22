extends Node2D
## Tirolesa: cabo esticado entre dois postes, sempre descendo de `a` para `b`.
## Sera agarra pulando contra o cabo e desliza até o fim (Z ou ↓ soltam antes).

var a := Vector2.ZERO
var b := Vector2.ZERO
var t := 0.0


func setup(from: Vector2, to: Vector2) -> void:
	a = from
	b = to
	z_index = 2


func _ready() -> void:
	add_to_group("zipline")


func length() -> float:
	return a.distance_to(b)


func dir_x() -> int:
	return 1 if b.x >= a.x else -1


func point(k: float) -> Vector2:
	return a.lerp(b, clampf(k, 0.0, 1.0))


func closest_t(p: Vector2) -> float:
	var ab := b - a
	return clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1.0), 0.0, 1.0)


func _process(delta: float) -> void:
	t += delta


func _draw() -> void:
	var la := a - global_position
	var lb := b - global_position
	# Postes
	for p in [la, lb]:
		draw_rect(Rect2(p + Vector2(-2, -4), Vector2(4, 8)), Color("4a3020"))
		draw_circle(p, 3.0, Color("b87333"))
		draw_circle(p, 1.4, Color("2a2523"))
	draw_line(la + Vector2(0, 1), lb + Vector2(0, 1), Color(0, 0, 0, 0.35), 1.0)
	draw_line(la, lb, Color("a8a29a"), 1.2)
	# Bandeirolas indicando a descida
	var n := int(length() / 60.0)
	for i in n:
		var p: Vector2 = la.lerp(lb, (i + 0.5) / float(n))
		var sway := sin(t * 3.0 + i) * 1.5
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(3 + sway, 7), p + Vector2(-3 + sway, 7)]),
			Color("8a2a1a") if i % 2 == 0 else Color("c9a24a"))
