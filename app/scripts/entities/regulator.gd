extends Area2D
## Chefão final (Ato 3): o Regulador, o relógio-mestre da Torre, comandado
## pelo Diretor Halvard Maar de dentro de uma cabine de vidro.
## Origem = centro da arena (no chão).
##
## Ataques: o pêndulo varre o centro da arena (agachar, rolar ou pular),
## chuva de engrenagens com alvo no chão e, na segunda metade, jatos de vapor
## no piso e autômatos que saem das escotilhas.
## Dano: puxar um freio (A) quando a lâmina chega ao seu lado trava o pêndulo
## (4) e faz a cabine descer; aí o núcleo fica exposto a rebites (até 4 por
## vez) e a cargas de vapor (3).

const GearScript := preload("res://scripts/entities/falling_gear.gd")
const AutomatonScript := preload("res://scripts/entities/automaton.gd")
const Fx := preload("res://scripts/fx.gd")
const Light := preload("res://scripts/fx/light.gd")

enum S { IDLE, INTRO, WAIT, SWING, GEARS, VENTS, SUMMON, EXPOSED, RISE, DYING, DEAD }

const MAX_HP := 24
const PHASE2_HP := 12
const BRAKE_DMG := 4
const CORE_HITS := 4
const AMP := 0.9
const LATCH := 1.05
const EXPOSE_TIME := 4.6

const BRASS := Color("a07a38")
const BRASS_D := Color("6e5428")
const BRASS_L := Color("e0b860")
const IRON := Color("2e2826")
const GLASS := Color(0.55, 0.8, 0.85, 0.22)

const INTRO_LINES := [
	["Diretor Maar", "A engenheira das Caldeiras. Você trouxe meu livro de válvulas até a minha porta. Que gentileza."],
	["Sera", "Vinte e três pessoas morreram na Caldeira Sul. Por quê?"],
	["Diretor Maar", "Pressão, senhorita Vael. Uma cidade é uma caldeira: de tempos em tempos é preciso aliviar. As Caldeiras estavam se organizando. Agora estão de luto — e quietas."],
	["Sera", "Então eu vou abrir as válvulas desta Torre."],
	["Diretor Maar", "O Regulador marca o tempo de Ironveil há cem anos. Hoje ele marca o seu fim."],
]
const RETRY_LINES := [
	["Diretor Maar", "O pêndulo nunca se atrasa, senhorita Vael."],
]

var title := "O REGULADOR · Diretor Halvard Maar"
var state: int = S.IDLE
var hp := MAX_HP
var bar_hp := float(MAX_HP)
var bar_visible := false
var phase2 := false
var arena := Rect2()
var floor_y := 0.0
var pivot := Vector2.ZERO
var length := 200.0
var t := 0.0
var anim := 0.0
var flash := 0.0
var seq_i := 0
# Pêndulo
var pend_ang := LATCH
var pend_mode := "latched"    # latched | swing | jammed | falling
var latch_side := 1.0
var swing_t := 0.0
var swing_n := 4
var omega := 2.2
var pend_vel := 0.0
var blade_cd := 0.0
var gear_t := 0.0
# Cabine
var booth_hi := 0.0
var booth_lo := 0.0
var booth_y := 0.0
var core_hits := 0
var glass_cracks: Array = []
# Jatos de vapor no piso: [x, t]
var vents: Array = []
var summoned: Array = []
var dead_t := 0.0
var exit_lift = null
var core_light = null


func setup(pos: Vector2, screen_rect: Rect2, floor_world_y: float) -> void:
	arena = screen_rect
	floor_y = floor_world_y
	position = Vector2(arena.get_center().x, floor_y)
	pivot = Vector2(arena.get_center().x, arena.position.y + 34.0)
	length = floor_y - 26.0 - pivot.y
	booth_hi = arena.position.y + 70.0
	booth_lo = floor_y - 24.0
	booth_y = booth_hi
	z_index = 2


