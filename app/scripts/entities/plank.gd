extends StaticBody2D
## Tábua podre (uma célula): plataforma vazada que range e cai pouco depois de
## Sera pisar. Volta depois de alguns segundos.

const Fx := preload("res://scripts/fx.gd")
const SHAKE_TIME := 0.45
const RESPAWN := 4.0

var state := 0          # 0 firme, 1 rangendo, 2 caída
var t := 0.0
var fall_y := 0.0
var cs: CollisionShape2D


func setup(pos: Vector2) -> void:
	position = pos
	z_index = 1


func _ready() -> void:
	add_to_group("plank")
	collision_layer = 16
	collision_mask = 0
	cs = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 6)
	cs.shape = shape
	cs.position = Vector2(10, 3)
	cs.one_way_collision = true
	add_child(cs)


func _player_on() -> bool:
	var p = Game.world.player if Game.world else null
	if p == null or p.is_dead() or not p.is_on_floor():
		return false
	var x: float = p.global_position.x
	return x > global_position.x - 4.0 and x < global_position.x + 24.0 \
			and absf(p.global_position.y - global_position.y) < 3.0


func _physics_process(delta: float) -> void:
	match state:
		0:
			if _player_on():
				state = 1
				t = SHAKE_TIME
				Sfx.play("clunk", -12.0, 1.6)
		1:
			t -= delta
			if t <= 0.0:
				state = 2
				t = RESPAWN
				fall_y = 0.0
				cs.set_deferred("disabled", true)
				Fx.burst(get_parent(), global_position + Vector2(10, 3), Color("6e4a2c"), 8, 60.0, 0.6, Vector2(0, 400), 2.0)
				Sfx.play("crash", -14.0, 1.8)
		2:
			t -= delta
			fall_y += delta * 260.0
			if t <= 0.0:
				state = 0
				fall_y = 0.0
				cs.set_deferred("disabled", false)
	queue_redraw()


func _draw() -> void:
	if state == 2:
		if fall_y < 300.0:
			draw_set_transform(Vector2(10, 3 + fall_y), fall_y * 0.01, Vector2.ONE)
			draw_rect(Rect2(-10, -3, 20, 5), Color(0.35, 0.24, 0.15, clampf(1.0 - fall_y / 300.0, 0.0, 1.0)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Suportes vazios
		draw_rect(Rect2(0, 0, 2, 4), Color("3a2c22"))
		draw_rect(Rect2(18, 0, 2, 4), Color("3a2c22"))
		return
	var off := Vector2.ZERO
	if state == 1:
		off = Vector2(randf_range(-0.8, 0.8), randf_range(0, 1.2))
	draw_rect(Rect2(off + Vector2(0, 0), Vector2(20, 5)), Color("6e4a2c"))
	draw_rect(Rect2(off + Vector2(0, 0), Vector2(20, 1.5)), Color("9a6a3c"))
	draw_line(off + Vector2(6, 1), off + Vector2(9, 4), Color("3a2c22"), 1.0)
	draw_line(off + Vector2(14, 2), off + Vector2(12, 5), Color("3a2c22"), 1.0)
	draw_circle(off + Vector2(2, 2.5), 0.8, Color("2a2523"))
	draw_circle(off + Vector2(18, 2.5), 0.8, Color("2a2523"))
