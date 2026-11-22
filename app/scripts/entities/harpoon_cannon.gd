extends Node2D
## Canhão-arpão do telhado (interagir): dispara um arpão para cima, inclinado
## para o lado do dirigível. Se acertar o casco: dano alto. Recarrega em 4 s.

const Fx := preload("res://scripts/fx.gd")
const RELOAD := 4.0
const SPEED := 520.0

var reload := 0.0
var prompt := "A: disparar arpão"
var shot_pos := Vector2.ZERO
var shot_vel := Vector2.ZERO
var flying := false
var t := 0.0
var aim := Vector2(0, -1)


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("harpoon")
	z_index = 3


func can_interact() -> bool:
	return reload <= 0.0 and not flying


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 18.0 and absf(p.global_position.y - global_position.y) < 20.0


func _ship():
	var b = Game.world.boss if Game.world else null
	if b != null and b.has_method("hull_rect") and b.is_alive():
		return b
	return null


func _aim_dir() -> Vector2:
	var s = _ship()
	if s == null:
		return Vector2(0, -1)
	var to: Vector2 = s.global_position - (global_position + Vector2(0, -12))
	var d := to.normalized()
	# Inclinação limitada: o canhão só gira ±35° da vertical.
	var ang := clampf(Vector2(0, -1).angle_to(d), -0.6, 0.6)
	return Vector2(0, -1).rotated(ang)


func ship_in_line() -> bool:
	var s = _ship()
	if s == null:
		return false
	var from := global_position + Vector2(0, -12)
	var d := _aim_dir()
	var r: Rect2 = s.hull_rect()
	for i in 40:
		if r.has_point(from + d * i * 10.0):
			return true
	return false


func interact(_p) -> void:
	if not can_interact():
		return
	flying = true
	shot_pos = global_position + Vector2(0, -12)
	shot_vel = _aim_dir() * SPEED
	reload = RELOAD
	Sfx.play("grapple", 0.0, 0.7)
	Sfx.play("explosion", -12.0, 1.8)
	Fx.smoke(get_parent(), shot_pos, 8)
	if Game.world:
		Game.world.shake(2.0)


func _physics_process(delta: float) -> void:
	t += delta
	aim = aim.lerp(_aim_dir(), delta * 6.0).normalized()
	if reload > 0.0 and not flying:
		reload -= delta
		if reload <= 0.0:
			Sfx.play("lever", -6.0)
	if flying:
		shot_pos += shot_vel * delta
		var s = _ship()
		if s != null and s.hull_rect().has_point(shot_pos):
			flying = false
			s.harpoon_hit(shot_pos)
		elif shot_pos.y < global_position.y - 420.0:
			flying = false
	prompt = "A: disparar arpão"
	queue_redraw()


func _draw() -> void:
	# Base
	draw_rect(Rect2(-10, -6, 20, 6), Color("3a3330"))
	draw_rect(Rect2(-10, -6, 20, 2), Color("b87333"))
	# Cano apontado
	var tip := Vector2(0, -8) + aim * 16.0
	draw_line(Vector2(0, -8), tip, Color("4a4240"), 6.0)
	draw_line(Vector2(0, -8), tip, Color("6a6260"), 2.0)
	draw_circle(Vector2(0, -8), 4.0, Color("2a2523"))
	var ready := reload <= 0.0 and not flying
	var lamp := Color(0.4, 1.0, 0.5) if ready else Color(1.0, 0.35, 0.2)
	if ready and ship_in_line():
		lamp = Color(1.0, 1.0, 0.5) if fmod(t, 0.2) < 0.1 else Color(0.4, 1.0, 0.5)
	draw_circle(Vector2(-7, -9), 1.8, lamp)
	if ready:
		# Linha de mira pontilhada
		for i in 12:
			if i % 2 == 0:
				var a := Vector2(0, -8) + aim * (20.0 + i * 12.0)
				draw_line(a, a + aim * 12.0, Color(1.0, 0.9, 0.6, 0.25), 1.0)
	else:
		var k := 1.0 - clampf(reload / RELOAD, 0.0, 1.0)
		draw_rect(Rect2(-8, 2, 16 * k, 2), Color(1.0, 0.8, 0.4, 0.8))
	if flying:
		var lp := shot_pos - global_position
		draw_line(tip, lp, Color("a8a29a"), 1.0)
		draw_line(lp, lp - shot_vel.normalized() * 10.0, Color("d0d0d0"), 2.5)
		draw_colored_polygon(PackedVector2Array([lp + shot_vel.normalized() * 5.0,
			lp + shot_vel.normalized().rotated(2.5) * 4.0, lp + shot_vel.normalized().rotated(-2.5) * 4.0]), Color("e0e0e0"))
