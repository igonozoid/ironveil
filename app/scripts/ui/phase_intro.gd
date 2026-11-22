extends CanvasLayer
## Abertura de fase: faixas de cinema, nome do ato e da fase, uma linha de
## clima e, depois que Sera chega, "aperte qualquer tecla". O jogo só começa
## depois disso.

const FLAVOR := [
	"O apito da Caldeira Sul ainda ecoa. Os guardas já procuram pela engenheira.",
	"As bombas que mantêm Ironveil respirando — e uma saída pelo elevador de carga.",
	"Tomé guarda o guindaste. Lá no alto, algo enorme se move.",
	"O Mercado Suspenso: madeira podre, correntes e um abismo que não devolve ninguém.",
	"Na multidão, um rosto a mais não chama atenção. Um tiro chama.",
	"Os arquivos do Diretório ficam nos telhados. Algo ronda no céu.",
	"A Torre. Latão polido, pedra fria — e olhos por toda parte.",
	"O coração do relógio. Cada engrenagem aqui trabalha para o Diretor.",
	"No alto, o Regulador marca o tempo da cidade. E Halvard Maar espera.",
	"Abaixo das Caldeiras, onde a montanha ainda queima. Tomé conhece o caminho.",
	"Cadinhos do tamanho de casas. Quem trabalha aqui nunca viu a luz do dia.",
	"A Fornalha-Mãe empurra a pressão que segura o Véu. Ela nunca parou.",
	"Sobre a cúpula, o vento uiva entre as placas. Do outro lado do ferro, o céu.",
	"A frota do Conselho troca as placas do Véu toda noite.",
	"A Coroa. O Tecelão costura o céu fechado — e o Conselho assiste.",
]

var on_start: Callable = Callable()
var ready_to_start := false
var started := false
var t := 0.0
var bars := 0.0
var fade := 1.0
var canvas: Control
var act_label: Label
var title_label: Label
var flavor_label: Label
var press_label: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_paint)
	add_child(canvas)
	var i := clampi(Game.phase, 0, Game.PHASE_COUNT - 1)
	act_label = _label(String(Game.ACTS[Game.act_of(i)]["title"]).to_upper(), 10, 112, Color(0.95, 0.7, 0.45))
	title_label = _label(String(Game.world.phase_data.get("title", Game.PHASE_NAMES[i])) if Game.world else Game.PHASE_NAMES[i], 24, 128, Color(0.98, 0.93, 0.85))
	flavor_label = _label(FLAVOR[i] if i < FLAVOR.size() else "", 10, 166, Color(0.9, 0.84, 0.78))
	press_label = _label("Aperte qualquer tecla para começar", 10, 300, Color(1.0, 0.85, 0.55))
	for l in [act_label, title_label, flavor_label, press_label]:
		l.modulate.a = 0.0


func _label(txt: String, size: int, y: float, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = Vector2(20, y)
	l.size = Vector2(600, 30)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(l)
	return l


func _process(delta: float) -> void:
	t += delta
	if not started:
		bars = minf(1.0, bars + delta * 2.5)
		act_label.modulate.a = clampf((t - 0.3) * 2.0, 0.0, 1.0)
		title_label.modulate.a = clampf((t - 0.5) * 2.0, 0.0, 1.0)
		flavor_label.modulate.a = clampf((t - 1.0) * 1.5, 0.0, 0.9)
		var p = Game.world.player if Game.world else null
		ready_to_start = t > 1.2 and (p == null or not p.entering)
		press_label.modulate.a = (0.55 + 0.45 * sin(t * 4.0)) if ready_to_start else 0.0
	else:
		fade = maxf(0.0, fade - delta * 2.5)
		bars = fade
		for l in [act_label, title_label, flavor_label, press_label]:
			l.modulate.a = minf(l.modulate.a, fade)
		if fade <= 0.0:
			queue_free()
	canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if started or not ready_to_start:
		return
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode != KEY_F11:
		pressed = true
	elif (event is InputEventJoypadButton or event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		pressed = true
	if pressed:
		started = true
		Sfx.play("menu", -2.0)
		get_viewport().set_input_as_handled()
		if on_start.is_valid():
			on_start.call()


func _paint() -> void:
	var h := 46.0 * bars
	canvas.draw_rect(Rect2(0, 0, 640, h), Color(0, 0, 0, 0.92))
	canvas.draw_rect(Rect2(0, 360 - h, 640, h), Color(0, 0, 0, 0.92))
	if not started or fade > 0.0:
		var a := 0.35 * (bars if not started else fade)
		canvas.draw_rect(Rect2(0, 104, 640, 90), Color(0, 0, 0, a))
		canvas.draw_rect(Rect2(170, 160, 300, 1), Color(0.75, 0.48, 0.25, a * 2.0))
