extends Node2D
## Gatilho invisível de dica: mostra o texto no HUD quando Sera passa.

var text := ""


func setup(pos: Vector2, txt: String) -> void:
	position = pos
	text = txt


func _physics_process(_delta: float) -> void:
	if text == "":
		queue_free()
		return
	var p = Game.world.player if Game.world else null
	if p == null:
		return
	if absf(p.global_position.x - global_position.x) < 20.0 and absf(p.global_position.y - global_position.y) < 50.0:
		Game.world.hud.show_hint(text)
		queue_free()
