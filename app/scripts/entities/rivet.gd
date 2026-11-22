extends Node2D
## Rebite do lança-rebites de Sera. Viaja na horizontal usando raycast.

const Fx := preload("res://scripts/fx.gd")
const SPEED := 430.0

var dir: int = 1
var life := 1.4


func setup(pos: Vector2, d: int) -> void:
	position = pos
	dir = d
	z_index = 6


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var from := global_position
	var to := from + Vector2(dir * SPEED * delta, 0)
	var q := PhysicsRayQueryParameters2D.create(from, to, 1 | 4 | 8)
	q.collide_with_areas = true
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var col = hit["collider"]
		var pos: Vector2 = hit["position"]
		if col != null and col.has_method("on_rivet_hit"):
			col.on_rivet_hit(dir)
		else:
			Sfx.play("ricochet", -10.0)
		Fx.sparks(get_parent(), pos)
		queue_free()
		return
	global_position = to
	if Game.world and not Game.world.is_active(global_position):
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-dir * 8, 0), Vector2.ZERO, Color(0.85, 0.55, 0.3, 0.5), 1.5)
	draw_line(Vector2(-dir * 3, 0), Vector2(dir * 1, 0), Color("e0a060"), 2.5)
