extends CharacterBody2D
## Sera Vael. Origem do nó = pés. Movimento com peso (aceleração, embalo para
## correr, giro ao virar), agachar, pulos curto/longo, agarrar e subir bordas,
## descer de bordas, encostar em reentrâncias, rolamento (esquiva), lança-rebites,
## rebite de escalada e uso de ferramentas. Sangue que respinga nela fica na roupa.

const RivetScript := preload("res://scripts/entities/rivet.gd")
const ChargeScript := preload("res://scripts/entities/steam_charge.gd")
const GrappleShotScript := preload("res://scripts/entities/grapple_shot.gd")
const Fx := preload("res://scripts/fx.gd")
const SplatsScript := preload("res://scripts/splats.gd")
const Light := preload("res://scripts/fx/light.gd")

const TILE := 20
const HALF_W := 5.0
const STAND_H := 28.0
const CROUCH_H := 16.0
const HAND_H := 26.0
const GRAVITY := 980.0
const MAX_FALL := 520.0
const WALK := 80.0
const RUN := 150.0
const CROUCH_SPEED := 40.0
const ROLL_SPEED := 210.0
const ROLL_TIME := 0.36
const ROLL_COOLDOWN := 0.22
const ACCEL := 1400.0
const RUN_ACCEL := 900.0
const FRICTION := 1800.0
const AIR_ACCEL := 550.0
const SHORT_JUMP_V := 290.0
const LONG_JUMP_V := 300.0
const SHORT_JUMP_X := 80.0
const RUN_DELAY := 0.2
const FALL_DAMAGE_H := 180.0
const SHOOT_COOLDOWN := 0.3
const GRAPPLE_RANGE := 170.0

enum S { NORMAL, HANG, CLIMB, DESCEND, COVER, STUN, DEAD, ZIP, ROLL }

const ZIP_SPEED := 230.0

const SUIT := Color("7fd4ff")
const SUIT_D := Color("3d93c2")
const SKIN := Color("e8c6a0")
const HAIR := Color("2b2f3a")
const TOOL := Color("8a8f96")
const BELT := Color("b87333")

var state: int = S.NORMAL
var facing: int = 1
var vis_scale: float = 1.0
var crouching := false
var in_cover := false
var cover_x := 0.0
var run_timer := 0.0
var turn_timer := 0.0
var turn_total := 0.14
var turn_from: int = 1
var turn_flipped := false
var anim_t := 0.0
var walk_phase := 0.0
var shoot_cd := 0.0
var shoot_flash := 0.0
var shoot_dir: int = 1
var invuln := 0.0
var stun_t := 0.0
var coyote := 0.0
var peak_y := 0.0
var was_on_floor := true
var hang_pos := Vector2.ZERO
var hang_is_peg := false
var climb_from := Vector2.ZERO
var climb_to := Vector2.ZERO
var climb_t := 0.0
var climb_dur := 0.38
var drop_through_t := 0.0
var roll_t := 0.0
var roll_dir: int = 1
var roll_cd := 0.0
## Sangue grudado na roupa e sujeira acumulada (0..1).
var splats = SplatsScript.new()
var grime := 0.0
## Esticar e achatar (só visual): pulo estica, pouso achata.
var squash := Vector2.ONE
var dead_t := 0.0
var step_t := 0.0
var cover_t := 0.0
var current_prompt := ""
var locked_last := false
var grab_cd := 0.0
var pool_pending := false
var zip_line = null
var zip_t := 0.0
var zip_speed := 0.0
var since_shot := 9.0

var collider: CollisionShape2D
var stand_shape := RectangleShape2D.new()
var crouch_shape := RectangleShape2D.new()


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 16
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(50)
	z_index = 5
	stand_shape.size = Vector2(HALF_W * 2.0, STAND_H)
	crouch_shape.size = Vector2(HALF_W * 2.0, CROUCH_H)
	collider = CollisionShape2D.new()
	collider.shape = stand_shape
	collider.position = Vector2(0, -STAND_H * 0.5)
	add_child(collider)
	peak_y = global_position.y
	add_to_group("splat_target")
	# Luz de preenchimento: Sera sempre legível no escuro.
	var fill = Light.make(self, Vector2(0, -16), Color(1.0, 0.92, 0.82), 72.0, 0.42)
	fill.z_index = 20
	splats.from_array(Game.sera_splats)
	grime = Game.sera_grime


func _exit_tree() -> void:
	Game.sera_splats = splats.to_array()
	Game.sera_grime = grime


func splat_rect() -> Rect2:
	return hitbox() if state != S.DEAD else Rect2()


## Sangue alheio espirrando na roupa de Sera.
func receive_splat(p: Vector2, r: float, col: Color) -> void:
	var h := CROUCH_H if crouching else STAND_H
	splats.add(p - global_position, facing, h, HALF_W - 1.0, r * 0.85, col)
	grime = minf(1.0, grime + 0.006 * r)


func is_rolling() -> bool:
	return state == S.ROLL


# ---------------------------------------------------------------- utilidades

func is_dead() -> bool:
	return state == S.DEAD


func hitbox() -> Rect2:
	var h := CROUCH_H if crouching else STAND_H
	return Rect2(global_position.x - HALF_W, global_position.y - h, HALF_W * 2.0, h)


func center() -> Vector2:
	return global_position + Vector2(0, -(CROUCH_H if crouching else STAND_H) * 0.5)


func _level():
	return Game.world.level


func _msg(t: String) -> void:
	Game.world.hud.message(t)


func _set_crouch(on: bool) -> void:
	crouching = on
	collider.shape = crouch_shape if on else stand_shape
	collider.position = Vector2(0, -(CROUCH_H if on else STAND_H) * 0.5)


func _can_stand() -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(HALF_W * 2.0 - 1.0, STAND_H - 2.0)
	q.shape = r
	q.transform = Transform2D(0.0, global_position + Vector2(0, -STAND_H * 0.5 - 1.0))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _input_axis() -> Vector2:
	# x = direção (-1/0/1), y = intensidade analógica
	var ax := Input.get_axis("move_left", "move_right")
	var strength := absf(ax)
	if strength < 0.25:
		return Vector2.ZERO
	return Vector2(signf(ax), strength)


# ---------------------------------------------------------------- loop

