extends Control
## Fim de ato. Ato 1: Sera no topo do poço vê a luz do Mercado Suspenso.
## Ato 2: no telhado, com o livro de válvulas, Sera encara a Torre do Diretório.
## Ato 3 (final): no alto da Torre, ao amanhecer, Sera lê o livro para a cidade.

var t := 0.0
var title: Label
var sub: Label
var hint: Label


func _ready() -> void:
	Music.play("ending" if Game.end_act >= Game.ACTS.size() - 1 else "menu")
	get_tree().paused = false
	# Novo ato, roupa limpa.
	Game.clean_sera()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var done := (Game.progress.get("completed", []) as Array).size()
	if Game.end_act == 0:
		title = _label("Ato 1 concluído", 26, 210)
		sub = _label("Do alto do poço, Sera vê pela primeira vez o Mercado Suspenso: uma cidade inteira\npendurada por correntes sob a abóbada da montanha. Os guardas do Diretório não vão parar — mas Sera também não.", 10, 248)
		hint = _label(tr("Fases concluídas: %d/%d  ·  Progresso salvo\nZ / Enter: seguir para o Ato 2") % [done, Game.PHASE_COUNT], 9, 312)
	elif Game.end_act >= 4:
		title = _label("Ato 5 concluído — Fim", 26, 200)
		sub = _label("O Tecelão caiu e o Véu de Ferro se abre, placa por placa. Pela primeira vez, Ironveil vê o céu.\nDo alto da cúpula, Sera lê o livro de válvulas para a cidade inteira:\nninguém mais vai decidir quem respira e quem carrega a pressão.", 10, 236)
		hint = _label(tr("Fases concluídas: %d/%d  ·  Progresso salvo  ·  Obrigado por jogar IRONVEIL\nZ / Enter: abrir o mapa (repita qualquer fase)") % [done, Game.PHASE_COUNT], 9, 316)
	elif Game.end_act == 3:
		title = _label("Ato 4 concluído", 26, 200)
		sub = _label("A Fornalha-Mãe esfriou. Pela primeira vez em cem anos, as Caldeiras silenciam.\nLá no alto, sem pressão, as placas do Véu rangem e começam a ceder.\nO Conselho ainda está lá em cima, dentro do Tecelão.", 10, 236)
		hint = _label(tr("Fases concluídas: %d/%d  ·  Progresso salvo\nZ / Enter: seguir para o Ato 5") % [done, Game.PHASE_COUNT], 9, 316)
	elif Game.end_act == 2:
		title = _label("Ato 3 concluído", 26, 200)
		sub = _label("O Regulador parou. Antes de morrer, Maar riu: o relógio nunca foi dele.\nQuem mantém Ironveil fechada sob o Véu de Ferro é o Conselho das Válvulas —\ne a pressão que segura o Véu vem da Fornalha-Mãe, lá embaixo. Para chegar ao céu, é preciso descer.", 10, 236)
		hint = _label(tr("Fases concluídas: %d/%d  ·  Progresso salvo\nZ / Enter: seguir para o Ato 4") % [done, Game.PHASE_COUNT], 9, 316)
	else:
		title = _label("Ato 2 concluído", 26, 210)
		sub = _label("O livro de válvulas prova: a ordem que explodiu a Caldeira Sul saiu da Torre do Diretório.\nLá em cima, alguém já sabe que Sera tem o livro.", 11, 248)
		hint = _label(tr("Fases concluídas: %d/%d  ·  Progresso salvo\nZ / Enter: seguir para o Ato 3") % [done, Game.PHASE_COUNT], 9, 312)
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
	l.text = tr(txt)
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
	if Game.end_act >= 4:
		_draw_finale(true)
		return
	if Game.end_act == 3:
		_draw_foundry_end()
		return
	if Game.end_act == 2:
		_draw_finale(false)
		return
	if Game.end_act >= 1:
		_draw_tower()
		return
	_draw_act1()


