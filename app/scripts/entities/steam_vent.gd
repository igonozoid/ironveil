extends Node2D
## Bocal de vapor. "trigger": dispara um jato de 3 s quando a válvula ligada é
## aberta. "periodic": liga e desliga sozinho (com aviso antes do jato).
## O jato fere Sera (sem proteção da reentrância), guardas e drones.

const Fx := preload("res://scripts/fx.gd")
const WIDTH := 24.0
const TICK := 0.35
const BURST := 3.0
const ON_TIME := 1.5
const OFF_TIME := 2.1
const WARN := 0.5

var dir: int = -1          # -1 = para cima, 1 = para baixo
var length := 80.0
var mode := "trigger"
var active := false
var timer := 0.0
var tick := 0.0
var cycle := 0.0
var particles: CPUParticles2D


func setup(pos: Vector2, d: int, len_px: float, m: String, phase_offset: float) -> void:
	position = pos
	dir = d
	length = maxf(len_px, 20.0)
	mode = m
	cycle = phase_offset
	z_index = 3


func _ready() -> void:
	add_to_group("vent")
	particles = CPUParticles2D.new()
	particles.amount = 48
	particles.lifetime = 0.45
	particles.direction = Vector2(0, dir)
	particles.spread = 9.0
	particles.initial_velocity_min = length * 2.0
	particles.initial_velocity_max = length * 2.6
	particles.gravity = Vector2.ZERO
	particles.damping_min = 20.0
	particles.damping_max = 60.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(4, 1)
	particles.color_ramp = Fx.fade_ramp(Color(0.95, 0.95, 0.95, 0.75))
	particles.emitting = false
	add_child(particles)


func trigger() -> void:
	_set_active(true)
	timer = BURST


func _set_active(on: bool) -> void:
	if on == active:
		return
	active = on
	particles.emitting = on
	if on and Game.world and Game.world.is_active(global_position + Vector2(0, -2 * dir)):
		Sfx.play("steam", -4.0)


func jet_rect() -> Rect2:
	if dir < 0:
		return Rect2(global_position.x - WIDTH * 0.5, global_position.y - length, WIDTH, length)
	return Rect2(global_position.x - WIDTH * 0.5, global_position.y, WIDTH, length)


func _warning() -> bool:
	return mode == "periodic" and not active and cycle > OFF_TIME - WARN


func _physics_process(delta: float) -> void:
	if mode == "periodic":
		cycle += delta
		if active and cycle >= ON_TIME:
			_set_active(false)
			cycle = 0.0
		elif not active and cycle >= OFF_TIME:
			_set_active(true)
			cycle = 0.0
	elif active:
		timer -= delta
		if timer <= 0.0:
			_set_active(false)
	if active:
		tick -= delta
		if tick <= 0.0:
			tick = TICK
			_damage()
	else:
		tick = 0.0
	queue_redraw()


func _damage() -> void:
	var r := jet_rect()
	var p = Game.world.player
	if p != null and not p.is_dead() and r.intersects(p.hitbox()):
		p.hurt(1, "steam")
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and r.intersects(g.rect()):
			g.steam_hit(1)
	for bs in get_tree().get_nodes_in_group("boss"):
		if bs.is_alive() and r.intersects(bs.rect()):
			bs.steam_hit(1)
	for d in get_tree().get_nodes_in_group("drone"):
		if r.grow(4).has_point(d.global_position):
			d.steam_hit(1)


func _draw() -> void:
	# Bocal
	var base := Vector2(0, 0)
	if dir < 0:
		draw_rect(Rect2(base + Vector2(-7, -5), Vector2(14, 5)), Color("6e4a2c"))
		draw_rect(Rect2(base + Vector2(-5, -7), Vector2(10, 2)), Color("b87333"))
	else:
		draw_rect(Rect2(base + Vector2(-7, 0), Vector2(14, 5)), Color("6e4a2c"))
		draw_rect(Rect2(base + Vector2(-5, 5), Vector2(10, 2)), Color("b87333"))
	if active:
		var r := jet_rect()
		r.position -= global_position
		draw_rect(r, Color(1, 1, 1, 0.12))
		draw_rect(r.grow_individual(-6, 0, -6, 0), Color(1, 1, 1, 0.16))
	elif _warning():
		var k := fmod(cycle * 10.0, 1.0)
		draw_circle(Vector2(0, dir * (6.0 + k * 8.0)), 2.0 + k * 3.0, Color(1, 1, 1, 0.45 * (1.0 - k)))
		draw_circle(Vector2(0, -2.5 * dir), 2.0, Color(1.0, 0.5, 0.2, 0.8))
