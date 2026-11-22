extends Node2D
## Pistão esmagador da Torre (Ato 3). Desce do teto num ciclo fixo: espera,
## treme (aviso), bate no chão e sobe devagar. Quem estiver embaixo é
## esmagado — rolar não salva. Guardas também.

const Fx := preload("res://scripts/fx.gd")
const W := 20.0
const WAIT := 1.5
const WARN := 0.45
const SLAM := 0.1
const HOLD := 0.45
const RISE := 0.9

var top := 0.0        # y do teto (onde o pistão fica recolhido)
var floor_y := 0.0    # y do chão
var t := 0.0
var phase := 0        # 0 espera, 1 aviso, 2 descendo, 3 embaixo, 4 subindo
var ext := 0.0        # 0 recolhido .. 1 no chão
var hit_done := false


func setup(x: float, ceiling_y: float, floor_world_y: float, offset: float) -> void:
	position = Vector2(x, ceiling_y)
	top = ceiling_y
	floor_y = floor_world_y
	t = -offset
	z_index = 3


func _ready() -> void:
	add_to_group("crusher")


func head_y() -> float:
	return lerpf(top + 18.0, floor_y, ext)


func danger_rect() -> Rect2:
	return Rect2(global_position.x - W * 0.5 + 1.0, head_y() - 14.0, W - 2.0, 14.0)


func _physics_process(delta: float) -> void:
	t += delta
	match phase:
		0:
			ext = 0.0
			if t >= WAIT:
				_go(1)
		1:
			if t >= WARN:
				_go(2)
		2:
			ext = clampf(t / SLAM, 0.0, 1.0)
			_check_hits()
			if t >= SLAM:
				ext = 1.0
				_go(3)
				if Game.world and Game.world.is_active(global_position + Vector2(0, 20)):
					Sfx.play("clang", -4.0, 0.6)
					Fx.dust(get_parent(), Vector2(global_position.x, floor_y), 10)
					Game.world.shake(2.5)
		3:
			_check_hits()
			if t >= HOLD:
				_go(4)
		4:
			ext = 1.0 - clampf(t / RISE, 0.0, 1.0)
			if t >= RISE:
				_go(0)
	queue_redraw()


func _go(p: int) -> void:
	phase = p
	t = 0.0
	if p == 2:
		hit_done = false


func _check_hits() -> void:
	if Game.world == null:
		return
	var r := danger_rect()
	var p = Game.world.player
	if p != null and not p.is_dead() and r.intersects(p.hitbox()):
		p.hurt(Game.MAX_HP, "crush")
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and r.intersects(g.rect()):
			g.crush()


func _draw() -> void:
	var hy := head_y() - global_position.y
	# Trilho/cilindro no teto
	draw_rect(Rect2(-W * 0.5 - 3, 0, W + 6, 12), Color("2c2622"))
	draw_rect(Rect2(-W * 0.5 - 3, 10, W + 6, 2), Color("8a6a2a"))
	# Haste
	var shake := 0.0
	if phase == 1:
		shake = sin(t * 80.0) * 1.2
	draw_rect(Rect2(-3 + shake, 12, 6, maxf(0.0, hy - 26.0)), Color("7a7470"))
	draw_rect(Rect2(-1 + shake, 12, 1.5, maxf(0.0, hy - 26.0)), Color("a8a29a"))
	# Cabeça do pistão
	var head := Rect2(-W * 0.5 + shake, hy - 14.0, W, 14.0)
	draw_rect(head, Color("4a4240"))
	draw_rect(Rect2(head.position, Vector2(W, 2)), Color("8a8480"))
	draw_rect(Rect2(head.position + Vector2(0, 12), Vector2(W, 2)), Color("2a2523"))
	for i in 3:
		draw_line(head.position + Vector2(3 + i * 6, 4), head.position + Vector2(6 + i * 6, 10), Color("e8c547", 0.7), 1.5)
	# Aviso: luz vermelha piscando
	if phase == 1 or (phase == 0 and t > WAIT - 0.5):
		if fmod(t, 0.16) < 0.08:
			draw_circle(Vector2(0, 6), 2.5, Color(1.0, 0.2, 0.1))
		# Sombra no chão
		draw_rect(Rect2(-W * 0.5, floor_y - global_position.y - 2.0, W, 2.0), Color(0, 0, 0, 0.35))
