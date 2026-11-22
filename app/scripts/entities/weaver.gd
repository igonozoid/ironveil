extends Area2D
## Chefão final (Ato 5): o Tecelão, a máquina que tece as placas do Véu de
## Ferro, com o Conselho das Válvulas numa cápsula de vidro no topo.
## Origem = centro da arena, no chão.
##
## Três estágios (36 de vida; muda em 24 e 12). Ataques: lançadeira que cruza
## a arena numa de três alturas (com uma linha de aviso), placas que despencam,
## raios (estágio 2+), autômatos (estágio 2+) e rajadas de vento (estágio 3).
## Depois de cada ataque o "olho" do tear se abre por alguns segundos.
## A cada estágio o Véu se abre um pouco mais e entra luz do sol.

const GearScript := preload("res://scripts/entities/falling_gear.gd")
const AutomatonScript := preload("res://scripts/entities/automaton.gd")
const Fx := preload("res://scripts/fx.gd")
const Light := preload("res://scripts/fx/light.gd")

enum S { IDLE, INTRO, WAIT, SHUTTLE, PLATES, LIGHTNING, SUMMON, OPEN, DYING, DEAD }

const BASE_HP := 36
## Vida máxima nesta dificuldade (definida em _ready).
var MAX_HP := 36
const OPEN_TIME := 3.6
const CORE_HITS := 6
const SHUTTLE_SPEED := 430.0

const IRON := Color("2a2830")
const IRON_L := Color("4a4652")
const BRASS := Color("a07a38")
const BRASS_L := Color("e0b860")

const INTRO_LINES := [
	["Conselho", "Sera Vael. A engenheira que apagou a Fornalha."],
	["Sera", "Sem pressão, o Véu não fica de pé. Vocês acabaram, todos vocês."],
	["Conselho", "Lá fora não há nada para essa gente. Por isso tecemos o Véu: para que nunca precisem saber."],
	["Sera", "Então que eles vejam com os próprios olhos."],
	["Conselho", "Tecelão. Feche o céu."],
]
const RETRY_LINES := [
	["Conselho", "O Véu sempre se fecha de novo."],
]

var title := "O TECELÃO · O Conselho das Válvulas"
var state: int = S.IDLE
var hp := MAX_HP
var bar_hp := float(MAX_HP)
var bar_visible := false
var phase2 := false
var stage := 1
var arena := Rect2()
var floor_y := 0.0
var t := 0.0
var anim := 0.0
var flash := 0.0
var seq_i := 0
var core_hits := 0
var open_k := 0.0
# Lançadeira
var sh_y := 0.0
var sh_x := 0.0
var sh_dir := 1
var sh_warn := 0.0
var sh_active := false
var sh_hit := false
# Raios: [x, tempo]
var bolts: Array = []
var summoned: Array = []
var exit_lift = null
var sun = null
var veil_open := 0.0
var dead_t := 0.0


func setup(_pos: Vector2, screen_rect: Rect2, floor_world_y: float) -> void:
	arena = screen_rect
	floor_y = floor_world_y
	position = Vector2(arena.get_center().x, floor_y)
	z_index = 1


func _ready() -> void:
	MAX_HP = Game.boss_hp(BASE_HP)
	hp = MAX_HP
	bar_hp = float(MAX_HP)
	add_to_group("boss")
	add_to_group("enemy")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	cs.name = "CoreShape"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	cs.shape = shape
	cs.position = core_pos() - position
	cs.disabled = true
	add_child(cs)
	sun = Light.make(self, Vector2(0, arena.position.y - floor_y + 30.0), Color(1.0, 0.92, 0.7), 260.0, 0.0)


func is_alive() -> bool:
	return state != S.DYING and state != S.DEAD


func hp_ratio() -> float:
	return bar_hp / float(MAX_HP)


func hp_real() -> float:
	return float(hp) / float(MAX_HP)


func core_pos() -> Vector2:
	return Vector2(arena.get_center().x, arena.position.y + 150.0)


func center() -> Vector2:
	return core_pos()


func rect() -> Rect2:
	return Rect2(core_pos() - Vector2(24, 24), Vector2(48, 48))


func _player():
	return Game.world.player if Game.world else null


# ---------------------------------------------------------------- lógica

