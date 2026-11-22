extends RefCounted
## Ícones geométricos das ferramentas, usados no HUD e nos itens do chão.

const COPPER := Color("b87333")
const COPPER_L := Color("d9965a")
const STEEL := Color("8a8f96")
const GREEN := Color("6fbf73")
const YELLOW := Color("e8c547")
const RED := Color("d04030")


static func draw_tool(ci: CanvasItem, kind: String, c: Vector2, s: float = 1.0) -> void:
	match kind:
		"charge":
			ci.draw_rect(Rect2(c + Vector2(-4, -6) * s, Vector2(8, 12) * s), COPPER)
			ci.draw_rect(Rect2(c + Vector2(-4, -6) * s, Vector2(8, 2) * s), COPPER_L)
			ci.draw_rect(Rect2(c + Vector2(-2, -9) * s, Vector2(4, 3) * s), STEEL)
			ci.draw_circle(c + Vector2(0, 1) * s, 1.6 * s, RED)
		"sealant":
			ci.draw_rect(Rect2(c + Vector2(-3, -5) * s, Vector2(6, 11) * s), GREEN)
			ci.draw_rect(Rect2(c + Vector2(-1.5, -8) * s, Vector2(3, 3) * s), STEEL)
			ci.draw_rect(Rect2(c + Vector2(-3, -1) * s, Vector2(6, 2) * s), Color(1, 1, 1, 0.6))
		"card":
			ci.draw_rect(Rect2(c + Vector2(-6, -4) * s, Vector2(12, 8) * s), YELLOW)
			ci.draw_rect(Rect2(c + Vector2(-6, -2) * s, Vector2(12, 2) * s), Color("3a3330"))
			ci.draw_rect(Rect2(c + Vector2(2, 1) * s, Vector2(3, 2) * s), COPPER)
