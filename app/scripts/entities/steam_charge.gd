extends CharacterBody2D
## Carga de vapor arremessada: quica e explode após 2 s.

const ExplosionScript := preload("res://scripts/entities/explosion.gd")
const FUSE := 2.0

var fuse := FUSE
var spin := 0.0


func setup(pos: Vector2, vel: Vector2) -> void:
	position = pos
	velocity = vel
	z_index = 6


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 16
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	fuse -= delta
	if fuse <= 0.0:
		var e = ExplosionScript.new()
		e.setup(global_position, 46.0, 2)
		get_parent().add_child(e)
		queue_free()
		return
	velocity.y = minf(velocity.y + 700.0 * delta, 500.0)
	spin += velocity.x * delta * 0.2
	var col := move_and_collide(velocity * delta)
	if col:
		var n := col.get_normal()
		velocity = velocity.bounce(n) * 0.45
		if n.y < -0.5:
			velocity.x *= 0.7
			if absf(velocity.y) < 30.0:
				velocity.y = 0.0
		if velocity.length() > 40.0:
			Sfx.play("clunk", -14.0, 1.6)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
	draw_rect(Rect2(-3.5, -4.5, 7, 9), Color("b87333"))
	draw_rect(Rect2(-3.5, -4.5, 7, 2), Color("d9965a"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var blink_rate := 4.0 if fuse > 1.0 else 12.0
	if int(fuse * blink_rate) % 2 == 0:
		draw_circle(Vector2.ZERO, 1.8, Color("ff4030"))
		draw_circle(Vector2.ZERO, 4.0, Color(1, 0.25, 0.2, 0.25))
