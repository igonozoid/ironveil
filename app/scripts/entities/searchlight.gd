extends Area2D
## Holofote do Diretório num poste. Varre o chão com um cone de luz; se Sera
## entrar no cone (sem estar encostada nem misturada na multidão) dispara o
## alarme: os guardas da tela vêm atrás dela e um reforço desce do alto.
## Um rebite ou uma explosão o quebram.

const GuardScript := preload("res://scripts/entities/guard.gd")
const Fx := preload("res://scripts/fx.gd")
const Light := preload("res://scripts/fx/light.gd")
const HEAD := Vector2(0, -34)
const LENGTH := 230.0
const HALF := 0.17          # meia abertura do cone (rad)
const MIN_A := 0.22
const MAX_A := 1.05

var facing: int = 1
var t := 0.0
var angle := 0.5
var broken := false
var alarm := 0.0
var reinforce_t := -1.0
var reinforcements := 0
var lock_dir := Vector2.ZERO
var phase_off := 0.0
var beam_light = null


func setup(pos: Vector2, f: int, off: float) -> void:
	position = pos
	facing = f
	phase_off = off
	z_index = 4


func _ready() -> void:
	add_to_group("searchlight")
	add_to_group("breakable")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 34)
	cs.shape = shape
	cs.position = Vector2(0, -19)
	add_child(cs)
	beam_light = Light.make(self, HEAD, Color(1.0, 0.95, 0.78), 90.0, 0.7)


func head_pos() -> Vector2:
	return global_position + HEAD


func beam_dir() -> Vector2:
	if alarm > 0.0 and lock_dir != Vector2.ZERO:
		return lock_dir
	return Vector2(cos(angle) * facing, sin(angle))


func _physics_process(delta: float) -> void:
	t += delta
	if broken or Game.world == null or not Game.world.is_active(global_position):
		queue_redraw()
		return
	if beam_light != null:
		beam_light.position = HEAD + beam_dir() * 120.0
		beam_light.color = Color(1.0, 0.3, 0.2) if alarm > 0.0 else Color(1.0, 0.95, 0.78)
	var k := 0.5 + 0.5 * sin((t + phase_off) * TAU / 4.5)
	angle = lerpf(MIN_A, MAX_A, k)
	var p = Game.world.player
	if alarm > 0.0:
		alarm -= delta
		if p != null and not p.is_dead():
			lock_dir = (p.center() - head_pos()).normalized()
	elif p != null and _sees(p):
		_raise_alarm(p)
	if reinforce_t >= 0.0:
		reinforce_t -= delta
		if reinforce_t < 0.0:
			_spawn_reinforcement()
	queue_redraw()


func _sees(p) -> bool:
	if p.is_dead() or p.in_cover or p.hidden_in_crowd():
		return false
	var to: Vector2 = p.center() - head_pos()
	if to.length() > LENGTH:
		return false
	if absf(beam_dir().angle_to(to)) > HALF:
		return false
	var q := PhysicsRayQueryParameters2D.create(head_pos(), p.center(), 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _raise_alarm(p) -> void:
	alarm = 3.0
	lock_dir = (p.center() - head_pos()).normalized()
	Sfx.play("alert", 0.0, 0.8)
	Game.world.hud.message("Holofote: ALARME!")
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and Game.world.is_active(g.global_position) and g.has_method("alert_to"):
			g.alert_to(p)
	if reinforcements < 1 and reinforce_t < 0.0:
		reinforce_t = 1.0


## Um guarda desce de corda do teto mais próximo.
func _spawn_reinforcement() -> void:
	var lvl = Game.world.level
	var g = GuardScript.new()
	var x := global_position.x - facing * 30.0
	g.position = Vector2(x, global_position.y - 70.0)
	if lvl.is_solid(lvl.world_to_cell(g.position)) or lvl.is_solid(lvl.world_to_cell(g.position + Vector2(0, 30))):
		g.position = Vector2(x, global_position.y - 0.5)
	g.reinforcement = true
	get_parent().add_child(g)
	reinforcements += 1
	Fx.dust(get_parent(), Vector2(g.position.x, global_position.y), 8)
	Game.world.hud.message("Reforço do Diretório!")


func on_rivet_hit(_dir: int) -> void:
	destroy()


func distance_to_point(p: Vector2) -> float:
	return head_pos().distance_to(p)


func destroy() -> void:
	if broken:
		return
	broken = true
	alarm = 0.0
	if beam_light != null:
		beam_light.queue_free()
		beam_light = null
	collision_layer = 0
	Sfx.play("spark", -2.0)
	Sfx.play("clang", -6.0, 1.3)
	Fx.sparks(get_parent(), head_pos())
	Fx.burst(get_parent(), head_pos(), Color(0.9, 0.95, 1.0), 10, 90.0, 0.4, Vector2(0, 300), 1.5)
	queue_redraw()


func _draw() -> void:
	var h := HEAD
	# Poste
	draw_rect(Rect2(-2, -30, 4, 30), Color("3a3330"))
	draw_rect(Rect2(-5, -3, 10, 3), Color("2a2523"))
	if broken:
		draw_set_transform(h, 0.9 * facing, Vector2(facing, 1))
		draw_rect(Rect2(-5, -3, 10, 7), Color("2a2523"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if fmod(t, 1.7) < 0.08:
			draw_circle(h + Vector2(facing * 4, 2), 2.0, Color(0.8, 0.9, 1.0, 0.8))
		return
	var d := beam_dir()
	var col := Color(1.0, 0.95, 0.75) if alarm <= 0.0 else Color(1.0, 0.3, 0.2)
	# Cone
	var left := d.rotated(-HALF) * LENGTH
	var right := d.rotated(HALF) * LENGTH
	var steps := 6
	for i in steps:
		var a := (i + 1) / float(steps)
		draw_colored_polygon(PackedVector2Array([h, h + left * a, h + right * a]),
			Color(col, 0.05 if alarm <= 0.0 else 0.08))
	draw_line(h, h + d * LENGTH, Color(col, 0.12), 2.0)
	# Cabeça do holofote
	draw_set_transform(h, d.angle(), Vector2.ONE)
	draw_rect(Rect2(-6, -4, 10, 8), Color("4a4240"))
	draw_rect(Rect2(3, -4, 3, 8), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(h, 2.0, Color("b87333"))
	if alarm > 0.0 and fmod(t, 0.3) < 0.15:
		draw_circle(h + Vector2(0, -8), 2.5, Color(1.0, 0.2, 0.1))
