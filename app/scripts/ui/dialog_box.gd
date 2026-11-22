extends CanvasLayer
## Caixa de diálogo com efeito de máquina de escrever.
## Avança com A, Z ou Enter. Ao terminar chama o callback.

const CHARS_PER_SEC := 45.0

var active := false
var lines: Array = []
var index := 0
var on_done: Callable = Callable()
var panel: PanelContainer
var speaker: Label
var text: Label
var arrow: Label
var shown := 0.0
var opened_frame := -1
var blip_acc := 0.0


func _ready() -> void:
	layer = 20
	panel = PanelContainer.new()
	panel.position = Vector2(40, 40)
	panel.custom_minimum_size = Vector2(560, 80)
	panel.size = Vector2(560, 80)
	panel.visible = false
	add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size", 11)
	vb.add_child(speaker)
	text = Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(540, 40)
	text.add_theme_font_size_override("font_size", 11)
	vb.add_child(text)
	arrow = Label.new()
	arrow.text = "▼ A / Z"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arrow.add_theme_font_size_override("font_size", 8)
	arrow.modulate = Color(1, 0.8, 0.5, 0.7)
	vb.add_child(arrow)


func start(new_lines: Array, done: Callable) -> void:
	lines = new_lines
	index = 0
	on_done = done
	active = true
	panel.visible = true
	opened_frame = Engine.get_process_frames()
	if Game.world and Game.world.hud:
		Game.world.hud.hide_hint()
	_show_line()


func _show_line() -> void:
	var entry: Array = lines[index]
	speaker.text = tr(String(entry[0]))
	speaker.modulate = Color("7fd4ff") if entry[0] == "Sera" else Color("e0b860")
	text.text = Game.fmt(tr(String(entry[1])))
	text.visible_characters = 0
	shown = 0.0


func _process(delta: float) -> void:
	if not active:
		return
	var total := text.text.length()
	if shown < total:
		shown = minf(shown + delta * CHARS_PER_SEC, float(total))
		text.visible_characters = int(shown)
		blip_acc += delta
		if blip_acc > 0.07:
			blip_acc = 0.0
			Sfx.play("blip", -10.0)
	arrow.visible = shown >= total
	if Engine.get_process_frames() == opened_frame:
		return
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		if shown < total:
			shown = float(total)
			text.visible_characters = -1
		else:
			index += 1
			if index >= lines.size():
				_close()
			else:
				_show_line()


func _close() -> void:
	active = false
	panel.visible = false
	if Game.world:
		Game.world.input_lock = 0.3
	if on_done.is_valid():
		on_done.call()
