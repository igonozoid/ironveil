extends Node2D
## Indicadores de interação: sobre cada alavanca, válvula, painel, elevador,
## canhão, freio, registro ou aliado que pode ser usado agora aparece um
## losango dourado pulsando (como o anel do rebite de escalada). Quando Sera
## está ao alcance, ele vira a tecla de interagir.
## Moradores que dão dicas têm o próprio balão e ficam de fora.

var t := 0.0


func _ready() -> void:
	z_index = 15


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var w = Game.world
	if w == null or w.player == null or w.cutscene:
		return
	var p = w.player
	var font := ThemeDB.fallback_font
	var key := Game.key_name("interact")
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.is_in_group("npc") or not is_instance_valid(n):
			continue
		if not w.is_active(n.global_position) or not n.can_interact():
			continue
		var off := Vector2(0, -40)
		if n.has_method("marker_offset"):
			off = n.marker_offset()
		var c: Vector2 = n.global_position + off + Vector2(0, sin(t * 3.0 + n.global_position.x * 0.05) * 1.5)
		var near: bool = n.is_in_reach(p)
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		if near:
			# Tecla de interagir
			var r := Rect2(c - Vector2(7, 7), Vector2(14, 14))
			draw_rect(r.grow(1.5), Color(0.1, 0.08, 0.06, 0.85))
			draw_rect(r, Color(1.0, 0.8, 0.35, 0.95))
			draw_string(font, c + Vector2(-4, 4.5), key.left(2), HORIZONTAL_ALIGNMENT_CENTER, 8, 10, Color(0.12, 0.08, 0.05))
		else:
			draw_arc(c, 6.0 + pulse * 2.0, 0, TAU, 16, Color(1.0, 0.8, 0.35, 0.35 + 0.25 * pulse), 1.2)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3.5), c + Vector2(3, 0), c + Vector2(0, 3.5), c + Vector2(-3, 0)]),
				Color(1.0, 0.82, 0.4, 0.7 + 0.3 * pulse))
