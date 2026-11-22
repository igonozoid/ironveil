extends CharacterBody2D
## Chefão do Ato 1: o Martelo-de-Vapor, andador blindado pilotado pelo
## Capataz Ordo. Origem do nó nos pés (centro).
##
## Ataques: rajada alta (agache ou encoste), rajada baixa (pule ou encoste),
## martelada com ondas de choque (pule — a reentrância não protege) e, na
## segunda metade, drones. Não atira em Sera encostada: martela em vez disso.
##
## Dano: rebite no tanque das costas (sempre), rebite no núcleo da frente
## (só aberto depois da martelada ou atordoado), jato de vapor (2 + atordoa),
## carga de vapor (2) e explosão de drone por perto (1).

const BulletScript := preload("res://scripts/entities/enemy_bullet.gd")
const ShockScript := preload("res://scripts/entities/shockwave.gd")
const DroneScript := preload("res://scripts/entities/drone.gd")
const PickupScript := preload("res://scripts/entities/pickup.gd")
const Fx := preload("res://scripts/fx.gd")

enum S { IDLE, INTRO, WALK, AIM, FIRE, RAISE, RECOVER, LAUNCH, STUN, DYING, DEAD }

const BASE_HP := 20
## Vida máxima nesta dificuldade (definida em _ready).
var MAX_HP := 20
var PHASE2_HP := 10
const GRAVITY := 980.0
const HIGH_Y := -21.0
const LOW_Y := -7.0
const SHOULDER := Vector2(2, -56)
const ARM_LEN := 60.0
const ARM_REST := 1.36      # rad (quase vertical, martelo arrastando)
const ARM_UP := -1.95
const ARM_SLAM := 1.01

const RED := Color("8a1e1e")
const RED_D := Color("5e1414")
const ARMOR := Color("3e3434")
const ARMOR_L := Color("5a4e4c")
const COPPER := Color("b87333")
const COPPER_D := Color("6e4a2c")
const VISOR := Color("f0c040")

const INTRO_LINES := [
	["Capataz Ordo", "Engenheira Vael. O Diretório quer você viva... mas ninguém disse inteira."],
	["Sera", "Esse andador é da Caldeira Sul. Fui eu que calibrei as válvulas dele."],
	["Capataz Ordo", "Então sabe quanto ele aguenta. E eu sei quanto você aguenta."],
]
const RETRY_LINES := [
	["Capataz Ordo", "De volta? O martelo também voltou."],
]

var title := "MARTELO-DE-VAPOR · Capataz Ordo"
var state: int = S.IDLE
var hp := MAX_HP
var facing: int = -1
var t := 0.0
var anim := 0.0
var leg_phase := 0.0
var arm := ARM_REST
var gun_y := HIGH_Y
var shot_low := false
var shots_left := 0
var slams_left := 0
var core_open := 0.0
var steam_cd := 0.0
var blast_cd := 0.0
var contact_cd := 0.0
var flash := 0.0
var muzzle := 0.0
var laser_len := 0.0
var seq_i := 0
var phase2 := false
var bar_visible := false
var bar_hp := float(MAX_HP)
var smoke_t := 0.0
var boom_t := 0.0
var dead_t := 0.0
var supplies_dropped := 0
var exit_lift = null
var arena := Rect2()


func _ready() -> void:
	MAX_HP = Game.boss_hp(BASE_HP)
	hp = MAX_HP
	bar_hp = float(MAX_HP)
	PHASE2_HP = MAX_HP / 2
	add_to_group("enemy")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 4.0
	z_index = 4
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 64)
	cs.shape = shape
	cs.position = Vector2(0, -32)
	add_child(cs)


func setup(pos: Vector2, screen_rect: Rect2) -> void:
	position = pos
	arena = screen_rect


func _player():
	return Game.world.player if Game.world else null


func is_alive() -> bool:
	return state != S.DEAD and state != S.DYING


func rect() -> Rect2:
	return Rect2(global_position.x - 22.0, global_position.y - 66.0, 44.0, 66.0)


func center() -> Vector2:
	return global_position + Vector2(0, -40)


func hp_ratio() -> float:
	return bar_hp / float(MAX_HP)


