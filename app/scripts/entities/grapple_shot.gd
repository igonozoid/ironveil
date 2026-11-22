extends Node2D
## Efeito do rebite de escalada: um cabo se estende até o ponto marcado e,
## ao chegar, crava o rebite (que vira um ponto de agarrar).

var from := Vector2.ZERO
var target = null
var t := 0.0
const TRAVEL := 0.12
const LINGER := 0.18
var done := false


func setup(start: Vector2, gp) -> void:
	from = start
	target = gp
	z_index = 7


func _process(delta: float) -> void:
	t += delta
	if not done and t >= TRAVEL:
		done = true
		if is_instance_valid(target):
			target.anchor()
	if t >= TRAVEL + LINGER:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(target):
		return
	var to: Vector2 = target.global_position
	var k := clampf(t / TRAVEL, 0.0, 1.0)
	var tip := from.lerp(to, k)
	var a := 1.0 if t < TRAVEL else 1.0 - (t - TRAVEL) / LINGER
	draw_line(from, tip, Color(0.75, 0.75, 0.78, a), 1.2)
	draw_circle(tip, 2.0, Color(0.9, 0.6, 0.3, a))
