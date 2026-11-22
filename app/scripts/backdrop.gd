extends Node2D
## Fundo procedural de UMA tela, em uma camada:
##   "far" = longe (céu, silhuetas, lava distante), com um leve parallax;
##   "mid" = paredes, canos, janelas e máquinas.
## Desenha uma vez só dentro de um SubViewport (level.gd: _bake) e vira
## textura — custo zero por quadro. O que se mexe (engrenagens, lava
## pulsando, vapor, lanternas, raios, luzes de aviso) vira "prop": nós
## pequenos animados por rotação/transparência, sem redesenhar.

const PropsScript := preload("res://scripts/backdrop_props.gd")

var level = null
var screen := Vector2i.ZERO
var layer := "mid"
## Sobra desenhada em volta da tela (para o parallax não mostrar borda).
var margin := 0.0
var reported := false
## Pontos de luz: [pos, cor, raio, energia, tremulação]
var spots: Array = []
## Peças animadas: [tipo, dados]
var props: Array = []


## Quanto cada tema desloca a camada de longe (px).
static func parallax_of(theme: String) -> float:
	match theme:
		"market":
			return 14.0
		"foundry":
			return 10.0
		"veil":
			return 12.0
		"tower":
			return 0.0
	return 8.0


func _spot(p: Vector2, col: Color, r: float, e: float, f: float = 0.0) -> void:
	spots.append([p, col, r, e, f])


func _prop(kind: String, data: Dictionary) -> void:
	props.append([kind, data])


func _draw() -> void:
	spots.clear()
	props.clear()
	var rect: Rect2 = level.screen_rect(screen)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(screen.x, screen.y, level.phase_index * 7 + (1 if layer == "far" else 0)))
	match level.theme:
		"market":
			_market(rect, rng)
		"tower":
			_tower(rect, rng)
		"foundry":
			_foundry(rect, rng)
		"veil":
			_veil(rect, rng)
		_:
			_boiler(rect, rng)
	if not reported:
		reported = true
		level.call_deferred("backdrop_report", screen, layer, spots.duplicate(), props.duplicate())


# ---------------------------------------------------------------- ajudantes

func _vgrad(r: Rect2, top: Color, bottom: Color, steps: int = 18) -> void:
	var h := r.size.y / steps
	for i in steps:
		draw_rect(Rect2(r.position.x, r.position.y + i * h, r.size.x, h + 1.0), top.lerp(bottom, float(i) / (steps - 1)))


## Halo: círculos concêntricos bem transparentes.
func _glow(c: Vector2, radius: float, col: Color, rings: int = 5) -> void:
	for i in rings:
		draw_circle(c, radius * (1.0 - float(i) / rings), Color(col, col.a))


## `n` posições x espalhadas pela tela, sem se encostarem.
func _slots(rng: RandomNumberGenerator, n: int, rect: Rect2, jitter: float) -> Array:
	var out: Array = []
	var w := rect.size.x / n
	for i in n:
		out.append(rect.position.x + (i + 0.5) * w + rng.randf_range(-jitter, jitter))
	return out


