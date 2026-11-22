extends Area2D
## Torreta-sentinela da Torre (Ato 3). Presa ao chão, gira o cano atrás de
## Sera quando a vê; mira por um instante (laser) e dispara uma rajada.
## Rolar ou encostar escapa dos tiros. 3 rebites ou uma explosão a destroem.

const BulletScript := preload("res://scripts/entities/enemy_bullet.gd")
const Fx := preload("res://scripts/fx.gd")
const RANGE := 280.0
const AIM_TIME := 0.7
const SHOTS := 3
const COOLDOWN := 1.6
const HEAD := Vector2(0, -14)

var facing: int = 1
var hp := 3
var broken := false
var aim := 0.0          # ângulo do cano (rad, 0 = para a frente)
var state := 0          # 0 vigiando, 1 mirando, 2 atirando, 3 recarga
var t := 0.0
var shots := 0
var flash := 0.0
var anim := 0.0
var sweep := 0.0


func setup(pos: Vector2, f: int, off: float) -> void:
	position = pos
	facing = f
	sweep = off
	z_index = 4


func _ready() -> void:
	add_to_group("turret")
	add_to_group("breakable")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 20)
	cs.shape = shape
	cs.position = Vector2(0, -10)
	add_child(cs)


func head_pos() -> Vector2:
	return global_position + HEAD


func barrel_dir() -> Vector2:
	return Vector2(cos(aim) * facing, sin(aim))


func _player():
	return Game.world.player if Game.world else null


func _sees(p) -> bool:
	if p == null or p.is_dead() or p.in_cover:
		return false
	var to: Vector2 = p.center() - head_pos()
	if to.length() > RANGE or signf(to.x) != float(facing) or absf(to.y) > 90.0:
		return false
	var q := PhysicsRayQueryParameters2D.create(head_pos(), p.center(), 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _physics_process(delta: float) -> void:
	anim += delta
	flash = maxf(flash - delta, 0.0)
	if broken or Game.world == null or not Game.world.is_active(global_position):
		queue_redraw()
		return
	var p = _player()
	t += delta
	match state:
		0:
			# Varredura lenta enquanto vigia.
			aim = sin((anim + sweep) * 1.2) * 0.25
			if _sees(p):
				state = 1
				t = 0.0
				Sfx.play("blip", -4.0, 1.6)
		1:
			if p != null:
				_track(p, delta, 8.0)
			if not _sees(p):
				state = 3
				t = COOLDOWN * 0.5
			elif t >= AIM_TIME:
				state = 2
				t = 0.0
				shots = SHOTS
		2:
			if p != null:
				_track(p, delta, 3.0)
			if t >= 0.13 and shots > 0:
				t = 0.0
				shots -= 1
				_fire()
			elif shots <= 0:
				state = 3
				t = 0.0
		3:
			aim = lerpf(aim, 0.0, delta * 2.0)
			if t >= COOLDOWN:
				state = 0
				t = 0.0
	queue_redraw()


func _track(p, delta: float, speed: float) -> void:
	var to: Vector2 = p.center() - head_pos()
	var want := atan2(to.y, absf(to.x))
	aim = lerp_angle(aim, clampf(want, -0.7, 0.7), delta * speed)


func _fire() -> void:
	var b = BulletScript.new()
	var d := barrel_dir()
	b.setup_vel(head_pos() + d * 12.0, d * 260.0)
	get_parent().add_child(b)
	flash = 0.07
	Sfx.play("eshot", -5.0, 1.3)
	Fx.smoke(get_parent(), head_pos() + d * 14.0, 2)


func on_rivet_hit(_dir: int) -> void:
	if broken:
		return
	hp -= 1
	flash = 0.12
	Sfx.play("clang", -4.0, 1.4)
	Fx.sparks(get_parent(), head_pos())
	if hp <= 0:
		destroy()
	elif state == 0:
		state = 1
		t = 0.0


func distance_to_point(p: Vector2) -> float:
	return head_pos().distance_to(p)


func destroy() -> void:
	if broken:
		return
	broken = true
	collision_layer = 0
	Sfx.play("crash", -6.0, 1.3)
	Fx.sparks(get_parent(), head_pos())
	Fx.smoke(get_parent(), head_pos(), 8)
	Fx.burst(get_parent(), head_pos(), Color(1.0, 0.7, 0.3), 14, 140.0, 0.4, Vector2(0, 300), 1.5)
	if Game.world and Game.world.blood:
		Game.world.blood.gibs(head_pos(), 6, [Color("5a5250"), Color("8a6a2a"), Color("3a3330")], false, 200.0)
	queue_redraw()


func _draw() -> void:
	# Base
	draw_rect(Rect2(-8, -6, 16, 6), Color("2c2622"))
	draw_rect(Rect2(-8, -6, 16, 1.5), Color("8a6a2a"))
	draw_rect(Rect2(-3, -12, 6, 6), Color("3a3330"))
	if broken:
		draw_set_transform(HEAD + Vector2(0, 4), 0.8 * facing, Vector2(facing, 1))
		draw_rect(Rect2(-5, -4, 10, 7), Color("2a2523"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if fmod(anim, 1.3) < 0.1:
			draw_circle(HEAD + Vector2(facing * 4, 2), 1.6, Color(1.0, 0.8, 0.4, 0.8))
		return
	var d := barrel_dir()
	# Laser de mira
	if state == 1:
		var a := 0.3 + 0.3 * sin(anim * 40.0)
		draw_line(HEAD + d * 12.0, HEAD + d * RANGE, Color(1, 0.2, 0.15, a), 1.0)
	# Cabeça e cano
	draw_set_transform(HEAD, d.angle(), Vector2.ONE)
	var body := Color("4a4240") if flash <= 0.0 else Color(1, 0.85, 0.8)
	draw_rect(Rect2(-6, -5, 12, 10), body)
	draw_rect(Rect2(-6, -5, 12, 2), Color("8a8480"))
	draw_rect(Rect2(4, -1.5, 9, 3), Color("2a2626"))
	draw_circle(Vector2(-1, 0), 2.0, Color(1.0, 0.3, 0.15) if state >= 1 and state <= 2 else Color(0.9, 0.7, 0.3))
	if flash > 0.0 and state == 2:
		draw_circle(Vector2(15, 0), 3.0, Color(1, 0.8, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
