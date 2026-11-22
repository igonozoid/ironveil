extends RefCounted
## Círculo pronto em textura. Desenhar círculos como retângulos com esta
## textura deixa a placa de vídeo juntar centenas deles numa chamada só
## (draw_circle vira um polígono por círculo, uma chamada cada).

static var _tex: GradientTexture2D = null


static func tex() -> GradientTexture2D:
	if _tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.86, Color(1, 1, 1, 1))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_tex = GradientTexture2D.new()
		_tex.gradient = g
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 0.5)
		_tex.width = 32
		_tex.height = 32
	return _tex


static func draw(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(tex(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, col)
