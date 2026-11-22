extends Area2D
## Drone de vapor: voa num padrão fixo e explode ao tocar Sera.
## Um rebite, vapor ou explosão o destroem (a explosão fere quem estiver perto).

const ExplosionScript := preload("res://scripts/entities/explosion.gd")

var pattern := "h"
var origin := Vector2.ZERO
var t := 0.0
var dead := false
var prop := 0.0


func setup(pos: Vector2, pat: String) -> void:
	origin = pos
	position = pos
	pattern = pat
	z_index = 5


func _ready() -> void:
	add_to_group("drone")
	add_to_group("enemy")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	if dead or Game.world == null or not Game.world.is_active(origin):
		return
	t += delta
	prop += delta * 40.0
	match pattern:
		"v":
			position = origin + Vector2(sin(t * 2.0) * 2.0, sin(t * TAU / 2.6) * 50.0)
		"o":
			position = origin + Vector2(cos(t * TAU / 3.0), sin(t * TAU / 3.0)) * 40.0
		_:
			position = origin + Vector2(sin(t * TAU / 3.2) * 60.0, sin(t * 4.0) * 2.0)
	var p = Game.world.player
	if p != null and not p.is_dead():
		var hb: Rect2 = p.hitbox()
		if hb.grow(4.0).has_point(global_position):
			explode()
	queue_redraw()


func on_rivet_hit(_dir: int) -> void:
	explode()


func steam_hit(_n: int) -> void:
	explode()


func explode() -> void:
	if dead:
		return
	dead = true
	if Game.world and Game.world.blood:
		Game.world.blood.gibs(global_position, 6, [Color("5a5250"), Color("8a5a2b"), Color("3a3330")], false, 200.0)
	var e = ExplosionScript.new()
	e.setup(global_position, 26.0, 1)
	get_parent().add_child(e)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("5a5250"))
	draw_circle(Vector2.ZERO, 5.0, Color("8a5a2b"))
	draw_circle(Vector2(0, 0.5), 2.6, Color(1.0, 0.3 + 0.2 * sin(t * 10.0), 0.15))
	var w := absf(sin(prop)) * 9.0
	draw_line(Vector2(-w, -9), Vector2(w, -9), Color(0.85, 0.85, 0.85, 0.7), 1.5)
	draw_line(Vector2(0, -7), Vector2(0, -9), Color("5a5250"), 1.5)
	draw_circle(Vector2(0, 8), 1.5 + absf(sin(t * 7.0)), Color(0.95, 0.95, 0.95, 0.5))
