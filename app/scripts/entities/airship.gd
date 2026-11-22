extends Area2D
## Chefão do Ato 2: o dirigível-patrulha Vigília, da Comandante Vesk.
## Origem = centro do balão. Paira no alto da arena dos telhados.
##
## Ataques: bombardeio (alvos vermelhos no chão), varredura de holofote seguida
## de rajada inclinada (encostar protege), guardas descendo de corda e, na
## segunda metade, uma âncora arrastada pelo telhado.
## Dano: arpões dos canhões do telhado (4) e cortar o cabo da âncora a rebites
## (3 acertos na âncora = 3 de dano).

const BombScript := preload("res://scripts/entities/bomb.gd")
const BulletScript := preload("res://scripts/entities/enemy_bullet.gd")
const GuardScript := preload("res://scripts/entities/guard.gd")
const Fx := preload("res://scripts/fx.gd")

enum S { IDLE, INTRO, CRUISE, BOMB, SEARCH, BURST, DROP, ANCHOR, STAGGER, DYING, DEAD }

const MAX_HP := 24
const PHASE2_HP := 12
const HARPOON_DMG := 4
const ANCHOR_DMG := 3
const BEAM_LEN := 260.0
const BEAM_HALF := 0.16

const RED := Color("6e1a1a")
const RED_L := Color("8a2a24")
const COPPER := Color("b87333")
const COPPER_D := Color("6e4a2c")
const IRON := Color("3a3330")

const INTRO_LINES := [
	["Comandante Vesk", "Sera Vael. Desça do telhado e entregue o livro, e o Diretório talvez lembre que você cooperou."],
	["Sera", "Esse livro diz que a ordem de abrir as válvulas saiu da Torre. Vinte e três pessoas morreram na Caldeira Sul."],
	["Comandante Vesk", "Então você entende por que ele não pode sair deste telhado. Vigília: soltar bombas."],
]
const RETRY_LINES := [
	["Comandante Vesk", "Ainda de pé? Vigília, de novo."],
]

var title := "DIRIGÍVEL VIGÍLIA · Comandante Vesk"
var state: int = S.IDLE
var hp := MAX_HP
var bar_hp := float(MAX_HP)
var bar_visible := false
var phase2 := false
var arena := Rect2()
var floor_y := 0.0
var hover_y := 0.0
var target_x := 0.0
var facing: int = -1
var t := 0.0
var anim := 0.0
var flash := 0.0
var seq_i := 0
var bombs_left := 0
var bomb_t := 0.0
var beam_ang := 0.0
var beam_from := 0.0
var beam_to := 0.0
var beam_locked := false
var shots_left := 0
var harpoons: Array = []     # pontos locais de arpões cravados
var anchor_pos := Vector2.ZERO
var anchor_vy := 0.0
var anchor_hp := 0
var anchor_out := false
var anchor_cd := 0.0
var anchor_life := 0.0
var dead_t := 0.0
var boom_t := 0.0
var exit_lift = null
var guards_dropped: Array = []
var prop := 0.0


func setup(pos: Vector2, screen_rect: Rect2, floor_world_y: float) -> void:
	arena = screen_rect
	floor_y = floor_world_y
	hover_y = arena.position.y + 72.0
	position = Vector2(pos.x, hover_y)
	target_x = pos.x
	z_index = 7


func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	# Área atingível por rebites: a âncora (posicionada quando lançada).
	var cs := CollisionShape2D.new()
	cs.name = "AnchorShape"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 28)
	cs.shape = shape
	cs.disabled = true
	add_child(cs)


func is_alive() -> bool:
	return state != S.DYING and state != S.DEAD


func hp_ratio() -> float:
	return bar_hp / float(MAX_HP)


func hp_real() -> float:
	return float(hp) / float(MAX_HP)


func hull_rect() -> Rect2:
	return Rect2(global_position + Vector2(-74, -26), Vector2(148, 76))


func center() -> Vector2:
	return global_position


func rect() -> Rect2:
	return hull_rect()


func _gondola() -> Vector2:
	return global_position + Vector2(0, 38)


func _player():
	return Game.world.player if Game.world else null


# ---------------------------------------------------------------- lógica

