extends Control
## Tela de Configurações (menu principal e pausa): gore, efeitos de tela, tela
## cheia e troca de teclas. Mostra embaixo o que cada opção faz.

var on_close: Callable = Callable()
var desc: Label
var waiting := ""
var waiting_btn: Button = null
var key_buttons: Dictionary = {}
var first: Button

const DESCRIPTIONS := {
	"gore": "Sangue que voa, mancha o cenário, gruda nas pessoas e espirra na tela. Desligado, vira faíscas e destroços.",
	"fx": "Pós-processamento: cor própria de cada ato (Caldeiras quentes, Mercado ao entardecer, Torre fria), brilho em volta das luzes, cantos escurecidos, grão de filme e a imagem separando em cores ao levar dano. Desligado: imagem limpa e um pouco mais leve para o computador. As luzes do cenário e a borda de vida continuam.",
	"fs": "Alterna entre janela e tela cheia. Atalho: F11 a qualquer momento.",
	"music": "Volume da trilha sonora (cada clique sobe 10%; depois de 100% volta a 0, que desliga a música).",
	"sfx": "Volume dos efeitos sonoros: tiros, vapor, passos, explosões.",
	"keys": "Clique (ou Enter) numa ação e aperte a nova tecla. Se outra ação usava essa tecla, as duas trocam. Esc cancela. O controle de videogame não muda.",
	"reset": "Volta todas as teclas para o padrão: setas, Z, X, C, Shift, A, S, Q e Esc.",
	"back": "Voltar.",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2.ZERO
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.04, 0.97)
	bg.position = Vector2.ZERO
	bg.size = Vector2(640, 360)
	add_child(bg)
	var title := Label.new()
	title.text = "CONFIGURAÇÕES"
	title.position = Vector2(0, 10)
	title.size = Vector2(640, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("d9965a"))
	add_child(title)

	# Coluna da esquerda: opções gerais
	var left := VBoxContainer.new()
	left.position = Vector2(36, 54)
	left.custom_minimum_size = Vector2(240, 0)
	left.add_theme_constant_override("separation", 3)
	add_child(left)
	var head := _head(left, "JOGO")
	head.custom_minimum_size = Vector2(0, 14)
	var gore := _button(left, "", "gore")
	gore.pressed.connect(func():
		Game.toggle_gore()
		_refresh())
	first = gore
	var fx := _button(left, "", "fx")
	fx.pressed.connect(func():
		Game.toggle_fx()
		_refresh())
	var fs := _button(left, "", "fs")
	fs.pressed.connect(func():
		Game.toggle_fullscreen()
		_refresh())
	var mus := _button(left, "", "music")
	mus.pressed.connect(func():
		Game.cycle_volume("music")
		_refresh())
	var sfx := _button(left, "", "sfx")
	sfx.pressed.connect(func():
		Game.cycle_volume("sfx")
		Sfx.play("shot", -3.0)
		_refresh())
	left.add_child(_spacer(6))
	var reset := _button(left, "Restaurar teclas padrão", "reset")
	reset.pressed.connect(func():
		Game.reset_keys()
		_refresh())
	var back := _button(left, "Voltar", "back")
	back.pressed.connect(close)
	gore.set_meta("id", "gore")
	fx.set_meta("id", "fx")
	fs.set_meta("id", "fs")

	# Coluna da direita: teclas
	var right := VBoxContainer.new()
	right.position = Vector2(300, 54)
	right.custom_minimum_size = Vector2(306, 0)
	right.add_theme_constant_override("separation", 0)
	add_child(right)
	var h2 := _head(right, "TECLAS")
	h2.custom_minimum_size = Vector2(0, 14)
	for entry in Game.REBINDABLE:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		right.add_child(row)
		var l := Label.new()
		l.text = String(entry[1])
		l.custom_minimum_size = Vector2(150, 0)
		l.add_theme_font_size_override("font_size", 9)
		row.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(140, 18)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 9)
		var action := String(entry[0])
		b.pressed.connect(func(): _start_capture(action, b))
		b.focus_entered.connect(func(): _describe("keys"))
		b.mouse_entered.connect(func(): _describe("keys"))
		row.add_child(b)
		key_buttons[action] = b

	desc = Label.new()
	desc.position = Vector2(36, 306)
	desc.size = Vector2(570, 52)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(1.0, 0.88, 0.7))
	add_child(desc)
	_refresh()
	_describe("gore")
	first.grab_focus()


func _head(parent: Node, txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color(0.85, 0.65, 0.45))
	parent.add_child(l)
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _button(parent: Node, txt: String, id: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 12)
	b.focus_entered.connect(func():
		_describe(id)
		Sfx.play("menu", -8.0))
	b.mouse_entered.connect(func(): _describe(id))
	b.set_meta("id", id)
	parent.add_child(b)
	return b


func _describe(id: String) -> void:
	if desc != null:
		desc.text = String(DESCRIPTIONS.get(id, ""))


func _refresh() -> void:
	for c in find_children("*", "Button", true, false):
		match String(c.get_meta("id", "")):
			"gore":
				c.text = "Sangue e gore: " + ("Ligado" if Game.gore_enabled() else "Desligado")
			"fx":
				c.text = "Efeitos de tela: " + ("Ligados" if Game.fx_enabled() else "Desligados")
			"fs":
				c.text = "Tela cheia (F11): " + ("Ligada" if bool(Game.settings.get("fullscreen", false)) else "Desligada")
			"music":
				c.text = "Música: %d%%" % int(round(float(Game.settings.get("music", 0.7)) * 100.0))
			"sfx":
				c.text = "Efeitos sonoros: %d%%" % int(round(float(Game.settings.get("sfx", 1.0)) * 100.0))
	for a in key_buttons.keys():
		var b: Button = key_buttons[a]
		b.text = Game.key_name(a) if waiting != a else "Aperte uma tecla…"


func _start_capture(action: String, b: Button) -> void:
	waiting = action
	waiting_btn = b
	_refresh()


func _input(event: InputEvent) -> void:
	if waiting == "":
		if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
			close()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.keycode
		if code == KEY_ESCAPE and waiting != "pause":
			pass
		elif code != KEY_F11:
			Game.rebind(waiting, code)
			Sfx.play("menu", -4.0)
		var btn := waiting_btn
		waiting = ""
		waiting_btn = null
		_refresh()
		if btn != null:
			btn.grab_focus()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


func close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()
