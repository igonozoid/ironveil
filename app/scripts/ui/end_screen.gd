extends Control
## Fim de ato. Ato 1: Sera no topo do poço vê a luz do Mercado Suspenso.
## Ato 2: no telhado, com o livro de válvulas, Sera encara a Torre do Diretório.
## Ato 3 (final): no alto da Torre, ao amanhecer, Sera lê o livro para a cidade.

var t := 0.0
var title: Label
var sub: Label
var hint: Label


func _ready() -> void:
	get_tree().paused = false
	# Novo ato, roupa limpa.
	Game.clean_sera()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var done := (Game.progress.get("completed", []) as Array).size()
	if Game.end_act == 0:
		title = _label("Ato 1 concluído", 26, 210)
		sub = _label("Acima, as luzes do Mercado Suspenso. Os guardas do Diretório não vão parar —\nmas Sera também não.", 11, 248)
		hint = _label("Fases concluídas: %d/%d  ·  Progresso salvo\nZ / Enter: seguir para o Ato 2" % [done, Game.PHASE_COUNT], 9, 312)
	elif Game.end_act >= 2:
		title = _label("Ato 3 concluído — Fim", 26, 200)
		sub = _label("O Regulador parou. Pelos alto-falantes do Diretório, Sera lê o livro de válvulas\npara toda Ironveil: a ordem que matou vinte e três pessoas na Caldeira Sul tem nome e assinatura.\nLá embaixo, as Caldeiras abrem as válvulas — desta vez, para aliviar quem sempre carregou a pressão.", 10, 236)
		hint = _label("Fases concluídas: %d/%d  ·  Progresso salvo  ·  Obrigado por jogar IRONVEIL\nZ / Enter: abrir o mapa (repita qualquer fase)" % [done, Game.PHASE_COUNT], 9, 316)
	else:
		title = _label("Ato 2 concluído", 26, 210)
		sub = _label("O livro de válvulas prova: a ordem que explodiu a Caldeira Sul saiu da Torre do Diretório.\nLá em cima, alguém já sabe que Sera tem o livro.", 11, 248)
		hint = _label("Fases concluídas: %d/%d  ·  Progresso salvo\nZ / Enter: seguir para o Ato 3" % [done, Game.PHASE_COUNT], 9, 312)
	title.add_theme_color_override("font_color", Color("ffd27a"))
	for l in [title, sub, hint]:
		l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(title, "modulate:a", 1.0, 1.2)
	tw.tween_property(sub, "modulate:a", 1.0, 1.0)
	tw.tween_property(hint, "modulate:a", 0.7, 0.6)
	Sfx.play("door", -6.0, 0.6)


func _label(txt: String, size_px: int, y: float) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(640, 40)
	l.add_theme_font_size_override("font_size", size_px)
	add_child(l)
	return l


var tapped := false


## Toque ou clique também seguem (Android).
func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		tapped = true


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	var go := tapped or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact")
	tapped = false
	if t > 3.0 and go:
		if Game.end_act < Game.ACTS.size() - 1:
			Game.open_map("travel", Game.map_from)
		else:
			Game.open_map("browse", Game.map_from)