func _physics_process(delta: float) -> void:
	anim += delta
	flash = maxf(flash - delta, 0.0)
	bar_hp = move_toward(bar_hp, float(hp), delta * 14.0)
	veil_open = move_toward(veil_open, float(stage - 1) / 3.0 + (1.0 if state == S.DEAD or state == S.DYING else 0.0), delta * 0.3)
	if sun != null:
		sun.base_energy = veil_open * 1.6
	if state == S.DEAD:
		queue_redraw()
		return
	if state == S.DYING:
		_process_dying(delta)
		queue_redraw()
		return
	var w = Game.world
	if w == null or not w.is_active(global_position + Vector2(0, -10)):
		return
	var p = _player()
	_process_shuttle(delta, p)
	_process_bolts(delta, p)
	open_k = move_toward(open_k, 1.0 if state == S.OPEN else 0.0, delta * 4.0)
	match state:
		S.IDLE:
			if p != null and not p.is_dead() and w.is_active(p.global_position) and p.is_on_floor() and not w.cutscene:
				state = S.INTRO
				Sfx.play("alert", -2.0, 0.4)
				var seen := bool(Game.cp().get("boss_seen", false))
				w.dialog.start(RETRY_LINES if seen else INTRO_LINES, _on_intro_done)
		S.INTRO:
			pass
		S.WAIT:
			t -= delta
			if t <= 0.0:
				_next_attack(p)
		S.SHUTTLE:
			if not sh_active and sh_warn <= 0.0:
				_open()
		S.PLATES, S.LIGHTNING:
			t -= delta
			if t <= 0.0 and bolts.is_empty():
				_open()
		S.SUMMON:
			t -= delta
			if t <= 0.0:
				_summon()
				_open()
		S.OPEN:
			t -= delta
			if t <= 0.0 or core_hits >= CORE_HITS:
				_close()
	queue_redraw()


func _on_intro_done() -> void:
	Game.cp()["boss_seen"] = true
	if not Game.replay:
		Game.write_save()
	bar_visible = true
	_to_wait(1.4)


func _to_wait(time: float) -> void:
	state = S.WAIT
	t = time * (1.0 - 0.15 * (stage - 1))


func _next_attack(p) -> void:
	var seq := ["shuttle", "plates", "shuttle"]
	if stage == 2:
		seq = ["shuttle", "lightning", "plates", "summon", "shuttle"]
	elif stage >= 3:
		seq = ["shuttle", "lightning", "shuttle", "summon", "plates", "lightning"]
	var a: String = seq[seq_i % seq.size()]
	seq_i += 1
	if a == "summon":
		var alive := 0
		for g in summoned:
			if is_instance_valid(g) and g.is_alive():
				alive += 1
		if alive >= 2:
			a = "plates"
	match a:
		"shuttle":
			state = S.SHUTTLE
			_launch_shuttle(p)
		"plates":
			state = S.PLATES
			var n := 3 + stage
			var px: float = p.global_position.x if p != null else position.x
			for i in n:
				var x := px if i == 0 else px + randf_range(-170, 170)
				x = clampf(x, arena.position.x + 30.0, arena.end.x - 30.0)
				var gr = GearScript.new()
				gr.setup(x, arena.position.y + 40.0, floor_y, i * 0.15)
				get_parent().add_child(gr)
			t = 1.4 + n * 0.15
			Sfx.play("clang", -2.0, 0.5)
		"lightning":
			state = S.LIGHTNING
			var px2: float = p.global_position.x if p != null else position.x
			var xs := [px2]
			for i in stage:
				xs.append(clampf(px2 + randf_range(-200, 200), arena.position.x + 20.0, arena.end.x - 20.0))
			for x in xs:
				bolts.append([float(x), 0.0])
			t = 1.6
			Sfx.play("spark", 0.0, 0.5)
		"summon":
			state = S.SUMMON
			t = 0.6
			Sfx.play("door", -4.0, 0.7)


func _launch_shuttle(p) -> void:
	# Três alturas: rente ao chão (pule), na altura do peito (agache/role)
	# ou na altura das passarelas (desça).
	var options := [floor_y - 7.0, floor_y - 22.0, floor_y - 128.0]
	var pick := randi() % 3
	if p != null and p.global_position.y < floor_y - 60.0:
		pick = 2
	sh_y = options[pick]
	sh_dir = 1 if randf() < 0.5 else -1
	sh_x = arena.position.x - 30.0 if sh_dir > 0 else arena.end.x + 30.0
	sh_warn = 0.85 - 0.12 * (stage - 1)
	sh_active = false
	sh_hit = false
	Sfx.play("lever", -2.0, 1.4)


