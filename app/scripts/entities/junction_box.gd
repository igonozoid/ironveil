extends Area2D
## Caixa de força que mantém uma grade suspensa. Cortar a corrente (rebite,
## interação ou explosão) derruba a grade.

const Fx := preload("res://scripts/fx.gd")

var grate = null
var is_cut := false
var prompt := "A: cortar a corrente"
var t := 0.0


func _ready() -> void:
	add_to_group("junction")
	add_to_group("interactable")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	z_index = 2
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 24)
	cs.shape = shape
	add_child(cs)


func can_interact() -> bool:
	return not is_cut


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 18.0 and absf(p.global_position.y - global_position.y) < 24.0


func interact(_p) -> void:
	cut()


func on_rivet_hit(_dir: int) -> void:
	cut()


func cut() -> void:
	if is_cut:
		return
	is_cut = true
	Fx.sparks(get_parent(), global_position)
	Fx.sparks(get_parent(), global_position + Vector2(0, -6))
	Sfx.play("spark")
	set_deferred("collision_layer", 0)
	if grate != null:
		grate.drop()
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	if is_cut and randf() < delta * 1.5:
		Fx.sparks(get_parent(), global_position + Vector2(randf_range(-4, 4), -4))
	if not is_cut:
		queue_redraw()


func _draw() -> void:
	draw_line(Vector2(0, -8), Vector2(0, -40), Color("2a2523"), 2.0)
	draw_rect(Rect2(-6, -8, 12, 16), Color("4a4542"))
	draw_rect(Rect2(-6, -8, 12, 16), Color("e8c547") if not is_cut else Color("3a3330"), false, 1.2)
	if not is_cut:
		var c := Color(1.0, 0.85, 0.3, 0.7 + 0.3 * sin(t * 9.0))
		draw_polyline(PackedVector2Array([Vector2(1, -6), Vector2(-2, 0), Vector2(1.5, 0), Vector2(-1, 6)]), c, 1.5)
	else:
		draw_line(Vector2(-4, -4), Vector2(4, 4), Color("1e1b1b"), 2.0)
