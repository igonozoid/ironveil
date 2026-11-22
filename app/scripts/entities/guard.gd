extends CharacterBody2D
## Guarda do Diretório. Patrulha; ao ver Sera alterna entre mirar/atirar e se
## abrigar (imune a rebites enquanto abrigado). 2 acertos para derrotar.
## Não atira em Sera encostada: espera um pouco e volta a patrulhar.

const BulletScript := preload("res://scripts/entities/enemy_bullet.gd")
const Fx := preload("res://scripts/fx.gd")
const SplatsScript := preload("res://scripts/splats.gd")
const Light := preload("res://scripts/fx/light.gd")

enum S { PATROL, PAUSE, AIM, SHOOT, SHELTER, WAIT, DEAD }

const SPEED := 38.0
const RANGE := 100.0
const VISION := 240.0
const GRAVITY := 980.0

const RED := Color("8a1e1e")
const RED_D := Color("5e1414")
const ARMOR := Color("3e3434")
const VISOR := Color("f0c040")
const GUN := Color("2a2626")

var state: int = S.PATROL
var facing: int = -1
var home_x := 0.0
var hp := 2
var t := 0.0
var shots_left := 0
var flash := 0.0
var alert_t := 0.0
var anim := 0.0
var dead_t := 0.0
var laser_len := 0.0
var gibbed := false
var pool_pending := false
## Guarda com escudo (Ato 2): rebites de frente batem no escudo.
var shielded := false
## Veio como reforço de um holofote.
var reinforcement := false
## Sangue grudado na farda.
var splats = SplatsScript.new()


func _ready() -> void:
	hp = Game.enemy_hp(2)
	add_to_group("enemy")
	add_to_group("guard")
	add_to_group("splat_target")
	collision_layer = 4
	collision_mask = 1 | 16
	floor_snap_length = 4.0
	z_index = 4
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 30)
	cs.shape = shape
	cs.position = Vector2(0, -15)
	add_child(cs)
	home_x = global_position.x


func _player():
	return Game.world.player if Game.world else null


func _physics_process(delta: float) -> void:
	anim += delta
	flash = maxf(flash - delta, 0.0)
	alert_t = maxf(alert_t - delta, 0.0)
	if state == S.DEAD:
		dead_t += delta
		if gibbed:
			return
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
		move_and_slide()
		if pool_pending and is_on_floor() and dead_t > 0.3:
			pool_pending = false
			var b = _blood()
			if b:
				b.pool(global_position + Vector2(-facing * 3.0, 0), randf_range(12.0, 18.0))
		queue_redraw()
		# Corpo assentado: não precisa mais de física nem de redesenho.
		if dead_t > 1.5 and not pool_pending and is_on_floor() and absf(velocity.x) < 1.0:
			set_physics_process(false)
		return
	if Game.world == null or not Game.world.is_active(global_position):
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
	var player = _player()
	match state:
		S.PATROL:
			velocity.x = facing * SPEED
			if _should_turn():
				state = S.PAUSE
				t = 0.8
				velocity.x = 0.0
			if _sees(player, false):
				_engage()
		S.PAUSE:
			velocity.x = 0.0
			t -= delta
			if t <= 0.0:
				facing = -facing
				state = S.PATROL
			if _sees(player, false):
				_engage()
		S.AIM:
			velocity.x = 0.0
			_face(player)
			t -= delta
			_update_laser()
			if player.in_cover:
				_to_wait()
			elif player.is_dead():
				state = S.PATROL
			elif t <= 0.0:
				state = S.SHOOT
				shots_left = 2
				t = 0.0
		S.SHOOT:
			velocity.x = 0.0
			t -= delta
			if player.in_cover:
				_to_wait()
			elif t <= 0.0:
				if shots_left > 0 and _civilian_in_line(player):
					# Não atira com civil na frente.
					_to_wait()
					t = 1.2
				elif shots_left > 0:
					_fire()
					shots_left -= 1
					t = 0.38
				else:
					state = S.SHELTER
					t = 1.4
		S.SHELTER:
			velocity.x = 0.0
			t -= delta
			if t <= 0.0:
				if _sees(player, true):
					state = S.AIM
					t = 0.45
				elif player.in_cover and _line_clear(player):
					_to_wait()
				else:
					state = S.PATROL
		S.WAIT:
			velocity.x = 0.0
			t -= delta
			if not player.in_cover and _sees(player, true):
				state = S.AIM
				t = 0.35
			elif t <= 0.0:
				state = S.PATROL
				facing = -facing
	move_and_slide()
	queue_redraw()