func _physics_process(delta: float) -> void:
	anim_t += delta
	shoot_cd = maxf(shoot_cd - delta, 0.0)
	shoot_flash = maxf(shoot_flash - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)
	grab_cd = maxf(grab_cd - delta, 0.0)
	roll_cd = maxf(roll_cd - delta, 0.0)
	since_shot += delta
	if drop_through_t > 0.0:
		drop_through_t -= delta
		if drop_through_t <= 0.0:
			collision_mask = 1 | 16
	var locked: bool = Game.world != null and Game.world.is_input_locked()
	current_prompt = ""
	match state:
		S.DEAD:
			_process_dead(delta)
		S.HANG:
			_process_hang(locked)
		S.CLIMB, S.DESCEND:
			_process_climb(delta)
		S.COVER:
			_process_cover(delta, locked)
		S.STUN:
			_process_stun(delta)
		S.ZIP:
			_process_zip(delta, locked)
		S.ROLL:
			_process_roll(delta, locked)
		_:
			_process_normal(delta, locked)
	if turn_timer <= 0.0:
		vis_scale = move_toward(vis_scale, float(facing), delta * 14.0)
	locked_last = locked
	_update_secondary(delta)
	squash = squash.lerp(Vector2.ONE, minf(1.0, delta * 14.0))
	queue_redraw()


func _process_normal(delta: float, locked: bool) -> void:
	var on_floor := is_on_floor()
	var inp := Vector2.ZERO if locked else _input_axis()
	var ix := inp.x

	if on_floor:
		coyote = 0.1
		if not was_on_floor:
			_on_land()
			if state != S.NORMAL:
				was_on_floor = true
				return
		peak_y = global_position.y
		var want_crouch := not locked and Input.is_action_pressed("move_down")
		if want_crouch != crouching:
			if want_crouch:
				_set_crouch(true)
				run_timer = 0.0
			elif _can_stand():
				_set_crouch(false)

		if turn_timer > 0.0:
			turn_timer -= delta
			var p := 1.0 - clampf(turn_timer / turn_total, 0.0, 1.0)
			vis_scale = cos(p * PI) * float(turn_from)
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.7 * delta)
			if p >= 0.5 and not turn_flipped:
				facing = -turn_from
				turn_flipped = true
			if turn_timer <= 0.0:
				vis_scale = float(facing)
		elif ix != 0.0:
			var dir := int(ix)
			if dir != facing:
				_start_turn(absf(velocity.x) > WALK + 10.0)
			else:
				var max_speed := WALK
				if crouching:
					max_speed = CROUCH_SPEED
				else:
					run_timer += delta
					if run_timer >= RUN_DELAY and inp.y > 0.65:
						max_speed = RUN
				var acc := RUN_ACCEL if max_speed > WALK else ACCEL
				if absf(velocity.x) > max_speed:
					acc = FRICTION
				velocity.x = move_toward(velocity.x, dir * max_speed, acc * delta)
		else:
			run_timer = 0.0
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

		if not locked and Input.is_action_just_pressed("roll") and roll_cd <= 0.0:
			_start_roll(int(ix))
			was_on_floor = true
			return
		if not locked and turn_timer <= 0.0:
			if Input.is_action_just_pressed("jump"):
				if crouching:
					if not _try_drop_through():
						if _try_descend_ledge():
							was_on_floor = false
							return
				else:
					_do_jump(ix)
			elif Input.is_action_just_pressed("move_up") and not crouching and not Input.is_action_pressed("shoot"):
				var spot = _find_cover()
				if spot != null:
					_enter_cover(spot)
					return
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	else:
		coyote -= delta
		if was_on_floor and velocity.y >= 0.0:
			peak_y = global_position.y
		peak_y = minf(peak_y, global_position.y)
		if turn_timer > 0.0:
			turn_timer = 0.0
			facing = -turn_from if turn_flipped else facing
		if crouching and _can_stand():
			_set_crouch(false)
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		if ix != 0.0:
			var cap := maxf(absf(velocity.x), WALK)
			velocity.x = move_toward(velocity.x, ix * cap, AIR_ACCEL * delta)
		if not locked and coyote > 0.0 and Input.is_action_just_pressed("jump"):
			_do_jump(ix)
		elif velocity.y > -40.0 and grab_cd <= 0.0 and _try_grab():
			was_on_floor = false
			return
		elif velocity.y > -60.0 and grab_cd <= 0.0 and _try_zip():
			was_on_floor = false
			return

	if not locked:
		if Input.is_action_just_pressed("interact"):
			_try_interact()
		if Input.is_action_just_pressed("shoot") and shoot_cd <= 0.0 and turn_timer <= 0.0:
			_shoot()
		if Input.is_action_just_pressed("use_tool"):
			_use_tool()
		if Input.is_action_just_pressed("swap_tool"):
			Game.cycle_tool()
			Sfx.play("menu", -6.0)

	was_on_floor = on_floor
	move_and_slide()

	# Passos
	if on_floor and absf(velocity.x) > 20.0:
		walk_phase += absf(velocity.x) * delta * 0.11
		step_t -= absf(velocity.x) * delta
		if step_t <= 0.0:
			step_t = 26.0
			Sfx.play("step", -16.0 if absf(velocity.x) < WALK + 5 else -11.0)
			if absf(velocity.x) > WALK + 10.0:
				Fx.dust(get_parent(), global_position, 3)
	elif on_floor:
		walk_phase = 0.0

	if on_floor and not locked:
		_update_prompt()


func _update_prompt() -> void:
	var it = _find_interactable()
	if it != null:
		current_prompt = String(it.prompt)
	elif not crouching and _find_cover() != null:
		current_prompt = "↑: encostar"
	elif hidden_in_crowd():
		current_prompt = "Misturada na multidão"


## Escondida entre civis: no chão, sem correr e sem ter atirado há pouco.
## Guardas e holofotes não a enxergam.
func hidden_in_crowd() -> bool:
	if state != S.NORMAL or not is_on_floor() or since_shot < 1.2 or absf(velocity.x) > WALK + 5.0:
		return false
	for c in get_tree().get_nodes_in_group("civilian"):
		if c.can_hide() and absf(c.global_position.x - global_position.x) < 12.0 \
				and absf(c.global_position.y - global_position.y) < 10.0:
			return true
	return false


# ---------------------------------------------------------------- tirolesa

func _try_zip() -> bool:
	var hand := global_position + Vector2(0, -HAND_H)
	for z in get_tree().get_nodes_in_group("zipline"):
		var k: float = z.closest_t(hand)
		if k > 0.97:
			continue
		if z.point(k).distance_to(hand) < 9.0:
			_start_zip(z, k)
			return true
	return false


func _start_zip(z, k: float) -> void:
	state = S.ZIP
	zip_line = z
	zip_t = k
	zip_speed = maxf(70.0, absf(velocity.x))
	hang_is_peg = true
	_set_crouch(false)
	facing = z.dir_x()
	vis_scale = float(facing)
	velocity = Vector2.ZERO
	global_position = z.point(k) + Vector2(0, HAND_H)
	Sfx.play("grapple", -6.0, 1.4)


