extends Node2D
## Tiro dos guardas. Passa por cima de Sera agachada (altura do peito do guarda)
## e não a atinge enquanto ela estiver encostada.

const Fx := preload("res://scripts/fx.gd")
const SPEED := 240.0

var dir: int = 1
var life := 2.5
## Velocidade livre (tiros inclinados do dirigível). Zero = horizontal.
var vel := Vector2.ZERO


func setup(pos: Vector2, d: int) -> void:
	position = pos
	dir = d
	z_index = 6


func setup_vel(pos: Vector2, v: Vector2) -> void:
	position = pos
	vel = v
	dir = 1 if v.x >= 0.0 else -1
	z_index = 6


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var from := global_position
	var to := from + (vel * delta if vel != Vector2.ZERO else Vector2(dir * SPEED * delta, 0))
	var q := PhysicsRayQueryParameters2D.create(from, to, 1 | 2)
	var player = Game.world.player if Game.world else null
	if player != null and (player.in_cover or player.is_rolling()):
		# Encostada ou rolando, o tiro passa por Sera.
		q.exclude = [player.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var col = hit["collider"]
		if col != null and col.is_in_group("player"):
			col.hurt(1, "bullet")
		else:
			Fx.sparks(get_parent(), hit["position"])
		queue_free()
		return
	global_position = to
	if Game.world and not Game.world.is_active(global_position):
		queue_free()
	queue_redraw()


func _draw() -> void:
	if vel != Vector2.ZERO:
		draw_line(-vel.normalized() * 10.0, Vector2.ZERO, Color(1.0, 0.4, 0.2, 0.45), 2.0)
		draw_circle(Vector2.ZERO, 1.8, Color("ffb060"))
		return
	draw_line(Vector2(-dir * 10, 0), Vector2.ZERO, Color(1.0, 0.4, 0.2, 0.45), 2.0)
	draw_circle(Vector2.ZERO, 1.8, Color("ffb060"))