## Linha de topo irregular (silhueta de rocha, telhados...).
func _ridge(rng: RandomNumberGenerator, x0: float, x1: float, y: float, amp: float, step: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := x0
	while x < x1:
		pts.append(Vector2(x, y + rng.randf_range(-amp, amp)))
		x += step * rng.randf_range(0.6, 1.4)
	pts.append(Vector2(x1, y + rng.randf_range(-amp, amp)))
	return pts


func _fill_below(top: PackedVector2Array, bottom_y: float, col: Color) -> void:
	var pts := top.duplicate()
	pts.append(Vector2(top[top.size() - 1].x, bottom_y))
	pts.append(Vector2(top[0].x, bottom_y))
	draw_colored_polygon(pts, col)


func _riveted_band(x0: float, x1: float, y: float, col: Color, rivet: Color) -> void:
	draw_rect(Rect2(x0, y, x1 - x0, 3), col)
	var x := x0 + 6.0
	while x < x1 - 4.0:
		draw_circle(Vector2(x, y + 1.5), 1.0, rivet)
		x += 14.0


## Luz vinda de cima onde a tela tem abertura no teto sem vizinha.
func _skylight(rect: Rect2, strength: float) -> void:
	if level.screens.has(screen + Vector2i(0, -1)):
		return
	var rows: Array = level.screens[screen]
	var top: String = rows[0]
	var light := Color("ffd27a") if level.warm_light else Color("e0a060")
	var last_spot := -99
	for x in top.length():
		if top[x] == "#":
			continue
		if x - last_spot >= 5:
			last_spot = x
			_spot(Vector2(rect.position.x + x * 20.0 + 10.0, rect.position.y + 40.0), light, 120.0, 0.55)
		var px := rect.position.x + x * 20.0
		for k in 10:
			var a := strength * (1.0 - k / 10.0)
			draw_rect(Rect2(Vector2(px - 2, rect.position.y + k * 18), Vector2(24, 18)), Color(light, a))


# ---------------------------------------------------------------- Ato 1

## Caldeiras: ao longe, caldeiras gigantes e treliças no escuro quente;
## perto, colunas de ferro, canos com vapor e portas de fornalha acesas.
func _boiler(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var pump: bool = level.phase_index == 1
	var accent := Color(0.35, 0.72, 0.62) if pump else Color(0.92, 0.42, 0.14)
	if layer == "far":
		var R := rect.grow(margin)
		_vgrad(R, Color(0.045, 0.035, 0.035), Color(0.06, 0.09, 0.09) if pump else Color(0.15, 0.09, 0.06))
		# Névoa quente baixa
		for i in 6:
			draw_rect(Rect2(R.position.x, rect.end.y - 150 + i * 18, R.size.x, 18), Color(accent, 0.015 + i * 0.006))
		# Treliças distantes
		var far_col := Color(0.095, 0.075, 0.068)
		for i in 2:
			var y := rect.position.y + 60.0 + i * 130.0 + rng.randf_range(-15, 15)
			draw_rect(Rect2(R.position.x, y, R.size.x, 5), far_col)
			draw_rect(Rect2(R.position.x, y + 20, R.size.x, 3), far_col)
			var x := R.position.x
			while x < R.end.x:
				draw_line(Vector2(x, y + 5), Vector2(x + 20, y + 20), far_col, 1.5)
				draw_line(Vector2(x + 20, y + 5), Vector2(x, y + 20), far_col, 1.5)
				x += 20.0
		# Caldeiras gigantes
		var xs := _slots(rng, 2, rect, 70.0)
		for i in xs.size():
			if i == 1 and rng.randf() < 0.3:
				continue
			var w := rng.randf_range(120, 170)
			var cx: float = xs[i]
			var top := rect.position.y + rng.randf_range(50, 110)
			var body := Color(0.23, 0.15, 0.115) if not pump else Color(0.12, 0.18, 0.18)
			draw_rect(Rect2(cx - w * 0.5, top, w, R.end.y - top), body)
			draw_circle(Vector2(cx, top), w * 0.5, body)
			# Sombreado de cilindro: faixa clara à esquerda, escura à direita
			draw_rect(Rect2(cx - w * 0.36, top, w * 0.16, R.end.y - top), body.lightened(0.08))
			draw_rect(Rect2(cx + w * 0.22, top, w * 0.28, R.end.y - top), body.darkened(0.3))
			draw_circle(Vector2(cx - w * 0.12, top - w * 0.22), w * 0.1, Color(body.lightened(0.1), 0.6))
			draw_rect(Rect2(cx - 8, top - w * 0.5 - 30, 16, 30), body)
			var y2 := top + 26.0
			while y2 < R.end.y - 20:
				_riveted_band(cx - w * 0.5, cx + w * 0.5, y2, body.lightened(0.12), body.lightened(0.25))
				y2 += 44.0
			# Borda acesa pelo fogo
			draw_rect(Rect2(cx - w * 0.5, top, 3, R.end.y - top), Color(accent, 0.4))
			draw_arc(Vector2(cx, top), w * 0.5, PI, PI * 1.6, 14, Color(accent, 0.4), 3.0)
			# Boca da fornalha (pulsa)
			var door := Rect2(cx - 16, rect.position.y + rect.size.y * 0.42, 32, 18)
			draw_rect(door.grow(3), body.darkened(0.3))
			draw_rect(door, accent.darkened(0.3))
			for k in 5:
				var gx := door.position.x + 4 + k * 8.0
				draw_line(Vector2(gx, door.position.y), Vector2(gx, door.end.y), body.darkened(0.2), 2.0)
			_prop("pulse", {"pos": door.get_center(), "r": 46.0, "col": accent, "a": 0.12, "speed": 1.3})
		return
	# --- mid
	var col_x := _slots(rng, 4, rect, 25.0)
	var wain := rect.position.y + rect.size.y * 0.6 + rng.randf_range(-20, 12)
	# Chapas rebitadas só na parte de baixo: em cima aparece o fundo.
	var plates := 8
	for i in plates:
		var shade := 0.12 + 0.025 * float(i % 2) + rng.randf_range(-0.01, 0.01)
		var x0 := rect.position.x + i * rect.size.x / plates
		var c := Color(shade * 1.15, shade, shade * 0.95) if not pump else Color(shade * 0.9, shade, shade * 1.02)
		draw_rect(Rect2(x0, wain, rect.size.x / plates, rect.end.y - wain), c)
		draw_rect(Rect2(x0, wain, 1, rect.end.y - wain), Color(0, 0, 0, 0.25))
	_riveted_band(rect.position.x, rect.end.x, wain, Color("5a3a24"), Color("8a6040"))
	draw_rect(Rect2(rect.position.x, wain + 3, rect.size.x, 6), Color(0, 0, 0, 0.25))
	# Colunas de ferro com mãos-francesas
	for x in col_x:
		var cx: float = x
		draw_rect(Rect2(cx - 7, rect.position.y, 14, rect.size.y), Color(0.14, 0.105, 0.09))
		draw_rect(Rect2(cx - 7, rect.position.y, 2, rect.size.y), Color(0.3, 0.2, 0.14))
		draw_rect(Rect2(cx + 5, rect.position.y, 2, rect.size.y), Color(0.06, 0.05, 0.05))
		var y := rect.position.y + 16.0
		while y < rect.end.y:
			draw_circle(Vector2(cx - 3, y), 1.1, Color(0.4, 0.3, 0.22))
			draw_circle(Vector2(cx + 3, y), 1.1, Color(0.4, 0.3, 0.22))
			y += 24.0
		draw_line(Vector2(cx - 7, rect.position.y + 40), Vector2(cx - 34, rect.position.y + 12), Color(0.14, 0.105, 0.09), 4.0)
		draw_line(Vector2(cx + 7, rect.position.y + 40), Vector2(cx + 34, rect.position.y + 12), Color(0.14, 0.105, 0.09), 4.0)
	# Canos horizontais com flanges e válvulas soltando vapor
	for i in rng.randi_range(1, 2):
		var y := rect.position.y + rng.randf_range(70, wain - 30)
		var h := rng.randf_range(5, 9)
		draw_rect(Rect2(rect.position.x, y, rect.size.x, h), Color("3f2a1e"))
		draw_rect(Rect2(rect.position.x, y + 1, rect.size.x, 1.2), Color("7a5230"))
		var fx := rect.position.x + rng.randf_range(10, 60)
		while fx < rect.end.x:
			draw_rect(Rect2(fx, y - 1.5, 4, h + 3), Color("5a3a24"))
			fx += rng.randf_range(70, 130)
		var vx := rect.position.x + rng.randf_range(80, rect.size.x - 80)
		draw_rect(Rect2(vx - 3, y - 6, 6, 6), Color("6e4a2c"))
		draw_circle(Vector2(vx, y - 8), 4.0, Color("8a2a1a"))
		if rng.randf() < 0.75:
			_prop("steam", {"pos": Vector2(vx, y - 10), "dir": Vector2(rng.randf_range(-0.3, 0.3), -1)})
	# Canos verticais entre as colunas
	for i in col_x.size() - 1:
		if rng.randf() < 0.45:
			continue
		var x := (float(col_x[i]) + float(col_x[i + 1])) * 0.5 + rng.randf_range(-30, 30)
		var w := rng.randf_range(5, 10)
		draw_rect(Rect2(x, rect.position.y, w, wain - rect.position.y), Color("4a3020"))
		draw_rect(Rect2(x + 1, rect.position.y, 1.5, wain - rect.position.y), Color("6e4a2c"))
		var j := rect.position.y + rng.randf_range(20, 80)
		while j < wain:
			draw_rect(Rect2(x - 1.5, j, w + 3, 4), Color("5a3a24"))
			j += rng.randf_range(60, 110)
	# Portas de fornalha e manômetros no rodapé, entre as colunas
	for i in col_x.size() - 1:
		var x := (float(col_x[i]) + float(col_x[i + 1])) * 0.5
		var y := wain + rng.randf_range(18, 40)
		if y + 26 > rect.end.y - 50:
			continue
		if rng.randf() < 0.55:
			var r := Rect2(x - 18, y, 36, 22)
			draw_rect(r.grow(4), Color("2c2422"))
			draw_rect(r, accent.darkened(0.35))
			for k in 3:
				var gx := r.position.x + r.size.x * (k + 1) / 4.0
				draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), Color("2c2422"), 1.5)
			_prop("pulse", {"pos": r.get_center(), "r": 30.0, "col": accent, "a": 0.16, "speed": 2.1})
			_spot(r.get_center(), accent.lightened(0.1), 60.0, 0.5, 0.18)
		else:
			var c := Vector2(x, y + 10)
			draw_circle(c, 7, Color("2a2523"))
			draw_circle(c, 6, Color("a89c8a"))
			draw_line(c, c + Vector2.from_angle(rng.randf_range(-PI, 0)) * 5, Color("8a2a1a"), 1.2)
	# Volante girando lá no alto
	if rng.randf() < 0.5:
		var gc := Vector2(rng.randf_range(rect.position.x + 80, rect.end.x - 80), rect.position.y + rng.randf_range(70, 120))
		_prop("gear", {"pos": gc, "r": rng.randf_range(26, 38), "col": Color(0.18, 0.13, 0.11), "speed": rng.randf_range(-0.5, 0.5), "spokes": true})
	_skylight(rect, 0.22 if level.warm_light else 0.08)