## Fim do Ato 1: Sera sai do poço e vê o Mercado Suspenso pela primeira vez.
## Cena em camadas com a câmera subindo devagar: abóbada da caverna com
## frestas de luz, plataformas penduradas por correntes com lanternas, toldos,
## vapor, raios de sol com poeira, brasas subindo do poço e Sera em silhueta
## na borda, contra a luz.
func _draw_act1() -> void:
	var w := 640.0
	var h := 360.0
	var k := clampf(t / 5.0, 0.0, 1.0)
	var ease := k * k * (3.0 - 2.0 * k)
	var cam := (1.0 - ease) * 60.0      # a cena sobe 60 px ao abrir
	# Céu da caverna: roxo no alto, âmbar perto das plataformas
	for i in 36:
		var y := i * 10.0
		var c := Color(0.09, 0.06, 0.12).lerp(Color(0.78, 0.45, 0.22), clampf((y - 40.0) / 260.0, 0.0, 1.0))
		draw_rect(Rect2(0, y, w, 10), c)
	# Abóbada de rocha com frestas por onde entra luz
	var dome := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 46 + cam * 0.3)])
	var x := w
	while x >= 0.0:
		dome.append(Vector2(x, 38.0 + sin(x * 0.03) * 10.0 + sin(x * 0.11) * 4.0 + cam * 0.3))
		x -= 32.0
	dome.append(Vector2(0, 46 + cam * 0.3))
	draw_colored_polygon(dome, Color(0.07, 0.05, 0.07))
	# Raios de sol entrando pelas frestas, com poeira
	for i in 4:
		var x0 := 90.0 + i * 140.0
		var sway := sin(t * 0.4 + i) * 6.0
		for s in 6:
			var wid := 10.0 + s * 9.0
			draw_colored_polygon(PackedVector2Array([Vector2(x0 - wid * 0.2, 40), Vector2(x0 + wid * 0.2, 40),
				Vector2(x0 + 120 + wid + sway, h), Vector2(x0 + 120 - wid * 0.4 + sway, h)]), Color(1.0, 0.85, 0.55, 0.018 * ease))
	# Camada distante: plataformas penduradas, bem apagadas
	_market_layer(0.35, 0.55, 70.0 + cam * 0.5, 7, 1.0, 11)
	# Camada do meio
	_market_layer(0.65, 0.82, 120.0 + cam * 0.8, 5, 1.5, 23)
	# Plataforma principal com toldos, perto
	var py := 190.0 + cam
	var plat := Rect2(330, py, 260, 12)
	draw_line(Vector2(360, 0), Vector2(360, py), Color(0.15, 0.1, 0.08), 3.0)
	draw_line(Vector2(560, 0), Vector2(560, py), Color(0.15, 0.1, 0.08), 3.0)
	draw_rect(plat, Color(0.16, 0.1, 0.07))
	draw_rect(Rect2(plat.position, Vector2(plat.size.x, 2)), Color(0.9, 0.55, 0.25, 0.8))
	var tents := [Color("8a2a1e"), Color("c08a2a"), Color("3e5a46"), Color("6a3a5a")]
	for i in 4:
		var tx := 345.0 + i * 60.0
		var col: Color = tents[i]
		draw_colored_polygon(PackedVector2Array([Vector2(tx, py), Vector2(tx + 24, py - 28), Vector2(tx + 48, py)]), col.darkened(0.25))
		draw_line(Vector2(tx + 24, py - 28), Vector2(tx + 48, py), col.lightened(0.15), 1.0)
		var on := 0.6 + 0.4 * sin(t * 2.0 + i * 1.7)
		draw_circle(Vector2(tx + 24, py - 8), 9.0, Color(1.0, 0.75, 0.35, 0.12 * on))
		draw_rect(Rect2(Vector2(tx + 22, py - 10), Vector2(4, 4)), Color(1.0, 0.8, 0.4, on))
	# Bandeirolas entre as correntes
	for i in 14:
		var a := Vector2(340 + i * 17.0, py - 40 + sin(i * 0.7) * 5.0)
		var b := Vector2(340 + (i + 1) * 17.0, py - 40 + sin((i + 1) * 0.7) * 5.0)
		draw_line(a, b, Color(0.3, 0.2, 0.15), 1.0)
		draw_colored_polygon(PackedVector2Array([a, a + Vector2(6, 0), a + Vector2(3, 8 + sin(t * 3.0 + i) * 1.5)]), [Color("8a2a1e"), Color("c08a2a"), Color("3e5a46")][i % 3])
	# Vapor subindo das plataformas
	for i in 10:
		var vx := 360.0 + fmod(i * 47.0, 220.0) + sin(t * 0.7 + i) * 8.0
		var vy := py - fmod(t * (10.0 + i) + i * 23.0, 160.0)
		draw_circle(Vector2(vx, vy), 7.0 + (i % 3) * 4.0, Color(1, 0.95, 0.9, 0.035 * ease))
	# Tirolesa com um carrinho de carga atravessando
	var z0 := Vector2(0, 150 + cam)
	var z1 := Vector2(340, py - 4)
	draw_line(z0, z1, Color(0.25, 0.2, 0.18), 1.2)
	var zk := fmod(t * 0.05, 1.0)
	var zc := z0.lerp(z1, zk)
	draw_line(zc, zc + Vector2(0, 10), Color(0.25, 0.2, 0.18), 1.0)
	draw_rect(Rect2(zc + Vector2(-6, 10), Vector2(12, 7)), Color(0.22, 0.15, 0.1))
	# Brilho das Caldeiras subindo do poço, lá embaixo
	for i in 10:
		draw_rect(Rect2(0, h - 60 + i * 6.0, w, 6), Color(0.95, 0.4, 0.12, 0.02 + i * 0.012))
	# Brasas subindo
	for i in 26:
		var ex := fmod(i * 73.0 + sin(t * 0.8 + i) * 20.0, w)
		var ey := h - fmod(t * (16.0 + (i % 5) * 6.0) + i * 41.0, h + 40.0)
		var ea := clampf((ey - 60.0) / 300.0, 0.0, 1.0)
		draw_rect(Rect2(Vector2(ex, ey), Vector2(1.6, 1.6)), Color(1.0, 0.6, 0.2, 0.8 * ea))
	# Primeiro plano: borda do poço (grade de ferro) em silhueta
	var rim := 300.0 + cam * 0.2
	draw_colored_polygon(PackedVector2Array([Vector2(0, rim + 6), Vector2(260, rim), Vector2(300, rim + 10), Vector2(300, h), Vector2(0, h)]), Color(0.05, 0.035, 0.035))
	draw_line(Vector2(0, rim + 6), Vector2(260, rim), Color(0.9, 0.55, 0.25, 0.7), 1.5)
	for i in 9:
		draw_line(Vector2(20 + i * 28.0, rim + 4 - i * 0.6), Vector2(20 + i * 28.0, h), Color(0.12, 0.08, 0.07), 3.0)
	# Sera em silhueta, contra a luz, com o rabo de cavalo ao vento
	var base := Vector2(196, rim + 1.5)
	var sil := Color(0.04, 0.03, 0.04)
	var rimc := Color(1.0, 0.75, 0.4, 0.9)
	draw_line(base + Vector2(-2.5, -14), base + Vector2(-4, 0), sil, 3.6)
	draw_line(base + Vector2(2.5, -14), base + Vector2(4, 0), sil, 3.6)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-5, -14), base + Vector2(5, -14), base + Vector2(4.5, -25), base + Vector2(-4.5, -25)]), sil)
	draw_circle(base + Vector2(0.5, -29), 3.8, sil)
	var wind := sin(t * 2.2) * 2.0
	draw_line(base + Vector2(-2.5, -30), base + Vector2(-9 + wind, -26), sil, 2.2)
	draw_line(base + Vector2(-9 + wind, -26), base + Vector2(-13 + wind * 1.4, -23), sil, 1.6)
	# Braço apontando para cima, para o Mercado
	draw_line(base + Vector2(4, -23), base + Vector2(9, -33), sil, 2.4)
	# Contorno de luz quente
	draw_line(base + Vector2(4.5, -25), base + Vector2(5, -14), rimc, 0.8)
	draw_arc(base + Vector2(0.5, -29), 3.8, -1.4, 0.6, 8, rimc, 0.8)
	draw_line(base + Vector2(4, -23), base + Vector2(9, -33), Color(rimc, 0.6), 0.6)
	# Faixa escura atrás do texto
	for i in 12:
		draw_rect(Rect2(0, 196 + i * 12.0, w, 12), Color(0, 0, 0, minf(0.06 * i, 0.4) * ease))