func _process_zip(delta: float, locked: bool) -> void:
	current_prompt = "Z: soltar"
	zip_speed = minf(zip_speed + 260.0 * delta, ZIP_SPEED)
	var len: float = zip_line.length()
	zip_t += zip_speed * delta / maxf(len, 1.0)
	var p: Vector2 = zip_line.point(minf(zip_t, 1.0))
	var prev := global_position
	global_position = p + Vector2(0, HAND_H)
	velocity = (global_position - prev) / maxf(delta, 0.001)
	peak_y = global_position.y
	if fmod(anim_t, 0.06) < delta:
		Fx.sparks(get_parent(), p + Vector2(-facing * 2.0, 0))
	if zip_t >= 1.0 or (not locked and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_down"))):
		state = S.NORMAL
		grab_cd = 0.35
		was_on_floor = false
		if zip_t < 1.0 and Input.is_action_just_pressed("jump"):
			velocity.y = -180.0
		velocity.x = clampf(velocity.x, -200.0, 200.0)
		velocity.y = minf(velocity.y, 80.0)
		Sfx.play("grab", -8.0, 1.2)


## Queda no abismo do Mercado: sem volta.
func fall_into_abyss() -> void:
	if state == S.DEAD:
		return
	Game.hp = 0
	state = S.DEAD
	in_cover = false
	dead_t = 0.0
	Sfx.play("death")
	Game.world.on_player_died()


# ---------------------------------------------------------------- rolamento

func _start_roll(ix: int) -> void:
	roll_dir = ix if ix != 0 else facing
	facing = roll_dir
	vis_scale = float(facing)
	turn_timer = 0.0
	roll_t = 0.0
	run_timer = 0.0
	state = S.ROLL
	_set_crouch(true)
	velocity.x = roll_dir * ROLL_SPEED
	Sfx.play("step", -2.0, 0.7)
	Fx.dust(get_parent(), global_position, 5)


func _process_roll(delta: float, locked: bool) -> void:
	roll_t += delta
	var k := roll_t / ROLL_TIME
	velocity.x = roll_dir * lerpf(ROLL_SPEED, ROLL_SPEED * 0.55, k)
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	move_and_slide()
	if is_on_wall():
		roll_t = ROLL_TIME
	if roll_t >= ROLL_TIME:
		state = S.NORMAL
		roll_cd = ROLL_COOLDOWN
		velocity.x = roll_dir * WALK * 0.8
		if _can_stand() and not (not locked and Input.is_action_pressed("move_down")):
			_set_crouch(false)
		was_on_floor = is_on_floor()
		peak_y = global_position.y


func _start_turn(skid: bool) -> void:
	turn_total = 0.12 if skid else 0.07
	if crouching:
		turn_total = 0.06
	turn_timer = turn_total
	turn_from = facing
	turn_flipped = false
	run_timer = RUN_DELAY * 0.5 if skid else 0.0
	if skid:
		Sfx.play("step", -6.0, 0.7)
		Fx.dust(get_parent(), global_position + Vector2(facing * 4, 0), 8)


func _do_jump(ix: float) -> void:
	if absf(velocity.x) > WALK + 15.0:
		velocity.y = -LONG_JUMP_V
	else:
		velocity.y = -SHORT_JUMP_V
		velocity.x = ix * SHORT_JUMP_X
	coyote = 0.0
	squash = Vector2(0.82, 1.18)
	peak_y = global_position.y
	Sfx.play("jump", -4.0)
	Fx.dust(get_parent(), global_position, 5)


func _on_land() -> void:
	var fall := global_position.y - peak_y
	var k := clampf(fall / 120.0, 0.15, 1.0)
	squash = Vector2(1.0 + 0.28 * k, 1.0 - 0.24 * k)
	if fall > FALL_DAMAGE_H:
		Sfx.play("land", 2.0)
		hurt(1, "fall")
		if state != S.DEAD:
			state = S.STUN
			stun_t = 0.55
			velocity.x = 0.0
	elif fall > 30.0:
		Sfx.play("land", -6.0)
	if fall > 30.0:
		Fx.dust(get_parent(), global_position, int(clampf(fall / 8.0, 5.0, 16.0)))


func _process_stun(delta: float) -> void:
	stun_t -= delta
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	move_and_slide()
	if stun_t <= 0.0:
		state = S.NORMAL
		was_on_floor = true


# ---------------------------------------------------------------- bordas

func _try_grab() -> bool:
	var level = _level()
	var f := facing
	var hand := global_position + Vector2(f * (HALF_W + 3.0), -HAND_H)
	for p in level.hang_points:
		var pt: Vector2 = p
		if absf(global_position.x - pt.x) < 12.0 and hand.y >= pt.y - 4.0 and hand.y <= pt.y + 10.0:
			_start_hang(pt, true)
			return true
	var probe := global_position + Vector2(f * (HALF_W + 8.0), -HAND_H)
	var c: Vector2i = level.world_to_cell(probe)
	for dy in [0, 1]:
		var t: Vector2i = c + Vector2i(0, dy)
		if not level.is_solid(t) or level.is_solid(t + Vector2i(0, -1)):
			continue
		var top := float(t.y * TILE)
		if hand.y < top - 4.0 or hand.y > top + 10.0:
			continue
		var wall_x := float(t.x * TILE) if f > 0 else float((t.x + 1) * TILE)
		var front := global_position.x + f * HALF_W
		if absf(front - wall_x) > 7.0:
			continue
		var bc := Vector2i(t.x - f, t.y)
		if level.is_solid(bc) or level.is_solid(bc + Vector2i(0, 1)):
			continue
		_start_hang(Vector2(wall_x, top), false)
		return true
	return false


func _start_hang(p: Vector2, is_peg: bool) -> void:
	state = S.HANG
	hang_pos = p
	hang_is_peg = is_peg
	velocity = Vector2.ZERO
	turn_timer = 0.0
	_set_crouch(false)
	if is_peg:
		global_position = Vector2(p.x, p.y + HAND_H)
	else:
		global_position = Vector2(p.x - facing * (HALF_W + 0.5), p.y + HAND_H)
	peak_y = global_position.y
	Sfx.play("grab", -4.0)


func _process_hang(locked: bool) -> void:
	velocity = Vector2.ZERO
	current_prompt = "↑: subir · ↓: soltar"
	if locked:
		return
	var ix := _input_axis().x
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up"):
		var target := hang_pos if hang_is_peg else Vector2(hang_pos.x + facing * (HALF_W + 2.0), hang_pos.y)
		var level = _level()
		var above: Vector2i = level.world_to_cell(target + Vector2(0, -4))
		if not level.is_solid(above):
			climb_from = global_position
			climb_to = target
			climb_t = 0.0
			state = S.CLIMB
			collider.set_deferred("disabled", true)
			Sfx.play("grab", -8.0, 0.8)
		elif hang_is_peg and Input.is_action_just_pressed("jump"):
			state = S.NORMAL
			grab_cd = 0.2
			velocity = Vector2(ix * 90.0, -240.0)
			was_on_floor = false
	elif Input.is_action_just_pressed("move_down") or (ix != 0.0 and int(ix) == -facing):
		state = S.NORMAL
		grab_cd = 0.3
		if not hang_is_peg:
			global_position.x -= facing * 2.0
		peak_y = global_position.y
		was_on_floor = false


func _try_drop_through() -> bool:
	var level = _level()
	var below: Vector2i = level.world_to_cell(global_position + Vector2(0, 3))
	var on_peg := false
	for p in level.hang_points:
		var pt: Vector2 = p
		if absf(global_position.x - pt.x) < 12.0 and absf(global_position.y - pt.y) < 3.0:
			on_peg = true
	if level.is_oneway(below) or on_peg:
		collision_mask = 1
		drop_through_t = 0.25
		global_position.y += 2.0
		_set_crouch(false)
		return true
	return false


func _try_descend_ledge() -> bool:
	var level = _level()
	var below: Vector2i = level.world_to_cell(global_position + Vector2(0, 2))
	if not level.is_solid(below):
		return false
	for f in [facing, -facing]:
		var edge_x := float((below.x + 1) * TILE) if f > 0 else float(below.x * TILE)
		if absf(global_position.x - edge_x) > 12.0:
			continue
		var out: Vector2i = below + Vector2i(f, 0)
		if level.is_solid(out) or level.is_solid(out + Vector2i(0, 1)) or level.is_solid(out + Vector2i(0, -1)):
			continue
		facing = -f
		vis_scale = float(facing)
		hang_pos = Vector2(edge_x, float(below.y * TILE))
		hang_is_peg = false
		climb_from = global_position
		climb_to = Vector2(edge_x + f * (HALF_W + 0.5), hang_pos.y + HAND_H)
		climb_t = 0.0
		state = S.DESCEND
		_set_crouch(false)
		collider.set_deferred("disabled", true)
		velocity = Vector2.ZERO
		return true
	return false


func _process_climb(delta: float) -> void:
	climb_t += delta
	var p := clampf(climb_t / climb_dur, 0.0, 1.0)
	if state == S.CLIMB:
		# Primeiro sobe, depois avança.
		if p < 0.6:
			var k := p / 0.6
			global_position = Vector2(climb_from.x, lerpf(climb_from.y, climb_to.y, k * k * (3.0 - 2.0 * k)))
		else:
			var k := (p - 0.6) / 0.4
			global_position = Vector2(lerpf(climb_from.x, climb_to.x, k), climb_to.y)
	else:
		# Descer: avança para a borda, depois desce.
		if p < 0.4:
			var k := p / 0.4
			global_position = Vector2(lerpf(climb_from.x, climb_to.x, k), climb_from.y)
		else:
			var k := (p - 0.4) / 0.6
			global_position = Vector2(climb_to.x, lerpf(climb_from.y, climb_to.y, k))
	if p >= 1.0:
		global_position = climb_to
		collider.set_deferred("disabled", false)
		velocity = Vector2.ZERO
		if state == S.CLIMB:
			state = S.NORMAL
			was_on_floor = true
			peak_y = global_position.y
			if not _can_stand():
				_set_crouch(true)
		else:
			state = S.HANG
			peak_y = global_position.y
			Sfx.play("grab", -6.0)


# ---------------------------------------------------------------- encostar

func _find_cover():
	for c in get_tree().get_nodes_in_group("cover"):
		var n: Node2D = c
		if absf(n.global_position.x - global_position.x) < 14.0 and absf(n.global_position.y - global_position.y) < 6.0:
			return n
	return null


func _enter_cover(spot) -> void:
	state = S.COVER
	in_cover = true
	cover_x = spot.global_position.x
	cover_t = 0.0
	velocity = Vector2.ZERO
	turn_timer = 0.0
	Sfx.play("cover", -4.0)


func _process_cover(delta: float, locked: bool) -> void:
	cover_t += delta
	current_prompt = "↓ / ← →: sair"
	global_position.x = move_toward(global_position.x, cover_x, 140.0 * delta)
	velocity = Vector2.ZERO
	if locked or cover_t < 0.15:
		return
	if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("jump") \
			or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		_leave_cover()
		if Input.is_action_just_pressed("move_left"):
			facing = -1
		elif Input.is_action_just_pressed("move_right"):
			facing = 1


func _leave_cover() -> void:
	in_cover = false
	state = S.NORMAL
	was_on_floor = true


# ---------------------------------------------------------------- ações

func _find_interactable():
	var best = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n.can_interact() or not n.is_in_reach(self):
			continue
		var d: float = absf(n.global_position.x - global_position.x)
		if d < best_d:
			best_d = d
			best = n
	return best


func _try_interact() -> void:
	var it = _find_interactable()
	if it != null:
		it.interact(self)


func _shoot() -> void:
	if Input.is_action_pressed("move_up") and not crouching:
		var gp = _find_grapple()
		if gp != null:
			_fire_grapple(gp)
			return
	var dir := facing
	var h := 9.0 if crouching else 18.0
	since_shot = 0.0
	var r = RivetScript.new()
	r.setup(global_position + Vector2(0, -h), dir)
	Game.world.add_entity(r)
	shoot_cd = SHOOT_COOLDOWN
	shoot_flash = 0.1
	shoot_dir = dir
	Sfx.play("shot", -3.0)
	Fx.smoke(get_parent(), global_position + Vector2(dir * 15.0, -h), 3)
	Light.make(get_parent(), global_position + Vector2(dir * 15.0, -h), Color(1.0, 0.75, 0.4), 60.0, 1.3, 0.0, 0.09)


func _find_grapple():
	var best = null
	var best_d := GRAPPLE_RANGE
	var chest := global_position + Vector2(0, -20)
	for g in get_tree().get_nodes_in_group("grapple"):
		if g.anchored:
			continue
		var gpos: Vector2 = g.global_position
		var d := gpos - chest
		if d.y > 4.0 or d.length() > best_d:
			continue
		var q := PhysicsRayQueryParameters2D.create(chest, gpos - d.normalized() * 3.0, 1, [get_rid()])
		if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			continue
		best_d = d.length()
		best = g
	return best


func _fire_grapple(gp) -> void:
	var dx: float = gp.global_position.x - global_position.x
	if absf(dx) > 2.0 and int(signf(dx)) != facing:
		facing = int(signf(dx))
	var shot = GrappleShotScript.new()
	shot.setup(global_position + Vector2(facing * 4, -20), gp)
	Game.world.add_entity(shot)
	shoot_cd = SHOOT_COOLDOWN * 2.0
	shoot_flash = 0.15
	shoot_dir = facing
	Sfx.play("grapple")


func _use_tool() -> void:
	var tool := Game.current_tool()
	if Game.tool_count(tool) <= 0:
		_msg("Nenhuma ferramenta no inventário")
		return
	match tool:
		"charge":
			var c = ChargeScript.new()
			c.setup(global_position + Vector2(facing * 6, -20), Vector2(facing * 150.0 + velocity.x * 0.3, -170.0))
			Game.world.add_entity(c)
			Game.consume("charge")
			Sfx.play("throw")
		"sealant":
			if Game.hp >= Game.MAX_HP:
				_msg("A vida já está cheia")
				return
			Game.hp = mini(Game.MAX_HP, Game.hp + 2)
			Game.consume("sealant")
			Sfx.play("heal")
			_msg("Selante aplicado: +2 de vida")
		"card":
			var door = _find_security_door()
			if door == null:
				_msg("Nenhuma porta de segurança por perto")
				return
			door.open()
			Game.consume("card")
			_msg("Cartão de acesso usado")


func _find_security_door():
	for d in get_tree().get_nodes_in_group("security_door"):
		if d.opened:
			continue
		var dc: Vector2 = d.global_position + Vector2(10, float(d.height) * 0.5)
		if absf(dc.x - global_position.x) < 48.0 and absf(dc.y - global_position.y) < 60.0:
			return d
	return null


# ---------------------------------------------------------------- dano

func hurt(amount: int, kind: String = "generic") -> void:
	if state == S.DEAD or invuln > 0.0:
		return
	if in_cover and kind == "bullet":
		return
	# Rolando, Sera escapa de tiros, ondas de choque, estilhaços e vapor.
	if state == S.ROLL and kind != "fall" and kind != "crush":
		return
	Game.hp = maxi(0, Game.hp - amount)
	invuln = 1.0
	Sfx.play("hurt")
	if Game.world:
		Game.world.shake(3.0)
		Game.world.hitstop(0.05)
		var b = Game.world.blood
		if b and kind != "steam":
			var away := Vector2(-facing, -0.4)
			b.spray(center(), away, 14 + amount * 8, 200.0, 0.6, 1.3)
			# O próprio sangue mancha a roupa em volta do ferimento.
			for k in 3 + amount * 2:
				splats.add(Vector2(randf_range(-HALF_W, HALF_W), -randf_range(8.0, 24.0)), 1, STAND_H, HALF_W,
					randf_range(0.8, 1.7), b.blood_color())
			grime = minf(1.0, grime + 0.05 * amount)
	if Game.hp <= 0:
		_die()
		return
	if state == S.NORMAL and is_on_floor() and kind != "fall":
		velocity.x = -facing * 60.0
		velocity.y = -90.0


func _die() -> void:
	state = S.DEAD
	in_cover = false
	dead_t = 0.0
	if state == S.HANG or collider.disabled:
		collider.set_deferred("disabled", false)
	_set_crouch(true)
	Sfx.play("death")
	var b = Game.world.blood
	if b:
		b.burst(center(), 45, 260.0)
		pool_pending = true
	Game.world.on_player_died()


func _process_dead(delta: float) -> void:
	dead_t += delta
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.5 * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	move_and_slide()
	if pool_pending and is_on_floor() and dead_t > 0.25:
		pool_pending = false
		if Game.world.blood:
			Game.world.blood.pool(global_position + Vector2(3, 0), 16.0)



# ---------------------------------------------------------------- aparência
# Sera é desenhada por código. Origem = pés; desenho virado para a direita e
# espelhado por vis_scale. Movimento secundário: respiração, rabo de cavalo e
# busto com molas amortecidas que reagem a passos, pulos e pousos.

const SUIT_L := Color("c8efff")
const GLOVE := Color("2e2a28")
const BOOT := Color("3a2a22")
const SOLE := Color("1e1612")
const HAIR_L := Color("4c566c")
const LIP := Color("b4605a")
const EYE := Color("1a1c24")
const GOGGLE := Color("d08a4a")
const BLUSH := Color(0.95, 0.55, 0.5, 0.35)
const HAIR_SEG := 3.1
const HAIR_REST := Vector2(-0.55, 0.83)

var breath := 0.0
var bust_y := 0.0
var bust_v := 0.0
var last_vel := Vector2.ZERO
var hair_anchor := Vector2(-3.4, -27.4)
var hair_pts: Array[Vector2] = []
var hair_vel: Array[Vector2] = []


func _init_hair() -> void:
	hair_pts.clear()
	hair_vel.clear()
	for i in 4:
		hair_pts.append(hair_anchor + HAIR_REST * HAIR_SEG * (i + 1))
		hair_vel.append(Vector2.ZERO)


func _update_secondary(delta: float) -> void:
	if hair_pts.is_empty():
		_init_hair()
	var dv := velocity - last_vel
	last_vel = velocity
	if state in [S.HANG, S.CLIMB, S.DESCEND, S.COVER]:
		dv = Vector2.ZERO
	var idle := state in [S.NORMAL, S.COVER] and absf(velocity.x) < 8.0
	breath = sin(anim_t * (2.1 if idle else 3.6))
	# Busto: mola amortecida, excitada pelos passos e por trancos verticais.
	var force := -bust_y * 650.0 - bust_v * 12.0
	if state == S.NORMAL and is_on_floor() and absf(velocity.x) > 20.0:
		force += -cos(walk_phase * 2.0) * (absf(velocity.x) / RUN) * 300.0
	bust_v += force * delta
	bust_v += clampf(-dv.y, -400.0, 400.0) * 0.045
	bust_y = clampf(bust_y + bust_v * delta, -1.1, 1.1)
	# Rabo de cavalo: corrente de 4 pontos com mola, gravidade, vento e tranco.
	var f := float(facing)
	var wind := Vector2(-velocity.x * f, -velocity.y * 0.6) * 3.0
	var kick := Vector2(-dv.x * f, -dv.y) * 0.45
	var prev := hair_anchor
	for i in hair_pts.size():
		var p: Vector2 = hair_pts[i]
		var v: Vector2 = hair_vel[i]
		var target := prev + HAIR_REST * HAIR_SEG
		var acc := (target - p) * 150.0 + Vector2(0, 240.0) + wind * (0.5 + i * 0.35)
		acc.y += sin(anim_t * 2.1 + i) * 25.0 * (1.0 if idle else 0.0)
		v += acc * delta + kick * (0.4 + 0.3 * i)
		v *= 0.86
		p += v * delta
		var d := p - prev
		if d.length() > HAIR_SEG:
			p = prev + d.normalized() * HAIR_SEG
		hair_pts[i] = p
		hair_vel[i] = v
		prev = p


var suit_c := SUIT
var suit_dc := SUIT_D
var suit_lc := SUIT_L
const DIRT := Color("5a3028")


func _draw() -> void:
	var g := grime * 0.42
	suit_c = SUIT.lerp(DIRT, g)
	suit_dc = SUIT_D.lerp(DIRT.darkened(0.3), g)
	suit_lc = SUIT_L.lerp(DIRT.lightened(0.2), g)
	# Sombra no chão
	if state != S.HANG and state != S.CLIMB and is_on_floor():
		draw_set_transform(Vector2(0, -0.5), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if invuln > 0.0 and state != S.DEAD and int(invuln * 16.0) % 2 == 0:
		return
	if state == S.COVER:
		_draw_cover()
		splats.draw_on(self, STAND_H - 4.0, 0.9)
		return
	var sx := vis_scale
	if absf(sx) < 0.2:
		sx = 0.2 if sx >= 0.0 else -0.2
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx * squash.x, squash.y))
	match state:
		S.DEAD:
			_draw_dead()
		S.HANG:
			_draw_hang(0.0)
		S.ZIP:
			_draw_hang(0.35)
			draw_arc(Vector2(0.5, -HAND_H - 2.0), 3.0, PI, TAU, 8, Color("8a8f96"), 1.5)
		S.CLIMB:
			var p := climb_t / climb_dur
			if p < 0.6:
				_draw_hang(p / 0.6)
			else:
				_draw_crouch_pose()
		S.DESCEND:
			if climb_t / climb_dur < 0.4:
				_draw_crouch_pose()
			else:
				_draw_hang(0.0)
		S.STUN:
			_draw_crouch_pose()
		S.ROLL:
			_draw_roll()
		_:
			if crouching:
				_draw_crouch_pose()
			elif not is_on_floor():
				_draw_air()
			else:
				_draw_ground()
	if state != S.DEAD and state != S.ROLL:
		var sh := STAND_H
		if crouching or state == S.STUN:
			sh = CROUCH_H + 2.0
		splats.draw_on(self, sh)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Encolhida, girando no ar rente ao chão.