func _physics_process(delta: float) -> void:
	anim += delta
	prop += delta * 30.0
	flash = maxf(flash - delta, 0.0)
	anchor_cd = maxf(anchor_cd - delta, 0.0)
	bar_hp = move_toward(bar_hp, float(hp), delta * 14.0)
	if state == S.DEAD:
		queue_redraw()
		return
	if state == S.DYING:
		_process_dying(delta)
		queue_redraw()
		return
	var w = Game.world
	if w == null or not w.is_active(Vector2(global_position.x, floor_y - 10.0)):
		return
	var p = _player()
	if fmod(anim, 0.4) < delta:
		Fx.smoke(get_parent(), global_position + Vector2(-facing * 70, 4), 2)
	if phase2 and fmod(anim, 0.15) < delta:
		Fx.fire(get_parent(), global_position + Vector2(randf_range(-40, 40), randf_range(-14, 8)), 3)
	_move(delta)
	_process_anchor(delta, p)
	match state:
		S.IDLE:
			if p != null and not p.is_dead() and w.is_active(p.global_position) and p.is_on_floor() and not w.cutscene:
				state = S.INTRO
				Sfx.play("alert", -2.0, 0.7)
				var seen := bool(Game.cp().get("boss_seen", false))
				w.dialog.start(RETRY_LINES if seen else INTRO_LINES, _on_intro_done)
		S.INTRO:
			pass
		S.CRUISE:
			t -= delta
			if t <= 0.0:
				_next_attack(p)
		S.BOMB:
			target_x = p.global_position.x
			bomb_t -= delta
			if bomb_t <= 0.0 and bombs_left > 0:
				bomb_t = 0.22 if phase2 else 0.32
				bombs_left -= 1
				_drop_bomb(p)
			elif bombs_left <= 0 and bomb_t <= 0.0:
				_to_cruise(1.4)
		S.SEARCH:
			t -= delta
			var k := 1.0 - clampf(t / 1.6, 0.0, 1.0)
			beam_ang = lerpf(beam_from, beam_to, k)
			if p != null and _beam_sees(p):
				beam_locked = true
				state = S.BURST
				shots_left = 8 if phase2 else 6
				t = 0.35
				Sfx.play("alert", -4.0, 1.2)
			elif t <= 0.0:
				_to_cruise(1.0)
		S.BURST:
			if p != null and not p.is_dead():
				var to: Vector2 = p.center() - _gondola()
				beam_ang = lerp_angle(beam_ang, Vector2.DOWN.angle_to(to), delta * 6.0)
			t -= delta
			if t <= 0.0:
				if shots_left > 0:
					shots_left -= 1
					t = 0.12
					_fire_burst()
				else:
					beam_locked = false
					_to_cruise(1.2)
		S.DROP:
			t -= delta
			if t <= 0.0:
				_drop_guard()
				_to_cruise(1.5)
		S.ANCHOR:
			if p != null:
				target_x = p.global_position.x
			t -= delta
			if t <= 0.0 and not anchor_out:
				_to_cruise(0.8)
		S.STAGGER:
			t -= delta
			position.y = hover_y - 12.0 + sin(anim * 30.0) * 2.0
			if t <= 0.0:
				_to_cruise(0.8)
	queue_redraw()


func _move(delta: float) -> void:
	var lo := arena.position.x + 90.0
	var hi := arena.end.x - 90.0
	target_x = clampf(target_x, lo, hi)
	var spd := 95.0 if phase2 else 65.0
	if state == S.STAGGER or state == S.INTRO or state == S.IDLE:
		spd = 0.0
	var dx := target_x - global_position.x
	if absf(dx) > 2.0:
		facing = 1 if dx > 0.0 else -1
	position.x = move_toward(position.x, target_x, spd * delta)
	if state != S.STAGGER:
		var hy := hover_y + (22.0 if phase2 else 0.0)
		position.y = lerpf(position.y, hy + sin(anim * 1.3) * 5.0, delta * 2.0)


func _on_intro_done() -> void:
	Game.cp()["boss_seen"] = true
	if not Game.replay:
		Game.write_save()
	bar_visible = true
	Game.world.hud.show_hint("Dirigível Vigília: use os canhões-arpão do telhado (A) quando o casco estiver na mira. Encoste nas chaminés durante a varredura do holofote e fuja dos alvos vermelhos das bombas.")
	_to_cruise(1.5)


func _to_cruise(time: float) -> void:
	state = S.CRUISE
	t = time * (0.75 if phase2 else 1.0)
	# Passa por cima de um dos canhões de vez em quando, para dar chance.
	var cannons := get_tree().get_nodes_in_group("harpoon")
	if not cannons.is_empty() and randf() < 0.6:
		target_x = cannons[randi() % cannons.size()].global_position.x + randf_range(-40, 40)
	else:
		target_x = randf_range(arena.position.x + 100.0, arena.end.x - 100.0)


