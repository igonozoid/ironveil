extends CharacterBody2D
## Autômato de corda da Torre (Ato 3): carcaça de latão com um operador
## espremido dentro. Patrulha devagar; ao ver Sera, sopra vapor e investe.
## A couraça da frente para rebites — o ponto fraco é a chave de corda nas
## costas. Role por ele durante a investida, vire e atire. Vapor e explosões
## também funcionam. Bate de frente na parede e fica tonto.

const Fx := preload("res://scripts/fx.gd")
const SplatsScript := preload("res://scripts/splats.gd")

enum S { PATROL, PAUSE, WINDUP, CHARGE, RECOVER, STUN, DEAD }

const WALK := 26.0
const CHARGE_SPEED := 175.0
const VISION := 210.0
const GRAVITY := 980.0
const RANGE := 90.0

const BRASS := Color("a07a38")
const BRASS_D := Color("6e5428")
const BRASS_L := Color("e0b860")
const IRON := Color("3a3330")
const EYE := Color("ff5a2a")

var state: int = S.PATROL
var facing: int = -1
var home_x := 0.0
var hp := 2
var t := 0.0
var anim := 0.0
var flash := 0.0
var hit_done := false
var key_rot := 0.0
var splats = SplatsScript.new()


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("guard")
	add_to_group("automaton")
	add_to_group("splat_target")
	collision_layer = 4
	collision_mask = 1 | 16
	floor_snap_length = 4.0
	z_index = 4
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 32)
	cs.shape = shape
	cs.position = Vector2(0, -16)
	add_child(cs)
	home_x = global_position.x


func _player():
	return Game.world.player if Game.world else null


func is_alive() -> bool:
	return state != S.DEAD


func rect() -> Rect2:
	return Rect2(global_position.x - 8.0, global_position.y - 32.0, 16.0, 32.0)


func splat_rect() -> Rect2:
	return rect() if is_alive() else Rect2()


func receive_splat(p: Vector2, r: float, col: Color) -> void:
	splats.add(p - global_position, facing, 32.0, 7.0, r, col)


func _physics_process(delta: float) -> void:
	anim += delta
	flash = maxf(flash - delta, 0.0)
	key_rot += delta * (2.0 if state == S.PATROL else 6.0 if state == S.CHARGE else 0.6)
	if state == S.DEAD:
		return
	if Game.world == null or not Game.world.is_active(global_position):
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
	var p = _player()
	t -= delta
	match state:
		S.PATROL:
			velocity.x = facing * WALK
			if _should_turn():
				state = S.PAUSE
				t = 1.0
			elif _sees(p):
				_windup(p)
		S.PAUSE:
			velocity.x = 0.0
			if _sees(p):
				_windup(p)
			elif t <= 0.0:
				facing = -facing
				state = S.PATROL
		S.WINDUP:
			velocity.x = -facing * 8.0
			if fmod(anim, 0.12) < delta:
				Fx.steam_puff(get_parent(), global_position + Vector2(-facing * 8, -26), 2)
			if t <= 0.0:
				state = S.CHARGE
				t = 1.5
				hit_done = false
				Sfx.play("steam", -6.0, 1.4)
		S.CHARGE:
			velocity.x = facing * CHARGE_SPEED
			if fmod(anim, 0.08) < delta:
				Fx.dust(get_parent(), global_position + Vector2(-facing * 6, 0), 2)
			if p != null and not hit_done and _touching(p):
				hit_done = true
				if not p.is_rolling():
					p.hurt(1, "melee")
					p.velocity = Vector2(facing * 160.0, -140.0)
					Sfx.play("clang", -2.0, 0.8)
			if is_on_wall() or _wall_ahead():
				_stun(1.6)
				Sfx.play("crash", -6.0, 1.2)
				Fx.sparks(get_parent(), global_position + Vector2(facing * 9, -18))
				if Game.world:
					Game.world.shake(3.0)
			elif _ledge_ahead() or t <= 0.0:
				state = S.RECOVER
				t = 1.1
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if fmod(anim, 0.2) < delta:
				Fx.steam_puff(get_parent(), global_position + Vector2(-facing * 7, -20), 2)
			if t <= 0.0:
				_face(p)
				state = S.PAUSE
				t = 0.3
		S.STUN:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if t <= 0.0:
				_face(p)
				state = S.PAUSE
				t = 0.3
	move_and_slide()
	queue_redraw()