func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	cs.name = "CoreShape"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 26)
	cs.shape = shape
	cs.disabled = true
	add_child(cs)
	core_light = Light.make(self, Vector2.ZERO, Color(1.0, 0.55, 0.2), 80.0, 0.0, 0.25)


func is_alive() -> bool:
	return state != S.DYING and state != S.DEAD


func hp_ratio() -> float:
	return bar_hp / float(MAX_HP)


func hp_real() -> float:
	return float(hp) / float(MAX_HP)


func booth_center() -> Vector2:
	return Vector2(pivot.x, booth_y)


func core_pos() -> Vector2:
	return booth_center() + Vector2(0, 6)


func center() -> Vector2:
	return core_pos()


func rect() -> Rect2:
	return Rect2(booth_center() - Vector2(36, 26), Vector2(72, 52))


func blade_pos() -> Vector2:
	return pivot + Vector2(sin(pend_ang), cos(pend_ang)) * length


func blade_rect() -> Rect2:
	var b := blade_pos()
	return Rect2(b - Vector2(22, 6), Vector2(44, 12))


func _player():
	return Game.world.player if Game.world else null


# ---------------------------------------------------------------- lógica

func _physics_process(delta: float) -> void:
	anim += delta
	flash = maxf(flash - delta, 0.0)
	blade_cd = maxf(blade_cd - delta, 0.0)
	bar_hp = move_toward(bar_hp, float(hp), delta * 14.0)
	if state == S.DEAD:
		_process_pendulum(delta)
		queue_redraw()
		return
	if state == S.DYING:
		_process_dying(delta)
		_process_pendulum(delta)
		queue_redraw()
		return
	var w = Game.world
	if w == null or not w.is_active(global_position + Vector2(0, -10)):
		return
	var p = _player()
	_process_pendulum(delta)
	_process_vents(delta, p)
	match state:
		S.IDLE:
			if p != null and not p.is_dead() and w.is_active(p.global_position) and p.is_on_floor() and not w.cutscene:
				state = S.INTRO
				Sfx.play("alert", -2.0, 0.5)
				var seen := bool(Game.cp().get("boss_seen", false))
				w.dialog.start(RETRY_LINES if seen else INTRO_LINES, _on_intro_done)
		S.INTRO:
			pass
		S.WAIT:
			t -= delta
			if t <= 0.0:
				_next_attack(p)
		S.SWING:
			# Durante a varredura o Diretor ainda derruba engrenagens em Sera.
			gear_t -= delta
			if gear_t <= 0.0 and p != null:
				gear_t = 1.0 if phase2 else 1.4
				_drop_gear(p.global_position.x + randf_range(-20, 20), 0.0)
			if pend_mode == "latched":
				_to_wait(1.2)
		S.GEARS:
			t -= delta
			if t <= 0.0:
				_to_wait(1.6)
		S.VENTS:
			t -= delta
			if t <= 0.0:
				_to_wait(1.2)
		S.SUMMON:
			t -= delta
			if t <= 0.0:
				_summon()
				_to_wait(1.4)
		S.EXPOSED:
			booth_y = move_toward(booth_y, booth_lo, delta * 260.0)
			_update_core()
			t -= delta
			if t <= 0.0 or core_hits >= CORE_HITS:
				_close_core()
		S.RISE:
			booth_y = move_toward(booth_y, booth_hi, delta * 140.0)
			_update_core()
			if booth_y <= booth_hi + 0.5:
				pend_mode = "latched"
				latch_side = signf(pend_ang) if pend_ang != 0.0 else 1.0
				_to_wait(1.0)
	queue_redraw()


func _on_intro_done() -> void:
	Game.cp()["boss_seen"] = true
	if not Game.replay:
		Game.write_save()
	bar_visible = true
	Game.world.hud.message("Maar: Deem corda ao Regulador.")
	_to_wait(1.4)