# ---------------------------------------------------------------- Ato 2

## Mercado Suspenso: céu (pôr do sol nas Docas, crepúsculo no Bazar, noite
## nos Telhados), cidade em duas camadas de silhuetas, o brilho das
## Caldeiras no abismo; perto, plataformas penduradas, correntes,
## bandeirolas e lanternas balançando.
func _market(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var variant: int = level.phase_index - 3
	var depth := float(screen.y)
	if layer == "far":
		var R := rect.grow(margin)
		var top: Color = [Color(0.22, 0.12, 0.16), Color(0.16, 0.13, 0.17), Color(0.06, 0.06, 0.11)][clampi(variant, 0, 2)]
		var bottom: Color = [Color(0.5, 0.26, 0.13), Color(0.32, 0.2, 0.14), Color(0.22, 0.13, 0.12)][clampi(variant, 0, 2)]
		_vgrad(R, top.lerp(bottom, clampf(depth * 0.25, 0.0, 0.8)), bottom)
		# Sol enevoado (Docas) / lua (Telhados) / estrelas
		if variant == 0 and depth <= 0.0:
			var sc := Vector2(rect.position.x + rect.size.x * rng.randf_range(0.3, 0.7), rect.position.y + 150)
			_glow(sc, 110.0, Color(1.0, 0.55, 0.25, 0.04), 6)
			draw_circle(sc, 26.0, Color(1.0, 0.7, 0.4, 0.55))
		elif variant == 2 and depth <= 0.0:
			for i in 40:
				draw_rect(Rect2(R.position + Vector2(rng.randf_range(0, R.size.x), rng.randf_range(0, 160)), Vector2(1, 1)), Color(1, 1, 0.9, rng.randf_range(0.2, 0.7)))
			var mc := Vector2(rect.position.x + rng.randf_range(120, 520), rect.position.y + 60)
			_glow(mc, 50.0, Color(0.8, 0.85, 1.0, 0.035), 5)
			draw_circle(mc, 13.0, Color(0.9, 0.9, 0.82, 0.8))
			draw_circle(mc + Vector2(4, -2), 11.0, top.lerp(bottom, 0.1))
		# Cidade ao longe (camada mais clara e enevoada)
		var haze: Color = top.lerp(bottom, 0.65).darkened(0.25)
		var base1 := rect.end.y - 40.0 - depth * 120.0
		var x := R.position.x
		while x < R.end.x:
			var w := rng.randf_range(18, 40)
			var h := rng.randf_range(30, 90)
			draw_rect(Rect2(x, base1 - h, w, R.end.y - base1 + h), haze)
			if rng.randf() < 0.3:
				draw_colored_polygon(PackedVector2Array([Vector2(x, base1 - h), Vector2(x + w * 0.5, base1 - h - rng.randf_range(10, 30)), Vector2(x + w, base1 - h)]), haze)
			for k in rng.randi_range(0, 3):
				draw_rect(Rect2(x + rng.randf_range(3, w - 4), base1 - h + rng.randf_range(6, h), 2, 2), Color(1.0, 0.75, 0.35, rng.randf_range(0.25, 0.6)))
			x += w + rng.randf_range(-4, 6)
		# Cidade mais perto (mais escura, chaminés com fumaça)
		var near: Color = top.lerp(bottom, 0.3).darkened(0.55)
		var base2 := rect.end.y - 10.0 - depth * 90.0
		x = R.position.x
		while x < R.end.x:
			var w := rng.randf_range(26, 56)
			var h := rng.randf_range(20, 70)
			draw_rect(Rect2(x, base2 - h, w, R.end.y - base2 + h), near)
			if rng.randf() < 0.35:
				var cx := x + rng.randf_range(4, w - 8)
				draw_rect(Rect2(cx, base2 - h - 16, 5, 16), near)
				for k in 5:
					draw_circle(Vector2(cx + 2 + k * 4, base2 - h - 22 - k * 9), 4.0 + k * 1.5, Color(near.lightened(0.1), 0.18 - k * 0.03))
			for k in rng.randi_range(1, 4):
				draw_rect(Rect2(x + rng.randf_range(3, w - 5), base2 - h + rng.randf_range(5, h), 3, 2), Color(1.0, 0.72, 0.32, rng.randf_range(0.35, 0.8)))
			x += w + rng.randf_range(0, 10)
		# Brilho das Caldeiras subindo do abismo
		if not level.screens.has(screen + Vector2i(0, 1)):
			for i in 8:
				draw_rect(Rect2(R.position.x, rect.end.y - 80 + i * 10, R.size.x, 10), Color(0.9, 0.35, 0.1, 0.03 + i * 0.02))
			_prop("pulse", {"pos": Vector2(rect.get_center().x, rect.end.y), "r": 260.0, "col": Color(1.0, 0.45, 0.15), "a": 0.05, "speed": 0.6})
			for k in 3:
				_spot(rect.position + Vector2(110 + k * 210, rect.size.y + 10), Color(1.0, 0.45, 0.15), 170.0, 0.7, 0.12)
		return
	# --- mid: plataformas penduradas em vagas que não se sobrepõem
	var xs := _slots(rng, 3, rect, 40.0)
	for i in xs.size():
		var w := rng.randf_range(70, 120)
		var x: float = float(xs[i]) - w * 0.5
		var y := rect.position.y + rng.randf_range(70, rect.size.y - 150)
		var col := Color(0.1, 0.085, 0.09, 0.92)
		draw_line(Vector2(x + 8, rect.position.y), Vector2(x + 8, y), Color(0.3, 0.27, 0.27, 0.55), 1.0)
		draw_line(Vector2(x + w - 8, rect.position.y), Vector2(x + w - 8, y), Color(0.3, 0.27, 0.27, 0.55), 1.0)
		draw_rect(Rect2(Vector2(x, y), Vector2(w, 8)), col)
		draw_rect(Rect2(Vector2(x, y + 8), Vector2(w, 2)), Color(0.9, 0.45, 0.15, 0.12))
		var hx := x + 6
		while hx < x + w - 14:
			var hh := rng.randf_range(14, 34)
			var hw := rng.randf_range(12, 22)
			draw_rect(Rect2(Vector2(hx, y - hh), Vector2(hw, hh)), col)
			draw_colored_polygon(PackedVector2Array([Vector2(hx - 2, y - hh), Vector2(hx + hw * 0.5, y - hh - 7), Vector2(hx + hw + 2, y - hh)]), col)
			if rng.randf() < 0.7:
				draw_rect(Rect2(Vector2(hx + 4, y - hh + 6), Vector2(4, 3)), Color(1.0, 0.75, 0.35, rng.randf_range(0.3, 0.7)))
			hx += rng.randf_range(16, 26)
	# Correntes grossas
	for i in rng.randi_range(2, 3):
		var x := rect.position.x + rng.randf_range(20, rect.size.x - 20)
		var y := rect.position.y
		while y < rect.end.y:
			draw_rect(Rect2(Vector2(x - 2, y), Vector2(4, 8)), Color("3a302a"))
			draw_rect(Rect2(Vector2(x - 1, y + 8), Vector2(2, 4)), Color("2a2420"))
			y += 12.0
	# Varais de bandeirolas
	for i in rng.randi_range(1, 2):
		var y := rect.position.y + rng.randf_range(50, 150)
		var n := 16
		for k in n:
			var a := Vector2(rect.position.x + k * rect.size.x / n, y + sin(k * 0.8) * 6.0)
			var b := Vector2(rect.position.x + (k + 1) * rect.size.x / n, y + sin((k + 1) * 0.8) * 6.0)
			draw_line(a, b, Color(0.4, 0.35, 0.3, 0.6), 1.0)
			var col: Color = [Color("6e2a1e"), Color("8a6a2a"), Color("3e4a36"), Color("5a3a50")][k % 4]
			draw_colored_polygon(PackedVector2Array([a, a + Vector2(5, 0), a + Vector2(2.5, 8)]), Color(col, 0.75))
	# Lanternas balançando
	for x in _slots(rng, rng.randi_range(3, 4), rect, 50.0):
		var p := Vector2(float(x), rect.position.y + rng.randf_range(40, rect.size.y - 120))
		_prop("lantern", {"pos": p, "len": rng.randf_range(10, 22), "phase": rng.randf() * TAU})
		_spot(p, Color(1.0, 0.7, 0.32), 58.0, 0.85, 0.22)


# ---------------------------------------------------------------- Ato 3

## Torre do Diretório: pilastras em ritmo fixo; entre elas, janelões em
## arco com a cidade à noite OU engrenagens gigantes girando (nunca os dois
## no mesmo vão); estandartes nas pilastras e arandelas.
func _tower(rect: Rect2, rng: RandomNumberGenerator) -> void:
	if layer == "far":
		return
	var height := -float(screen.y)
	_vgrad(rect, Color(0.11, 0.1, 0.13), Color(0.15, 0.13, 0.16))
	# Pilastras a cada 128 px; os vãos entre elas recebem uma peça cada.
	var bay := 128.0
	var n := int(rect.size.x / bay)
	var kinds: Array = []
	for i in n:
		kinds.append("window" if i % 2 == 0 else "")
	# Vãos que sobram: engrenagem, tubo ou vazio
	for i in n:
		if kinds[i] == "":
			kinds[i] = ["gear", "tube", "gear", ""][rng.randi() % 4]
	if level.phase_index == 8:
		kinds[n / 2] = "clock"
	for i in n:
		var bx := rect.position.x + i * bay
		var cx := bx + bay * 0.5
		match String(kinds[i]):
			"window":
				_tower_window(Rect2(cx - 32, rect.position.y + rng.randf_range(60, 84), 64, rng.randf_range(140, 170)), rng, height)
			"gear":
				var gc := Vector2(cx, rect.position.y + rng.randf_range(110, 200))
				_prop("gear", {"pos": gc, "r": rng.randf_range(34, 48), "col": Color(0.2, 0.17, 0.16), "speed": rng.randf_range(0.15, 0.35) * (1 if i % 2 == 0 else -1), "spokes": true})
			"clock":
				var cc := Vector2(cx, rect.position.y + 130)
				draw_circle(cc, 52, Color(0.16, 0.14, 0.12))
				draw_circle(cc, 46, Color(0.82, 0.76, 0.6, 0.85))
				draw_arc(cc, 52, 0, TAU, 40, Color("8a6a2a"), 3.0)
				for k in 12:
					var a := k * TAU / 12.0
					draw_line(cc + Vector2.from_angle(a) * 38, cc + Vector2.from_angle(a) * 44, Color(0.2, 0.15, 0.1), 2.0)
				_prop("hand", {"pos": cc, "len": 34.0, "speed": 0.05, "w": 2.0})
				_prop("hand", {"pos": cc, "len": 24.0, "speed": 0.6, "w": 3.0})
			"tube":
				var x := cx - 4
				draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(8, rect.size.y)), Color(0.5, 0.7, 0.75, 0.08))
				draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(1, rect.size.y)), Color(0.8, 0.9, 0.95, 0.15))
				var j := rect.position.y + rng.randf_range(10, 60)
				while j < rect.end.y:
					draw_rect(Rect2(Vector2(x - 2, j), Vector2(12, 3)), Color("6e5428"))
					j += rng.randf_range(50, 90)
				_prop("capsule", {"x": x + 1, "top": rect.position.y, "bottom": rect.end.y, "speed": rng.randf_range(60, 120)})
	# Pilastras por cima das bordas dos vãos
	for i in n + 1:
		var x := rect.position.x + i * bay - 11
		draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(22, rect.size.y)), Color(0.15, 0.14, 0.18))
		draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(2, rect.size.y)), Color(0.62, 0.48, 0.24, 0.35))
		draw_rect(Rect2(Vector2(x + 20, rect.position.y), Vector2(2, rect.size.y)), Color(0.05, 0.05, 0.06, 0.6))
		draw_rect(Rect2(Vector2(x - 3, rect.position.y + 30), Vector2(28, 5)), Color(0.2, 0.18, 0.22))
		# Estandarte do Diretório (em algumas)
		if i % 2 == 1 and rng.randf() < 0.7:
			var y := rect.position.y + rng.randf_range(40, 70)
			var bxx := x - 1
			draw_rect(Rect2(Vector2(bxx, y), Vector2(24, 50)), Color(0.35, 0.08, 0.08, 0.92))
			draw_colored_polygon(PackedVector2Array([Vector2(bxx, y + 50), Vector2(bxx + 12, y + 58), Vector2(bxx + 24, y + 50)]), Color(0.35, 0.08, 0.08, 0.92))
			draw_arc(Vector2(bxx + 12, y + 22), 7.0, 0, TAU, 12, Color(0.75, 0.58, 0.26, 0.8), 1.5)
			draw_circle(Vector2(bxx + 12, y + 22), 2.5, Color(0.95, 0.8, 0.45, 0.8))
		elif rng.randf() < 0.6:
			# Arandela
			var p := Vector2(x + 11, rect.position.y + rng.randf_range(150, 220))
			_spot(p, Color(1.0, 0.74, 0.36), 60.0, 0.85, 0.1)
			_glow(p, 18.0, Color(1.0, 0.75, 0.35, 0.025), 3)
			draw_rect(Rect2(p + Vector2(-2, -3), Vector2(4, 6)), Color(1.0, 0.82, 0.45, 0.8))
			draw_rect(Rect2(p + Vector2(-3, 3), Vector2(6, 2)), Color("6e5428"))


