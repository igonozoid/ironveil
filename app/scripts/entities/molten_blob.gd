extends Node2D
## Bola de ferro fundido lançada pela Fornalha-Mãe: voa em arco e espirra
## fogo onde cai. Fere Sera no voo e na queda (rolar escapa).

const Fx := preload("res://scripts/fx.gd")

var vel := Vector2.ZERO
var t := 0.0


func setup(pos: Vector2, v: Vector2) -> void:
	position = pos
	vel = v
	z_index = 6


func _physics_process(delta: float) -> void:
	t += delta
	vel.y = minf(vel.y + 520.0 * delta, 480.0)
	position += vel * delta
	if fmod(t, 0.05) < delta:
		Fx.burst(get_parent(), position, Color(1.0, 0.55, 0.15), 1, 20.0, 0.4, Vector2(0, 100), 1.5)
	var w = Game.world
	if w == null or t > 4.0:
		queue_free()
		return
	var p = w.player
	if p != null and not p.is_dead() and p.hitbox().grow(2.0).has_point(position):
		p.hurt(1, "blast")
		_splash()
		return
	var lvl = w.level
	var c: Vector2i = lvl.world_to_cell(position + Vector2(0, 3))
	if lvl.is_solid(c) or lvl.is_oneway(c):
		_splash()
		return
	for l in get_tree().get_nodes_in_group("lava"):
		if l.rect.has_point(position + Vector2(0, -4)):
			queue_free()
			return
	queue_redraw()


func _splash() -> void:
	Fx.fire(get_parent(), position, 18)
	Fx.burst(get_parent(), position, Color(1.0, 0.6, 0.2), 14, 140.0, 0.5, Vector2(0, 300), 1.8)
	Sfx.play("steam", -6.0, 1.4)
	var p = Game.world.player if Game.world else null
	if p != null and not p.is_dead() and p.center().distance_to(position) < 22.0:
		p.hurt(1, "blast")
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.5, 0.1, 0.35))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.65, 0.2))
	draw_circle(Vector2(-1, -1), 1.6, Color(1.0, 0.95, 0.7))