func hp_real() -> float:
	return float(hp) / float(MAX_HP)


# ---------------------------------------------------------------- lógica

func _physics_process(delta: float) -> void:
	anim += delta
	flash = maxf(flash - delta, 0.0)
	muzzle = maxf(muzzle - delta, 0.0)
	steam_cd = maxf(steam_cd - delta, 0.0)
	blast_cd = maxf(blast_cd - delta, 0.0)
	contact_cd = maxf(contact_cd - delta, 0.0)
	core_open = maxf(core_open - delta, 0.0)
	bar_hp = move_toward(bar_hp, float(hp), delta * 12.0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
	if state == S.DEAD:
		dead_t += delta
		_wreck_smoke(delta)
		velocity.x = 0.0
		move_and_slide()
		queue_redraw()
		return
	if state == S.DYING:
		_process_dying(delta)
		move_and_slide()
		queue_redraw()
		return
	var w = Game.world
	if w == null or not w.is_active(global_position):
		return
	var p = _player()
	_chimney(delta)
	match state:
		S.IDLE:
			velocity.x = 0.0
			if p != null and not p.is_dead() and w.is_active(p.global_position) and p.is_on_floor() \
					and not w.cutscene:
				_start_intro()
		S.INTRO:
			velocity.x = 0.0
		S.WALK:
			_face(p)
			var dist := absf(p.global_position.x - global_position.x)
			var want := 90.0 if phase2 else 115.0
			var spd := 58.0 if phase2 else 40.0
			if dist > want:
				velocity.x = facing * spd
			elif dist < want - 40.0:
				velocity.x = -facing * spd * 0.6
			else:
				velocity.x = 0.0
			_clamp_x()
			leg_phase += absf(velocity.x) * delta * 0.11
			arm = lerp_angle(arm, ARM_REST, delta * 6.0)
			gun_y = lerpf(gun_y, HIGH_Y, delta * 6.0)
			_contact(p)
			t -= delta
			if t <= 0.0 and is_on_floor():
				_next_attack(p)
		S.AIM:
			velocity.x = 0.0
			_face(p)
			gun_y = lerpf(gun_y, LOW_Y if shot_low else HIGH_Y, delta * 10.0)
			_update_laser()
			t -= delta
			if p.in_cover:
				# Não atira em quem está encostada: martela.
				w.hud.message("Ordo: Sair daí ou virar sucata, Vael!")
				_start_raise()
			elif t <= 0.0:
				state = S.FIRE
				shots_left = (3 if shot_low else 5) + (2 if phase2 else 0)
				t = 0.0
		S.FIRE:
			velocity.x = 0.0
			t -= delta
			if p.in_cover:
				_start_raise()
			elif t <= 0.0:
				if shots_left > 0:
					_fire()
					shots_left -= 1
					t = 0.13 if shot_low else 0.16
				else:
					_to_walk(0.9)
		S.RAISE:
			velocity.x = 0.0
			arm = lerp_angle(arm, ARM_UP, delta * 7.0)
			t -= delta
			if t <= 0.0:
				_slam()
		S.RECOVER:
			velocity.x = 0.0
			arm = lerp_angle(arm, ARM_SLAM, delta * 20.0)
			t -= delta
			if t <= 0.0:
				if slams_left > 0:
					slams_left -= 1
					_start_raise(0.4)
				else:
					_to_walk(0.7)
		S.LAUNCH:
			velocity.x = 0.0
			t -= delta
			if t <= 0.0:
				_launch_drones()
				_to_walk(1.2)
		S.STUN:
			velocity.x = 0.0
			arm = lerp_angle(arm, ARM_SLAM + 0.2, delta * 4.0)
			t -= delta
			if fmod(anim, 0.25) < delta:
				Fx.steam_puff(get_parent(), global_position + Vector2(randf_range(-18, 18), -60), 4)
				Fx.sparks(get_parent(), global_position + Vector2(randf_range(-18, 18), randf_range(-60, -30)))
			if t <= 0.0:
				_to_walk(0.5)
	move_and_slide()
	queue_redraw()


func _face(p) -> void:
	if p == null:
		return
	var dx: float = p.global_position.x - global_position.x
	if absf(dx) > 6.0:
		facing = 1 if dx > 0.0 else -1


func _clamp_x() -> void:
	var lo := arena.position.x + 70.0
	var hi := arena.end.x - 70.0
	if (global_position.x < lo and velocity.x < 0.0) or (global_position.x > hi and velocity.x > 0.0):
		velocity.x = 0.0


func _contact(p) -> void:
	if p == null or p.is_dead() or contact_cd > 0.0 or absf(velocity.x) < 1.0:
		return
	var r := Rect2(global_position.x - 18.0, global_position.y - 40.0, 36.0, 40.0)
	if r.intersects(p.hitbox()):
		contact_cd = 1.0
		p.hurt(1, "crush")


func _start_intro() -> void:
	state = S.INTRO
	var seen := bool(Game.cp().get("boss_seen", false))
	Sfx.play("alert", -2.0)
	Game.world.shake(3.0)
	Game.world.dialog.start(RETRY_LINES if seen else INTRO_LINES, _on_intro_done)


func _on_intro_done() -> void:
	Game.cp()["boss_seen"] = true
	if not Game.replay:
		Game.write_save()
	bar_visible = true
	Game.world.hud.message("Ordo: Ninguém atravessa o Martelo!")
	Sfx.play("lift", 0.0, 0.6)
	_to_walk(1.2)


func _to_walk(time: float) -> void:
	state = S.WALK
	t = time * (0.7 if phase2 else 1.0)


func _next_attack(p) -> void:
	var seq := ["high", "slam", "low", "slam"]
	if phase2:
		seq = ["high", "drones", "slam", "low", "high", "slam"]
	var a: String = seq[seq_i % seq.size()]
	seq_i += 1
	if a == "drones" and get_tree().get_nodes_in_group("boss_drone").size() >= 2:
		a = "low"
	if (a == "high" or a == "low") and p.in_cover:
		a = "slam"
	match a:
		"high", "low":
			shot_low = a == "low"
			state = S.AIM
			t = 0.6 if phase2 else 0.85
			Sfx.play("alert", -8.0, 0.7 if shot_low else 1.0)
		"slam":
			slams_left = 1 if phase2 else 0
			_start_raise()
		"drones":
			state = S.LAUNCH
			t = 0.7
			Sfx.play("steam", -4.0, 0.7)


func _start_raise(time: float = -1.0) -> void:
	state = S.RAISE
	t = time if time > 0.0 else (0.55 if phase2 else 0.75)
	Sfx.play("lift", -6.0, 1.4)


func _update_laser() -> void:
	var from := global_position + Vector2(facing * 36, gun_y)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(facing * 400, 0), 1 | 2)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	laser_len = 400.0 if hit.is_empty() else absf(float(hit["position"].x) - from.x)


