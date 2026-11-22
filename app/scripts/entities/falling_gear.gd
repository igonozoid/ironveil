extends Node2D
## Engrenagem que despenca do mecanismo do Regulador (chefão do Ato 3).
## Marca um alvo no chão, cai e sai rolando; rolar (C) atravessa a engrenagem
## rolando, mas não a que está caindo.

const Fx := preload("res://scripts/fx.gd")
const R := 9.0

var warn := 0.8
var vy := 0.0
var floor_y := 0.0
var landed := false
var roll_dir := 1.0
var roll_t := 0.0
var rot := 0.0
var t := 0.0
var hit_cd := 0.0


func setup(x: float, top_y: float, floor_world_y: float, delay: float) -> void:
	position = Vector2(x, top_y)
	floor_y = floor_world_y
	warn = 0.8 + delay
	roll_dir = 1.0 if randf() < 0.5 else -1.0
	z_index = 6


func _physics_process(delta: float) -> void:
	t += delta
	hit_cd = maxf(hit_cd - delta, 0.0)
	if warn > 0.0:
		warn -= delta
		queue_redraw()
		return
	var lvl = Game.world.level if Game.world else null
	if not landed:
		vy = minf(vy + 900.0 * delta, 520.0)
		position.y += vy * delta
		rot += delta * 6.0
		_hurt_player("crush")
		if position.y >= floor_y - R:
			position.y = floor_y - R
			landed = true
			Sfx.play("clang", -4.0, 0.7)
			Fx.sparks(get_parent(), Vector2(position.x, floor_y))
			Fx.dust(get_parent(), Vector2(position.x, floor_y), 8)
			if Game.world:
				Game.world.shake(2.0)
	else:
		roll_t += delta
		var nx := position.x + roll_dir * 85.0 * delta
		if lvl != null and lvl.is_solid(lvl.world_to_cell(Vector2(nx + roll_dir * R, position.y))):
			roll_dir = -roll_dir
		else:
			position.x = nx
		rot += roll_dir * 85.0 * delta / R
		_hurt_player("blade")
		if roll_t > 1.6:
			modulate.a = maxf(0.0, 1.0 - (roll_t - 1.6) / 0.4)
			if roll_t > 2.0:
				queue_free()
				return
	queue_redraw()


func _hurt_player(kind: String) -> void:
	if Game.world == null or hit_cd > 0.0:
		return
	var p = Game.world.player
	if p == null or p.is_dead():
		return
	var r := Rect2(global_position - Vector2(R - 2.0, R - 2.0), Vector2(R * 2.0 - 4.0, R * 2.0 - 4.0))
	if r.intersects(p.hitbox()):
		p.hurt(1, kind)
		hit_cd = 0.6
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and r.intersects(g.rect()):
			g.crush()


func _draw() -> void:
	if warn > 0.0:
		var gy := floor_y - position.y
		var k := 0.5 + 0.5 * sin(t * 18.0)
		draw_arc(Vector2(0, gy - 1), 10.0 - k * 2.0, 0, TAU, 16, Color(1.0, 0.7, 0.2, 0.55), 1.3)
		draw_line(Vector2(-5, gy - 1), Vector2(5, gy - 1), Color(1.0, 0.7, 0.2, 0.45), 1.0)
		return
	draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
	for i in 8:
		var a := i * TAU / 8.0
		draw_rect(Rect2(Vector2.from_angle(a) * (R - 1.0) - Vector2(2, 2), Vector2(4, 4)), Color("8a6a2a"))
	draw_circle(Vector2.ZERO, R - 1.5, Color("a07a38"))
	draw_circle(Vector2.ZERO, R - 4.5, Color("6e5428"))
	draw_circle(Vector2.ZERO, 2.0, Color("2a2420"))
	draw_line(Vector2(-R + 3, 0), Vector2(R - 3, 0), Color("e0b860"), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