func _draw() -> void:
	if Game.end_act >= 2:
		_draw_finale()
		return
	if Game.end_act >= 1:
		_draw_tower()
		return
	var w := 640.0
	var h := 360.0
	var k := clampf(t / 4.0, 0.0, 1.0)
	draw_rect(Rect2(0, 0, w, h), Color("0d0b0b"))
	# Feixe de luz dourada vindo do alto do poço
	for i in 24:
		var y := i * 15.0
		var a := (0.32 - i * 0.012) * k
		var spread := 90.0 + i * 6.0
		draw_rect(Rect2(320 - spread * 0.5, y, spread, 15), Color(1.0, 0.82, 0.45, maxf(a, 0.0)))
	# Raios
	for i in 5:
		var x0 := 280.0 + i * 20.0
		var sway := sin(t * 0.6 + i) * 10.0
		draw_line(Vector2(x0, 0), Vector2(x0 + (i - 2) * 50.0 + sway, h), Color(1.0, 0.9, 0.6, 0.06 * k), 12.0)
	# Paredes do poço
	draw_rect(Rect2(0, 0, 200, h), Color("2a2321"))
	draw_rect(Rect2(440, 0, 200, h), Color("2a2321"))
	draw_rect(Rect2(196, 0, 4, h), Color("8a5a2b"))
	draw_rect(Rect2(440, 0, 4, h), Color("8a5a2b"))
	for y in range(0, 360, 40):
		draw_circle(Vector2(190, y + 20), 2.0, Color("5e5450"))
		draw_circle(Vector2(450, y + 20), 2.0, Color("5e5450"))
	# Silhuetas do Mercado lá em cima
	for i in 6:
		var x := 210.0 + i * 38.0
		var hh := 10.0 + (i * 7) % 14
		draw_rect(Rect2(x, 0, 22, hh), Color(0.25, 0.18, 0.1, 0.8))
		draw_rect(Rect2(x + 8, hh - 6, 5, 3), Color(1.0, 0.85, 0.4, 0.9 * k))
	# Plataforma e Sera olhando para cima
	draw_rect(Rect2(200, 300, 240, 60), Color("3d3735"))
	draw_rect(Rect2(200, 300, 240, 4), Color("c07a3a"))
	var sx := 320.0
	var base := Vector2(sx, 300)
	draw_line(base + Vector2(-2, -13), base + Vector2(-3, 0), Color("3d93c2"), 3.2)
	draw_line(base + Vector2(2, -13), base + Vector2(3, 0), Color("3d93c2"), 3.2)
	draw_rect(Rect2(base + Vector2(-4.5, -23), Vector2(9, 11)), Color("7fd4ff"))
	draw_rect(Rect2(base + Vector2(-4.5, -14), Vector2(9, 2)), Color("b87333"))
	draw_circle(base + Vector2(0.5, -27), 3.4, Color("e8c6a0"))
	draw_circle(base + Vector2(-0.5, -27.5), 3.0, Color("2b2f3a"))
	draw_line(base + Vector2(4, -21), base + Vector2(8, -30), Color("7fd4ff"), 2.4)
	# Vapor subindo pelo feixe
	for i in 12:
		var px := 230.0 + fmod(i * 53.0, 180.0) + sin(t + i) * 6.0
		var py := h - fmod(t * (18.0 + i * 3.0) + i * 29.0, h)
		draw_circle(Vector2(px, py), 6.0 + (i % 3) * 3.0, Color(1, 1, 1, 0.05))


