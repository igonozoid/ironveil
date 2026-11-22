extends CanvasLayer
## HUD: vida no canto superior esquerdo, ferramenta selecionada no canto
## superior direito, dica contextual, mensagens e título da fase.

var draw_layer: Control
var prompt_label: Label
var message_label: Label
var hint_panel: PanelContainer
var hint_label: Label
var title_label: Label
var message_t := 0.0
var hint_t := 0.0


func _ready() -> void:
	layer = 10
	draw_layer = HudDraw.new()
	draw_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draw_layer)

	prompt_label = _label(11, HORIZONTAL_ALIGNMENT_CENTER)
	prompt_label.position = Vector2(170, 338)
	prompt_label.size = Vector2(300, 16)
	prompt_label.modulate = Color(1.0, 0.88, 0.65)

	message_label = _label(11, HORIZONTAL_ALIGNMENT_CENTER)
	message_label.position = Vector2(120, 320)
	message_label.size = Vector2(400, 16)

	hint_panel = PanelContainer.new()
	hint_panel.position = Vector2(110, 40)
	hint_panel.size = Vector2(420, 40)
	hint_panel.custom_minimum_size = Vector2(420, 0)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.visible = false
	add_child(hint_panel)
	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size = Vector2(400, 0)
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_panel.add_child(hint_label)

	title_label = _label(20, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.position = Vector2(0, 150)
	title_label.size = Vector2(640, 30)
	title_label.modulate.a = 0.0


func _label(font_size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func message(t: String) -> void:
	message_label.text = tr(t)
	message_label.modulate.a = 1.0
	message_t = 2.4


func show_hint(t: String) -> void:
	hint_label.text = tr(t)
	hint_panel.visible = true
	hint_panel.modulate.a = 1.0
	hint_panel.reset_size()
	hint_t = 7.0


func hide_hint() -> void:
	hint_t = 0.0
	hint_panel.visible = false


## Aviso grande de upgrade novo.
func show_upgrade(up_name: String, desc: String) -> void:
	title_label.text = tr("NOVO: %s") % tr(up_name)
	message(desc)
	message_t = 4.5
	title_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(title_label, "modulate:a", 1.0, 0.4)
	tw.tween_interval(3.6)
	tw.tween_property(title_label, "modulate:a", 0.0, 0.8)


func show_title(t: String) -> void:
	title_label.text = tr(t)
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(title_label, "modulate:a", 1.0, 0.6)
	tw.tween_interval(1.8)
	tw.tween_property(title_label, "modulate:a", 0.0, 0.8)


func _process(delta: float) -> void:
	var p = Game.world.player if Game.world else null
	prompt_label.text = String(p.current_prompt) if p != null else ""
	if message_t > 0.0:
		message_t -= delta
		message_label.modulate.a = clampf(message_t / 0.5, 0.0, 1.0)
	if hint_t > 0.0:
		hint_t -= delta
		hint_panel.modulate.a = clampf(hint_t / 0.6, 0.0, 1.0)
		if hint_t <= 0.0:
			hint_panel.visible = false
	draw_layer.queue_redraw()


class HudDraw extends Control:
	const Icons := preload("res://scripts/icons.gd")

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		# Vida
		draw_string(font, Vector2(10, 17), tr("VIDA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.75, 0.65))
		for i in Game.max_hp():
			var r := Rect2(Vector2(38 + i * 15, 8), Vector2(12, 10))
			draw_rect(r.grow(1), Color("1e1b1b"))
			if i < Game.hp:
				draw_rect(r, Color("7fd4ff"))
				draw_rect(Rect2(r.position, Vector2(12, 3)), Color("c8efff"))
			else:
				draw_rect(r, Color("2e2a2a"))
				draw_rect(r, Color("5a3a24"), false, 1.0)
		var x := 38.0 + Game.max_hp() * 15.0 + 4.0
		var pl = Game.world.player if Game.world else null
		# Couraça (upgrade): placa cheia ou recarregando
		if Game.has_upgrade("couraca") and pl != null:
			var pr := Rect2(Vector2(x, 7), Vector2(10, 12))
			draw_rect(pr.grow(1), Color("1e1b1b"))
			if pl.armor > 0:
				draw_rect(pr, Color("a07a38"))
				draw_rect(Rect2(pr.position, Vector2(10, 3)), Color("e0b860"))
			else:
				var k: float = clampf(pl.armor_t / pl.ARMOR_RECHARGE, 0.0, 1.0)
				draw_rect(pr, Color("2e2a2a"))
				draw_rect(Rect2(pr.position + Vector2(0, 12 * (1.0 - k)), Vector2(10, 12 * k)), Color(0.63, 0.48, 0.22, 0.5))
			x += 16.0
		if Game.difficulty > 0:
			draw_string(font, Vector2(10, 32), tr(String(Game.diff()["name"])).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
				Color(1.0, 0.35, 0.2) if Game.difficulty >= 2 else Color(1.0, 0.65, 0.3))
		if Game.run_mode:
			draw_string(font, Vector2(x + 2, 17), tr("CORRENDO"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.8, 0.45))
		_draw_boss(font)
		# Ferramenta
		var box := Rect2(Vector2(470, 6), Vector2(162, 28))
		draw_rect(box, Color(0.08, 0.07, 0.065, 0.85))
		draw_rect(box, Color("8a5a2b"), false, 1.0)
		var tool := Game.current_tool()
		var count := Game.tool_count(tool)
		if count > 0:
			Icons.draw_tool(self, tool, box.position + Vector2(14, 14), 1.2)
			draw_string(font, box.position + Vector2(28, 13), tr(String(Game.TOOL_NAMES[tool])), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.9, 0.82))
			draw_string(font, box.position + Vector2(28, 24), tr("x%d   %s trocar · %s usar") % [count, Game.key_name("swap_tool"), Game.key_name("use_tool")], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.65, 0.5))
		else:
			draw_string(font, box.position + Vector2(10, 17), tr("— sem ferramenta —"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.5, 0.47))


	func _draw_boss(font: Font) -> void:
		var b = Game.world.boss if Game.world else null
		if b == null or not b.bar_visible:
			return
		var r := Rect2(Vector2(200, 10), Vector2(240, 7))
		draw_string(font, Vector2(200, 30), tr(String(b.title)), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.95, 0.75, 0.6))
		draw_rect(r.grow(1.5), Color("1e1b1b"))
		draw_rect(r, Color("2e2a2a"))
		var k: float = clampf(b.hp_ratio(), 0.0, 1.0)
		var real: float = clampf(b.hp_real(), 0.0, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), Color(1.0, 0.85, 0.6))
		draw_rect(Rect2(r.position, Vector2(r.size.x * real, r.size.y)), Color("8a1e1e") if not b.phase2 else Color("c0401e"))
		draw_rect(Rect2(r.position, Vector2(r.size.x * real, 2)), Color(1.0, 0.5, 0.4, 0.6))
		draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.end.y), Color(0, 0, 0, 0.6), 1.0)