func _fire() -> void:
	var b = BulletScript.new()
	var y := LOW_Y if shot_low else HIGH_Y
	b.setup(global_position + Vector2(facing * 38, y), facing)
	get_parent().add_child(b)
	Fx.smoke(get_parent(), global_position + Vector2(facing * 42, y), 2)
	muzzle = 0.07
	Sfx.play("eshot", -3.0, 0.8)


func _slam() -> void:
	state = S.RECOVER
	t = 1.0 if phase2 else 1.4
	core_open = t + 0.1
	arm = ARM_SLAM
	var hit := global_position + Vector2(facing * 34, 0)
	var par := get_parent()
	Sfx.play("crash", 0.0, 0.7)
	Sfx.play("explosion", -8.0, 1.4)
	Game.world.shake(7.0)
	Fx.dust(par, hit, 16)
	Fx.debris(par, hit + Vector2(0, -4))
	Fx.sparks(par, hit)
	var spd := 240.0 if phase2 else 200.0
	for d in [-1, 1]:
		var s = ShockScript.new()
		s.setup(hit + Vector2(d * 10, 0), d, spd)
		par.add_child(s)
	var p = _player()
	if p != null and not p.is_dead():
		var r := Rect2(hit.x - 16.0, hit.y - 26.0, 32.0, 26.0)
		if r.intersects(p.hitbox()):
			p.hurt(2, "crush")