func _draw_roll() -> void:
	var k := clampf(roll_t / ROLL_TIME, 0.0, 1.0)
	var sx := vis_scale
	if absf(sx) < 0.2:
		sx = 0.2 if sx >= 0.0 else -0.2
	var c := Vector2(0, -7.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx, 1.0))
	var x := Transform2D(0.0, Vector2(sx, 1.0), 0.0, Vector2.ZERO) * Transform2D(k * TAU, c) * Transform2D(0.0, -c)
	draw_set_transform_matrix(x)
	_draw_crouch_pose()
	splats.draw_on(self, CROUCH_H + 2.0)


# ---------------------------------------------------------------- partes

func _leg(hip: Vector2, thigh: float, bend: float, back: bool) -> void:
	var col := suit_dc if back else suit_c
	var knee := hip + Vector2(sin(thigh), cos(thigh)) * 6.5
	var foot := knee + Vector2(sin(thigh - bend), cos(thigh - bend)) * 6.5
	draw_line(hip, knee, col, 3.5, true)
	draw_line(knee, foot, col, 3.0, true)
	var boot_top := knee.lerp(foot, 0.45)
	draw_line(boot_top, foot, BOOT if not back else SOLE, 3.3, true)
	draw_rect(Rect2(foot + Vector2(-1.6, -1.3), Vector2(5.0, 2.3)), SOLE)
	if not back:
		draw_circle(knee, 1.1, suit_lc)


