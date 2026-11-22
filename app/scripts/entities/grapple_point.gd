extends Node2D
## Ponto marcado para o rebite de escalada. Ao receber o rebite vira um pino
## onde Sera pode se agarrar e ficar de pé (plataforma vazada).

var anchored := false
var t := 0.0


func _ready() -> void:
	add_to_group("grapple")
	z_index = 2


func anchor() -> void:
	if anchored:
		return
	anchored = true
	Sfx.play("clunk", -2.0, 1.4)
	var body := StaticBody2D.new()
	body.collision_layer = 16
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 4)
	cs.shape = shape
	cs.position = Vector2(0, 2)
	cs.one_way_collision = true
	body.add_child(cs)
	add_child(body)
	Game.world.level.hang_points.append(global_position)
	queue_redraw()


func _process(delta: float) -> void:
	if not anchored:
		t += delta
		queue_redraw()


func _draw() -> void:
	if anchored:
		draw_rect(Rect2(-9, 0, 18, 4), Color("8a8f96"))
		draw_rect(Rect2(-9, 0, 18, 1), Color("c0c4c8"))
		draw_circle(Vector2(9, 2), 2.5, Color("b87333"))
	else:
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		var c := Vector2(7, 4)
		draw_arc(c, 4.0 + pulse * 1.5, 0, TAU, 16, Color(0.91, 0.77, 0.28, 0.6 + 0.4 * pulse), 1.5)
		draw_line(c + Vector2(-2, 0), c + Vector2(2, 0), Color("e8c547"), 1.2)
		draw_line(c + Vector2(0, -2), c + Vector2(0, 2), Color("e8c547"), 1.2)
