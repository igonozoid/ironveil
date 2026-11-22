extends Node2D
## Painel de controle (interagir): religa a energia da porta blindada mais
## próxima, abrindo-a.

var door = null
var prompt := "A: religar painel"
var powered := false
var t := 0.0


func _ready() -> void:
	add_to_group("interactable")
	z_index = 2


func can_interact() -> bool:
	return not powered


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 16.0 and absf(p.global_position.y - global_position.y) < 24.0


func interact(_p) -> void:
	if powered:
		return
	powered = true
	Sfx.play("lever")
	Sfx.play("spark", -6.0)
	if door != null:
		door.open()
		Game.world.hud.message("Energia restaurada: porta blindada aberta")


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-8, -30, 16, 20), Color("2e2a28"))
	draw_rect(Rect2(-8, -30, 16, 20), Color("8a5a2b"), false, 1.5)
	draw_rect(Rect2(-1, -10, 2, 10), Color("3a3330"))
	var lit := Color(0.35, 1.0, 0.45) if powered else Color(1.0, 0.3, 0.2, 0.5 + 0.5 * sin(t * 6.0))
	draw_rect(Rect2(-5, -27, 10, 5), Color("101010"))
	draw_rect(Rect2(-4, -26, 8 if powered else 3, 3), lit)
	for i in 3:
		draw_circle(Vector2(-4 + i * 4, -16), 1.4, Color("d9965a") if powered else Color("6a6460"))