func _launch_drones() -> void:
	Sfx.play("grapple", -2.0, 0.6)
	var back := global_position + Vector2(-facing * 26, -58)
	Fx.steam_puff(get_parent(), back, 12)
	for i in 2:
		var d = DroneScript.new()
		# Um varre o chão na altura do peito; o outro gira por cima.
		var cx := arena.position.x + arena.size.x * (0.3 if i == 0 else 0.7)
		if i == 0:
			d.setup(Vector2(cx, arena.position.y + 282.0), "h")
		else:
			d.setup(Vector2(cx, arena.position.y + 248.0), "o")
		d.add_to_group("boss_drone")
		get_parent().add_child(d)
		Fx.sparks(get_parent(), d.position)


func _chimney(delta: float) -> void:
	smoke_t -= delta
	if smoke_t <= 0.0:
		smoke_t = 0.25 if phase2 else 0.45
		Fx.smoke(get_parent(), global_position + Vector2(-facing * 24, -76), 2)


# ---------------------------------------------------------------- dano

func _blood():
	return Game.world.blood if Game.world else null


func _vulnerable() -> bool:
	return state in [S.WALK, S.AIM, S.FIRE, S.RAISE, S.RECOVER, S.LAUNCH, S.STUN]


func on_rivet_hit(dir: int) -> void:
	if not _vulnerable():
		Sfx.play("clang", -4.0)
		return
	var back := dir == facing
	if back:
		# Tanque das costas: vaza vapor.
		Fx.steam_puff(get_parent(), global_position + Vector2(-facing * 26, -48), 6)
		_damage(1)
	elif core_open > 0.0:
		Fx.burst(get_parent(), global_position + Vector2(facing * 16, -40), Color(1.0, 0.6, 0.2), 10, 120.0, 0.3)
		_damage(1)
	else:
		Sfx.play("clang", -2.0)
		Fx.sparks(get_parent(), global_position + Vector2(facing * 22, -40))


func steam_hit(_n: int) -> void:
	if steam_cd > 0.0 or not _vulnerable():
		return
	steam_cd = 3.0
	Game.world.hud.message("O Martelo engasgou com o vapor!")
	_damage(2)
	if is_alive():
		state = S.STUN
		t = 2.2
		core_open = 2.3
		Sfx.play("steam", -2.0, 0.6)


func blast_hit(n: int, _from: Vector2 = Vector2.INF) -> void:
	if blast_cd > 0.0 or not _vulnerable():
		return
	blast_cd = 0.4
	_damage(mini(n, 2))
	if is_alive() and n >= 2 and state in [S.WALK, S.AIM, S.FIRE]:
		state = S.STUN
		t = 1.2
		core_open = 1.3


func crush() -> void:
	_damage(3)


func _damage(n: int) -> void:
	if not is_alive():
		return
	hp = maxi(0, hp - n)
	flash = 0.15
	Sfx.play("hit", -2.0, 0.7)
	Sfx.play("clang", -6.0, 0.8)
	Fx.sparks(get_parent(), center() + Vector2(randf_range(-12, 12), randf_range(-12, 12)))
	# Óleo escuro escorrendo da blindagem
	Fx.burst(get_parent(), center(), Color(0.12, 0.09, 0.08), 6, 90.0, 0.5, Vector2(0, 400), 2.0)
	if Game.world:
		Game.world.shake(2.0)
	if hp <= 0:
		_die()
		return
	if not phase2 and hp <= PHASE2_HP:
		phase2 = true
		Game.world.hud.message("Ordo: PRESSÃO MÁXIMA!")
		Game.world.shake(6.0)
		Sfx.play("steam", 0.0, 0.5)
		Fx.steam_puff(get_parent(), center(), 20)
	if supplies_dropped == 0 and hp <= 14 or supplies_dropped == 1 and hp <= 6:
		supplies_dropped += 1
		_drop_supply()