func _glove(hand: Vector2) -> void:
	draw_circle(hand, 1.5, GLOVE)


func _arm_angle(shoulder: Vector2, angle: float, front: bool, holding: bool) -> void:
	var col := suit_c if front else suit_dc
	var elbow := shoulder + Vector2(sin(angle), cos(angle)) * 4.4
	var hand := elbow + Vector2(sin(angle * 1.08), cos(angle * 1.08)) * 4.2
	draw_line(shoulder, elbow, col, 2.5, true)
	draw_line(elbow, hand, col, 2.3, true)
	_glove(hand)
	if holding:
		# Lança-rebites sempre apontado para a frente (ou para trás ao mirar).
		var dir := Vector2(1.0, 0.3).normalized()
		if absf(angle) > 1.2:
			dir = Vector2(signf(sin(angle)), 0)
		draw_line(hand - dir * 1.5, hand + dir * 6.5, TOOL, 3.2, true)
		draw_line(hand + dir * 5.5, hand + dir * 7.0, Color("5a5e64"), 2.2)
		draw_circle(hand + dir * 2.0 + Vector2(0, 1.8), 1.3, BELT)


func _arm_to(shoulder: Vector2, hand: Vector2, col: Color) -> void:
	var d := hand - shoulder
	var length := 8.6
	var mid := shoulder + d * 0.5
	var elbow := mid
	if d.length() < length:
		var perp := Vector2(-d.y, d.x).normalized()
		if perp.x > 0.0:
			perp = -perp
		elbow = mid + perp * sqrt(maxf(0.0, length * length * 0.25 - d.length_squared() * 0.25))
	draw_line(shoulder, elbow, col, 2.5, true)
	draw_line(elbow, hand, col, 2.3, true)
	_glove(hand)


