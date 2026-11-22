extends Node2D
## Bomba do dirigível: cai com uma sombra-alvo no chão e explode ao tocar.

const ExplosionScript := preload("res://scripts/entities/explosion.gd")

var vel := Vector2.ZERO
var target_y := 0.0
var t := 0.0


func setup(pos: Vector2, v: Vector2, floor_y: float) -> void:
	position = pos
	vel = v
	target_y = floor_y
	z_index = 6


func _physics_process(delta: float) -> void:
	t += delta
	vel.y = minf(vel.y + 520.0 * delta, 420.0)
	vel.x = move_toward(vel.x, 0.0, 40.0 * delta)
	position += vel * delta
	var lvl = Game.world.level if Game.world else null
	var hit_floor := position.y >= target_y - 2.0
	if lvl != null and lvl.is_solid(lvl.world_to_cell(position + Vector2(0, 3))):
		hit_floor = true
	if hit_floor:
		var e = ExplosionScript.new()
		e.setup(Vector2(position.x, minf(position.y, target_y) - 6.0), 30.0, 1)
		get_parent().add_child(e)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	# Alvo no chão
	var gy := target_y - position.y
	var k := 0.5 + 0.5 * sin(t * 20.0)
	draw_arc(Vector2(0, gy - 1), 10.0 - k * 2.0, 0, TAU, 16, Color(1.0, 0.25, 0.15, 0.5), 1.2)
	draw_line(Vector2(-4, gy - 1), Vector2(4, gy - 1), Color(1.0, 0.25, 0.15, 0.4), 1.0)
	# Bomba
	draw_circle(Vector2.ZERO, 4.0, Color("2a2626"))
	draw_rect(Rect2(-1.5, -7, 3, 3), Color("8a1e1e"))
	draw_circle(Vector2(1.2, -1.2), 1.0, Color(1, 1, 1, 0.3))
	if fmod(t, 0.2) < 0.1:
		draw_circle(Vector2(0, -7), 1.2, Color(1.0, 0.6, 0.2))
