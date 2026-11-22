extends Control
## Mapa de progressão: corte da montanha-cidade com as fases de cada ato.
## Modo "browse" (menu): escolher fase liberada para continuar, começar ou repetir.
## Modo "travel" (entre fases): Sera anda no mapa até a próxima fase.

const NODES := [
	Vector2(60, 288), Vector2(140, 272), Vector2(220, 256),
	Vector2(170, 224), Vector2(80, 202), Vector2(180, 178),
	Vector2(330, 146), Vector2(330, 118), Vector2(330, 90),
	Vector2(372, 296), Vector2(300, 330), Vector2(190, 342),
	Vector2(70, 52), Vector2(170, 36), Vector2(262, 22),
]
## Fases com o nome escrito à esquerda do nó (perto do painel).
const LABEL_LEFT := [6, 7, 8, 9]
const TOWER := Vector2(330, 110)
const BOSSES := {2: "Martelo-de-Vapor", 5: "Dirigível Vigília", 8: "O Regulador", 11: "A Fornalha-Mãe", 14: "O Tecelão"}
## Caminhos que dão a volta (descida às Fundições e subida ao Véu).
const DETOURS := {
	8: [Vector2(392, 90), Vector2(392, 290)],
	11: [Vector2(14, 340), Vector2(14, 66)],
}
const DESCRIPTIONS := [
	"Tutorial nas caldeiras: bordas, reentrâncias, válvulas e a primeira carga de vapor.",
	"Elevador de carga, caixa de força, painel, cartão de acesso e rebite de escalada.",
	"Tomé e o guindaste. No alto do poço espera o Martelo-de-Vapor.",
	"Chegada ao Mercado pelas docas: tábuas podres sobre o abismo, tirolesas e o primeiro holofote.",
	"Multidão, holofotes e guardas com escudo. Lira, a contrabandista, conhece um atalho.",
	"Pelos telhados até o livro de válvulas. No céu, o dirigível Vigília caça Sera.",
	"A base da Torre: torretas-sentinela, pistões esmagadores e o primeiro autômato. Hora de aprender a rolar.",
	"O coração do relógio: plataformas de engrenagem, guardas, torretas e pistões trabalhando juntos.",
	"O Diretor Halvard Maar espera no alto, no comando do Regulador e seu pêndulo.",
	"Abaixo das Caldeiras: esteiras que arrastam para o ferro fundido e um poço para descer.",
	"Martelos-pilão, rios de ferro e registros de água que endurecem a superfície por alguns segundos.",
	"A Fornalha-Mãe, o golem que gera a pressão do Véu, e a Conselheira Ívora.",
	"Sobre a cúpula: vento em rajadas, tábuas soltas e uma tirolesa sobre o vazio.",
	"A doca onde a frota do Conselho troca as placas: esteiras, prensas e uma plataforma de carga.",
	"A Coroa do Véu. O Tecelão e o Conselho das Válvulas — o fim da história.",
]

var t := 0.0
var sel := 0
var travel_t := -1.0
var travel_from := -1
var travel_to := -1
var title_l: Label
var info_name: Label
var info_act: Label
var info_status: Label
var info_desc: Label
var info_action: Label
var footer: Label


func _ready() -> void:
	Music.play("menu")
	get_tree().paused = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Game.load_save()
	title_l = _label(Vector2(410, 18), Vector2(220, 20), 14, Color("d9965a"))
	title_l.text = "MAPA DE IRONVEIL"
	info_act = _label(Vector2(410, 52), Vector2(220, 16), 9, Color(0.85, 0.75, 0.65))
	info_name = _label(Vector2(410, 66), Vector2(220, 22), 14, Color(0.97, 0.92, 0.85))
	info_status = _label(Vector2(410, 90), Vector2(220, 16), 10, Color("ffd27a"))
	info_desc = _label(Vector2(410, 112), Vector2(214, 90), 10, Color(0.88, 0.84, 0.8))
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_action = _label(Vector2(410, 230), Vector2(220, 40), 10, Color(1.0, 0.88, 0.65))
	info_action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer = _label(Vector2(410, 318), Vector2(220, 30), 8, Color(1, 0.85, 0.7, 0.7))
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var cp_phase := int(Game.checkpoint.get("phase", 0)) if not Game.checkpoint.is_empty() else 0
	sel = cp_phase
	if Game.map_mode == "travel" and Game.map_from >= 0 and Game.map_from + 1 < Game.PHASE_COUNT:
		travel_from = Game.map_from
		travel_to = Game.map_from + 1
		travel_t = 0.0
		sel = travel_to
		Sfx.play("lift", -8.0, 1.2)
	elif Game.map_from >= 0:
		sel = Game.map_from
	Game.map_mode = "browse"
	Game.map_from = -1
	_refresh()


