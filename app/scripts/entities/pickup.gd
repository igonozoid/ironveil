extends Node2D
## Item coletável: carga de vapor (+2), selante (+1) ou cartão de acesso (+1).

const Icons := preload("res://scripts/icons.gd")

var kind := "charge"
var amount := 1
var t := 0.0


func setup(pos: Vector2, k: String, n: int) -> void:
	position = pos
	kind = k
	amount = n
	z_index = 3
	t = pos.x * 0.1


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	var p = Game.world.player if Game.world else null
	if p == null or p.is_dead():
		return
	if p.hitbox().grow(6.0).has_point(global_position):
		Game.add_item(kind, amount)
		var name_str: String = Game.TOOL_NAMES[kind]
		Game.world.hud.message("%s +%d" % [name_str, amount])
		Sfx.play("pickup")
		queue_free()


func _draw() -> void:
	var y := sin(t * 3.0) * 2.0
	draw_circle(Vector2(0, y), 9.0, Color(1.0, 0.8, 0.4, 0.08 + 0.05 * sin(t * 5.0)))
	Icons.draw_tool(self, kind, Vector2(0, y), 1.0)