func _tower_window(win: Rect2, rng: RandomNumberGenerator, height: float) -> void:
	var x := win.position.x
	var y := win.position.y
	var w := win.size.x
	var h := win.size.y
	_spot(win.get_center() + Vector2(0, h * 0.2), Color(0.55, 0.65, 1.0), 110.0, 0.45)
	draw_rect(win, Color(0.09, 0.08, 0.16))
	draw_circle(Vector2(x + w * 0.5, y), w * 0.5, Color(0.09, 0.08, 0.16))
	for k in 8:
		draw_rect(Rect2(Vector2(x, y + h - 40 + k * 5), Vector2(w, 5)), Color(0.8, 0.35, 0.15, 0.02 + k * 0.012))
	for k in 8:
		draw_circle(Vector2(x + rng.randf_range(4, w - 4), y + rng.randf_range(-w * 0.3, h * 0.5)), 0.6, Color(1, 1, 0.9, 0.5))
	# Silhuetas de prédios e luzes da cidade lá embaixo
	var by := y + h - 8 + height * 4.0
	var bx := x
	while bx < x + w:
		var bw := rng.randf_range(5, 10)
		var bh := rng.randf_range(6, 22) / (1.0 + height * 0.4)
		draw_rect(Rect2(bx, by - bh, bw, y + h - by + bh), Color(0.06, 0.05, 0.1))
		bx += bw
	for k in 16:
		var lx := x + rng.randf_range(3, w - 3)
		var ly := y + h - rng.randf_range(4, 30 - height * 4.0)
		draw_rect(Rect2(Vector2(lx, ly), Vector2(1.5, 1.5)), Color(1.0, 0.75, 0.35, rng.randf_range(0.3, 0.85)))
	draw_rect(win, Color("8a6a2a"), false, 2.0)
	draw_arc(Vector2(x + w * 0.5, y), w * 0.5, PI, TAU, 16, Color("8a6a2a"), 2.0)
	draw_line(Vector2(x + w * 0.5, y - w * 0.5), Vector2(x + w * 0.5, y + h), Color("8a6a2a"), 1.5)
	for k in 3:
		draw_line(Vector2(x, y + h * (k + 1) / 4.0), Vector2(x + w, y + h * (k + 1) / 4.0), Color("6e5428"), 1.0)
	draw_rect(Rect2(x - 4, y + h, w + 8, 5), Color(0.22, 0.19, 0.24))