## Um cano do teto estoura e derruba cargas de vapor.
func _drop_supply() -> void:
	var p = _player()
	var x := arena.position.x + arena.size.x * 0.5
	if p != null:
		# Do lado oposto ao chefão, para Sera conseguir pegar.
		x = arena.position.x + (arena.size.x * 0.28 if global_position.x > arena.get_center().x else arena.size.x * 0.72)
	var pos := Vector2(x, arena.position.y + 290.0)
	var pk = PickupScript.new()
	pk.setup(pos, "charge", 2)
	get_parent().add_child(pk)
	Fx.debris(get_parent(), Vector2(x, arena.position.y + 50.0))
	Fx.steam_puff(get_parent(), Vector2(x, arena.position.y + 50.0), 10)
	Sfx.play("clunk", -2.0)
	Game.world.hud.message("Algo caiu de um cano estourado...")


func _die() -> void:
	state = S.DYING
	t = 2.4
	boom_t = 0.0
	collision_layer = 0
	bar_visible = true
	for d in get_tree().get_nodes_in_group("boss_drone"):
		d.call_deferred("explode")
	Game.world.hud.message("Ordo: Não... a pressão... !")
	Game.world.hitstop(0.12)


func _process_dying(delta: float) -> void:
	velocity.x = 0.0
	t -= delta
	boom_t -= delta
	flash = 0.05 if fmod(anim, 0.12) < 0.06 else 0.0
	if boom_t <= 0.0:
		boom_t = 0.22
		var pos := global_position + Vector2(randf_range(-22, 22), randf_range(-66, -10))
		Fx.fire(get_parent(), pos, 14)
		Fx.sparks(get_parent(), pos)
		Fx.smoke(get_parent(), pos, 6)
		Sfx.play("explosion", -8.0, randf_range(0.9, 1.3))
		Game.world.shake(4.0)
	if t <= 0.0:
		_final_blast()


func _final_blast() -> void:
	state = S.DEAD
	dead_t = 0.0
	var c := center()
	var par := get_parent()
	# Só o visual da explosão (sem dano: a luta acabou).
	Fx.burst(par, c, Color(1.0, 0.7, 0.3), 40, 260.0, 0.6, Vector2(0, 250), 2.5)
	Fx.fire(par, c, 40)
	Fx.smoke(par, c, 24)
	Fx.steam_puff(par, c, 20)
	Fx.debris(par, c)
	Game.world.shake(10.0)
	Game.world.hitstop(0.15)
	Sfx.play("crash", 0.0, 0.6)
	var b = _blood()
	if b:
		# Blindagem e peças
		b.gibs(c, 14, [ARMOR, ARMOR_L, RED, COPPER, COPPER_D], false, 320.0)
		# O piloto não sobreviveu à cabine.
		var cab := global_position + Vector2(facing * 10, -54)
		b.burst(cab, 90, 340.0)
		b.spray(cab, Vector2(facing, -0.6), 50, 380.0, 0.7, 2.0)
		b.spray(cab, Vector2(-facing, -0.6), 30, 300.0, 0.7, 1.6)
		b.gibs(cab, 10, [RED, RED_D, Color(0.55, 0.08, 0.08), Color(0.38, 0.03, 0.03), VISOR], true, 300.0)
		b.pool(global_position + Vector2(facing * 8, 0), 26.0)
	if exit_lift != null:
		exit_lift.locked = false
	Game.world.on_boss_defeated(Vector2(global_position.x, global_position.y - 22.0))
	await get_tree().create_timer(1.2).timeout
	if Game.world:
		bar_visible = false
		Game.world.hud.message("O elevador para o Mercado está livre.")
		Sfx.play("door", -2.0)