func _to_wait(time: float) -> void:
	state = S.WAIT
	t = time * (0.7 if phase2 else 1.0)


func _next_attack(p) -> void:
	var seq := ["swing", "gears", "swing", "gears"]
	if phase2:
		seq = ["swing", "vents", "summon", "swing", "gears", "vents"]
	var a: String = seq[seq_i % seq.size()]
	seq_i += 1
	if a == "summon":
		var alive := 0
		for g in summoned:
			if is_instance_valid(g) and g.is_alive():
				alive += 1
		if alive >= 2:
			a = "gears"
	match a:
		"swing":
			state = S.SWING
			pend_mode = "swing"
			swing_t = 0.0
			swing_n = 6 if phase2 else 4
			omega = 2.7 if phase2 else 2.15
			gear_t = 1.0
			Sfx.play("lever", -2.0, 0.5)
			Sfx.play("clang", -6.0, 0.5)
			Game.world.hud.message("O Regulador soltou o pêndulo!")
		"gears":
			state = S.GEARS
			var n := 6 if phase2 else 4
			var px: float = p.global_position.x if p != null else pivot.x
			for i in n:
				var x := px + randf_range(-140, 140) if i > 0 else px
				x = clampf(x, arena.position.x + 30.0, arena.end.x - 30.0)
				_drop_gear(x, i * 0.18)
			t = 1.6 + n * 0.18
			Sfx.play("spark", -4.0, 0.6)
		"vents":
			state = S.VENTS
			var px: float = p.global_position.x if p != null else pivot.x
			var xs := [px]
			for i in 3:
				xs.append(clampf(px + randf_range(-200, 200), arena.position.x + 30.0, arena.end.x - 30.0))
			for x in xs:
				vents.append([float(x), 0.0])
			t = 1.8
			Sfx.play("steam", -6.0, 0.6)
		"summon":
			state = S.SUMMON
			t = 0.7
			Sfx.play("door", -4.0, 0.8)


# ---------------------------------------------------------------- pêndulo

func _process_pendulum(delta: float) -> void:
	match pend_mode:
		"latched":
			pend_ang = lerpf(pend_ang, LATCH * latch_side, delta * 4.0)
		"swing":
			swing_t += delta
			var prev := pend_ang
			pend_ang = latch_side * AMP * cos(omega * swing_t)
			pend_vel = (pend_ang - prev) / maxf(delta, 0.001)
			if swing_t >= swing_n * PI / omega:
				pend_mode = "latched"
				latch_side = latch_side * (1.0 if swing_n % 2 == 0 else -1.0)
			if absf(pend_ang) < 0.12 and absf(pend_vel) > 0.5 and fmod(anim, 0.25) < delta:
				Sfx.play("steam", -14.0, 1.8)
			_blade_hits()
		"jammed":
			pend_ang = lerpf(pend_ang, signf(pend_ang) * (AMP + 0.06), delta * 6.0)
		"falling":
			pend_vel += delta * 3.0 * signf(pend_ang if pend_ang != 0.0 else 1.0)
			pend_ang += pend_vel * delta
			if absf(pend_ang) > 1.45:
				pend_mode = "gone"
				Sfx.play("crash", -2.0, 0.5)
				Fx.sparks(get_parent(), blade_pos())
				if Game.world:
					Game.world.shake(6.0)


func _blade_hits() -> void:
	var r := blade_rect()
	var p = _player()
	if p != null and not p.is_dead() and blade_cd <= 0.0 and r.intersects(p.hitbox()):
		p.hurt(1, "blade")
		blade_cd = 0.8
		if Game.world.blood:
			Game.world.blood.spray(p.center(), Vector2(signf(pend_vel), -0.3), 20, 260.0, 0.5, 1.4)
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and r.intersects(g.rect()):
			g.crush()


## O freio deste lado pegaria a lâmina agora?
func brake_ready(side: int) -> bool:
	return state == S.SWING and pend_mode == "swing" and signf(pend_ang) == float(side) and absf(pend_ang) > AMP * 0.72


