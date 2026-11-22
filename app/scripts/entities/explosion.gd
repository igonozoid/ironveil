extends Node2D
## Explosão com dano em área: fere Sera, guardas e drones, destrói grades e
## corta caixas de força dentro do raio.

const Fx := preload("res://scripts/fx.gd")
const Light := preload("res://scripts/fx/light.gd")

var radius := 44.0
var power := 2
var t := 0.0
const DUR := 0.35


func setup(pos: Vector2, r: float, p: int) -> void:
	position = pos
	radius = r
	power = p
	z_index = 9


func _ready() -> void:
	call_deferred("_apply")
	var par := get_parent()
	Fx.burst(par, position, Color(1.0, 0.7, 0.3), 30, radius * 5.0, 0.5, Vector2(0, 250), 2.0)
	Fx.fire(par, position, int(radius))
	Fx.smoke(par, position, 16)
	Fx.steam_puff(par, position, 14)
	Fx.sparks(par, position)
	Fx.sparks(par, position + Vector2(4, -4))
	Light.make(par, position, Color(1.0, 0.6, 0.25), radius * 4.0, 2.2, 0.0, 0.45)
	Sfx.play("explosion", -2.0 if radius > 30.0 else -6.0)
	if Game.world:
		Game.world.shake(6.0 if radius > 30.0 else 3.0)


func _apply() -> void:
	var c := global_position
	var player = Game.world.player
	if player != null and not player.is_dead():
		if player.center().distance_to(c) < radius + 6.0:
			player.hurt(1, "blast")
	for g in get_tree().get_nodes_in_group("guard"):
		if g.global_position.distance_to(c) < radius + 12.0 or (g.global_position + Vector2(0, -16)).distance_to(c) < radius + 8.0:
			g.blast_hit(power, c)
	for bs in get_tree().get_nodes_in_group("boss"):
		if bs.center().distance_to(c) < radius + 30.0:
			bs.blast_hit(power, c)
	for d in get_tree().get_nodes_in_group("drone"):
		if d.global_position.distance_to(c) < radius + 6.0:
			d.call_deferred("explode")
	for cv in get_tree().get_nodes_in_group("civilian"):
		if cv.global_position.distance_to(c) < radius * 3.0:
			cv.panic(c)
	for b in get_tree().get_nodes_in_group("breakable"):
		if b.distance_to_point(c) < radius:
			b.destroy()
	for j in get_tree().get_nodes_in_group("junction"):
		if j.global_position.distance_to(c) < radius + 8.0:
			j.cut()


func _process(delta: float) -> void:
	t += delta
	if t >= DUR:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := t / DUR
	draw_circle(Vector2.ZERO, radius * (0.4 + k * 0.7), Color(1.0, 0.75, 0.35, 0.5 * (1.0 - k)))
	draw_circle(Vector2.ZERO, radius * (0.2 + k * 0.5), Color(1.0, 0.95, 0.8, 0.7 * (1.0 - k)))
	draw_arc(Vector2.ZERO, radius * (0.5 + k * 0.6), 0, TAU, 32, Color(0.95, 0.95, 0.95, 0.6 * (1.0 - k)), 3.0)