## Fim do Ato 2: telhado do Mercado à noite, destroços do dirigível ardendo e a
## Torre do Diretório entre nuvens, com uma janela acesa no alto.
func _draw_tower() -> void:
	var w := 640.0
	var h := 360.0
	var k := clampf(t / 4.0, 0.0, 1.0)
	draw_rect(Rect2(0, 0, w, h), Color("0e0c10"))
	for i in 12:
		draw_rect(Rect2(0, i * 16.0, w, 16), Color(0.25, 0.16, 0.2, 0.05 + i * 0.01))
	# Torre
	var tx := 400.0
	draw_rect(Rect2(tx - 30, 0, 60, 300), Color("1d1a1f"))
	draw_rect(Rect2(tx - 44, 40, 88, 14), Color("231f25"))
	draw_rect(Rect2(tx - 40, 120, 80, 10), Color("231f25"))
	draw_rect(Rect2(tx - 3, 0, 6, 300), Color("2a2530"))
	var blink := 0.6 + 0.4 * sin(t * 2.0)
	draw_rect(Rect2(tx - 8, 64, 16, 10), Color(1.0, 0.75, 0.35, blink * k))
	draw_rect(Rect2(tx - 14, 60, 28, 18), Color(1.0, 0.75, 0.35, 0.08 * k))
	for i in 6:
		draw_rect(Rect2(tx - 20 + (i % 3) * 16, 150 + i * 22, 5, 4), Color(0.9, 0.5, 0.25, 0.4 * k))
	# Nuvens passando
	for i in 7:
		var cx := fmod(i * 140.0 + t * (8.0 + i), w + 200.0) - 100.0
		var cy := 30.0 + (i * 37) % 120
		draw_circle(Vector2(cx, cy), 34.0, Color(0.5, 0.45, 0.5, 0.022))
		draw_circle(Vector2(cx + 34, cy + 6), 26.0, Color(0.5, 0.45, 0.5, 0.018))
	# Telhados do Mercado
	for i in 7:
		var x := i * 100.0 - 20.0
		var top := 250.0 + (i * 23) % 30
		draw_rect(Rect2(x, top, 84, h - top), Color("201a18"))
		draw_rect(Rect2(x, top, 84, 3), Color("6e4a2c"))
		draw_rect(Rect2(x + 20, top + 14, 6, 5), Color(1.0, 0.75, 0.35, 0.5))
	# Destroços do dirigível ardendo
	for i in 10:
		var fx := 110.0 + i * 9.0 + sin(t * 3.0 + i) * 3.0
		var fy := 262.0 - fmod(t * 30.0 + i * 13.0, 50.0)
		draw_circle(Vector2(fx, fy), 3.0 + (i % 3), Color(1.0, 0.5, 0.15, 0.35))
	draw_rect(Rect2(90, 262, 110, 14), Color("2a1f1c"))
	draw_line(Vector2(95, 262), Vector2(190, 248), Color("4a3a30"), 3.0)
	# Sera de costas no parapeito, segurando o livro
	var base := Vector2(300, 300)
	draw_rect(Rect2(250, 300, 120, 60), Color("2a2321"))
	draw_rect(Rect2(250, 300, 120, 3), Color("b87333"))
	draw_line(base + Vector2(-2, -13), base + Vector2(-3, 0), Color("3d93c2"), 3.2)
	draw_line(base + Vector2(2, -13), base + Vector2(3, 0), Color("3d93c2"), 3.2)
	draw_rect(Rect2(base + Vector2(-4.5, -23), Vector2(9, 11)), Color("7fd4ff"))
	draw_rect(Rect2(base + Vector2(-4.5, -14), Vector2(9, 2)), Color("b87333"))
	draw_circle(base + Vector2(0.5, -27), 3.4, Color("2b2f3a"))
	draw_line(base + Vector2(-1, -28), base + Vector2(-5, -20 + sin(t * 2.0)), Color("2b2f3a"), 2.0)
	draw_rect(Rect2(base + Vector2(4, -18), Vector2(6, 7)), Color("6e2f18"))
	draw_rect(Rect2(base + Vector2(4, -18), Vector2(6, 1.5)), Color("ffd27a"))