func try_brake(side: int) -> bool:
	if not brake_ready(side):
		Game.world.hud.message("O freio range, mas não pega.")
		return false
	pend_mode = "jammed"
	state = S.EXPOSED
	t = EXPOSE_TIME
	core_hits = 0
	Sfx.play("crash", -2.0, 0.6)
	Sfx.play("steam", -2.0, 0.7)
	Fx.sparks(get_parent(), blade_pos())
	Fx.steam_puff(get_parent(), pivot + Vector2(0, 10), 16)
	Game.world.shake(6.0)
	Game.world.hud.message("Maar: O que... o pêndulo travou!")
	_damage(BRAKE_DMG)
	return true


func _update_core() -> void:
	if core_light != null:
		core_light.position = core_pos() + Vector2(0, 12) - global_position
		core_light.base_energy = 1.4 if state == S.EXPOSED and core_hits < CORE_HITS else 0.0
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.position = core_pos() - global_position
	var open := state == S.EXPOSED and booth_y >= booth_lo - 4.0 and core_hits < CORE_HITS
	if cs.disabled == open:
		cs.set_deferred("disabled", not open)


func _close_core() -> void:
	state = S.RISE
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", true)
	Sfx.play("lift", -4.0, 0.7)
	Game.world.hud.message("Maar: Blindagem! Subam a cabine!")


# ---------------------------------------------------------------- ataques

func _drop_gear(x: float, delay: float) -> void:
	var g = GearScript.new()
	g.setup(x, arena.position.y + 30.0, floor_y, delay)
	get_parent().add_child(g)


func _process_vents(delta: float, p) -> void:
	var i := 0
	while i < vents.size():
		var v: Array = vents[i]
		v[1] = float(v[1]) + delta
		var vt: float = v[1]
		if vt > 0.8 and vt - delta <= 0.8:
			Sfx.play("steam", -6.0, 1.0)
		if vt > 0.8 and vt < 1.5:
			if fmod(vt, 0.05) < delta:
				Fx.steam_puff(get_parent(), Vector2(float(v[0]), floor_y - 4.0), 3)
			var r := Rect2(Vector2(float(v[0]) - 9.0, floor_y - 64.0), Vector2(18.0, 64.0))
			if p != null and not p.is_dead() and r.intersects(p.hitbox()):
				p.hurt(1, "steam")
			for g in get_tree().get_nodes_in_group("guard"):
				if g.is_alive() and r.intersects(g.rect()):
					g.steam_hit(1)
		if vt > 1.6:
			vents.remove_at(i)
		else:
			i += 1


func _summon() -> void:
	var p = _player()
	var px: float = p.global_position.x if p != null else pivot.x
	var x := arena.position.x + 50.0 if px > pivot.x else arena.end.x - 50.0
	var a = AutomatonScript.new()
	a.position = Vector2(x, floor_y - 0.5)
	a.facing = 1 if x < pivot.x else -1
	get_parent().add_child(a)
	summoned.append(a)
	Fx.steam_puff(get_parent(), Vector2(x, floor_y - 16.0), 14)
	Game.world.hud.message("Maar: Autômatos, recolham a engenheira!")


# ---------------------------------------------------------------- dano

func on_rivet_hit(_dir: int) -> void:
	if state != S.EXPOSED or core_hits >= CORE_HITS or not is_alive():
		Sfx.play("clang", -6.0)
		return
	core_hits += 1
	Sfx.play("clang", -2.0, 1.4)
	Fx.sparks(get_parent(), core_pos())
	glass_cracks.append(Vector2(randf_range(-26, 26), randf_range(-20, 4)))
	_damage(1)
	if is_alive() and core_hits >= CORE_HITS:
		_close_core()


func steam_hit(_n: int) -> void:
	pass