func _tp(hip: Vector2, r: Vector2, u: Vector2, x: float, h: float) -> Vector2:
	return hip + r * x + u * h


## Tronco de perfil com cintura e busto; devolve o centro da cabeça.
func _torso(hip: Vector2, lean: float, s: float) -> Vector2:
	var u := Vector2(sin(lean), -cos(lean))
	var r := Vector2(cos(lean), sin(lean))
	var still := state == S.NORMAL and absf(velocity.x) < 8.0
	var th := (9.5 + (breath * 0.25 if still else 0.0)) * s
	var by := bust_y
	var bx := 0.12 * breath
	var pts := PackedVector2Array([
		_tp(hip, r, u, -3.2, -0.4),
		_tp(hip, r, u, -2.5, th * 0.36),
		_tp(hip, r, u, -2.9, th * 0.68),
		_tp(hip, r, u, -3.2, th - 0.6),
		_tp(hip, r, u, -1.7, th),
		_tp(hip, r, u, 1.9, th),
		_tp(hip, r, u, 2.8, th - 0.8),
		_tp(hip, r, u, 3.2 + bx, th * 0.78 - by * 0.5),
		_tp(hip, r, u, 3.95 + bx, th * 0.66 - by),
		_tp(hip, r, u, 3.6 + bx, th * 0.55 - by),
		_tp(hip, r, u, 2.5, th * 0.40),
		_tp(hip, r, u, 3.3, th * 0.08),
		_tp(hip, r, u, 3.0, -0.4),
	])
	draw_colored_polygon(pts, suit_c)
	# Sombreado das costas e contorno do busto
	draw_line(_tp(hip, r, u, -2.7, 0.4), _tp(hip, r, u, -2.7, th - 0.8), suit_dc, 1.2, true)
	draw_line(_tp(hip, r, u, 2.7, th * 0.71 - by), _tp(hip, r, u, 3.6, th * 0.62 - by), suit_lc, 0.8, true)
	draw_line(_tp(hip, r, u, 3.5, th * 0.56 - by), _tp(hip, r, u, 2.6, th * 0.50 - by * 0.5), suit_dc, 0.7, true)
	# Alça do equipamento, cinto e gola
	draw_line(_tp(hip, r, u, -2.6, th - 0.6), _tp(hip, r, u, 2.3, th * 0.32), BELT, 1.1, true)
	draw_line(_tp(hip, r, u, -3.2, 0.7), _tp(hip, r, u, 3.3, 0.7), BELT, 2.0, true)
	draw_circle(_tp(hip, r, u, 1.2, 0.7), 0.8, Color("e8c547"))
	draw_line(_tp(hip, r, u, -1.4, th), _tp(hip, r, u, 1.4, th), suit_dc, 1.0)
	# Pescoço
	var neck_base := _tp(hip, r, u, 0.2, th)
	var head := _tp(hip, r, u, 0.7, th + 3.3)
	draw_line(neck_base, neck_base.lerp(head, 0.55), SKIN, 2.0)
	return head


