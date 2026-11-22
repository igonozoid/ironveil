extends Node2D
## Alavanca (interagir): aciona o elevador de carga mais próximo.

var lift = null
var prompt := "A: acionar alavanca"
var pulled := false
var anim := 0.0


func _ready() -> void:
	add_to_group("interactable")
	z_index = 2


func can_interact() -> bool:
	return lift != null and not lift.moving


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 16.0 and absf(p.global_position.y - global_position.y) < 24.0


func interact(_p) -> void:
	if lift == null or lift.moving:
		return
	pulled = not pulled
	Sfx.play("lever")
	lift.toggle()


func _process(delta: float) -> void:
	var target := 1.0 if pulled else 0.0
	if anim != target:
		anim = move_toward(anim, target, delta * 6.0)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-6, -10, 12, 10), Color("3a3330"))
	draw_rect(Rect2(-6, -10, 12, 2), Color("b87333"))
	var a := lerpf(-0.7, 0.7, anim)
	var tip := Vector2(0, -8) + Vector2(sin(a), -cos(a)) * 12.0
	draw_line(Vector2(0, -8), tip, Color("8a8f96"), 2.0)
	draw_circle(tip, 2.5, Color("c03020"))