func blast_hit(_n: int, _from: Vector2 = Vector2.INF) -> void:
	if state != S.EXPOSED or not is_alive():
		return
	core_hits = CORE_HITS
	glass_cracks.append(Vector2(randf_range(-20, 20), randf_range(-16, 0)))
	_damage(3)
	if is_alive():
		_close_core()


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
		Game.world.hud.message("Maar: Acelerem o Regulador! Pressão total!")
		Sfx.play("explosion", -4.0, 0.6)
		Fx.steam_puff(get_parent(), pivot + Vector2(0, 20), 24)


func _die() -> void:
	state = S.DYING
	t = 3.0
	dead_t = 0.0
	collision_layer = 0
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", true)
	pend_mode = "falling"
	pend_vel = 0.0
	vents.clear()
	Game.world.hud.message("Maar: Tolinha... o relógio nunca foi meu. Pergunte ao Conselho... lá embaixo, na Fornalha...")
	for g in summoned:
		if is_instance_valid(g) and g.is_alive():
			g.blast_hit(2, booth_center())


func _process_dying(delta: float) -> void:
	t -= delta
	dead_t += delta
	booth_y = move_toward(booth_y, booth_lo, delta * 80.0)
	if fmod(dead_t, 0.2) < delta:
		var pos := booth_center() + Vector2(randf_range(-40, 40), randf_range(-30, 20))
		Fx.sparks(get_parent(), pos)
		Fx.steam_puff(get_parent(), pos, 6)
		Sfx.play("explosion", -10.0, randf_range(0.8, 1.2))
		Game.world.shake(3.0)
	if t <= 0.0:
		state = S.DEAD
		var c := booth_center()
		# A cabine se estilhaça; o Diretor não sai inteiro.
		Sfx.play("crash", 0.0, 0.6)
		Sfx.play("explosion", 0.0, 0.7)
		Game.world.shake(12.0)
		Game.world.hitstop(0.12)
		Fx.burst(get_parent(), c, Color(0.8, 0.95, 1.0), 40, 300.0, 0.6, Vector2(0, 400), 1.5)
		Fx.steam_puff(get_parent(), c, 30)
		var b = Game.world.blood
		if b:
			b.burst(c, 90, 340.0)
			b.spray(c, Vector2.LEFT, 40, 360.0, 0.5, 1.8)
			b.spray(c, Vector2.RIGHT, 40, 360.0, 0.5, 1.8)
			b.gibs(c, 16, [Color("4a5248"), Color("2a2523"), Color(0.55, 0.08, 0.08), Color("5e1414"), Color("e8c6a0")], true, 320.0)
			b.gibs(c, 14, [BRASS, BRASS_D, IRON, Color(0.7, 0.9, 0.95)], false, 340.0)
			b.pool(Vector2(c.x, floor_y - 2.0), 26.0)
		if exit_lift != null:
			exit_lift.locked = false
		Game.world.on_boss_defeated(Vector2(pivot.x, floor_y - 22.0))
		await get_tree().create_timer(1.6).timeout
		if Game.world:
			bar_visible = false
			Game.world.hud.message("O Regulador parou. O elevador para o alto da Torre está livre.")


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	draw_set_transform(-global_position, 0.0, Vector2.ONE)
	_draw_clock()
	_draw_pendulum()
	if state != S.DEAD:
		_draw_booth()
	else:
		_draw_wreck()
	for v in vents:
		var vt: float = v[1]
		var x: float = v[0]
		if vt < 0.8:
			var k := 0.5 + 0.5 * sin(vt * 30.0)
			draw_rect(Rect2(x - 8, floor_y - 3, 16, 3), Color(1.0, 0.6, 0.3, 0.3 + 0.3 * k))
		elif vt < 1.5:
			for i in 6:
				var yy := floor_y - i * 11.0
				draw_circle(Vector2(x + sin(anim * 20.0 + i) * 2.0, yy - 5.0), 7.0 + i, Color(0.95, 0.95, 0.95, 0.25 - i * 0.03))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_clock() -> void:
	# Mostrador gigante atrás do pivô
	var c := pivot
	draw_circle(c, 52.0, Color("1e1a18"))
	draw_arc(c, 52.0, 0, TAU, 48, BRASS_D, 3.0)
	draw_arc(c, 46.0, 0, TAU, 48, Color(BRASS, 0.5), 1.0)
	for i in 12:
		var a := i * TAU / 12.0
		draw_line(c + Vector2.from_angle(a) * 40.0, c + Vector2.from_angle(a) * 46.0, BRASS_L, 2.0)
	var spd := 0.4 if state != S.DEAD else 0.0
	draw_line(c, c + Vector2.from_angle(anim * spd - PI * 0.5) * 34.0, BRASS_L, 2.0)
	draw_line(c, c + Vector2.from_angle(anim * spd / 12.0 - PI * 0.5) * 24.0, BRASS_L, 3.0)
	# Engrenagens girando atrás
	for k in 2:
		var gc := c + Vector2(-70 + k * 140, -6)
		var rot := anim * (0.6 if k == 0 else -0.6) * (0.0 if state == S.DEAD or pend_mode == "jammed" else 1.0)
		draw_circle(gc, 18.0, Color("2a2420"))
		for i in 10:
			var a := rot + i * TAU / 10.0
			draw_line(gc + Vector2.from_angle(a) * 14.0, gc + Vector2.from_angle(a) * 21.0, BRASS_D, 4.0)
		draw_circle(gc, 5.0, BRASS_D)


