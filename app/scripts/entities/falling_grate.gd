extends Node2D
## Grade suspensa por corrente eletromagnética. Quando a caixa de força ligada
## é cortada, ela despenca: esmaga guardas (e fere Sera) e vira plataforma.

const Fx := preload("res://scripts/fx.gd")
const W := 60.0
const H := 10.0

var state := "hanging"
var vy := 0.0
var chain_top := 0.0
var level = null
var sway := 0.0


func setup(pos: Vector2, top_y: float, lvl) -> void:
	position = pos
	chain_top = top_y
	level = lvl
	z_index = 3


func drop() -> void:
	if state != "hanging":
		return
	state = "falling"
	vy = 0.0
	Sfx.play("spark", -2.0)


func rect() -> Rect2:
	return Rect2(global_position.x - W * 0.5, global_position.y, W, H)


func _physics_process(delta: float) -> void:
	sway += delta
	if state != "falling":
		if state == "hanging":
			queue_redraw()
		return
	vy = minf(vy + 900.0 * delta, 600.0)
	var new_y := position.y + vy * delta
	# Pousa quando a borda de baixo encontra uma célula sólida.
	var bottom := new_y + H
	var landed := false
	for dx in [-W * 0.5 + 2.0, 0.0, W * 0.5 - 2.0]:
		var c: Vector2i = level.world_to_cell(Vector2(position.x + dx, bottom))
		if level.is_solid(c):
			new_y = c.y * 20.0 - H
			landed = true
			break
	position.y = new_y
	var r := rect()
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and r.intersects(g.rect()):
			g.crush()
	var p = Game.world.player
	if p != null and not p.is_dead() and r.intersects(p.hitbox()):
		p.hurt(2, "crush")
	if landed:
		_land()
	queue_redraw()


func _land() -> void:
	state = "landed"
	Sfx.play("crash")
	Game.world.shake(5.0)
	Fx.debris(get_parent(), global_position + Vector2(0, H))
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(W, H)
	cs.shape = shape
	cs.position = Vector2(0, H * 0.5)
	body.add_child(cs)
	add_child(body)


func _draw() -> void:
	if state == "hanging":
		var top := chain_top - global_position.y
		var y := top
		var k := 0
		while y < 0.0:
			draw_arc(Vector2(0, y + 2.5), 2.2, 0, TAU, 8, Color("8a8f96"), 1.2)
			y += 5.0
			k += 1
		draw_rect(Rect2(-6, -5, 12, 5), Color("3a4250"))
		draw_rect(Rect2(-4, -4, 8, 2), Color(0.5, 0.8, 1.0, 0.5 + 0.3 * sin(sway * 8.0)))
	draw_rect(Rect2(-W * 0.5, 0, W, H), Color("5a4a44"))
	for i in 7:
		var x := -W * 0.5 + 3 + i * 9
		draw_line(Vector2(x, 0), Vector2(x, H), Color("2a2523"), 2.0)
	draw_rect(Rect2(-W * 0.5, 0, W, H), Color("8a7a70"), false, 1.5)