# ---------------------------------------------------------------- Ato 4

## Fundições Profundas: caverna em camadas de rocha (mais claras ao longe,
## contornadas pelo brilho da lava), cascatas e um lago de ferro fundido ao
## fundo que pulsa e solta vapor; perto, cadinhos pendurados e correntes.
func _foundry(rect: Rect2, rng: RandomNumberGenerator) -> void:
	if layer == "far":
		var R := rect.grow(margin)
		_vgrad(R, Color(0.03, 0.022, 0.022), Color(0.13, 0.05, 0.03))
		var lake_y := rect.position.y + rect.size.y * rng.randf_range(0.6, 0.68)
		# Rocha mais distante (enevoada, avermelhada)
		var far_rock := _ridge(rng, R.position.x, R.end.x, rect.position.y + rng.randf_range(120, 170), 40.0, 50.0)
		_fill_below(far_rock, R.end.y, Color(0.13, 0.065, 0.05))
		draw_polyline(far_rock, Color(1.0, 0.4, 0.12, 0.12), 2.0)
		# Cascatas de ferro fundido
		for i in rng.randi_range(1, 2):
			var fx := rect.position.x + rng.randf_range(60, rect.size.x - 60)
			var ftop := rect.position.y + rng.randf_range(40, 120)
			var fw := rng.randf_range(5, 10)
			fw *= 0.7
			_glow(Vector2(fx, (ftop + lake_y) * 0.5), (lake_y - ftop) * 0.4, Color(1.0, 0.4, 0.1, 0.012), 4)
			draw_rect(Rect2(fx - fw * 0.5, ftop, fw, lake_y - ftop), Color(0.7, 0.25, 0.07, 0.75))
			draw_rect(Rect2(fx - 0.5, ftop, 1, lake_y - ftop), Color(1.0, 0.6, 0.3, 0.6))
			_prop("pulse", {"pos": Vector2(fx, lake_y), "r": 34.0, "col": Color(1.0, 0.5, 0.15), "a": 0.1, "speed": 2.4})
		# Lago com margem irregular
		var shore := _ridge(rng, R.position.x, R.end.x, lake_y, 4.0, 30.0)
		for k in 6:
			draw_rect(Rect2(R.position.x, lake_y - 60 + k * 10, R.size.x, 10), Color(1.0, 0.4, 0.1, 0.008 + k * 0.006))
		_fill_below(shore, R.end.y, Color(0.42, 0.12, 0.04))
		draw_polyline(shore, Color(0.9, 0.45, 0.15, 0.6), 1.0)
		for k in 10:
			var cx := R.position.x + rng.randf_range(0, R.size.x)
			var cy := lake_y + rng.randf_range(6, 30)
			draw_line(Vector2(cx, cy), Vector2(cx + rng.randf_range(10, 30), cy + rng.randf_range(-2, 2)), Color(0.75, 0.3, 0.08, 0.5), 1.0)
		_prop("pulse", {"pos": Vector2(rect.get_center().x, lake_y + 10), "r": 300.0, "col": Color(1.0, 0.45, 0.12), "a": 0.02, "speed": 0.8})
		_spot(Vector2(rect.position.x + rect.size.x * 0.3, lake_y), Color(1.0, 0.45, 0.12), 150.0, 0.45, 0.2)
		_spot(Vector2(rect.position.x + rect.size.x * 0.75, lake_y), Color(1.0, 0.45, 0.12), 150.0, 0.45, 0.2)
		for i in rng.randi_range(1, 2):
			_prop("steam", {"pos": Vector2(rect.position.x + rng.randf_range(60, rect.size.x - 60), lake_y), "dir": Vector2(0, -1), "big": true})
		# Rocha mais perto, na frente do lago (escura, contorno aceso)
		var near_rock := _ridge(rng, R.position.x, R.end.x, lake_y + rng.randf_range(8, 22), 22.0, 32.0)
		_fill_below(near_rock, R.end.y, Color(0.05, 0.035, 0.035))
		draw_polyline(near_rock, Color(1.0, 0.45, 0.15, 0.35), 1.5)
		# Estalactites
		var x := R.position.x
		while x < R.end.x:
			var w := rng.randf_range(14, 40)
			var h := rng.randf_range(16, 70)
			draw_colored_polygon(PackedVector2Array([Vector2(x, R.position.y), Vector2(x + w, R.position.y), Vector2(x + w * rng.randf_range(0.35, 0.65), R.position.y + h)]), Color(0.06, 0.04, 0.04))
			x += w * rng.randf_range(0.6, 1.1)
		return
	# --- mid: cadinhos pendurados (bordas incandescentes) e correntes
	for x in _slots(rng, rng.randi_range(1, 2), rect, 60.0):
		var cx: float = x
		var cy := rect.position.y + rng.randf_range(60, 130)
		draw_line(Vector2(cx - 14, rect.position.y), Vector2(cx - 14, cy - 24), Color(0.25, 0.2, 0.18), 2.0)
		draw_line(Vector2(cx + 14, rect.position.y), Vector2(cx + 14, cy - 24), Color(0.25, 0.2, 0.18), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 28, cy - 24), Vector2(cx + 28, cy - 24), Vector2(cx + 18, cy + 18), Vector2(cx - 18, cy + 18)]), Color(0.16, 0.12, 0.11))
		draw_rect(Rect2(Vector2(cx - 28, cy - 24), Vector2(56, 3)), Color(0.3, 0.2, 0.16))
		draw_rect(Rect2(Vector2(cx - 24, cy - 27), Vector2(48, 4)), Color(1.0, 0.55, 0.15, 0.85))
		_prop("pulse", {"pos": Vector2(cx, cy - 26), "r": 30.0, "col": Color(1.0, 0.55, 0.15), "a": 0.22, "speed": 1.7})
		_spot(Vector2(cx, cy - 26), Color(1.0, 0.5, 0.15), 70.0, 0.6, 0.25)
	for i in rng.randi_range(2, 4):
		var x2 := rect.position.x + rng.randf_range(10, rect.size.x - 10)
		var y2 := rect.position.y
		var end_y := rect.position.y + rng.randf_range(80, 220)
		while y2 < end_y:
			draw_rect(Rect2(Vector2(x2 - 2, y2), Vector2(4, 7)), Color(0.2, 0.16, 0.14))
			y2 += 10.0
		draw_line(Vector2(x2, end_y), Vector2(x2 + 6, end_y + 8), Color(0.25, 0.2, 0.18), 2.0)
	# Engrenagem quebrada caída
	if rng.randf() < 0.5:
		var gc := Vector2(rect.position.x + rng.randf_range(60, rect.size.x - 60), rect.position.y + rng.randf_range(140, 220))
		var r := rng.randf_range(22, 32)
		var col := Color(0.12, 0.09, 0.085)
		draw_arc(gc, r, 0.4, TAU - 0.6, 16, col, 8.0)
		for k in 10:
			var a := 0.5 + k * (TAU - 1.2) / 10.0
			draw_line(gc + Vector2.from_angle(a) * (r + 3), gc + Vector2.from_angle(a) * (r + 8), col, 5.0)