func _draw_pendulum() -> void:
	if pend_mode == "gone":
		# Lâmina caída no chão, haste partida.
		var side := signf(pend_ang)
		var g := Vector2(pivot.x + side * 200.0, floor_y)
		draw_line(g + Vector2(-side * 60, -4), g + Vector2(0, -4), Color("5a5250"), 4.0)
		draw_colored_polygon(PackedVector2Array([g + Vector2(-22, 0), g + Vector2(22, 0), g + Vector2(14, -10), g + Vector2(-14, -10)]), Color("9a9490"))
		draw_line(pivot, pivot + Vector2(sin(pend_ang), cos(pend_ang)) * 40.0, Color("5a5250"), 4.0)
		return
	var b := blade_pos()
	draw_line(pivot, b, Color("5a5250"), 4.0)
	draw_line(pivot, b, Color("8a8480"), 1.5)
	draw_circle(pivot, 6.0, BRASS)
	draw_circle(pivot, 2.5, IRON)
	# Lâmina em meia-lua
	var dir := (b - pivot).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array()
	for i in 13:
		var k := -1.0 + i / 6.0
		pts.append(b + perp * k * 24.0 + dir * (6.0 - k * k * 9.0))
	for i in 13:
		var k := 1.0 - i / 6.0
		pts.append(b + perp * k * 20.0 + dir * (-2.0 - k * k * 6.0))
	draw_colored_polygon(pts, Color("9a9490"))
	draw_polyline(pts.slice(0, 13), Color("e8e4dc"), 1.0)
	draw_circle(b - dir * 4.0, 5.0, BRASS)
	if pend_mode == "swing" and absf(pend_vel) > 1.0:
		for k in 3:
			var ga := pend_ang - signf(pend_vel) * (k + 1) * 0.06
			var gb := pivot + Vector2(sin(ga), cos(ga)) * length
			draw_circle(gb, 10.0 - k * 2.0, Color(1, 1, 1, 0.05))


