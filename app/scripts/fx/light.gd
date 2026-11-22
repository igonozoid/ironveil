extends PointLight2D
## Luz 2D macia (textura radial gerada) com tremulação opcional e vida curta
## opcional (clarões de tiro e explosão). Use Light.make(...).

const SELF := preload("res://scripts/fx/light.gd")

static var _tex: GradientTexture2D = null

var flicker := 0.0
var base_energy := 1.0
var life := -1.0
var life_total := 1.0
var t := 0.0


static func texture() -> GradientTexture2D:
	if _tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_tex = GradientTexture2D.new()
		_tex.gradient = g
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 0.5)
		_tex.width = 128
		_tex.height = 128
	return _tex


## `radius` em px (alcance aproximado da luz).
static func make(parent: Node, pos: Vector2, col: Color, radius: float, energy: float = 1.0,
		flick: float = 0.0, duration: float = -1.0):
	if parent == null:
		return null
	var l = SELF.new()
	l.texture = texture()
	l.texture_scale = radius / 64.0
	l.color = col
	l.energy = energy
	l.base_energy = energy
	l.flicker = flick
	l.position = pos
	l.t = randf() * 10.0
	if duration > 0.0:
		l.life = duration
		l.life_total = duration
	parent.add_child(l)
	return l


func _process(delta: float) -> void:
	t += delta
	if life > 0.0:
		life -= delta
		energy = base_energy * clampf(life / life_total, 0.0, 1.0)
		if life <= 0.0:
			queue_free()
		return
	if flicker > 0.0:
		energy = base_energy * (1.0 - flicker * (0.5 + 0.5 * sin(t * 13.0) * sin(t * 7.3 + 1.0)))