## Uma camada de plataformas penduradas (profundidade 0..1 controla cor e tamanho).
func _market_layer(depth: float, scale: float, base_y: float, n: int, rope: float, seed_i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var col := Color(0.42, 0.26, 0.18).lerp(Color(0.12, 0.08, 0.07), depth)
	for i in n:
		var x := rng.randf_range(-20, 620)
		var y := base_y + rng.randf_range(-20, 40) + sin(t * 0.5 + i) * 1.5
		var wdt := rng.randf_range(50, 110) * scale
		draw_line(Vector2(x + 6, 0), Vector2(x + 6, y), Color(col, 0.6), rope)
		draw_line(Vector2(x + wdt - 6, 0), Vector2(x + wdt - 6, y), Color(col, 0.6), rope)
		draw_rect(Rect2(x, y, wdt, 6 * scale), col)
		var hx := x + 4.0
		while hx < x + wdt - 10.0:
			var hh := rng.randf_range(10, 26) * scale
			var hw := rng.randf_range(10, 18) * scale
			draw_rect(Rect2(hx, y - hh, hw, hh), col)
			if rng.randf() < 0.7:
				var on := 0.5 + 0.5 * sin(t * 1.5 + hx)
				draw_rect(Rect2(hx + hw * 0.4, y - hh + 4, 3 * scale, 2.5 * scale), Color(1.0, 0.75, 0.35, (0.3 + 0.5 * on) * (1.0 - depth * 0.5)))
			hx += hw + rng.randf_range(4, 10)


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


## Final (Ato 5, open_sky) ou fim do Ato 3 (noite, Véu fechado): alto da Torre. O relógio parado atrás, a cidade lá
## embaixo, colunas de vapor subindo das Caldeiras e Sera no parapeito com o
## livro, diante da corneta dos alto-falantes.
func _draw_finale(open_sky: bool) -> void:
	var w := 640.0
	var h := 360.0
	var k := clampf(t / 5.0, 0.0, 1.0) if open_sky else 0.12
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
	# O Véu de Ferro: placas que cobrem o céu (abrem no final)
	var gap := (k * 300.0) if open_sky else 0.0
	for side in [-1.0, 1.0]:
		var x0: float = 320.0 + side * gap * 0.5
		var x1: float = x0 + side * 420.0
		var pts := PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, 70), Vector2(x0, 90)])
		draw_colored_polygon(pts, Color(0.12, 0.12, 0.15))
		draw_line(Vector2(x0, 0), Vector2(x0, 90), Color(0.45, 0.48, 0.55), 2.0)
		for i in 8:
			draw_circle(Vector2(x0 + side * (12.0 + i * 24.0), 80.0 - i * 1.5), 1.6, Color(0.45, 0.48, 0.55))