func _draw_booth() -> void:
	var c := booth_center()
	var hot := flash > 0.0
	# Correntes até o teto
	for sx in [-30.0, 30.0]:
		var y := arena.position.y
		while y < c.y - 26.0:
			draw_rect(Rect2(Vector2(c.x + sx - 1.5, y), Vector2(3, 6)), Color("3a302a"))
			y += 8.0
	# Cabine
	var r := Rect2(c - Vector2(36, 26), Vector2(72, 52))
	draw_rect(r, IRON)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), BRASS)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), BRASS_D)
	# O Diretor lá dentro (cartola, monóculo, casaco verde-acinzentado)
	var d := c + Vector2(-8, 18)
	var lean := sin(anim * 1.5) * 1.0
	if state == S.EXPOSED or state == S.DYING:
		lean = sin(anim * 9.0) * 2.5
	draw_rect(Rect2(d + Vector2(-6 + lean, -26), Vector2(12, 16)), Color("4a5248"))
	draw_rect(Rect2(d + Vector2(-5 + lean, -12), Vector2(4, 10)), Color("2a2523"))
	draw_rect(Rect2(d + Vector2(1 + lean, -12), Vector2(4, 10)), Color("2a2523"))
	draw_circle(d + Vector2(lean, -30), 4.0, Color("e8c6a0"))
	draw_rect(Rect2(d + Vector2(-4.5 + lean, -38), Vector2(9, 5)), Color("1a1616"))
	draw_rect(Rect2(d + Vector2(-6 + lean, -34), Vector2(12, 1.5)), Color("1a1616"))
	draw_circle(d + Vector2(2 + lean, -30.5), 1.3, Color(1.0, 0.85, 0.4))
	draw_line(d + Vector2(5 + lean, -22), d + Vector2(14, -16), Color("4a5248"), 2.5)
	# Painel de alavancas
	draw_rect(Rect2(c + Vector2(6, -2), Vector2(22, 10)), Color("3a3330"))
	for i in 3:
		draw_line(c + Vector2(10 + i * 7, -2), c + Vector2(10 + i * 7 + sin(anim * 3.0 + i) * 2.0, -8), BRASS_L, 1.5)
	# Vidro com rachaduras
	draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, r.size.y - 10)), GLASS if not hot else Color(1, 0.9, 0.85, 0.4))
	draw_line(r.position + Vector2(10, 8), r.position + Vector2(22, 8), Color(1, 1, 1, 0.3), 1.0)
	for k in glass_cracks:
		var cp: Vector2 = c + k
		for i in 4:
			draw_line(cp, cp + Vector2.from_angle(i * 1.7 + k.x) * 7.0, Color(1, 1, 1, 0.55), 0.8)
	# Núcleo: escotilha embaixo da cabine
	var core := core_pos()
	var open := state == S.EXPOSED and core_hits < CORE_HITS
	draw_circle(core + Vector2(0, 12), 9.0, Color("3a3330"))
	if open:
		var pulse := 0.6 + 0.4 * sin(anim * 10.0)
		draw_circle(core + Vector2(0, 12), 7.0, Color(1.0, 0.55, 0.2, pulse))
		draw_circle(core + Vector2(0, 12), 11.0 + pulse * 2.0, Color(1.0, 0.55, 0.2, 0.15))
		for i in CORE_HITS - core_hits:
			draw_circle(core + Vector2(-6 + i * 4, -2), 1.2, Color(1.0, 0.85, 0.4))
	else:
		draw_circle(core + Vector2(0, 12), 7.0, BRASS_D)
		draw_line(core + Vector2(-5, 12), core + Vector2(5, 12), IRON, 1.5)


func _draw_wreck() -> void:
	var c := Vector2(pivot.x, floor_y)
	draw_rect(Rect2(c + Vector2(-38, -14), Vector2(76, 14)), IRON)
	draw_rect(Rect2(c + Vector2(-38, -14), Vector2(76, 3)), BRASS_D)
	for i in 6:
		draw_line(c + Vector2(-30 + i * 11, -14), c + Vector2(-26 + i * 11, -22 - (i % 3) * 4), Color(0.7, 0.9, 0.95, 0.5), 1.2)
	if fmod(anim, 0.6) < 0.08:
		draw_circle(c + Vector2(randf_range(-30, 30), -10), 1.6, Color(1.0, 0.8, 0.4))