## Chamado pelo alarme de um holofote.
func alert_to(player) -> void:
	if state == S.DEAD:
		return
	_face(player)
	if state in [S.PATROL, S.PAUSE, S.WAIT]:
		_engage()


func _civilian_in_line(player) -> bool:
	var x0: float = minf(global_position.x, player.global_position.x)
	var x1: float = maxf(global_position.x, player.global_position.x)
	for c in get_tree().get_nodes_in_group("civilian"):
		var cx: float = c.global_position.x
		if cx > x0 + 4.0 and cx < x1 - 4.0 and absf(c.global_position.y - global_position.y) < 16.0:
			return true
	return false


func _engage() -> void:
	state = S.AIM
	t = 0.6
	alert_t = 0.8
	Sfx.play("alert", -6.0)


func _to_wait() -> void:
	state = S.WAIT
	t = 2.5


func _face(player) -> void:
	if player == null:
		return
	var dx: float = player.global_position.x - global_position.x
	if absf(dx) > 2.0:
		facing = int(signf(dx))


func _should_turn() -> bool:
	if is_on_wall():
		return true
	var off := global_position.x - home_x
	if absf(off) > RANGE and int(signf(off)) == facing:
		return true
	var level = Game.world.level
	var ahead: Vector2i = level.world_to_cell(global_position + Vector2(facing * 10, 4))
	var wall: Vector2i = level.world_to_cell(global_position + Vector2(facing * 10, -10))
	if level.is_solid(wall):
		return true
	return not (level.is_solid(ahead) or level.is_oneway(ahead))


func _line_clear(player) -> bool:
	var from := global_position + Vector2(0, -24)
	var to: Vector2 = player.global_position + Vector2(0, -14)
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _sees(player, engaged: bool) -> bool:
	if player == null or player.is_dead() or player.in_cover:
		return false
	if player.hidden_in_crowd():
		return false
	var dx: float = player.global_position.x - global_position.x
	var dy: float = player.global_position.y - global_position.y
	if absf(dy) > 44.0 or absf(dx) > VISION:
		return false
	if not engaged and int(signf(dx)) != facing and absf(dx) > 24.0:
		return false
	if not Game.world.is_active(player.global_position):
		return false
	return _line_clear(player)


func _update_laser() -> void:
	var from := global_position + Vector2(facing * 10, -21)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(facing * VISION, 0), 1 | 2)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	laser_len = VISION if hit.is_empty() else absf(float(hit["position"].x) - from.x)


func _fire() -> void:
	var b = BulletScript.new()
	b.setup(global_position + Vector2(facing * 11, -21), facing)
	get_parent().add_child(b)
	Fx.smoke(get_parent(), global_position + Vector2(facing * 15, -21))
	Light.make(get_parent(), global_position + Vector2(facing * 15, -21), Color(1.0, 0.6, 0.3), 55.0, 1.2, 0.0, 0.09)
	flash = 0.08
	Sfx.play("eshot", -4.0)


# ---------------------------------------------------------------- dano

func _blood():
	return Game.world.blood if Game.world else null


