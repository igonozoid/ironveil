extends Node2D
## Poça de ferro fundido (Ato 4), uma faixa horizontal de células `~`.
## Encostar é morte na hora (nem rolar nem a couraça salvam); guardas e
## autômatos viram cinza. Água de um bico de resfriamento cria uma crosta
## preta por alguns segundos: dá para andar em cima até ela derreter de novo.

const Light := preload("res://scripts/fx/light.gd")
const Fx := preload("res://scripts/fx.gd")
const SURFACE := 6.0

var rect := Rect2()
var crust := 0.0
var crust_total := 1.0
var t := 0.0
var body: StaticBody2D
var shape: CollisionShape2D


func setup(r: Rect2) -> void:
	rect = r
	z_index = 2


func _ready() -> void:
	add_to_group("lava")
	body = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(rect.size.x, 8)
	shape.shape = rs
	shape.position = Vector2(rect.get_center().x, rect.position.y + SURFACE + 4)
	shape.disabled = true
	body.add_child(shape)
	var n := maxi(1, int(rect.size.x / 70.0))
	for i in n:
		var x := rect.position.x + (i + 0.5) * rect.size.x / n
		var l = Light.make(self, Vector2(x, rect.position.y + 4), Color(1.0, 0.45, 0.12), 90.0, 1.0, 0.25)
		l.z_index = 20


func hazard_rect() -> Rect2:
	return Rect2(rect.position + Vector2(0, SURFACE + 2), Vector2(rect.size.x, rect.size.y - SURFACE - 2))


func is_crusted() -> bool:
	return crust > 0.0


## Água por cima: endurece por `dur` segundos.
func cool(dur: float) -> void:
	var was := crust > 0.0
	crust = dur
	crust_total = dur
	shape.set_deferred("disabled", false)
	if not was:
		Sfx.play("steam", 0.0, 0.7)
	for i in 6:
		Fx.steam_puff(get_parent(), Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y + SURFACE), 6)


func _physics_process(delta: float) -> void:
	t += delta
	if crust > 0.0:
		crust -= delta
		if crust <= 0.0:
			shape.set_deferred("disabled", true)
			Sfx.play("steam", -6.0, 1.3)
		queue_redraw()
		return
	queue_redraw()
	if Game.world == null:
		return
	var hz := hazard_rect()
	var p = Game.world.player
	if p != null and not p.is_dead() and hz.intersects(p.hitbox()):
		Fx.fire(get_parent(), p.global_position, 16)
		p.hurt(99, "lava")
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and hz.intersects(g.rect()):
			Fx.fire(get_parent(), g.global_position, 14)
			g.crush()
	if fmod(t, 0.7) < delta and Game.world.is_active(rect.get_center()):
		Fx.burst(get_parent(), Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y + SURFACE), Color(1.0, 0.6, 0.2), 4, 60.0, 0.6, Vector2(0, 200), 1.5)


func _draw() -> void:
	var top := rect.position.y + SURFACE
	var r := Rect2(Vector2(rect.position.x, top), Vector2(rect.size.x, rect.end.y - top))
	if crust > 0.0:
		# Crosta preta com rachaduras que voltam a brilhar quando vai derreter
		var k := clampf(crust / crust_total, 0.0, 1.0)
		draw_rect(r, Color(0.12, 0.1, 0.1))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(0.25, 0.22, 0.2))
		var glow := Color(1.0, 0.45, 0.1, (1.0 - k) * 0.9 + (0.5 + 0.5 * sin(t * 20.0)) * (0.4 if k < 0.3 else 0.0))
		var x := r.position.x + 6.0
		var i := 0
		while x < r.end.x - 4.0:
			draw_line(Vector2(x, top + 1), Vector2(x + 5 + (i % 3) * 2, top + 6), glow, 1.0)
			x += 13.0
			i += 1
		return
	draw_rect(r, Color(0.85, 0.28, 0.05))
	var x2 := r.position.x
	var j := 0
	while x2 < r.end.x:
		var w := 6.0 + (j % 3) * 3.0
		var y := top + 1.5 + sin(t * 2.0 + j) * 1.0
		draw_rect(Rect2(Vector2(x2, y), Vector2(w, 2)), Color(1.0, 0.75, 0.25))
		x2 += w + 4.0
		j += 1
	draw_rect(Rect2(Vector2(r.position.x, top), Vector2(r.size.x, 1.5)), Color(1.0, 0.9, 0.5))
	for k2 in 3:
		var bx := r.position.x + fmod(t * 23.0 + k2 * 57.0, r.size.x)
		draw_circle(Vector2(bx, top + 4), 1.5 + sin(t * 5.0 + k2), Color(1.0, 0.85, 0.4, 0.8))