func _wreck_smoke(delta: float) -> void:
	smoke_t -= delta
	if smoke_t <= 0.0:
		smoke_t = 0.35
		Fx.smoke(get_parent(), global_position + Vector2(randf_range(-20, 20), -18), 2)
		if randf() < 0.3:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-20, 20), -12))


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if state == S.DEAD:
		_draw_wreck()
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var hot := flash > 0.0
	var bob := sin(leg_phase * 2.0) * 1.2 if state == S.WALK else sin(anim * 2.0) * 0.6
	if state == S.RAISE:
		bob = -1.5
	elif state == S.RECOVER or state == S.STUN:
		bob = 2.5
	# Sombra
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	_ellipse(Vector2(0, 0), Vector2(30, 3), Color(0, 0, 0, 0.35))
	# Braço do martelo (atrás)
	_draw_hammer_arm(bob, hot)
	# Pernas
	_draw_leg(-9.0, leg_phase + PI, bob, ARMOR.darkened(0.25))
	# Tanque nas costas
	var tank := Rect2(-31, -66 + bob, 13, 30)
	draw_rect(tank, COPPER_D)
	draw_rect(Rect2(tank.position + Vector2(1, 0), Vector2(11, 3)), COPPER)
	draw_rect(Rect2(tank.position + Vector2(1, 27), Vector2(11, 3)), COPPER)
	var glow := 0.55 + 0.45 * sin(anim * (9.0 if phase2 else 5.0))
	draw_rect(Rect2(-29, -58 + bob, 9, 12), Color(1.0, 0.45 + 0.3 * glow, 0.1, 0.9))
	draw_rect(Rect2(-29, -58 + bob, 9, 12), COPPER, false, 1.0)
	# Chaminé
	draw_rect(Rect2(-27, -76 + bob, 6, 10), ARMOR)
	draw_rect(Rect2(-28, -77 + bob, 8, 2), COPPER)
	# Chassi
	var body := Rect2(-20, -68 + bob, 40, 34)
	draw_rect(body, RED if not hot else Color(1, 0.8, 0.7))
	draw_rect(Rect2(-20, -68 + bob, 40, 5), RED.lightened(0.15))
	draw_rect(Rect2(-20, -40 + bob, 40, 6), ARMOR)
	draw_rect(Rect2(-18, -63 + bob, 3, 22), RED_D)
	for i in 4:
		draw_circle(Vector2(-14 + i * 9, -65 + bob), 1.1, COPPER)
		draw_circle(Vector2(-14 + i * 9, -37 + bob), 1.1, COPPER)
	# Cabine
	draw_rect(Rect2(4, -62 + bob, 15, 13), ARMOR)
	draw_rect(Rect2(6, -60 + bob, 12, 9), Color(0.25, 0.35, 0.38, 0.9))
	draw_circle(Vector2(11, -55 + bob), 3.4, Color("2a2222"))
	draw_rect(Rect2(10, -57 + bob, 6, 2), VISOR)
	draw_line(Vector2(7, -59 + bob), Vector2(11, -59 + bob), Color(1, 1, 1, 0.35), 1.0)
	# Núcleo frontal (abre depois da martelada)
	var core_r := Rect2(8, -46 + bob, 11, 8)
	if core_open > 0.0:
		var k := 0.6 + 0.4 * sin(anim * 20.0)
		draw_rect(core_r.grow(2), Color(1.0, 0.5, 0.15, 0.35 * k))
		draw_rect(core_r, Color(1.0, 0.75 * k + 0.2, 0.2))
		draw_rect(Rect2(8, -52 + bob, 11, 4), ARMOR_L)
	else:
		draw_rect(core_r, ARMOR_L)
		draw_line(Vector2(8, -42 + bob), Vector2(19, -42 + bob), ARMOR, 1.0)
	# Perna da frente
	_draw_leg(9.0, leg_phase, bob, ARMOR)
	# Braço da arma (frente)
	var sh := Vector2(14, -42 + bob)
	var mz := Vector2(36, gun_y)
	draw_line(sh, sh.lerp(mz, 0.5) + Vector2(0, 4), ARMOR_L, 5.0)
	draw_line(sh.lerp(mz, 0.5) + Vector2(0, 4), mz + Vector2(-8, 0), ARMOR_L, 4.0)
	draw_rect(Rect2(mz + Vector2(-12, -3), Vector2(12, 6)), Color("2a2626"))
	draw_rect(Rect2(mz + Vector2(-2, -1.5), Vector2(4, 3)), Color("1a1616"))
	if muzzle > 0.0:
		draw_circle(mz + Vector2(4, 0), 4.0, Color(1.0, 0.85, 0.4, 0.9))
	if state == S.AIM:
		var col := Color(1.0, 0.15, 0.1, 0.55) if not shot_low else Color(1.0, 0.75, 0.1, 0.6)
		var a := 0.4 + 0.6 * absf(sin(anim * 25.0))
		draw_line(mz, mz + Vector2(laser_len, 0), Color(col, col.a * a), 1.0)
	# Aviso da martelada
	if state == S.RAISE:
		var head := SHOULDER + Vector2(cos(arm), sin(arm)) * ARM_LEN + Vector2(0, bob)
		var a2 := 0.5 + 0.5 * absf(sin(anim * 30.0))
		draw_circle(head, 11.0, Color(1.0, 0.2, 0.1, 0.25 * a2))
		draw_line(Vector2(26, 0), Vector2(44, 0), Color(1.0, 0.3, 0.1, 0.7 * a2), 2.0)
	if state == S.DYING:
		draw_rect(body.grow(2), Color(1.0, 0.6, 0.2, 0.25 + 0.25 * sin(anim * 30.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hammer_arm(bob: float, hot: bool) -> void:
	var s := SHOULDER + Vector2(0, bob)
	var dirv := Vector2(cos(arm), sin(arm))
	var elbow := s + dirv * (ARM_LEN * 0.5) + Vector2(dirv.y, -dirv.x) * -4.0
	var head := s + dirv * ARM_LEN
	var c := ARMOR.darkened(0.1) if not hot else Color(1, 0.8, 0.7)
	draw_line(s, elbow, c, 6.0)
	draw_line(elbow, head, c, 5.0)
	draw_circle(elbow, 3.5, COPPER_D)
	# Pistão
	draw_line(s + dirv * 6.0, head - dirv * 8.0, COPPER, 1.5)
	# Cabeça do martelo
	var perp := Vector2(-dirv.y, dirv.x)
	var pts := PackedVector2Array([
		head + perp * 9.0 - dirv * 6.0, head + perp * 9.0 + dirv * 6.0,
		head - perp * 9.0 + dirv * 6.0, head - perp * 9.0 - dirv * 6.0])
	draw_colored_polygon(pts, Color("2e2828") if not hot else Color(1, 0.8, 0.7))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), COPPER_D, 1.0)
	draw_line(head + perp * 9.0 + dirv * 6.0, head - perp * 9.0 + dirv * 6.0, Color("8a8f96"), 2.0)


func _draw_leg(x: float, ph: float, bob: float, col: Color) -> void:
	var hip := Vector2(x, -36 + bob)
	var step := sin(ph) * 7.0 if state == S.WALK else 0.0
	var lift := maxf(0.0, cos(ph)) * 4.0 if state == S.WALK else 0.0
	var foot := Vector2(x + step, -lift)
	var knee := Vector2((hip.x + foot.x) * 0.5 + 7.0, (hip.y + foot.y) * 0.5 - 2.0)
	draw_line(hip, knee, col, 7.0)
	draw_line(knee, foot + Vector2(0, -4), col, 5.0)
	draw_circle(knee, 3.5, COPPER_D)
	draw_rect(Rect2(foot + Vector2(-7, -4), Vector2(14, 4)), col.darkened(0.2))
	draw_rect(Rect2(foot + Vector2(-7, -4), Vector2(14, 1.5)), RED_D)


func _draw_wreck() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	_ellipse(Vector2(0, 0), Vector2(34, 3), Color(0, 0, 0, 0.4))
	# Pernas dobradas
	draw_line(Vector2(-12, -8), Vector2(-24, -2), ARMOR.darkened(0.3), 6.0)
	draw_line(Vector2(12, -8), Vector2(26, -2), ARMOR.darkened(0.2), 6.0)
	# Chassi tombado e chamuscado
	draw_set_transform(Vector2(0, -12), 0.25, Vector2(facing, 1))
	draw_rect(Rect2(-22, -14, 40, 24), RED_D.darkened(0.4))
	draw_rect(Rect2(-22, -14, 40, 4), RED.darkened(0.5))
	draw_rect(Rect2(2, -10, 14, 10), Color("1a1414"))
	draw_line(Vector2(4, -9), Vector2(15, -1), Color(0.5, 0.1, 0.08), 2.0)
	draw_rect(Rect2(-32, -12, 11, 22), COPPER_D.darkened(0.4))
	var ember := 0.4 + 0.3 * sin(dead_t * 6.0)
	draw_rect(Rect2(-30, -6, 7, 8), Color(1.0, 0.4, 0.1, ember))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Martelo caído
	draw_rect(Rect2(facing * 30 - 9, -10, 18, 10), Color("2e2828"))


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
