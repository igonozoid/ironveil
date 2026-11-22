extends Node2D
## Freio do pêndulo na arena do Regulador (interagir). Funciona quando a
## lâmina chega ao ponto mais alto do lado deste freio: o pêndulo trava e a
## cabine do Diretor desce, expondo o núcleo.

const Fx := preload("res://scripts/fx.gd")

var side: int = -1
var cd := 0.0
var pulled := 0.0
var t := 0.0
var prompt := "A: puxar o freio"


func setup(pos: Vector2, s: int) -> void:
	position = pos
	side = s
	z_index = 3


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("brake")


func _boss():
	var b = Game.world.boss if Game.world else null
	if b != null and b.has_method("brake_ready") and b.is_alive():
		return b
	return null


func ready_now() -> bool:
	var b = _boss()
	return b != null and b.brake_ready(side)


func can_interact() -> bool:
	return cd <= 0.0 and _boss() != null


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 20.0 and absf(p.global_position.y - global_position.y) < 20.0


func interact(_p) -> void:
	if not can_interact():
		return
	pulled = 0.5
	Sfx.play("lever", 0.0, 0.8)
	var b = _boss()
	if b.try_brake(side):
		cd = 1.0
	else:
		cd = 0.8
		Sfx.play("clunk", -4.0)
		Fx.sparks(get_parent(), global_position + Vector2(0, -20))


func _physics_process(delta: float) -> void:
	t += delta
	cd = maxf(cd - delta, 0.0)
	pulled = maxf(pulled - delta, 0.0)
	prompt = "A: puxar o freio"
	queue_redraw()


func _draw() -> void:
	# Caixa do freio
	draw_rect(Rect2(-8, -16, 16, 16), Color("3a3330"))
	draw_rect(Rect2(-8, -16, 16, 2), Color("8a6a2a"))
	draw_rect(Rect2(-5, -12, 10, 3), Color("2a2420"))
	# Alavanca
	var ang: float = -0.6 * side if pulled <= 0.0 else 0.7 * side
	var tip := Vector2(0, -12) + Vector2(sin(ang), -cos(ang)) * 16.0
	draw_line(Vector2(0, -12), tip, Color("7a7470"), 2.5)
	draw_circle(tip, 2.6, Color("8a1e1e"))
	# Luz de pronto
	var on := ready_now()
	var col := Color(0.3, 1.0, 0.4) if on else Color(0.5, 0.2, 0.15)
	if on and fmod(t, 0.2) < 0.1:
		draw_circle(Vector2(0, -22), 5.0, Color(0.3, 1.0, 0.4, 0.3))
	draw_circle(Vector2(5, -6), 1.6, col)
