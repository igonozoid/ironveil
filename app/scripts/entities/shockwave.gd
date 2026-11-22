extends Node2D
## Onda de choque da martelada do chefão: corre pelo chão até bater numa parede.
## Fere Sera mesmo encostada na reentrância — é preciso pular por cima.

const Fx := preload("res://scripts/fx.gd")
const H := 14.0

var dir: int = 1
var speed := 210.0
var life := 2.2
var t := 0.0
var dust_t := 0.0


func setup(pos: Vector2, d: int, spd: float) -> void:
	position = pos
	dir = d
	speed = spd
	z_index = 6


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	var w = Game.world
	if w == null or life <= 0.0:
		queue_free()
		return
	position.x += dir * speed * delta
	var lvl = w.level
	var ahead: Vector2i = lvl.world_to_cell(global_position + Vector2(dir * 6.0, -6.0))
	var below: Vector2i = lvl.world_to_cell(global_position + Vector2(dir * 6.0, 4.0))
	if lvl.is_solid(ahead) or not lvl.is_solid(below) and not _over_lift():
		Fx.dust(get_parent(), global_position, 10)
		queue_free()
		return
	dust_t -= delta
	if dust_t <= 0.0:
		dust_t = 0.05
		Fx.dust(get_parent(), global_position, 3)
	var p = w.player
	if p != null and not p.is_dead():
		var r := Rect2(global_position.x - 7.0, global_position.y - H, 14.0, H)
		if r.intersects(p.hitbox()):
			p.hurt(1, "shock")
	queue_redraw()


func _over_lift() -> bool:
	for l in Game.world.level.lifts:
		if absf(l.global_position.x - global_position.x) < 32.0 and absf(l.global_position.y - global_position.y) < 4.0:
			return true
	return false


func _draw() -> void:
	var k := 0.5 + 0.5 * sin(t * 40.0)
	var pts := PackedVector2Array([
		Vector2(-dir * 14, 0), Vector2(-dir * 4, -H * (0.6 + 0.2 * k)),
		Vector2(dir * 2, -H), Vector2(dir * 8, 0)])
	draw_colored_polygon(pts, Color(0.95, 0.9, 0.85, 0.35))
	draw_polyline(PackedVector2Array([Vector2(-dir * 14, 0), Vector2(-dir * 4, -H * 0.7), Vector2(dir * 2, -H), Vector2(dir * 8, 0)]),
		Color(1.0, 0.75, 0.4, 0.8), 1.5)
	for i in 3:
		var x := -dir * (4 + i * 5) + randf_range(-1, 1)
		draw_circle(Vector2(x, -randf_range(2, 10)), 1.2, Color(0.6, 0.5, 0.42, 0.8))