func _process_shuttle(delta: float, p) -> void:
	if sh_warn > 0.0:
		sh_warn -= delta
		if sh_warn <= 0.0:
			sh_active = true
			Sfx.play("grapple", 0.0, 0.6)
		return
	if not sh_active:
		return
	sh_x += sh_dir * SHUTTLE_SPEED * delta
	var r := Rect2(Vector2(sh_x - 22.0, sh_y - 6.0), Vector2(44.0, 12.0))
	if p != null and not p.is_dead() and not sh_hit and r.intersects(p.hitbox()):
		sh_hit = true
		p.hurt(1, "blade")
		if Game.world.blood:
			Game.world.blood.spray(p.center(), Vector2(sh_dir, -0.3), 20, 260.0, 0.5, 1.4)
	for g in get_tree().get_nodes_in_group("guard"):
		if g.is_alive() and r.intersects(g.rect()):
			g.crush()
	if fmod(anim, 0.04) < delta:
		Fx.sparks(get_parent(), Vector2(sh_x - sh_dir * 20.0, sh_y))
	if (sh_dir > 0 and sh_x > arena.end.x + 40.0) or (sh_dir < 0 and sh_x < arena.position.x - 40.0):
		sh_active = false


func _process_bolts(delta: float, p) -> void:
	var i := 0
	while i < bolts.size():
		var b: Array = bolts[i]
		b[1] = float(b[1]) + delta
		var bt: float = b[1]
		if bt >= 1.0 and bt - delta < 1.0:
			var x: float = b[0]
			Sfx.play("explosion", -2.0, 1.6)
			Game.world.shake(5.0)
			Light.make(get_parent(), Vector2(x, floor_y - 120.0), Color(0.75, 0.85, 1.0), 220.0, 3.0, 0.0, 0.25)
			Fx.sparks(get_parent(), Vector2(x, floor_y))
			var col := Rect2(Vector2(x - 10.0, arena.position.y), Vector2(20.0, floor_y - arena.position.y))
			if p != null and not p.is_dead() and col.intersects(p.hitbox()):
				p.hurt(1, "shock")
			for g in get_tree().get_nodes_in_group("guard"):
				if g.is_alive() and col.intersects(g.rect()):
					g.blast_hit(2, Vector2(x, g.global_position.y - 15.0))
		if bt > 1.25:
			bolts.remove_at(i)
		else:
			i += 1


func _summon() -> void:
	var p = _player()
	var px: float = p.global_position.x if p != null else position.x
	var x := arena.position.x + 40.0 if px > position.x else arena.end.x - 40.0
	var a = AutomatonScript.new()
	a.position = Vector2(x, floor_y - 0.5)
	a.facing = 1 if x < position.x else -1
	get_parent().add_child(a)
	summoned.append(a)
	Fx.steam_puff(get_parent(), Vector2(x, floor_y - 16.0), 14)


func _open() -> void:
	state = S.OPEN
	t = OPEN_TIME
	core_hits = 0
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", false)
	Sfx.play("door", -4.0, 1.3)


func _close() -> void:
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", true)
	_to_wait(1.3)


func on_rivet_hit(_dir: int) -> void:
	if state != S.OPEN or core_hits >= CORE_HITS or not is_alive():
		Sfx.play("clang", -6.0, 1.1)
		return
	core_hits += 1
	Fx.sparks(get_parent(), core_pos())
	_damage(1)


func steam_hit(_n: int) -> void:
	pass


func blast_hit(_n: int, _from: Vector2 = Vector2.INF) -> void:
	if state != S.OPEN or not is_alive():
		return
	core_hits = CORE_HITS
	_damage(3)


func _damage(n: int) -> void:
	hp = maxi(0, hp - n)
	flash = 0.2
	Game.world.shake(5.0)
	Game.world.hitstop(0.05)
	Sfx.play("hit", -2.0, 0.6)
	if hp <= 0:
		_die()
		return
	var new_stage := 1 + (1 if hp <= MAX_HP * 2 / 3 else 0) + (1 if hp <= MAX_HP / 3 else 0)
	if new_stage != stage:
		stage = new_stage
		phase2 = stage >= 2
		Sfx.play("crash", -2.0, 0.5)
		if stage == 2:
			Game.world.hud.message("Conselho: As placas! Segurem o Véu!")
		else:
			Game.world.hud.message("Conselho: O céu... está entrando...")
			if Game.world.has_method("set_wind"):
				Game.world.set_wind(90.0)


