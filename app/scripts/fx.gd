extends RefCounted
## Efeitos visuais simples com CPUParticles2D (faíscas, vapor, destroços).

const STEAM := Color(0.94, 0.94, 0.94, 0.85)
const SPARK := Color(1.0, 0.78, 0.35)
const RUST := Color(0.55, 0.27, 0.13)


static func fade_ramp(c: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, c)
	g.set_color(1, Color(c, 0.0))
	return g


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 120.0,
		life: float = 0.4, grav: Vector2 = Vector2(0, 300), size: float = 2.0) -> void:
	if parent == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = life
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = grav
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.color_ramp = fade_ramp(color)
	p.position = pos
	p.z_index = 8
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func sparks(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, SPARK, 8, 140.0, 0.25, Vector2(0, 400), 1.5)


static func steam_puff(parent: Node, pos: Vector2, amount: int = 10) -> void:
	burst(parent, pos, STEAM, amount, 50.0, 0.8, Vector2(0, -40), 5.0)


static func smoke(parent: Node, pos: Vector2, amount: int = 5) -> void:
	burst(parent, pos, Color(0.55, 0.52, 0.5, 0.55), amount, 25.0, 0.7, Vector2(0, -30), 3.5)


static func dust(parent: Node, pos: Vector2, amount: int = 8) -> void:
	if parent == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.5
	p.direction = Vector2(0, -1)
	p.spread = 75.0
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 45.0
	p.gravity = Vector2(0, 40)
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(5, 1)
	p.color_ramp = fade_ramp(Color(0.62, 0.55, 0.48, 0.6))
	p.position = pos
	p.z_index = 8
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func fire(parent: Node, pos: Vector2, amount: int = 20) -> void:
	burst(parent, pos, Color(1.0, 0.55, 0.15), amount, 140.0, 0.55, Vector2(0, -60), 4.0)
	burst(parent, pos, Color(1.0, 0.9, 0.5), amount / 2, 90.0, 0.3, Vector2(0, -40), 3.0)


static func debris(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, RUST, 16, 180.0, 0.7, Vector2(0, 500), 3.0)