func on_rivet_hit(dir: int) -> void:
	if state == S.DEAD:
		return
	if state == S.SHELTER or (shielded and dir == -facing):
		Sfx.play("clang", -4.0)
		Fx.sparks(get_parent(), global_position + Vector2(facing * 8, -14))
		if shielded and state in [S.PATROL, S.PAUSE, S.WAIT]:
			_engage()
		return
	var hit_pos := global_position + Vector2(-dir * 3.0, -18.0)
	var b = _blood()
	if b:
		# Saída na direção do rebite e um pouco para trás.
		b.spray(hit_pos, Vector2(dir, -0.25), 18, 240.0, 0.45, 1.5)
		b.spray(hit_pos, Vector2(-dir, -0.4), 6, 90.0, 0.6, 1.1)
	_damage(1, "rivet", Vector2(dir, 0))
	if state != S.DEAD and state in [S.PATROL, S.PAUSE, S.WAIT]:
		facing = -dir
		_engage()


## Arpão de mão: atravessa escudo e abrigo.
func pierce_hit(dir: int) -> void:
	if state == S.DEAD:
		return
	if shielded:
		Sfx.play("crash", -6.0, 1.4)
		Fx.sparks(get_parent(), global_position + Vector2(facing * 8, -14))
	var b = _blood()
	if b:
		b.spray(global_position + Vector2(0, -18), Vector2(dir, -0.2), 26, 300.0, 0.4, 1.6)
	_damage(2, "rivet", Vector2(dir, 0))


func steam_hit(n: int) -> void:
	var b = _blood()
	if b and randf() < 0.6:
		b.spray(global_position + Vector2(0, -16), Vector2.UP, 4, 80.0, 1.2, 1.0)
	_damage(n, "steam", Vector2.ZERO)


func blast_hit(n: int, from: Vector2 = Vector2.INF) -> void:
	var dir := Vector2.UP
	if from != Vector2.INF:
		dir = (global_position + Vector2(0, -15) - from).normalized()
	_damage(n, "blast" if n >= 2 else "rivet", dir)


func crush() -> void:
	_damage(99, "crush", Vector2.ZERO)


func _damage(n: int, kind: String = "", dir: Vector2 = Vector2.ZERO) -> void:
	if state == S.DEAD:
		return
	hp -= n
	flash = 0.15
	Sfx.play("hit", -2.0)
	if hp <= 0:
		_die(kind, dir)


func _die(kind: String = "", dir: Vector2 = Vector2.ZERO) -> void:
	state = S.DEAD
	collision_layer = 0
	dead_t = 0.0
	var center := global_position + Vector2(0, -15)
	var b = _blood()
	Sfx.play("death", -8.0, 1.6)
	if Game.world:
		Game.world.hitstop(0.07)
		Game.world.shake(4.0)
	# Intenso/Insano: qualquer morte pode virar picadinho.
	var fxl := Game.fx_level()
	if kind != "blast" and kind != "crush" and (fxl >= 2 or (fxl == 1 and randf() < 0.4)) and Game.gore_enabled():
		kind = "blast"
		if dir == Vector2.ZERO:
			dir = Vector2(-facing, -0.5)
	if kind == "blast" or kind == "crush":
		# Despedaçado
		gibbed = true
		queue_redraw()
		if b:
			var spread := PI if kind == "blast" else 1.3
			b.burst(center, 70, 320.0)
			if kind == "crush":
				b.spray(global_position + Vector2(0, -3), Vector2.LEFT, 35, 300.0, 0.35, 1.8)
				b.spray(global_position + Vector2(0, -3), Vector2.RIGHT, 35, 300.0, 0.35, 1.8)
			else:
				b.spray(center, dir, 40, 360.0, spread * 0.4, 1.8)
			b.gibs(center, 12, [RED, RED_D, Color(0.55, 0.08, 0.08), Color(0.38, 0.03, 0.03), ARMOR], true, 300.0)
			b.pool(global_position, 16.0)
		Sfx.play("crash", -4.0, 0.8)
		return
	velocity = Vector2(-facing * 40.0, -80.0)
	if dir != Vector2.ZERO:
		velocity.x = dir.x * 70.0
	if b:
		b.spray(center, Vector2(dir.x if dir != Vector2.ZERO else -facing, -0.5), 30, 260.0, 0.7, 1.6)
		pool_pending = true