## Fim do Ato 4: a caverna da Fornalha, o golem resfriado afundando no ferro
## que escurece, vapor subindo e Sera com a lanterna olhando o poço de luz.
func _draw_foundry_end() -> void:
	var w := 640.0
	var h := 360.0
	var k := clampf(t / 4.0, 0.0, 1.0)
	draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.035, 0.035))
	# Poço de luz fria vindo de cima
	for i in 20:
		var y := i * 18.0
		var sp := 60.0 + i * 5.0
		draw_rect(Rect2(450 - sp * 0.5, y, sp, 18), Color(0.7, 0.8, 1.0, maxf(0.0, (0.16 - i * 0.007) * k)))
	# Ferro esfriando (de laranja a cinza)
	var lava := Color(0.9, 0.35, 0.08).lerp(Color(0.18, 0.15, 0.15), k)
	draw_rect(Rect2(0, 290, w, 70), lava)
	for i in 12:
		var x := fmod(i * 61.0, w)
		draw_line(Vector2(x, 292), Vector2(x + 18, 300), Color(1.0, 0.5, 0.15, 0.5 * (1.0 - k)), 1.0)
	# Golem afundando, crosta preta
	var gy := 300.0 - 90.0 * (1.0 - k * 0.6)
	draw_colored_polygon(PackedVector2Array([Vector2(150, 300), Vector2(250, 300), Vector2(258, gy + 40), Vector2(236, gy), Vector2(164, gy), Vector2(142, gy + 40)]), Color(0.12, 0.1, 0.1))
	draw_rect(Rect2(186, gy - 24, 28, 22), Color(0.12, 0.1, 0.1))
	draw_rect(Rect2(196, gy - 16, 8, 3), Color(0.3, 0.35, 0.4, 1.0 - k))
	# Vapor
	for i in 14:
		var px := 120.0 + fmod(i * 47.0, 200.0) + sin(t + i) * 8.0
		var py := 300.0 - fmod(t * (20.0 + i * 2.0) + i * 31.0, 260.0)
		draw_circle(Vector2(px, py), 8.0 + (i % 4) * 4.0, Color(1, 1, 1, 0.045))
	# Margem e Sera com a lanterna
	draw_rect(Rect2(380, 290, 260, 70), Color("1c1716"))
	draw_rect(Rect2(380, 290, 260, 3), Color("8a3a18"))
	var base := Vector2(450, 290)
	draw_circle(base + Vector2(6, -14), 30.0, Color(1.0, 0.8, 0.5, 0.08))
	draw_line(base + Vector2(-2, -13), base + Vector2(-3, 0), Color("3d93c2"), 3.2)
	draw_line(base + Vector2(2, -13), base + Vector2(3, 0), Color("3d93c2"), 3.2)
	draw_rect(Rect2(base + Vector2(-4.5, -23), Vector2(9, 11)), Color("7fd4ff"))
	draw_rect(Rect2(base + Vector2(-4.5, -14), Vector2(9, 2)), Color("b87333"))
	draw_circle(base + Vector2(0.5, -27), 3.4, Color("2b2f3a"))
	draw_line(base + Vector2(4, -20), base + Vector2(8, -14), Color("7fd4ff"), 2.2)
	draw_rect(Rect2(base + Vector2(6, -14), Vector2(5, 6)), Color(1.0, 0.85, 0.5))