func _blinking() -> bool:
	return fmod(anim_t, 3.7) < 0.12


## Cabeça de perfil (olhando para a direita).
func _head(c: Vector2) -> void:
	draw_circle(c + Vector2(-0.9, -0.3), 3.75, HAIR)
	draw_circle(c + Vector2(0.4, 0.4), 3.2, SKIN)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-3.7, 0.4), c + Vector2(-3.3, -2.6), c + Vector2(-1.1, -4.2),
		c + Vector2(1.7, -4.0), c + Vector2(3.5, -2.3), c + Vector2(3.3, -1.2),
		c + Vector2(1.8, -2.0), c + Vector2(0.4, -1.4), c + Vector2(-0.6, 0.4),
		c + Vector2(-1.5, 1.8),
	]), HAIR)
	draw_line(c + Vector2(-1.8, -3.4), c + Vector2(0.9, -3.7), HAIR_L, 0.8, true)
	# Óculos de proteção na testa
	draw_line(c + Vector2(-3.5, -1.7), c + Vector2(1.0, -3.6), Color("6e4a2c"), 0.9, true)
	draw_circle(c + Vector2(1.8, -3.3), 1.15, GOGGLE)
	draw_circle(c + Vector2(1.9, -3.35), 0.6, Color(0.6, 0.85, 1.0, 0.9))
	# Rosto
	if _blinking():
		draw_line(c + Vector2(1.5, -0.1), c + Vector2(2.6, -0.1), EYE, 0.6)
	else:
		draw_circle(c + Vector2(2.1, -0.15), 0.62, EYE)
		draw_circle(c + Vector2(2.3, -0.35), 0.2, Color.WHITE)
		draw_line(c + Vector2(1.7, -0.75), c + Vector2(2.6, -0.8), EYE, 0.45)
	draw_line(c + Vector2(3.5, 0.0), c + Vector2(3.75, 0.85), SKIN.darkened(0.25), 0.6)
	draw_circle(c + Vector2(1.6, 1.1), 0.75, BLUSH)
	draw_line(c + Vector2(2.3, 2.0), c + Vector2(3.1, 1.9), LIP, 0.75)


func _draw_ponytail(head: Vector2) -> void:
	hair_anchor = head + Vector2(-3.0, -1.4)
	if hair_pts.is_empty():
		_init_hair()
	var prev := hair_anchor
	var widths := [2.8, 2.5, 2.0, 1.4]
	for i in hair_pts.size():
		var p: Vector2 = hair_pts[i]
		draw_line(prev, p, HAIR, widths[i], true)
		prev = p
	draw_line(hair_anchor + Vector2(0, 0.4), hair_pts[1] + Vector2(0.3, 0), HAIR_L, 0.6, true)
	draw_circle(hair_anchor, 1.0, BELT)


## Monta o corpo inteiro de perfil.
func _rig(hip_y: float, lean: float, l1: float, b1: float, l2: float, b2: float,
		arm_f: float, arm_b: float, s: float = 1.0) -> void:
	var hip := Vector2(0, hip_y)
	var u := Vector2(sin(lean), -cos(lean))
	var shoulder := hip + u * (8.7 * s)
	var head_guess := hip + Vector2(cos(lean), sin(lean)) * 0.7 + u * ((9.5 * s) + 3.3)
	_leg(hip + Vector2(-0.6, 0), l2, b2, true)
	_arm_angle(shoulder + Vector2(-0.6, 0), arm_b, false, false)
	_draw_ponytail(head_guess)
	var head := _torso(hip, lean, s)
	_head(head)
	_leg(hip, l1, b1, false)
	var aiming := shoot_flash > 0.0
	var front_angle := arm_f
	if aiming:
		front_angle = -PI * 0.5 if shoot_dir != facing else PI * 0.5
	_arm_angle(shoulder, front_angle, true, true)
	if shoot_flash > 0.0:
		var dir := signf(sin(front_angle))
		draw_circle(shoulder + Vector2(dir * 15.0, 0.5), 2.6, Color(1.0, 0.85, 0.4, 0.9))


# ---------------------------------------------------------------- poses

func _draw_ground() -> void:
	var speed := absf(velocity.x)
	if turn_timer > 0.0:
		_rig(-13.0, -0.1, 0.25, 0.3, -0.2, 0.2, 0.3, -0.3)
		return
	if speed < 8.0:
		var b := breath * 0.18
		_rig(-13.0 + b, 0.02, 0.08, 0.05, -0.1, 0.05, 0.45 + b * 0.1, -0.12 - b * 0.2)
		return
	var running := speed > WALK + 10.0
	var amp := 0.85 if running else 0.45
	var lean := 0.26 if running else 0.06
	var ph := walk_phase
	var dirsign := 1.0
	var s1 := sin(ph) * amp * dirsign
	var s2 := sin(ph + PI) * amp * dirsign
	var bend1 := maxf(0.0, -cos(ph)) * (1.1 if running else 0.6)
	var bend2 := maxf(0.0, -cos(ph + PI)) * (1.1 if running else 0.6)
	var bob := absf(sin(ph)) * (1.2 if running else 0.5)
	_rig(-13.0 - bob * 0.5, lean, s1, bend1, s2, bend2, -s1 * 0.9, -s2 * 0.9)


func _draw_air() -> void:
	if velocity.y < 0.0:
		_rig(-14.0, 0.1, 0.9, 1.4, -0.3, 0.6, 0.9, -0.9)
	else:
		_rig(-13.5, 0.05, 0.4, 0.5, -0.25, 0.3, 0.6, -0.6)


func _draw_crouch_pose() -> void:
	_rig(-5.0, 0.62, 1.35, 2.45, 1.1, 2.2, 0.9, -0.2, 0.78)