func _next_attack(p) -> void:
	var seq := ["bombs", "search", "bombs", "guards"]
	if phase2:
		seq = ["bombs", "anchor", "search", "bombs", "guards", "search"]
	var a: String = seq[seq_i % seq.size()]
	seq_i += 1
	if a == "guards":
		var alive := 0
		for g in guards_dropped:
			if is_instance_valid(g) and g.is_alive():
				alive += 1
		if alive >= 2:
			a = "bombs"
	if a == "anchor" and (anchor_out or anchor_cd > 0.0):
		a = "search"
	match a:
		"bombs":
			state = S.BOMB
			bombs_left = 5 if phase2 else 3
			bomb_t = 0.6
			Sfx.play("lever", -2.0, 0.6)
		"search":
			state = S.SEARCH
			t = 1.6
			var px: float = p.global_position.x if p != null else global_position.x
			var side := 1.0 if px > global_position.x else -1.0
			beam_from = -side * 0.9
			beam_to = side * 0.9
			beam_ang = beam_from
			beam_locked = false
			Sfx.play("spark", -6.0, 0.7)
		"guards":
			state = S.DROP
			t = 0.8
			if p != null:
				target_x = p.global_position.x - signf(p.global_position.x - global_position.x) * 90.0
		"anchor":
			state = S.ANCHOR
			t = 2.5
			_launch_anchor()


func _drop_bomb(p) -> void:
	var px: float = p.global_position.x if p != null else global_position.x
	var from := _gondola() + Vector2(0, 8)
	var aim_x := px + randf_range(-50, 50)
	var vx := clampf((aim_x - from.x) * 0.9, -120.0, 120.0)
	var b = BombScript.new()
	b.setup(from, Vector2(vx, 20.0), floor_y)
	get_parent().add_child(b)
	Sfx.play("throw", -4.0, 0.7)


func _beam_dir() -> Vector2:
	return Vector2.DOWN.rotated(beam_ang)


func _beam_sees(p) -> bool:
	if p.is_dead() or p.in_cover or p.hidden_in_crowd():
		return false
	var to: Vector2 = p.center() - _gondola()
	if to.length() > BEAM_LEN:
		return false
	return absf(_beam_dir().angle_to(to)) < BEAM_HALF


func _fire_burst() -> void:
	var b = BulletScript.new()
	var dir := _beam_dir().rotated(randf_range(-0.05, 0.05))
	b.setup_vel(_gondola() + dir * 10.0, dir * 300.0)
	get_parent().add_child(b)
	Sfx.play("eshot", -4.0, 0.9)


func _drop_guard() -> void:
	var g = GuardScript.new()
	g.position = Vector2(global_position.x, global_position.y + 60.0)
	g.reinforcement = true
	get_parent().add_child(g)
	guards_dropped.append(g)
	Sfx.play("grapple", -4.0, 0.8)
	Game.world.hud.message("Vesk: Tropa, ao telhado!")


# ---------------------------------------------------------------- âncora

func _launch_anchor() -> void:
	anchor_out = true
	anchor_hp = 3
	anchor_pos = _gondola() + Vector2(0, 10) - global_position
	anchor_vy = 60.0
	anchor_life = 7.0
	var cs: CollisionShape2D = get_node("AnchorShape")
	cs.set_deferred("disabled", false)
	Sfx.play("lift", -2.0, 0.6)
	Game.world.hud.message("A âncora! Corte-a a rebites.")


func _process_anchor(delta: float, p) -> void:
	if not anchor_out:
		return
	var cs: CollisionShape2D = get_node("AnchorShape")
	var ground := floor_y - global_position.y - 9.0
	if anchor_pos.y < ground:
		anchor_vy = minf(anchor_vy + 600.0 * delta, 400.0)
		anchor_pos.y = minf(anchor_pos.y + anchor_vy * delta, ground)
		if anchor_pos.y >= ground:
			Sfx.play("crash", -6.0, 1.3)
			Fx.dust(get_parent(), global_position + anchor_pos + Vector2(0, 9), 12)
			Game.world.shake(3.0)
	else:
		# Arrastada pelo telhado atrás do dirigível.
		anchor_pos.x = move_toward(anchor_pos.x, 0.0, 30.0 * delta)
		if fmod(anim, 0.1) < delta:
			Fx.sparks(get_parent(), global_position + anchor_pos + Vector2(0, 9))
		if p != null and not p.is_dead():
			var r := Rect2(global_position + anchor_pos - Vector2(9, 9), Vector2(18, 18))
			if r.intersects(p.hitbox()):
				p.hurt(1, "crush")
	cs.position = anchor_pos + Vector2(0, -4)
	# Recolhe depois de um tempo.
	anchor_life -= delta
	if anchor_life <= 0.0:
		_retract_anchor()


