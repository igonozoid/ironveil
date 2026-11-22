extends Node2D
## Civil do Mercado: anda devagar perto de casa e para nas barracas.
## Sera pode se misturar a eles (os guardas não a enxergam) e os guardas não
## atiram com um civil na linha de tiro. Explosões por perto os fazem fugir.

const COATS := [Color("5a4a3a"), Color("4a5248"), Color("6a5a40"), Color("4e4450"), Color("5e4636")]
const SplatsScript := preload("res://scripts/splats.gd")
const SKINS := [Color("e8c6a0"), Color("c89a78"), Color("a67a5a"), Color("dab08c")]

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


## Sangue respingado no casaco: o civil se assusta e foge.
func receive_splat(p: Vector2, r: float, col: Color) -> void:
	splats.add(p - global_position, dir, 27.0 + tall, 6.0, r, col)
	if panic_t <= 0.0 and Game.world != null and Game.world.player != null:
		panic(p - Vector2(dir * 4.0, 0))


func can_hide() -> bool:
	return panic_t <= 0.0


func panic(from: Vector2) -> void:
	panic_t = 3.0
	dir = 1 if global_position.x >= from.x else -1


func _physics_process(delta: float) -> void:
	t += delta
	if Game.world == null or not Game.world.is_active(global_position):
		return
	var lvl = Game.world.level
	var v := speed
	if panic_t > 0.0:
		panic_t -= delta
		v = 75.0
	elif pause_t > 0.0:
		pause_t -= delta
		v = 0.0
	elif randf() < delta * 0.25:
		pause_t = randf_range(1.0, 3.0)
	var nx := global_position.x + dir * v * delta
	var ahead: Vector2i = lvl.world_to_cell(Vector2(nx + dir * 6.0, global_position.y + 4.0))
	var wall: Vector2i = lvl.world_to_cell(Vector2(nx + dir * 6.0, global_position.y - 10.0))
	var floor_ok: bool = lvl.is_solid(ahead) or lvl.is_oneway(ahead)
	if lvl.is_solid(wall) or not floor_ok or (panic_t <= 0.0 and absf(nx - home_x) > 60.0 and signf(nx - home_x) == dir):
		dir = -dir
	elif v > 0.0:
		global_position.x = nx
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
	var moving := pause_t <= 0.0
	var sw := sin(t * (14.0 if panic_t > 0.0 else 6.0)) * 2.5 if moving else 0.0
	var top := -27.0 - tall
	draw_line(Vector2(-2, -11), Vector2(-2 + sw, 0), Color("2e2826"), 3.0)
	draw_line(Vector2(2, -11), Vector2(2 - sw, 0), Color("2e2826"), 3.0)
	# Casaco longo
	draw_colored_polygon(PackedVector2Array([Vector2(-5, top + 6), Vector2(5, top + 6), Vector2(6, -8), Vector2(-6, -8)]), coat)
	draw_line(Vector2(0, top + 7), Vector2(0, -9), coat.darkened(0.25), 1.0)
	if basket:
		draw_rect(Rect2(4, -16, 6, 5), Color("8a6a3a"))
		draw_line(Vector2(4, -16), Vector2(7, -20), Color("8a6a3a"), 1.0)
	if panic_t > 0.0:
		draw_line(Vector2(-3, top + 8), Vector2(-6, top), coat.darkened(0.1), 2.0)
		draw_line(Vector2(3, top + 8), Vector2(6, top), coat.darkened(0.1), 2.0)
	draw_circle(Vector2(0, top + 2), 3.3, skin)
	if hat:
		draw_rect(Rect2(-4.5, top - 2.5, 9, 2.5), Color("2a2523"))
		draw_rect(Rect2(-3, top - 5, 6, 3), Color("2a2523"))
	else:
		draw_rect(Rect2(-3.5, top - 1.5, 7, 2.5), Color("3a2c22"))
	splats.draw_on(self, 27.0 + tall)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
