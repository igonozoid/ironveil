extends Node2D
## Arpão de mão (upgrade do Dirigível Vigília): tiro carregado que atravessa
## inimigos, ignora escudos e couraças (2 de dano) e para na parede. Em
## chefões e objetos conta como dois rebites.

const Fx := preload("res://scripts/fx.gd")
const SPEED := 560.0

var dir: int = 1
var life := 1.2
var start := Vector2.ZERO
var hit_rids: Array = []
var stuck := false
var stuck_t := 0.0


func setup(pos: Vector2, d: int) -> void:
	position = pos
	start = pos
	dir = d
	z_index = 6


func _physics_process(delta: float) -> void:
	if stuck:
		stuck_t += delta
		modulate.a = clampf(1.0 - (stuck_t - 0.6) / 0.4, 0.0, 1.0)
		if stuck_t > 1.0:
			queue_free()
		queue_redraw()
		return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var from := global_position
	var to := from + Vector2(dir * SPEED * delta, 0)
	var space := get_world_2d().direct_space_state
	# Atravessa tudo o que não for parede, acertando cada alvo uma vez.
	for i in 8:
		var q := PhysicsRayQueryParameters2D.create(from, to, 1 | 4 | 8, hit_rids)
		q.collide_with_areas = true
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var col = hit["collider"]
		var pos: Vector2 = hit["position"]
		hit_rids.append(hit["rid"])
		if col is StaticBody2D or (col is CollisionObject2D and (col.collision_layer & 1) != 0 and not col.has_method("on_rivet_hit")):
			global_position = pos - Vector2(dir * 2, 0)
			stuck = true
			Sfx.play("clang", -4.0, 0.7)
			Fx.sparks(get_parent(), pos)
			queue_redraw()
			return
		_strike(col, pos)
	global_position = to
	if Game.world and not Game.world.is_active(global_position):
		queue_free()
	queue_redraw()


func _strike(col, pos: Vector2) -> void:
	Fx.sparks(get_parent(), pos)
	if col.has_method("pierce_hit"):
		col.pierce_hit(dir)
	elif col.has_method("on_rivet_hit"):
		col.on_rivet_hit(dir)
		if is_instance_valid(col) and col.has_method("on_rivet_hit"):
			col.on_rivet_hit(dir)
	if Game.world:
		Game.world.shake(2.0)


func _draw() -> void:
	# Cabo até o ponto de disparo e a ponta farpada
	var back := start - global_position
	draw_line(back, Vector2.ZERO, Color(0.75, 0.72, 0.66, 0.6), 1.0)
	draw_line(Vector2(-dir * 12, 0), Vector2.ZERO, Color("c8c4bc"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(dir * 5, 0), Vector2(-dir * 1, -3), Vector2(-dir * 1, 3)]), Color("e0b860"))
