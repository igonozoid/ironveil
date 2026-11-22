extends Node2D
## Civil: anda devagar perto de casa e para nas barracas (ou fica parado, no
## caso dos personagens que dão dicas — npc.gd).
## Sera pode se misturar a eles (os guardas não a enxergam) e os guardas não
## atiram com um civil na linha de tiro. Explosões por perto os fazem fugir.
## Sangue respingado provoca uma reação ao acaso: fugir desesperado, vomitar,
## ajoelhar e rezar ou se encolher tremendo.

const COATS := [Color("5a4a3a"), Color("4a5248"), Color("6a5a40"), Color("4e4450"), Color("5e4636")]
const SplatsScript := preload("res://scripts/splats.gd")
const Fx := preload("res://scripts/fx.gd")
const SKINS := [Color("e8c6a0"), Color("c89a78"), Color("a67a5a"), Color("dab08c")]
const REACTIONS := ["flee", "flee", "vomit", "pray", "cower"]
const VOMIT := Color(0.55, 0.58, 0.18)

var home_x := 0.0
var dir: int = 1
var speed := 16.0
var t := 0.0
var pause_t := 0.0
var panic_t := 0.0
var coat := Color.WHITE
var skin := Color.WHITE
var hat := false
var basket := false
var tall := 0.0
var splats = SplatsScript.new()
## Parado no lugar (personagens que dão dicas).
var stationary := false
## Reação ao sangue: "", "flee", "vomit", "pray" ou "cower".
var reaction := ""
var reaction_t := 0.0
var react_cd := 0.0


func setup(pos: Vector2, seed_i: int) -> void:
	position = pos
	home_x = pos.x
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i * 7919 + 13
	coat = COATS[rng.randi() % COATS.size()]
	skin = SKINS[rng.randi() % SKINS.size()]
	hat = rng.randf() < 0.5
	basket = rng.randf() < 0.4
	tall = rng.randf_range(-2.0, 2.0)
	dir = 1 if rng.randf() < 0.5 else -1
	speed = rng.randf_range(12.0, 20.0)
	t = rng.randf() * 10.0
	z_index = 3


func _ready() -> void:
	add_to_group("civilian")
	add_to_group("splat_target")


func splat_rect() -> Rect2:
	var h := 27.0 + tall
	return Rect2(global_position.x - 6.0, global_position.y - h, 12.0, h)


## Sangue respingado: reage (uma vez a cada tanto).
func receive_splat(p: Vector2, r: float, col: Color) -> void:
	splats.add(p - global_position, dir, 27.0 + tall, 6.0, r, col)
	if react_cd > 0.0 or reaction != "":
		return
	react(p)


func react(from: Vector2) -> void:
	react_cd = 6.0
	reaction = REACTIONS[randi() % REACTIONS.size()]
	match reaction:
		"flee":
			panic(from)
			panic_t = 4.5
			Sfx.play("hurt", -14.0, 1.8)
		"vomit":
			reaction_t = randf_range(3.0, 4.5)
			dir = 1 if global_position.x >= from.x else -1
		"pray":
			reaction_t = randf_range(4.0, 6.0)
		_:
			reaction_t = randf_range(3.0, 5.0)


func can_hide() -> bool:
	return panic_t <= 0.0 and reaction == ""


func panic(from: Vector2) -> void:
	panic_t = 3.0
	dir = 1 if global_position.x >= from.x else -1
	if reaction == "":
		reaction = "flee"


func _physics_process(delta: float) -> void:
	t += delta
	react_cd = maxf(react_cd - delta, 0.0)
	if Game.world == null or not Game.world.is_active(global_position):
		return
	if reaction == "vomit" or reaction == "pray" or reaction == "cower":
		reaction_t -= delta
		if reaction == "vomit" and fmod(t, 0.5) < delta and fmod(t, 1.5) < 0.9:
			Fx.burst(get_parent(), global_position + Vector2(dir * 6.0, -18.0 - tall * 0.5), VOMIT, 6, 70.0, 0.5, Vector2(0, 380), 1.6)
			if fmod(t, 1.5) < delta:
				Sfx.play("steam", -20.0, 2.2)
		if reaction_t <= 0.0:
			reaction = ""
		queue_redraw()
		return
	var lvl = Game.world.level
	var v := speed
	if panic_t > 0.0:
		panic_t -= delta
		v = 80.0
		if panic_t <= 0.0:
			reaction = ""
	elif stationary:
		v = 0.0
		_idle_stationary(delta)
	elif pause_t > 0.0:
		pause_t -= delta
		v = 0.0
	elif randf() < delta * 0.25:
		pause_t = randf_range(1.0, 3.0)
	var nx := global_position.x + dir * v * delta
	var ahead: Vector2i = lvl.world_to_cell(Vector2(nx + dir * 6.0, global_position.y + 4.0))
	var wall: Vector2i = lvl.world_to_cell(Vector2(nx + dir * 6.0, global_position.y - 10.0))
	var floor_ok: bool = lvl.is_solid(ahead) or lvl.is_oneway(ahead)
	if v > 0.0 and (lvl.is_solid(wall) or not floor_ok or (panic_t <= 0.0 and absf(nx - home_x) > 60.0 and signf(nx - home_x) == dir)):
		dir = -dir
	elif v > 0.0:
		global_position.x = nx
	queue_redraw()