# ---------------------------------------------------------------- Ato 5

## Véu de Ferro: céu de tempestade em duas camadas de nuvens com raios; na
## frente, a curva da cúpula feita de placas de tamanhos diferentes, com
## vãos abertos, escoras, guindastes e luzes de aviso piscando.
func _veil(rect: Rect2, rng: RandomNumberGenerator) -> void:
	if layer == "far":
		var R := rect.grow(margin)
		_vgrad(R, Color(0.06, 0.07, 0.1), Color(0.18, 0.2, 0.25))
		for i in 7:
			var c := R.position + Vector2(rng.randf_range(0, R.size.x), rng.randf_range(10, 150))
			var r := rng.randf_range(40, 80)
			draw_circle(c, r, Color(0.15, 0.17, 0.22, 0.5))
			draw_circle(c + Vector2(0, r * 0.3), r * 0.8, Color(0.2, 0.22, 0.28, 0.25))
		for i in 8:
			var c := R.position + Vector2(rng.randf_range(0, R.size.x), rng.randf_range(0, 110))
			draw_circle(c, rng.randf_range(30, 60), Color(0.07, 0.08, 0.11, 0.6))
		# Cidade lá embaixo, quase sumindo
		var x := R.position.x
		while x < R.end.x:
			if rng.randf() < 0.5:
				draw_rect(Rect2(x, rect.end.y - rng.randf_range(10, 40), 2, 2), Color(1.0, 0.75, 0.4, rng.randf_range(0.2, 0.5)))
			x += rng.randf_range(6, 16)
		_prop("lightning", {"rect": R})
		return
	# --- mid: a cúpula
	var curve := 0.0009 + 0.0004 * float(posmod(screen.x, 3))
	var base_y := rect.position.y + 34.0 - float(screen.y) * 30.0
	var cx := rect.get_center().x + float(screen.x % 2) * 120.0 - 60.0
	var x := rect.position.x - 40.0
	while x < rect.end.x + 40:
		var pw := rng.randf_range(54, 96)
		var y0 := base_y + curve * pow(x - cx, 2)
		var y1 := base_y + curve * pow(x + pw - cx, 2)
		var ph := rng.randf_range(60, 100)
		if rng.randf() < 0.12:
			# Vão aberto: só a escora aparece
			draw_line(Vector2(x, y0 + 4), Vector2(x + pw, y1 + ph), Color(0.16, 0.17, 0.21), 3.0)
		else:
			var shade := rng.randf_range(0.18, 0.24)
			var plate := PackedVector2Array([Vector2(x, y0), Vector2(x + pw, y1), Vector2(x + pw + 2, y1 + ph), Vector2(x + 2, y0 + ph + 4)])
			draw_colored_polygon(plate, Color(shade, shade + 0.02, shade + 0.06, 0.95))
			draw_line(Vector2(x, y0), Vector2(x + pw, y1), Color(0.5, 0.55, 0.63, 0.7), 1.5)
			draw_line(Vector2(x, y0), Vector2(x + 2, y0 + ph + 4), Color(0.08, 0.09, 0.11, 0.8), 1.5)
			# Manchas de chuva escorrendo
			for k in rng.randi_range(1, 3):
				var sx := x + rng.randf_range(6, pw - 6)
				var sy := lerpf(y0, y1, (sx - x) / pw) + 6
				draw_line(Vector2(sx, sy), Vector2(sx, sy + rng.randf_range(20, ph - 10)), Color(0.1, 0.11, 0.14, 0.5), 2.0)
			var rx := x + 8
			while rx < x + pw - 4:
				draw_circle(Vector2(rx, lerpf(y0, y1, (rx - x) / pw) + 4), 1.3, Color(0.5, 0.55, 0.62))
				rx += 14.0
			if rng.randf() < 0.22:
				var lp := Vector2(x + pw * 0.5, (y0 + y1) * 0.5 + 10)
				_prop("blink", {"pos": lp, "col": Color(1.0, 0.25, 0.15), "period": rng.randf_range(1.2, 2.2), "phase": rng.randf()})
		x += pw
	# Guindastes de placas com luz de aviso
	for gx in _slots(rng, rng.randi_range(1, 2), rect, 80.0):
		var top := rect.position.y + rng.randf_range(140, 180)
		var col := Color(0.15, 0.16, 0.2)
		draw_line(Vector2(gx, rect.end.y), Vector2(gx, top), col, 5.0)
		var y := top + 10.0
		while y < rect.end.y:
			draw_line(Vector2(gx - 2.5, y), Vector2(gx + 2.5, y + 10), Color(0.22, 0.23, 0.28), 1.0)
			y += 14.0
		var dirx := 1.0 if rng.randf() < 0.5 else -1.0
		draw_line(Vector2(gx, top), Vector2(gx + dirx * 90, top - 10), col, 4.0)
		draw_line(Vector2(gx + dirx * 80, top - 9), Vector2(gx + dirx * 80, top + 40), Color(0.3, 0.32, 0.36), 1.0)
		draw_rect(Rect2(gx + dirx * 80 - 10, top + 40, 20, 6), Color(0.22, 0.24, 0.29))
		_prop("blink", {"pos": Vector2(gx + 2, top - 4), "col": Color(1.0, 0.2, 0.1), "period": 1.6, "phase": rng.randf()})
		_spot(Vector2(gx + 2, top - 4), Color(1.0, 0.25, 0.15), 50.0, 0.7, 0.4)
	# Holofotes de serviço
	for i in rng.randi_range(1, 2):
		var p := rect.position + Vector2(rng.randf_range(40, rect.size.x - 40), rng.randf_range(170, 250))
		_spot(p, Color(0.8, 0.88, 1.0), 70.0, 0.55)
		draw_rect(Rect2(p + Vector2(-3, -2), Vector2(6, 4)), Color(0.85, 0.9, 1.0, 0.8))