func on_rivet_hit(_dir: int) -> void:
	if not anchor_out or not is_alive():
		Sfx.play("clang", -6.0)
		return
	anchor_hp -= 1
	Sfx.play("clang", -2.0, 1.2)
	Fx.sparks(get_parent(), global_position + anchor_pos + Vector2(0, -8))
	if anchor_hp <= 0:
		_retract_anchor()
		Game.world.hud.message("Cabo cortado! O Vigília perdeu o prumo.")
		_damage(ANCHOR_DMG)
		if is_alive():
			state = S.STAGGER
			t = 1.6


func _retract_anchor() -> void:
	anchor_out = false
	anchor_cd = 6.0
	var cs: CollisionShape2D = get_node("AnchorShape")
	cs.set_deferred("disabled", true)


# ---------------------------------------------------------------- dano

func harpoon_hit(at: Vector2) -> void:
	if not is_alive() or state == S.INTRO or state == S.IDLE:
		return
	harpoons.append(at - global_position)
	if harpoons.size() > 6:
		harpoons.pop_front()
	Fx.burst(get_parent(), at, Color(1.0, 0.7, 0.3), 16, 160.0, 0.4)
	Fx.steam_puff(get_parent(), at, 10)
	Sfx.play("crash", -2.0, 1.1)
	Game.world.hud.message("Arpão no casco!")
	_damage(HARPOON_DMG)
	if is_alive() and state != S.STAGGER:
		if anchor_out:
			_retract_anchor()
		state = S.STAGGER
		t = 1.2


func steam_hit(_n: int) -> void:
	pass


func blast_hit(_n: int, _from: Vector2 = Vector2.INF) -> void:
	pass


func _damage(n: int) -> void:
	hp = maxi(0, hp - n)
	flash = 0.2
	Game.world.shake(5.0)
	Game.world.hitstop(0.06)
	Sfx.play("hit", -2.0, 0.6)
	if hp <= 0:
		_die()
		return
	if not phase2 and hp <= PHASE2_HP:
		phase2 = true
		Game.world.hud.message("Vesk: Motores no máximo! Desçam o Vigília!")
		Sfx.play("explosion", -4.0, 0.7)
		Fx.fire(get_parent(), global_position + Vector2(-30, 0), 24)


func _die() -> void:
	state = S.DYING
	t = 3.2
	boom_t = 0.0
	collision_layer = 0
	if anchor_out:
		_retract_anchor()
	Game.world.hud.message("Vesk: Estamos caindo! Abandonar a...")
	for g in guards_dropped:
		if is_instance_valid(g) and g.is_alive():
			g.blast_hit(2, global_position)