## Final: alto da Torre ao amanhecer. O relógio parado atrás, a cidade lá
## embaixo, colunas de vapor subindo das Caldeiras e Sera no parapeito com o
## livro, diante da corneta dos alto-falantes.
func _draw_finale() -> void:
	var w := 640.0
	var h := 360.0
	var k := clampf(t / 5.0, 0.0, 1.0)
	# Céu: noite virando amanhecer
	for i in 24:
		var y := i * 15.0
		var night := Color(0.06, 0.05, 0.1)
		var dawn := Color(0.55, 0.3, 0.28).lerp(Color(0.95, 0.62, 0.35), clampf((y - 140.0) / 120.0, 0.0, 1.0))
		draw_rect(Rect2(0, y, w, 15), night.lerp(dawn, k * clampf(y / 260.0, 0.15, 1.0)))
	# Sol nascendo atrás das montanhas
	draw_circle(Vector2(470, 250 - k * 30.0), 40.0, Color(1.0, 0.8, 0.5, 0.25 * k))
	draw_circle(Vector2(470, 250 - k * 30.0), 22.0, Color(1.0, 0.85, 0.6, 0.6 * k))
	# Montanhas e a cidade-montanha
	draw_colored_polygon(PackedVector2Array([Vector2(0, 260), Vector2(90, 220), Vector2(170, 240), Vector2(260, 200),
		Vector2(360, 236), Vector2(440, 214), Vector2(540, 240), Vector2(640, 222), Vector2(640, 360), Vector2(0, 360)]), Color("1c1618"))
	for i in 40:
		var lx := fmod(i * 97.0, 600.0) + 20.0
		var ly := 250.0 + fmod(i * 53.0, 90.0)
		draw_rect(Rect2(lx, ly, 2, 2), Color(1.0, 0.75, 0.35, 0.65 * (1.0 - k * 0.5)))
	# Vapor subindo das Caldeiras (válvulas abertas)
	for i in 6:
		var bx := 60.0 + i * 100.0
		for j in 8:
			var py := 330.0 - fmod(t * 22.0 + j * 18.0 + i * 7.0, 150.0)
			var r := 6.0 + (330.0 - py) * 0.12
			draw_circle(Vector2(bx + sin(t * 0.8 + j + i) * 6.0, py), r, Color(1, 1, 1, 0.035 * k * (1.0 - (330.0 - py) / 160.0)))
	# Topo da Torre: relógio parado e parapeito
	draw_rect(Rect2(150, 120, 140, 240), Color("17141a"))
	draw_circle(Vector2(220, 150), 40.0, Color("1e1a18"))
	draw_arc(Vector2(220, 150), 40.0, 0, TAU, 40, Color("8a6a2a"), 3.0)
	for i in 12:
		var a := i * TAU / 12.0
		draw_line(Vector2(220, 150) + Vector2.from_angle(a) * 31.0, Vector2(220, 150) + Vector2.from_angle(a) * 36.0, Color("e0b860"), 2.0)
	draw_line(Vector2(220, 150), Vector2(220, 150) + Vector2(0, -26), Color("e0b860"), 2.0)
	draw_line(Vector2(220, 150), Vector2(220, 150) + Vector2(18, 4), Color("e0b860"), 3.0)
	draw_line(Vector2(196, 130), Vector2(244, 172), Color(1, 1, 1, 0.12), 1.0)
	draw_rect(Rect2(120, 290, 260, 70), Color("221e24"))
	draw_rect(Rect2(120, 290, 260, 4), Color("a8843c"))
	# Corneta dos alto-falantes
	draw_line(Vector2(330, 290), Vector2(330, 250), Color("3a3330"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(326, 252), Vector2(356, 236), Vector2(356, 262), Vector2(326, 256)]), Color("a07a38"))
	for i in 3:
		var rr := 10.0 + fmod(t * 20.0 + i * 12.0, 36.0)
		draw_arc(Vector2(358, 249), rr, -0.6, 0.6, 10, Color(1.0, 0.85, 0.5, 0.25 * (1.0 - rr / 46.0) * k), 1.2)
	# Sera com o livro aberto
	var base := Vector2(304, 290)
	var sc := Color("7fd4ff")
	draw_line(base + Vector2(-2, -13), base + Vector2(-3, 0), Color("3d93c2"), 3.2)
	draw_line(base + Vector2(2, -13), base + Vector2(3, 0), Color("3d93c2"), 3.2)
	draw_rect(Rect2(base + Vector2(-4.5, -23), Vector2(9, 11)), sc)
	draw_rect(Rect2(base + Vector2(-4.5, -14), Vector2(9, 2)), Color("b87333"))
	draw_circle(base + Vector2(0.5, -27), 3.4, Color("e8c6a0"))
	draw_circle(base + Vector2(-0.6, -28), 3.0, Color("2b2f3a"))
	draw_line(base + Vector2(-3, -28), base + Vector2(-8, -24 + sin(t * 2.0) * 1.5), Color("2b2f3a"), 2.0)
	draw_line(base + Vector2(4, -20), base + Vector2(10, -19), sc, 2.2)
	draw_rect(Rect2(base + Vector2(9, -23), Vector2(8, 6)), Color("6e2f18"))
	draw_rect(Rect2(base + Vector2(9.5, -22.5), Vector2(7, 1.2)), Color("ffd27a"))
