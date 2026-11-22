extends Node2D
## Válvula (interagir): solta jatos nos bocais de vapor da mesma tela.

var vents: Array = []
var prompt := "A: abrir válvula"
var cooldown := 0.0
var spin := 0.0


func _ready() -> void:
	add_to_group("interactable")
	z_index = 2


func can_interact() -> bool:
	return cooldown <= 0.0


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 16.0 and absf(p.global_position.y - global_position.y) < 24.0


func interact(_p) -> void:
	if cooldown > 0.0:
		return
	cooldown = 3.6
	Sfx.play("lever")
	for v in vents:
		v.trigger()
	if vents.is_empty():
		Game.world.hud.message("A válvula gira em falso.")


func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta
		spin += delta * 8.0
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-2, -22, 4, 22), Color("5a3a24"))
	draw_rect(Rect2(-10, -24, 20, 4), Color("6e4a2c"))
	draw_set_transform(Vector2(0, -16), spin, Vector2.ONE)
	draw_arc(Vector2.ZERO, 6.0, 0, TAU, 20, Color("b02a20"), 2.0)
	for i in 3:
		var a := i * TAU / 3.0
		draw_line(Vector2.ZERO, Vector2.from_angle(a) * 6.0, Color("b02a20"), 1.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(0, -16), 1.6, Color("d9965a"))
	if cooldown <= 0.0:
		draw_circle(Vector2(8, -6), 1.5, Color(0.4, 1.0, 0.5, 0.8))