func _windup(p) -> void:
	_face(p)
	state = S.WINDUP
	t = 0.55
	Sfx.play("alert", -6.0, 0.7)


func _stun(time: float) -> void:
	state = S.STUN
	t = time
	velocity.x = -facing * 40.0


func _face(p) -> void:
	if p == null:
		return
	var dx: float = p.global_position.x - global_position.x
	if absf(dx) > 2.0:
		facing = int(signf(dx))


func _touching(p) -> bool:
	return rect().grow(2.0).intersects(p.hitbox())


func _sees(p) -> bool:
	if p == null or p.is_dead() or p.in_cover:
		return false
	var dx: float = p.global_position.x - global_position.x
	var dy: float = p.global_position.y - global_position.y
	if absf(dy) > 30.0 or absf(dx) > VISION or (int(signf(dx)) != facing and absf(dx) > 20.0):
		return false
	var from := global_position + Vector2(0, -22)
	var q := PhysicsRayQueryParameters2D.create(from, p.center(), 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _wall_ahead() -> bool:
	var lvl = Game.world.level
	return lvl.is_solid(lvl.world_to_cell(global_position + Vector2(facing * 11, -12)))


func _ledge_ahead() -> bool:
	var lvl = Game.world.level
	var c: Vector2i = lvl.world_to_cell(global_position + Vector2(facing * 12, 4))
	return not (lvl.is_solid(c) or lvl.is_oneway(c))


func _should_turn() -> bool:
	if is_on_wall() or _wall_ahead() or _ledge_ahead():
		return true
	var off := global_position.x - home_x
	return absf(off) > RANGE and int(signf(off)) == facing


## Chamado por alarmes.
func alert_to(p) -> void:
	if state in [S.PATROL, S.PAUSE]:
		_windup(p)


# ---------------------------------------------------------------- dano

func on_rivet_hit(dir: int) -> void:
	if state == S.DEAD:
		return
	if dir != facing:
		# Bateu na couraça da frente.
		Sfx.play("clang", -4.0, 1.1)
		Fx.sparks(get_parent(), global_position + Vector2(facing * 9, -18))
		if state in [S.PATROL, S.PAUSE]:
			_windup(_player())
		return
	# Acertou a chave de corda nas costas.
	Fx.sparks(get_parent(), global_position + Vector2(-facing * 9, -20))
	var b = _blood()
	if b:
		b.spray(global_position + Vector2(-facing * 6, -18), Vector2(dir, -0.3), 12, 200.0, 0.5, 1.3)
	_damage(1, "rivet", Vector2(dir, 0))
	if state != S.DEAD and state != S.STUN:
		_stun(0.9)


## Arpão de mão: fura a couraça.
func pierce_hit(dir: int) -> void:
	if state == S.DEAD:
		return
	Fx.sparks(get_parent(), global_position + Vector2(-dir * 6, -18))
	_damage(2, "rivet", Vector2(dir, 0))


func steam_hit(n: int) -> void:
	_damage(n, "steam", Vector2.ZERO)
	if state != S.DEAD:
		_stun(1.2)


func blast_hit(n: int, from: Vector2 = Vector2.INF) -> void:
	var dir := Vector2.UP
	if from != Vector2.INF:
		dir = (global_position + Vector2(0, -16) - from).normalized()
	_damage(maxi(n, 2), "blast", dir)


func crush() -> void:
	_damage(99, "crush", Vector2.ZERO)


func _blood():
	return Game.world.blood if Game.world else null


func _damage(n: int, kind: String, dir: Vector2) -> void:
	if state == S.DEAD:
		return
	hp -= n
	flash = 0.15
	Sfx.play("hit", -2.0, 0.8)
	if hp <= 0:
		_die(kind, dir)


func _die(kind: String, dir: Vector2) -> void:
	state = S.DEAD
	collision_layer = 0
	var c := global_position + Vector2(0, -16)
	Sfx.play("crash", -2.0, 0.9)
	Sfx.play("steam", -4.0, 0.8)
	Fx.steam_puff(get_parent(), c, 16)
	Fx.sparks(get_parent(), c)
	if Game.world:
		Game.world.hitstop(0.08)
		Game.world.shake(5.0)
	var b = _blood()
	if b:
		# A carcaça se abre: peças de latão e o operador lá dentro.
		var d := dir if dir != Vector2.ZERO else Vector2(-facing, -0.5)
		b.gibs(c, 12, [BRASS, BRASS_D, IRON, BRASS_L], false, 300.0)
		b.burst(c, 55 if kind != "rivet" else 35, 300.0)
		b.spray(c, d, 30, 320.0, 0.5, 1.7)
		b.gibs(c, 8, [Color("8a2a24"), Color("5e1414"), Color(0.55, 0.08, 0.08)], true, 260.0)
		b.pool(global_position, 18.0)
	queue_redraw()
	visible = false


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if state == S.DEAD:
		return
	var body := BRASS if flash <= 0.0 else Color(1, 0.9, 0.8)
	var shake := Vector2.ZERO
	if state == S.STUN:
		shake = Vector2(sin(anim * 50.0), 0) * 0.8
	draw_set_transform(shake, 0.0, Vector2(facing, 1))
	var walking := state == S.PATROL or state == S.CHARGE
	var sw := sin(anim * (16.0 if state == S.CHARGE else 6.0)) * 3.0 if walking else 0.0
	# Pernas de pistão
	draw_line(Vector2(-3, -12), Vector2(-3 + sw, 0), IRON, 4.0)
	draw_line(Vector2(3, -12), Vector2(3 - sw, 0), IRON, 4.0)
	draw_rect(Rect2(-6 + sw, -2, 6, 2), BRASS_D)
	draw_rect(Rect2(0 - sw, -2, 6, 2), BRASS_D)
	# Tronco em barril
	draw_rect(Rect2(-7, -28, 14, 17), body)
	draw_rect(Rect2(-7, -28, 14, 2), BRASS_L)
	draw_rect(Rect2(-7, -14, 14, 2), BRASS_D)
	for i in 3:
		draw_circle(Vector2(-4 + i * 4, -26), 0.8, BRASS_D)
	# Couraça da frente
	draw_rect(Rect2(5, -27, 4, 18), Color("8a6a2a"))
	draw_rect(Rect2(5, -27, 4, 1.5), BRASS_L)
	# Cabeça: elmo com olho-lente
	draw_rect(Rect2(-5, -34, 10, 7), IRON)
	draw_rect(Rect2(-5, -34, 10, 1.5), Color("5a5250"))
	var eye := EYE if state in [S.WINDUP, S.CHARGE] else Color(1.0, 0.75, 0.35)
	draw_circle(Vector2(3, -30.5), 1.6, eye)
	if state == S.WINDUP and fmod(anim, 0.1) < 0.05:
		draw_circle(Vector2(3, -30.5), 3.5, Color(eye, 0.35))
	# Braços: aríete à frente na investida
	if state == S.CHARGE or state == S.WINDUP:
		draw_line(Vector2(2, -22), Vector2(11, -20), IRON, 3.0)
		draw_rect(Rect2(10, -23, 4, 6), BRASS_D)
	else:
		draw_line(Vector2(2, -22), Vector2(5, -12), IRON, 3.0)
	# Chave de corda nas costas (ponto fraco): brilha quando parado
	var exposed := state in [S.RECOVER, S.STUN, S.PATROL, S.PAUSE]
	var kc := Vector2(-9, -22)
	draw_line(Vector2(-7, -22), kc, IRON, 2.0)
	var kx := cos(key_rot) * 3.0
	draw_line(kc + Vector2(-0.5, -kx), kc + Vector2(-0.5, kx), BRASS_L, 2.5)
	if exposed and fmod(anim, 0.6) < 0.3:
		draw_circle(kc, 2.2, Color(1.0, 0.85, 0.4, 0.35))
	splats.draw_on(self, 32.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
