extends AnimatableBody2D
## Plataforma móvel de 3 células de largura. A origem do nó é o topo-centro da
## plataforma. Modos:
##  "lift"  — elevador de carga, acionado por alavanca (vai e volta)
##  "crane" — gancho do guindaste de Tomé: travado até falar com ele; depois
##            sobe/desce sozinho quando Sera fica parada em cima
##  "exit"  — elevador de saída da fase (interagir em cima para subir); pode
##            ficar travado (ex.: até o chefão cair)
##  "arena" — elevador que leva à arena do chefão (interagir em cima; ao chegar
##            grava um checkpoint)

const W := 60.0
const H := 10.0

var pos_a := Vector2.ZERO
var pos_b := Vector2.ZERO
var mode := "lift"
var moving := false
var at_b := false
var target := Vector2.ZERO
var speed := 70.0
var locked := false
var ride_t := 0.0
var cable_top := 0.0
var prompt := "A: subir"
var warned := false
var need_leave := false
var level = null


func setup(a: Vector2, b: Vector2, m: String, lvl) -> void:
	pos_a = a
	pos_b = b
	position = a
	mode = m
	level = lvl
	locked = (m == "crane")
	speed = 90.0 if m == "crane" else (45.0 if m == "exit" else 70.0)
	if m == "arena":
		speed = 80.0
	# Topo do cabo: primeira célula sólida acima do ponto mais alto.
	var top := a if a.y < b.y else b
	var c: Vector2i = lvl.world_to_cell(top + Vector2(0, -2))
	var n := 0
	while n < 40 and not lvl.is_solid(c):
		c.y -= 1
		n += 1
	cable_top = float((c.y + 1) * 20)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	z_index = 3
	add_to_group("lift")
	if mode == "exit" or mode == "arena":
		add_to_group("interactable")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(W, H)
	cs.shape = shape
	cs.position = Vector2(0, H * 0.5)
	add_child(cs)


func toggle() -> void:
	if moving or locked:
		return
	target = pos_a if at_b else pos_b
	moving = true
	Sfx.play("lift", -4.0)


func player_on() -> bool:
	var p = Game.world.player if Game.world else null
	if p == null or p.is_dead():
		return false
	return p.is_on_floor() and absf(p.global_position.x - global_position.x) < W * 0.5 + 2.0 \
			and absf(p.global_position.y - global_position.y) < 3.0


# Interação (modos "exit" e "arena")
func can_interact() -> bool:
	return (mode == "exit" or mode == "arena") and not moving and not at_b and not locked


func is_in_reach(_p) -> bool:
	return player_on()


func interact(_p) -> void:
	if not can_interact():
		return
	toggle()
	if mode == "exit":
		Game.world.begin_exit()
	else:
		Game.world.cutscene = true
		Game.world.hud.message("Subindo...")


func _physics_process(delta: float) -> void:
	if moving:
		position = position.move_toward(target, speed * delta)
		if position.distance_to(target) < 0.01:
			position = target
			moving = false
			at_b = target == pos_b
			need_leave = true
			Sfx.play("clunk", -2.0)
			if mode == "exit" and at_b:
				Game.world.complete_phase()
			elif mode == "arena" and at_b:
				Game.world.cutscene = false
				Game.world.on_arena_reached()
	elif mode == "exit" and locked and player_on():
		if not warned:
			warned = true
			Game.world.hud.message("O elevador está travado pelo Martelo-de-Vapor.")
	elif mode == "crane":
		if player_on():
			if locked:
				if not warned:
					warned = true
					Game.world.hud.message("O gancho está travado. Fale com o operador.")
			elif not need_leave:
				ride_t += delta
				if ride_t > 0.7:
					ride_t = 0.0
					toggle()
		else:
			ride_t = 0.0
			need_leave = false
	queue_redraw()


func _draw() -> void:
	var top_local := cable_top - global_position.y
	if mode == "crane":
		draw_line(Vector2(0, top_local), Vector2(0, -14), Color("8a8f96"), 1.5)
		draw_line(Vector2(0, -14), Vector2(-24, 0), Color("8a8f96"), 1.0)
		draw_line(Vector2(0, -14), Vector2(24, 0), Color("8a8f96"), 1.0)
		draw_arc(Vector2(0, -17), 3.5, 0, PI * 1.5, 10, Color("d9965a"), 2.0)
	else:
		draw_line(Vector2(-26, top_local), Vector2(-26, 0), Color("6a6460"), 1.5)
		draw_line(Vector2(26, top_local), Vector2(26, 0), Color("6a6460"), 1.5)
	draw_rect(Rect2(-W * 0.5, 0, W, H), Color("5a3a24"))
	draw_rect(Rect2(-W * 0.5, 0, W, 3), Color("c07a3a"))
	for i in 6:
		var x := -W * 0.5 + 4 + i * 10
		draw_line(Vector2(x, 4), Vector2(x + 5, 9), Color("e8c547"), 2.0)
	var light := Color(0.4, 1.0, 0.5) if not locked else Color(1.0, 0.3, 0.2)
	if mode == "exit" and not locked or mode == "arena" and not at_b:
		light = Color(0.4, 1.0, 0.5) if int(Time.get_ticks_msec() / 400) % 2 == 0 else Color(0.2, 0.5, 0.25)
	draw_circle(Vector2(-W * 0.5 + 3, -2), 1.8, light)
	draw_circle(Vector2(W * 0.5 - 3, -2), 1.8, light)