## Parado: olha para Sera quando ela chega perto.
func _idle_stationary(_delta: float) -> void:
	var p = Game.world.player if Game.world else null
	if p != null and absf(p.global_position.x - global_position.x) < 90.0:
		var d := signf(p.global_position.x - global_position.x)
		if d != 0.0:
			dir = int(d)


func _draw() -> void:
	match reaction:
		"pray":
			_draw_pray()
			return
		"vomit":
			_draw_vomit()
			return
		"cower":
			_draw_cower()
			return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
	var moving := pause_t <= 0.0 and (not stationary or panic_t > 0.0)
	var sw := sin(t * (16.0 if panic_t > 0.0 else 6.0)) * 2.5 if moving else 0.0
	var top := -27.0 - tall
	draw_line(Vector2(-2, -11), Vector2(-2 + sw, 0), Color("2e2826"), 3.0)
	draw_line(Vector2(2, -11), Vector2(2 - sw, 0), Color("2e2826"), 3.0)
	_draw_coat(top, 0.0)
	if basket and panic_t <= 0.0:
		draw_rect(Rect2(4, -16, 6, 5), Color("8a6a3a"))
		draw_line(Vector2(4, -16), Vector2(7, -20), Color("8a6a3a"), 1.0)
	if panic_t > 0.0:
		# Braços para cima, desesperado
		var wave := sin(t * 20.0) * 2.0
		draw_line(Vector2(-3, top + 8), Vector2(-6 + wave, top - 1), coat.darkened(0.1), 2.0)
		draw_line(Vector2(3, top + 8), Vector2(6 - wave, top - 1), coat.darkened(0.1), 2.0)
	_draw_head(Vector2(0, top + 2), panic_t > 0.0)
	splats.draw_on(self, 27.0 + tall)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_coat(top: float, lean: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-5 + lean, top + 6), Vector2(5 + lean, top + 6), Vector2(6, -8), Vector2(-6, -8)]), coat)
	draw_line(Vector2(lean, top + 7), Vector2(0, -9), coat.darkened(0.25), 1.0)


func _draw_head(c: Vector2, scream: bool) -> void:
	draw_circle(c, 3.3, skin)
	if hat:
		draw_rect(Rect2(c + Vector2(-4.5, -4.5), Vector2(9, 2.5)), Color("2a2523"))
		draw_rect(Rect2(c + Vector2(-3, -7), Vector2(6, 3)), Color("2a2523"))
	else:
		draw_rect(Rect2(c + Vector2(-3.5, -3.5), Vector2(7, 2.5)), Color("3a2c22"))
	if scream:
		draw_circle(c + Vector2(1.8, 1.4), 0.9, Color("2a1414"))


## Ajoelhado, mãos juntas, cabeça baixa, tremendo.
func _draw_pray() -> void:
	var sh := sin(t * 40.0) * 0.4
	draw_set_transform(Vector2(sh, 0), 0.0, Vector2(dir, 1))
	var top := -19.0 - tall * 0.6
	draw_line(Vector2(-4, -2), Vector2(3, -2), Color("2e2826"), 3.0)
	draw_line(Vector2(-4, -2), Vector2(-4, -9), Color("2e2826"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, top + 6), Vector2(4, top + 6), Vector2(5, -6), Vector2(-6, -6)]), coat)
	draw_line(Vector2(2, top + 9), Vector2(6, top + 6), coat.darkened(0.1), 2.0)
	draw_circle(Vector2(6, top + 5), 1.4, skin)
	_draw_head(Vector2(1.5, top + 2.5), false)
	splats.draw_on(self, 20.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Curvado para a frente, vomitando.
func _draw_vomit() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
	var top := -24.0 - tall
	var heave := absf(sin(t * 6.0)) * 1.5
	draw_line(Vector2(-3, -11), Vector2(-3, 0), Color("2e2826"), 3.0)
	draw_line(Vector2(2, -11), Vector2(3, 0), Color("2e2826"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(1, top + 4 + heave), Vector2(8, top + 9 + heave), Vector2(5, -8), Vector2(-5, -8)]), coat)
	draw_line(Vector2(4, top + 10), Vector2(3, -12), coat.darkened(0.2), 2.0)
	_draw_head(Vector2(8, top + 6 + heave), false)
	if fmod(t, 1.5) < 0.9:
		draw_line(Vector2(10, top + 8 + heave), Vector2(11, -2), Color(VOMIT, 0.8), 1.6)
	draw_rect(Rect2(8, -2, 8, 2), Color(VOMIT, 0.7))
	splats.draw_on(self, 24.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Encolhido, mãos na cabeça, tremendo.
func _draw_cower() -> void:
	var sh := sin(t * 45.0) * 0.6
	draw_set_transform(Vector2(sh, 0), 0.0, Vector2(dir, 1))
	var top := -16.0 - tall * 0.5
	draw_line(Vector2(-3, -4), Vector2(-3, 0), Color("2e2826"), 3.0)
	draw_line(Vector2(3, -4), Vector2(3, 0), Color("2e2826"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, top + 5), Vector2(5, top + 5), Vector2(6, -3), Vector2(-6, -3)]), coat)
	_draw_head(Vector2(0, top + 1), false)
	draw_line(Vector2(-4, top + 6), Vector2(-3, top - 1), coat.darkened(0.1), 2.0)
	draw_line(Vector2(4, top + 6), Vector2(3, top - 1), coat.darkened(0.1), 2.0)
	splats.draw_on(self, 17.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