func _die() -> void:
	state = S.DYING
	t = 3.4
	dead_t = 0.0
	collision_layer = 0
	sh_active = false
	sh_warn = 0.0
	bolts.clear()
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", true)
	if Game.world.has_method("set_wind"):
		Game.world.set_wind(0.0)
	Game.world.hud.message("Conselho: Não... a luz...")
	for g in summoned:
		if is_instance_valid(g) and g.is_alive():
			g.blast_hit(2, core_pos())


func _process_dying(delta: float) -> void:
	t -= delta
	dead_t += delta
	if fmod(dead_t, 0.16) < delta:
		var pos := core_pos() + Vector2(randf_range(-110, 110), randf_range(-100, 20))
		Fx.sparks(get_parent(), pos)
		Fx.debris(get_parent(), pos)
		Sfx.play("explosion", -8.0, randf_range(0.7, 1.1))
		Game.world.shake(3.0)
	if dead_t > 1.6 and dead_t - delta <= 1.6:
		# A cápsula do Conselho despenca.
		var cap := Vector2(core_pos().x, floor_y - 10.0)
		var b = Game.world.blood
		if b:
			b.burst(cap, 90, 340.0)
			b.gibs(cap, 16, [Color("3a2a4a"), Color("2a2523"), Color(0.55, 0.08, 0.08), Color("e8c6a0"), Color(0.7, 0.9, 0.95)], true, 320.0)
		Fx.burst(get_parent(), cap, Color(0.8, 0.95, 1.0), 40, 300.0, 0.6, Vector2(0, 400), 1.5)
		Sfx.play("crash", 0.0, 0.5)
		Game.world.shake(10.0)
	if t <= 0.0:
		state = S.DEAD
		if exit_lift != null:
			exit_lift.locked = false
		Game.world.on_boss_defeated(Vector2(position.x, floor_y - 22.0))
		await get_tree().create_timer(1.6).timeout
		if Game.world:
			bar_visible = false
			Game.world.hud.message("O Véu está se abrindo. O elevador para o topo está livre.")


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	draw_set_transform(-global_position, 0.0, Vector2.ONE)
	var top := arena.position.y
	var cx := arena.get_center().x
	# Luz do sol entrando pela fresta do Véu
	if veil_open > 0.01:
		var w := 30.0 + veil_open * 260.0
		for i in 8:
			var k := i / 8.0
			draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.3, top), Vector2(cx + w * 0.3, top),
				Vector2(cx + w * (0.5 + k * 0.3), floor_y), Vector2(cx - w * (0.5 + k * 0.3), floor_y)]), Color(1.0, 0.93, 0.7, 0.025 * veil_open))
		draw_rect(Rect2(Vector2(cx - w * 0.3, top), Vector2(w * 0.6, 6)), Color(1.0, 0.95, 0.8, 0.8 * veil_open))
	if state == S.DEAD:
		# Destroços no chão
		draw_rect(Rect2(Vector2(cx - 60, floor_y - 16), Vector2(120, 16)), IRON)
		draw_rect(Rect2(Vector2(cx - 60, floor_y - 16), Vector2(120, 3)), BRASS)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var shake := Vector2(sin(anim * 40.0), 0) * (2.0 if state == S.DYING else 0.0)
	# Estrutura do tear presa ao teto
	var body := IRON if flash <= 0.0 else Color(1, 0.85, 0.8)
	draw_rect(Rect2(Vector2(cx - 120, top + 10) + shake, Vector2(240, 20)), body)
	draw_rect(Rect2(Vector2(cx - 120, top + 10) + shake, Vector2(240, 3)), BRASS)
	for side in [-1.0, 1.0]:
		var bx: float = cx + side * 100.0
		draw_line(Vector2(bx, top + 30) + shake, Vector2(cx + side * 40.0, top + 125) + shake, IRON_L, 6.0)
		# Fusos girando
		var sp := Vector2(bx, top + 60) + shake
		draw_circle(sp, 14.0, IRON)
		for i in 6:
			var a: float = anim * 3.0 * side + i * TAU / 6.0
			draw_line(sp, sp + Vector2.from_angle(a) * 16.0, BRASS, 2.0)
		draw_circle(sp, 4.0, BRASS_L)
	# Fios de aço puxando as placas
	for i in 7:
		var x := cx - 90.0 + i * 30.0
		draw_line(Vector2(x, top + 30) + shake, Vector2(x + sin(anim * 2.0 + i) * 6.0, top), Color(0.75, 0.75, 0.8, 0.5), 1.0)
	# Cápsula do Conselho
	var cap := Vector2(cx, top + 92) + shake
	draw_rect(Rect2(cap + Vector2(-30, -22), Vector2(60, 40)), Color(0.12, 0.11, 0.14))
	draw_rect(Rect2(cap + Vector2(-26, -18), Vector2(52, 30)), Color(0.55, 0.75, 0.85, 0.18))
	for i in 3:
		var fx := cap.x - 14.0 + i * 14.0
		draw_rect(Rect2(Vector2(fx - 3, cap.y - 4), Vector2(6, 12)), Color("3a2a4a"))
		draw_circle(Vector2(fx, cap.y - 7), 2.6, Color("e8c6a0"))
	# Olho do tear (núcleo)
	var c := core_pos() + shake
	draw_circle(c, 22.0, IRON)
	draw_arc(c, 22.0, 0, TAU, 24, BRASS, 2.0)
	var lid := 18.0 * (1.0 - open_k)
	draw_circle(c, 15.0, Color(0.95, 0.85, 0.5) if open_k > 0.05 else Color(0.2, 0.18, 0.22))
	draw_circle(c, 6.0 * open_k + 1.0, Color(0.15, 0.08, 0.05))
	draw_rect(Rect2(c + Vector2(-16, -16), Vector2(32, lid)), IRON_L)
	draw_rect(Rect2(c + Vector2(-16, 16 - lid), Vector2(32, lid)), IRON_L)
	if state == S.OPEN:
		for i in CORE_HITS - core_hits:
			draw_circle(c + Vector2(-10 + i * 4, -28), 1.2, BRASS_L)
	# Lançadeira e aviso
	if sh_warn > 0.0:
		var a2 := 0.3 + 0.3 * sin(anim * 30.0)
		draw_line(Vector2(arena.position.x, sh_y), Vector2(arena.end.x, sh_y), Color(1.0, 0.25, 0.15, a2), 2.0)
	elif sh_active:
		draw_rect(Rect2(Vector2(sh_x - 22, sh_y - 6), Vector2(44, 12)), Color("5a4a3a"))
		draw_rect(Rect2(Vector2(sh_x - 22, sh_y - 6), Vector2(44, 3)), BRASS_L)
		draw_colored_polygon(PackedVector2Array([Vector2(sh_x + sh_dir * 22, sh_y - 6), Vector2(sh_x + sh_dir * 32, sh_y), Vector2(sh_x + sh_dir * 22, sh_y + 6)]), BRASS)
		draw_line(Vector2(sh_x - sh_dir * 22, sh_y), Vector2(sh_x - sh_dir * 90, sh_y - 3), Color(0.9, 0.9, 0.95, 0.5), 1.0)
	# Raios
	for b in bolts:
		var bx2: float = b[0]
		var bt: float = b[1]
		if bt < 1.0:
			var k2 := 0.5 + 0.5 * sin(bt * 40.0)
			draw_rect(Rect2(Vector2(bx2 - 9, floor_y - 3), Vector2(18, 3)), Color(0.7, 0.85, 1.0, 0.4 + 0.4 * k2))
			draw_line(Vector2(bx2, top), Vector2(bx2, top + 30), Color(0.7, 0.85, 1.0, 0.3 * k2), 2.0)
		else:
			var pts := PackedVector2Array()
			var y := top
			var x2 := bx2
			while y < floor_y:
				pts.append(Vector2(x2, y))
				y += 24.0
				x2 = bx2 + randf_range(-7, 7)
			pts.append(Vector2(bx2, floor_y))
			draw_polyline(pts, Color(0.85, 0.92, 1.0), 3.0)
			draw_polyline(pts, Color(1, 1, 1), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