func _process_dying(delta: float) -> void:
	t -= delta
	boom_t -= delta
	rotation = lerpf(rotation, 0.35 * facing, delta * 1.5)
	position.x += facing * 40.0 * delta
	if t < 2.0:
		z_index = -8
		position.y += (2.0 - t) * 120.0 * delta
	if boom_t <= 0.0:
		boom_t = 0.18
		var pos := global_position + Vector2(randf_range(-60, 60), randf_range(-20, 30))
		Fx.fire(get_parent(), pos, 18)
		Fx.smoke(get_parent(), pos, 8)
		Fx.sparks(get_parent(), pos)
		Sfx.play("explosion", -8.0, randf_range(0.8, 1.2))
		Game.world.shake(3.0)
	if t <= 2.2 and t + delta > 2.2:
		# Tripulação jogada para fora da gôndola.
		var b = Game.world.blood
		if b:
			var g := _gondola()
			b.burst(g, 60, 280.0)
			b.gibs(g, 10, [Color("8a1e1e"), Color("5e1414"), Color(0.55, 0.08, 0.08), Color("3e3434")], true, 260.0)
			b.gibs(g, 10, [IRON, COPPER, COPPER_D, RED], false, 300.0)
	if t <= 0.0:
		state = S.DEAD
		visible = false
		var c := Vector2(global_position.x, floor_y + 30.0)
		Fx.burst(get_parent(), c, Color(1.0, 0.7, 0.3), 50, 320.0, 0.7, Vector2(0, 200), 3.0)
		Fx.fire(get_parent(), c, 50)
		Fx.smoke(get_parent(), c + Vector2(0, -20), 30)
		Sfx.play("crash", 0.0, 0.5)
		Sfx.play("explosion", 0.0, 0.6)
		Game.world.shake(12.0)
		if exit_lift != null:
			exit_lift.locked = false
		await get_tree().create_timer(1.4).timeout
		if Game.world:
			bar_visible = false
			Game.world.hud.message("O Vigília caiu. O elevador do arquivo está livre.")


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	# Âncora e cabo
	if anchor_out:
		var g := Vector2(0, 46)
		draw_line(g, anchor_pos + Vector2(0, -8), Color("8a8f96"), 1.5)
		var a := anchor_pos
		draw_line(a + Vector2(0, -9), a + Vector2(0, 6), IRON, 3.0)
		draw_arc(a + Vector2(0, 1), 8.0, 0.2, PI - 0.2, 10, IRON, 3.0)
		draw_rect(Rect2(a + Vector2(-5, -10), Vector2(10, 3)), COPPER_D)
		for i in anchor_hp:
			draw_circle(a + Vector2(-4 + i * 4, -14), 1.2, Color(1.0, 0.8, 0.3))
	var hot := flash > 0.0
	# Feixe do holofote
	if state == S.SEARCH or state == S.BURST:
		var gp := Vector2(0, 46)
		var d := _beam_dir()
		var col := Color(1.0, 0.95, 0.75, 0.07) if not beam_locked else Color(1.0, 0.3, 0.2, 0.1)
		for i in 5:
			var k := (i + 1) / 5.0
			draw_colored_polygon(PackedVector2Array([gp, gp + d.rotated(-BEAM_HALF) * BEAM_LEN * k, gp + d.rotated(BEAM_HALF) * BEAM_LEN * k]), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	# Hélices traseiras
	var pw := absf(sin(prop)) * 14.0
	draw_line(Vector2(-80, -pw), Vector2(-80, pw), Color(0.8, 0.8, 0.8, 0.5), 2.0)
	draw_rect(Rect2(-82, -3, 8, 6), IRON)
	# Lemes
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -6), Vector2(-78, -24), Vector2(-72, -6)]), RED)
	draw_colored_polygon(PackedVector2Array([Vector2(-60, 6), Vector2(-78, 22), Vector2(-72, 6)]), RED)
	# Balão
	var env := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		env.append(Vector2(cos(a) * 70.0, sin(a) * 24.0))
	draw_colored_polygon(env, RED if not hot else Color(1, 0.75, 0.7))
	for i in 5:
		var x := -48.0 + i * 24.0
		var hgt := 24.0 * sqrt(maxf(0.0, 1.0 - (x * x) / 4900.0))
		draw_line(Vector2(x, -hgt), Vector2(x, hgt), RED_L, 1.0)
	draw_line(Vector2(-68, 0), Vector2(68, 0), Color(0, 0, 0, 0.2), 1.0)
	draw_arc(Vector2(0, -2), 70.0, PI + 0.4, TAU - 0.4, 16, Color(1, 1, 1, 0.08), 3.0)
	# Emblema do Diretório (olho dentro de engrenagem)
	draw_circle(Vector2(8, -2), 9.0, Color("2a1414"))
	draw_arc(Vector2(8, -2), 9.0, 0, TAU, 16, COPPER, 1.5)
	draw_circle(Vector2(8, -2), 3.0, Color("ffd27a"))
	# Arpões cravados
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for h in harpoons:
		var hp_local: Vector2 = h
		draw_line(hp_local, hp_local + Vector2(0, 90), Color(0.65, 0.62, 0.58, 0.6), 1.0)
		draw_rect(Rect2(hp_local + Vector2(-1.5, -4), Vector2(3, 8)), Color("d0d0d0"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	# Gôndola
	draw_line(Vector2(-20, 20), Vector2(-16, 30), IRON, 1.5)
	draw_line(Vector2(20, 20), Vector2(16, 30), IRON, 1.5)
	draw_rect(Rect2(-30, 30, 60, 16), IRON)
	draw_rect(Rect2(-30, 30, 60, 3), COPPER)
	for i in 5:
		var lit := 0.55 + 0.35 * sin(anim * 2.0 + i)
		draw_rect(Rect2(-24 + i * 10, 35, 6, 5), Color(1.0, 0.8, 0.4, lit))
	draw_colored_polygon(PackedVector2Array([Vector2(30, 30), Vector2(40, 38), Vector2(30, 46)]), IRON)
	# Holofote sob a gôndola
	draw_circle(Vector2(0, 47), 3.5, Color("4a4240"))
	draw_circle(Vector2(0, 48), 2.0, Color(1.0, 0.95, 0.7) if state != S.BURST else Color(1.0, 0.3, 0.2))
	# Fogo nos motores (segunda metade)
	if phase2:
		for i in 3:
			var fx := -50.0 + i * 30.0
			draw_circle(Vector2(fx, -18 + sin(anim * 12.0 + i) * 2.0), 4.0, Color(1.0, 0.5, 0.15, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