func _label(pos: Vector2, sz: Vector2, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _status(i: int) -> String:
	var cp_phase := int(Game.checkpoint.get("phase", -1)) if not Game.checkpoint.is_empty() else -1
	if Game.is_phase_complete(i):
		return "✓ Concluída"
	if cp_phase == i:
		return "● Checkpoint aqui"
	if Game.is_phase_unlocked(i):
		return "Liberada"
	return "Bloqueada"


func _refresh() -> void:
	var a := Game.act_of(sel)
	info_act.text = String(Game.ACTS[a]["title"]).to_upper()
	info_name.text = "%d. %s" % [sel + 1, Game.PHASE_NAMES[sel]]
	info_status.text = _status(sel)
	var d: String = DESCRIPTIONS[sel]
	if BOSSES.has(sel):
		d += "\nChefão: " + String(BOSSES[sel]) + "."
	info_desc.text = d
	if travel_t >= 0.0:
		info_action.text = "Sera segue para a próxima fase..."
	elif not Game.is_phase_unlocked(sel):
		info_action.text = "Conclua a fase anterior para liberar."
	elif Game.is_phase_complete(sel):
		info_action.text = "Z / A / Enter: repetir a fase\n(o checkpoint salvo não muda)"
	elif int(Game.checkpoint.get("phase", -1)) == sel:
		info_action.text = "Z / A / Enter: continuar do checkpoint"
	else:
		info_action.text = "Z / A / Enter: começar a fase"
	footer.text = "←/→ ou ↑/↓: escolher fase · Esc: menu" if travel_t < 0.0 else "Z / Enter: seguir"


func _process(delta: float) -> void:
	t += delta
	if travel_t >= 0.0:
		travel_t += delta
		if travel_t > 1.8 and footer.text != "Z / Enter: seguir":
			footer.text = "Z / Enter: seguir"
			info_action.text = "Próxima fase: " + String(Game.PHASE_NAMES[travel_to])
			Sfx.play("blip", -6.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if travel_t >= 0.0:
		if travel_t > 1.8 and (event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("interact")):
			Sfx.play("menu", -4.0)
			Game.continue_game()
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		Game.go_to_menu()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_up") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up"):
		_select(mini(sel + 1, Game.PHASE_COUNT - 1))
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_down"):
		_select(maxi(sel - 1, 0))
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		_play()
	else:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if travel_t >= 0.0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in NODES.size():
			if (NODES[i] as Vector2).distance_to(event.position) < 14.0:
				if i == sel:
					_play()
				else:
					_select(i)
				return


func _select(i: int) -> void:
	if i != sel:
		sel = i
		Sfx.play("menu", -8.0)
		_refresh()


func _play() -> void:
	if not Game.is_phase_unlocked(sel):
		Sfx.play("clunk", -6.0)
		return
	Sfx.play("menu", -2.0)
	Game.play_from_map(sel)


# ---------------------------------------------------------------- desenho

func _sera_pos() -> Vector2:
	if travel_t >= 0.0:
		var k := clampf(travel_t / 1.6, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		return (NODES[travel_from] as Vector2).lerp(NODES[travel_to], k)
	var cp_phase := int(Game.checkpoint.get("phase", 0)) if not Game.checkpoint.is_empty() else 0
	return NODES[cp_phase]


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 640, 360), Color("100d0e"))
	# Silhueta da montanha
	var mount := PackedVector2Array([Vector2(0, 360), Vector2(0, 90), Vector2(60, 70), Vector2(160, 60),
		Vector2(260, 64), Vector2(400, 70), Vector2(400, 360)])
	draw_colored_polygon(mount, Color("1c1718"))
	# Ato 5: o Véu de Ferro, cúpula de placas sobre a montanha
	for i in 10:
		var x0 := i * 42.0 - 10.0
		var y0 := 8.0 + absf(i - 4.5) * 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x0 + 42, y0 - 4), Vector2(x0 + 44, y0 + 40), Vector2(x0 + 2, y0 + 44)]), Color(0.16, 0.17, 0.21))
		draw_line(Vector2(x0, y0), Vector2(x0 + 42, y0 - 4), Color(0.45, 0.5, 0.58, 0.4), 1.0)
	# Ato 2: plataformas do Mercado penduradas
	for i in 7:
		var x := 20.0 + i * 40.0
		var y := 160.0 + float((i * 31) % 60)
		draw_line(Vector2(x + 14, 100), Vector2(x + 14, y), Color(0.45, 0.4, 0.36, 0.3), 1.0)
		draw_rect(Rect2(x, y, 28, 7), Color("2c2420"))
		var on := int(t * 0.8 + i) % 4 != 0
		draw_rect(Rect2(x + 8, y - 4, 3, 2), Color(1.0, 0.8, 0.4, 0.6 if on else 0.2))
	# Ato 1: Caldeiras
	for i in 6:
		var x := 20.0 + i * 64.0
		draw_rect(Rect2(x, 262, 40, 40), Color("221b19"))
		draw_rect(Rect2(x + 10, 276, 18, 7), Color(0.9, 0.4, 0.15, 0.3 + 0.1 * sin(t * 2.0 + i)))
	# Ato 4: Fundições, o ferro fundido no fundo da montanha
	for i in 8:
		draw_rect(Rect2(0, 312 + i * 6.0, 400, 6), Color(0.9, 0.32, 0.08, 0.03 + i * 0.03))
	# Ato 3: a Torre
	draw_rect(Rect2(TOWER.x - 22, 62, 44, 98), Color("252027"))
	draw_rect(Rect2(TOWER.x - 30, 100, 60, 5), Color("2c262e"))
	draw_rect(Rect2(TOWER.x - 22, 62, 2, 98), Color(0.62, 0.48, 0.24, 0.35))
	for i in 4:
		var on2 := int(t * 0.6 + i * 1.7) % 3 != 0
		draw_rect(Rect2(TOWER.x - 18 + (i % 2) * 32, 70 + i * 22, 4, 5), Color(1.0, 0.72, 0.32, 0.55 if on2 else 0.18))
	# Nomes dos atos
	draw_string(font, Vector2(24, 80), "ATO 5 — O VÉU DE FERRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.82, 1.0, 0.75))
	draw_string(font, Vector2(24, 150), "ATO 2 — O MERCADO SUSPENSO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.82, 0.45, 0.75))
	draw_string(font, Vector2(282, 172), "ATO 3 — A TORRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.85, 0.75, 1.0, 0.75))
	draw_string(font, Vector2(24, 308), "ATO 1 — AS CALDEIRAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.95, 0.55, 0.3, 0.75))
	draw_string(font, Vector2(24, 356), "ATO 4 — AS FUNDIÇÕES", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.5, 0.2, 0.75))
	# Caminhos
	var path := NODES.duplicate()
	for i in path.size() - 1:
		var pts: Array = [path[i]]
		pts.append_array(DETOURS.get(i, []))
		pts.append(path[i + 1])
		var done := i < NODES.size() and Game.is_phase_complete(i)
		for k in pts.size() - 1:
			_dashed(pts[k], pts[k + 1], Color("c07a3a") if done else Color(0.5, 0.45, 0.42, 0.5), 2.0 if done else 1.0, not done)
	# Nós
	for i in NODES.size():
		var p: Vector2 = NODES[i]
		var unlocked := Game.is_phase_unlocked(i)
		var complete := Game.is_phase_complete(i)
		var col := Color("3a3330")
		if complete:
			col = Color("c07a3a")
		elif unlocked:
			col = Color("7a5a3a")
		if i == sel:
			var pulse := 0.5 + 0.5 * sin(t * 5.0)
			draw_circle(p, 13.0 + pulse * 2.0, Color(1.0, 0.85, 0.5, 0.18))
			draw_arc(p, 12.0, 0, TAU, 24, Color(1.0, 0.85, 0.5, 0.9), 1.5)
		draw_circle(p, 9.0, Color("1a1616"))
		draw_circle(p, 7.5, col)
		if BOSSES.has(i):
			_boss_icon(p, i, complete)
		elif complete:
			draw_polyline(PackedVector2Array([p + Vector2(-3.5, 0), p + Vector2(-1, 3), p + Vector2(4, -3)]), Color("fff2d8"), 1.8)
		elif not unlocked:
			draw_rect(Rect2(p + Vector2(-3, -1), Vector2(6, 5)), Color("6a6460"))
			draw_arc(p + Vector2(0, -1), 2.5, PI, TAU, 8, Color("6a6460"), 1.2)
		else:
			draw_string(font, p + Vector2(-3, 4), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff2d8"))
		var label := String(Game.PHASE_NAMES[i])
		var lp := p + Vector2(13, 4)
		if LABEL_LEFT.has(i):
			lp = p + Vector2(-13.0 - font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, 4)
		draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color(0.95, 0.9, 0.82, 0.95 if unlocked else 0.4))
	# Sera no mapa
	var sp := _sera_pos() + Vector2(0, -14 + sin(t * 4.0) * 1.5)
	draw_circle(sp + Vector2(0, 10), 4.0, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(sp + Vector2(-3, -4), Vector2(6, 8)), Color("7fd4ff"))
	draw_circle(sp + Vector2(0, -7), 3.0, Color("e8c6a0"))
	draw_circle(sp + Vector2(-0.6, -7.8), 2.6, Color("2b2f3a"))
	draw_line(sp + Vector2(-2, -7), sp + Vector2(-5, -3 + sin(t * 6.0)), Color("2b2f3a"), 1.6)
	# Painel de informação
	draw_rect(Rect2(400, 0, 240, 360), Color("171314"))
	draw_line(Vector2(400, 0), Vector2(400, 360), Color("8a5a2b"), 2.0)
	draw_rect(Rect2(410, 44, 220, 1), Color("8a5a2b"))
	# Contagem
	var done_n := (Game.progress.get("completed", []) as Array).size()
	draw_string(font, Vector2(410, 296), "Fases concluídas: %d/%d" % [done_n, Game.PHASE_COUNT], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.75, 0.65))
	var stars := "Atos  "
	for a in Game.ACTS.size():
		stars += ("★" if Game.is_act_complete(a) else "☆") + "%d  " % (a + 1)
	draw_string(font, Vector2(410, 284), stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("ffd27a"))


func _dashed(a: Vector2, b: Vector2, col: Color, w: float, dashed: bool) -> void:
	if not dashed:
		draw_line(a, b, col, w)
		return
	var n := int(a.distance_to(b) / 6.0)
	for i in n:
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, w)


func _boss_icon(p: Vector2, i: int, complete: bool) -> void:
	var c := Color("fff2d8") if complete else Color("d0c0b0")
	if i == 2:
		# Martelo
		draw_line(p + Vector2(-3, 4), p + Vector2(2, -2), c, 1.6)
		draw_rect(Rect2(p + Vector2(0, -5), Vector2(5, 4)), c)
	elif i == 11:
		# Golem
		draw_rect(Rect2(p + Vector2(-4, -4), Vector2(8, 8)), c)
		draw_rect(Rect2(p + Vector2(-2, -2), Vector2(4, 1.5)), Color("1a1616"))
	elif i == 14:
		# Tear / olho
		draw_arc(p, 4.0, 0, TAU, 12, c, 1.4)
		draw_circle(p, 1.5, c)
	elif i == 8:
		# Relógio com pêndulo
		draw_arc(p + Vector2(0, -1.5), 3.5, 0, TAU, 12, c, 1.3)
		draw_line(p + Vector2(0, -1.5), p + Vector2(0, -4), c, 1.0)
		draw_line(p + Vector2(0, 2), p + Vector2(1.5, 5), c, 1.0)
	else:
		# Dirigível
		draw_circle(p + Vector2(-2, -1), 3.0, c)
		draw_circle(p + Vector2(2, -1), 3.0, c)
		draw_rect(Rect2(p + Vector2(-2, 2), Vector2(4, 2)), c)