func _draw_hang(lift: float) -> void:
	var off := -lift * 10.0
	var hip := Vector2(-1.5, -12.0 + off)
	var hand := Vector2(HALF_W + 0.5, -HAND_H)
	if hang_is_peg:
		hand = Vector2(0.5, -HAND_H)
	var lean := -0.06
	var u := Vector2(sin(lean), -cos(lean))
	var shoulder := hip + u * 8.7
	_leg(hip + Vector2(-0.6, 0), 0.15 + lift * 0.8, 0.1 + lift * 1.2, true)
	_arm_to(shoulder + Vector2(-0.5, 0), hand + Vector2(-2.5, 0.4), suit_dc)
	_draw_ponytail(hip + Vector2(cos(lean), sin(lean)) * 0.7 + u * 12.8)
	var head := _torso(hip, lean, 1.0)
	_head(head)
	_leg(hip, 0.35 + lift * 0.9, 0.3 + lift * 1.2, false)
	_arm_to(shoulder, hand + Vector2(-0.8, 0), suit_c)


## Encostada: de frente para a câmera, costas na parede da reentrância.
func _draw_cover() -> void:
	var tint := Color(0.86, 0.86, 0.94)
	var suit := suit_c * tint
	var suit_d := suit_dc * tint
	var by := bust_y - breath * 0.2
	# Pernas e botas
	for side in [-1.0, 1.0]:
		var hipp := Vector2(side * 2.2, -13.0)
		var foot := Vector2(side * 2.9, 0.0)
		draw_line(hipp, foot, suit_d, 3.3, true)
		draw_line(hipp.lerp(foot, 0.55), foot, BOOT, 3.4, true)
		draw_rect(Rect2(foot + Vector2(-2.0, -1.3), Vector2(4.0, 2.3)), SOLE)
	# Braços abertos, mãos espalmadas na parede
	for side in [-1.0, 1.0]:
		var sh := Vector2(side * 4.1, -21.6)
		var el := Vector2(side * 6.3, -17.4)
		var hd := Vector2(side * 7.0, -13.6)
		draw_line(sh, el, suit_d, 2.4, true)
		draw_line(el, hd, suit_d, 2.2, true)
		_glove(hd)
	# Tronco de frente: ombros, busto, cintura, quadril
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.0, -12.9), Vector2(-3.0, -17.0), Vector2(-3.9, -19.6 + by),
		Vector2(-4.4, -22.2), Vector2(-1.6, -23.0), Vector2(1.6, -23.0),
		Vector2(4.4, -22.2), Vector2(3.9, -19.6 + by), Vector2(3.0, -17.0),
		Vector2(4.0, -12.9),
	]), suit)
	draw_arc(Vector2(-1.8, -19.9 + by), 1.6, 0.25, PI - 0.25, 8, suit_d, 0.7, true)
	draw_arc(Vector2(1.8, -19.9 + by), 1.6, 0.25, PI - 0.25, 8, suit_d, 0.7, true)
	draw_line(Vector2(-3.9, -22.0), Vector2(3.1, -15.6), BELT * tint, 1.1, true)
	draw_line(Vector2(-4.0, -13.6), Vector2(4.0, -13.6), BELT * tint, 2.0)
	draw_rect(Rect2(-0.9, -14.4, 1.8, 1.6), Color("e8c547"))
	draw_line(Vector2(-1.4, -23.0), Vector2(1.4, -23.0), suit_d, 1.0)
	draw_line(Vector2(0, -23.0), Vector2(0, -24.0), SKIN * tint, 2.0)
	# Cabeça de frente
	var c := Vector2(0, -26.2)
	draw_circle(c + Vector2(0, -0.2), 3.9, HAIR)
	draw_line(c + Vector2(-3.3, 0.0), c + Vector2(-3.7, 3.6), HAIR, 1.7, true)
	draw_line(c + Vector2(3.3, 0.0), c + Vector2(3.7, 3.6), HAIR, 1.7, true)
	draw_circle(c + Vector2(0, 0.4), 3.05, SKIN * tint)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-3.5, -0.2), c + Vector2(-2.7, -2.9), c + Vector2(0, -3.9),
		c + Vector2(2.7, -2.9), c + Vector2(3.5, -0.2), c + Vector2(2.0, -1.5),
		c + Vector2(0.4, -1.0), c + Vector2(-0.6, -1.6), c + Vector2(-2.0, -1.2),
	]), HAIR)
	draw_line(c + Vector2(-3.7, -2.2), c + Vector2(3.7, -2.2), Color("6e4a2c"), 0.8)
	draw_circle(c + Vector2(-1.4, -2.5), 0.95, GOGGLE)
	draw_circle(c + Vector2(1.4, -2.5), 0.95, GOGGLE)
	if _blinking():
		draw_line(c + Vector2(-1.8, 0.5), c + Vector2(-0.7, 0.5), EYE, 0.6)
		draw_line(c + Vector2(0.7, 0.5), c + Vector2(1.8, 0.5), EYE, 0.6)
	else:
		for side in [-1.0, 1.0]:
			draw_circle(c + Vector2(side * 1.25, 0.45), 0.6, EYE)
			draw_circle(c + Vector2(side * 1.25 + 0.2, 0.25), 0.2, Color.WHITE)
	draw_circle(c + Vector2(-2.0, 1.5), 0.7, BLUSH)
	draw_circle(c + Vector2(2.0, 1.5), 0.7, BLUSH)
	draw_line(c + Vector2(-0.7, 2.3), c + Vector2(0.7, 2.3), LIP, 0.75)
	# Luz da lâmpada da reentrância contornando o cabelo
	draw_arc(c + Vector2(0, -0.2), 3.9, PI + 0.5, TAU - 0.5, 10, Color(1.0, 0.75, 0.4, 0.45), 0.8, true)


func _draw_dead() -> void:
	draw_line(Vector2(-13, -2.0), Vector2(-7, -2.2), suit_dc, 3.0, true)
	draw_line(Vector2(-7, -2.2), Vector2(-1, -2.6), suit_dc, 3.0, true)
	draw_rect(Rect2(-15.5, -3.2, 3.0, 2.6), SOLE)
	draw_line(Vector2(-1, -3.2), Vector2(8, -3.4), suit_c, 6.5, true)
	draw_line(Vector2(-0.8, -3.2), Vector2(-0.8, -3.4), BELT, 6.6)
	draw_circle(Vector2(11.5, -3.0), 3.3, SKIN)
	draw_circle(Vector2(12.2, -4.2), 3.0, HAIR)
	draw_line(Vector2(14.5, -3.5), Vector2(18.5, -1.0), HAIR, 2.2, true)
	draw_line(Vector2(5, -2.0), Vector2(10, -0.8), suit_dc, 2.2, true)
	_glove(Vector2(10, -0.8))