func splat_rect() -> Rect2:
	return rect() if state != S.DEAD else Rect2()


func receive_splat(p: Vector2, r: float, col: Color) -> void:
	splats.add(p - global_position, facing, 30.0, 6.0, r, col)
	queue_redraw()


func is_alive() -> bool:
	return state != S.DEAD


func rect() -> Rect2:
	var h := 18.0 if state == S.SHELTER else 30.0
	return Rect2(global_position.x - 6.0, global_position.y - h, 12.0, h)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var body := RED
	if flash > 0.0 and state != S.DEAD:
		body = Color(1, 0.8, 0.8)
	if state == S.DEAD:
		if gibbed:
			return
		draw_rect(Rect2(-14, -6, 22, 6), RED_D)
		draw_rect(Rect2(-12, -6, 8, 2), Color(0.45, 0.02, 0.02))
		draw_rect(Rect2(8, -7, 6, 7), ARMOR)
		draw_rect(Rect2(-17, -3, 5, 3), GUN)
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	if state == S.SHELTER:
		# Agachado atrás do escudo.
		draw_rect(Rect2(-5, -10, 9, 10), RED_D)
		draw_rect(Rect2(-6, -18, 11, 9), body)
		draw_rect(Rect2(-5, -23, 9, 6), ARMOR)
		draw_rect(Rect2(0, -21, 4, 2), VISOR)
		draw_rect(Rect2(6, -22, 4, 22), Color("6a6460"))
		draw_rect(Rect2(6, -22, 4, 2), Color("8a8480"))
		splats.draw_on(self, 18.0, 0.8)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var walking := state == S.PATROL
	var sw := sin(anim * 9.0) * 3.0 if walking else 0.0
	draw_line(Vector2(-2, -13), Vector2(-2 + sw, 0), RED_D, 3.5)
	draw_line(Vector2(2, -13), Vector2(2 - sw, 0), RED_D, 3.5)
	draw_rect(Rect2(-6, -25, 12, 13), body)
	draw_rect(Rect2(-6, -14, 12, 2), ARMOR)
	draw_rect(Rect2(-4.5, -31, 9, 7), ARMOR)
	draw_rect(Rect2(-5.5, -32, 11, 2), ARMOR)
	draw_rect(Rect2(0, -29, 4.5, 2), VISOR)
	var aiming := state in [S.AIM, S.SHOOT, S.WAIT]
	if aiming:
		draw_rect(Rect2(0, -23, 12, 3), GUN)
		draw_line(Vector2(-2, -21), Vector2(4, -21), RED_D, 2.5)
		if state == S.AIM and laser_len > 0.0:
			var a := 0.25 + 0.25 * sin(anim * 30.0)
			draw_line(Vector2(12, -21), Vector2(10 + laser_len, -21), Color(1, 0.2, 0.15, a), 1.0)
		if flash > 0.0:
			draw_circle(Vector2(14, -21.5), 3.0, Color(1, 0.8, 0.4))
	else:
		draw_line(Vector2(-3, -22), Vector2(6, -14), GUN, 3.0)
	if shielded:
		# Escudo de chapa rebitada à frente do corpo.
		draw_rect(Rect2(7, -30, 5, 28), Color("5a5250"))
		draw_rect(Rect2(7, -30, 5, 2), Color("8a8480"))
		draw_rect(Rect2(8, -18, 3, 4), Color("2a2626"))
		draw_circle(Vector2(9.5, -25), 0.9, Color("b87333"))
		draw_circle(Vector2(9.5, -8), 0.9, Color("b87333"))
	splats.draw_on(self, 30.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if alert_t > 0.0:
		draw_rect(Rect2(-1, -44, 2.5, 6), VISOR)
		draw_rect(Rect2(-1, -36.5, 2.5, 2), VISOR)
	elif state == S.WAIT:
		draw_string(ThemeDB.fallback_font, Vector2(-3, -36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.85, 0.6, 0.8))
