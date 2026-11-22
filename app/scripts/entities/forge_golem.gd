extends Area2D
## Chefão do Ato 4: a Fornalha-Mãe, um golem de fundição que anda dentro do
## ferro fundido, com a Conselheira Ívora numa gaiola no ombro.
## Origem = pés do golem na superfície do ferro.
##
## Ataques: punhos que batem na beira da poça e soltam ondas de choque, bolas
## de ferro fundido em arco e, na segunda metade, as duas coisas juntas.
## Ponto fraco: água fria. Um registro de resfriamento derramado sobre ele o
## endurece (3 de dano) e abre o núcleo do peito por alguns segundos.

const ShockScript := preload("res://scripts/entities/shockwave.gd")
const BlobScript := preload("res://scripts/entities/molten_blob.gd")
const Fx := preload("res://scripts/fx.gd")
const Light := preload("res://scripts/fx/light.gd")

enum S { IDLE, INTRO, WADE, SLAM, THROW, COOLED, DYING, DEAD }

const MAX_HP := 30
const PHASE2_HP := 15
const COOL_DMG := 3
const CORE_HITS := 5
const COOL_TIME := 5.0

const ROCK := Color("3a3230")
const ROCK_D := Color("231e1d")
const MAGMA := Color(1.0, 0.5, 0.12)

const INTRO_LINES := [
	["Conselheira Ívora", "Então foi você quem parou o relógio do pobre Halvard. Ele sempre foi sentimental."],
	["Sera", "A Fornalha alimenta o Véu. Se ela apagar, a cúpula abre."],
	["Conselheira Ívora", "Se ela apagar, Ironveil congela no escuro. Mas você não vai viver para ver. Mãe, acorde."],
]
const RETRY_LINES := [
	["Conselheira Ívora", "De volta ao forno, engenheira?"],
]

var title := "A FORNALHA-MÃE · Conselheira Ívora"
var state: int = S.IDLE
var hp := MAX_HP
var bar_hp := float(MAX_HP)
var bar_visible := false
var phase2 := false
var arena := Rect2()
var floor_y := 0.0
var min_x := 0.0
var max_x := 0.0
var target_x := 0.0
var facing: int = -1
var t := 0.0
var anim := 0.0
var flash := 0.0
var seq_i := 0
var slam_side: int = 1
var throws_left := 0
var core_hits := 0
var cool_t := 0.0
var exit_lift = null
var glow = null
var dead_t := 0.0


func setup(pos: Vector2, screen_rect: Rect2, floor_world_y: float, x_from: float, x_to: float) -> void:
	arena = screen_rect
	floor_y = floor_world_y
	min_x = x_from + 34.0
	max_x = x_to - 34.0
	position = Vector2(clampf(pos.x, min_x, max_x), floor_y)
	target_x = position.x
	z_index = 3


func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	cs.name = "CoreShape"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 28)
	cs.shape = shape
	cs.position = Vector2(0, -20)
	cs.disabled = true
	add_child(cs)
	glow = Light.make(self, Vector2(0, -40), MAGMA, 120.0, 1.0, 0.2)


func is_alive() -> bool:
	return state != S.DYING and state != S.DEAD


func hp_ratio() -> float:
	return bar_hp / float(MAX_HP)


func hp_real() -> float:
	return float(hp) / float(MAX_HP)


func rect() -> Rect2:
	return Rect2(global_position + Vector2(-30, -84), Vector2(60, 84))


func center() -> Vector2:
	return global_position + Vector2(0, -20)


func _player():
	return Game.world.player if Game.world else null


# ---------------------------------------------------------------- lógica

func _physics_process(delta: float) -> void:
	anim += delta
	flash = maxf(flash - delta, 0.0)
	bar_hp = move_toward(bar_hp, float(hp), delta * 14.0)
	if state == S.DEAD:
		return
	if state == S.DYING:
		_process_dying(delta)
		queue_redraw()
		return
	var w = Game.world
	if w == null or not w.is_active(global_position + Vector2(0, -10)):
		return
	var p = _player()
	if fmod(anim, 0.3) < delta and state != S.COOLED:
		Fx.burst(get_parent(), global_position + Vector2(randf_range(-26, 26), -2), MAGMA, 3, 50.0, 0.5, Vector2(0, 150), 1.5)
	match state:
		S.IDLE:
			if p != null and not p.is_dead() and w.is_active(p.global_position) and p.is_on_floor() and not w.cutscene:
				state = S.INTRO
				Sfx.play("alert", -2.0, 0.4)
				var seen := bool(Game.cp().get("boss_seen", false))
				w.dialog.start(RETRY_LINES if seen else INTRO_LINES, _on_intro_done)
		S.INTRO:
			pass
		S.WADE:
			_wade(delta, p)
			t -= delta
			if t <= 0.0:
				_next_attack(p)
		S.SLAM:
			t -= delta
			if t <= 0.0:
				_do_slam()
				state = S.WADE
				t = 1.4 if not phase2 else 0.9
		S.THROW:
			t -= delta
			if t <= 0.0 and throws_left > 0:
				throws_left -= 1
				t = 0.45 if not phase2 else 0.3
				_throw(p)
			elif throws_left <= 0 and t <= 0.0:
				state = S.WADE
				t = 1.2
		S.COOLED:
			cool_t -= delta
			if cool_t <= 0.0 or core_hits >= CORE_HITS:
				_reheat()
	queue_redraw()


func _on_intro_done() -> void:
	Game.cp()["boss_seen"] = true
	if not Game.replay:
		Game.write_save()
	bar_visible = true
	Game.world.hud.message("Ívora: Queime-a, Mãe.")
	state = S.WADE
	t = 1.5


func _wade(delta: float, p) -> void:
	if p != null:
		target_x = clampf(p.global_position.x, min_x, max_x)
	var spd := 22.0 if not phase2 else 34.0
	var dx := target_x - global_position.x
	if absf(dx) > 2.0:
		facing = 1 if dx > 0.0 else -1
	position.x = move_toward(position.x, target_x, spd * delta)


func _next_attack(p) -> void:
	var seq := ["slam", "throw", "slam", "throw"]
	if phase2:
		seq = ["slam", "throw", "throw", "slam", "throw"]
	var a: String = seq[seq_i % seq.size()]
	seq_i += 1
	if a == "slam":
		state = S.SLAM
		t = 0.8
		slam_side = 1
		if p != null:
			slam_side = 1 if p.global_position.x > global_position.x else -1
		Sfx.play("lift", -2.0, 0.5)
	else:
		state = S.THROW
		throws_left = 3 if not phase2 else 5
		t = 0.5


func _do_slam() -> void:
	var sides := [slam_side]
	if phase2:
		sides = [-1, 1]
	for s in sides:
		var hit_x: float = (min_x - 34.0) if s < 0 else (max_x + 34.0)
		var sw = ShockScript.new()
		sw.setup(Vector2(hit_x + s * 6.0, floor_y), s, 230.0)
		get_parent().add_child(sw)
		Fx.dust(get_parent(), Vector2(hit_x, floor_y), 14)
		Fx.burst(get_parent(), Vector2(hit_x, floor_y - 4), MAGMA, 10, 140.0, 0.5, Vector2(0, 300), 2.0)
	Sfx.play("crash", -2.0, 0.6)
	if Game.world:
		Game.world.shake(7.0)


func _throw(p) -> void:
	var from := global_position + Vector2(facing * 22, -70)
	var aim_x: float = p.global_position.x + randf_range(-40, 40) if p != null else from.x
	var b = BlobScript.new()
	var dist := aim_x - from.x
	var vx := clampf(dist * 0.95, -260.0, 260.0)
	b.setup(from, Vector2(vx, -240.0))
	get_parent().add_child(b)
	Sfx.play("throw", -2.0, 0.6)


## Chamado pelo registro de resfriamento quando a água cai sobre o golem.
func cool_hit() -> void:
	if not is_alive() or state == S.INTRO or state == S.IDLE or state == S.COOLED:
		return
	state = S.COOLED
	cool_t = COOL_TIME
	core_hits = 0
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", false)
	Sfx.play("steam", 0.0, 0.5)
	Sfx.play("crash", -4.0, 0.4)
	for i in 8:
		Fx.steam_puff(get_parent(), global_position + Vector2(randf_range(-30, 30), randf_range(-80, 0)), 8)
	Game.world.hud.message("Ívora: Não! Fechem a água!")
	_damage(COOL_DMG)


func _reheat() -> void:
	state = S.WADE
	t = 1.0
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", true)
	Sfx.play("explosion", -8.0, 0.6)


func on_rivet_hit(_dir: int) -> void:
	if state != S.COOLED or core_hits >= CORE_HITS or not is_alive():
		Sfx.play("clang", -6.0, 0.7)
		return
	core_hits += 1
	Fx.sparks(get_parent(), center())
	Fx.burst(get_parent(), center(), MAGMA, 8, 100.0, 0.3)
	_damage(1)


func steam_hit(_n: int) -> void:
	pass


func blast_hit(_n: int, _from: Vector2 = Vector2.INF) -> void:
	if state != S.COOLED or not is_alive():
		return
	core_hits = CORE_HITS
	_damage(3)


func _damage(n: int) -> void:
	hp = maxi(0, hp - n)
	flash = 0.2
	Game.world.shake(5.0)
	Game.world.hitstop(0.06)
	Sfx.play("hit", -2.0, 0.5)
	if hp <= 0:
		_die()
		return
	if not phase2 and hp <= PHASE2_HP:
		phase2 = true
		Game.world.hud.message("Ívora: Mais calor, Mãe! MAIS!")
		Fx.fire(get_parent(), global_position + Vector2(0, -60), 30)


func _die() -> void:
	state = S.DYING
	t = 3.0
	collision_layer = 0
	var cs: CollisionShape2D = get_node("CoreShape")
	cs.set_deferred("disabled", true)
	Game.world.hud.message("Ívora: A Fornalha... está esfriando...")


func _process_dying(delta: float) -> void:
	t -= delta
	dead_t += delta
	position.y += delta * 18.0
	if glow != null:
		glow.base_energy = maxf(0.0, glow.base_energy - delta * 0.3)
	if fmod(dead_t, 0.18) < delta:
		var pos := global_position + Vector2(randf_range(-30, 30), randf_range(-80, -10))
		Fx.steam_puff(get_parent(), pos, 10)
		Fx.debris(get_parent(), pos)
		Sfx.play("explosion", -10.0, randf_range(0.6, 0.9))
		Game.world.shake(3.0)
	if dead_t > 1.2 and dead_t - delta <= 1.2:
		# A gaiola da conselheira se parte e cai no ferro.
		var cage := global_position + Vector2(-facing * 18, -86)
		var b = Game.world.blood
		if b:
			b.burst(cage, 70, 300.0)
			b.gibs(cage, 12, [Color("6a2a4a"), Color("3a1a2a"), Color(0.55, 0.08, 0.08), Color("e8c6a0")], true, 280.0)
		Fx.fire(get_parent(), cage, 30)
		Sfx.play("death", -4.0, 0.7)
	if t <= 0.0:
		state = S.DEAD
		visible = false
		Sfx.play("crash", 0.0, 0.4)
		Game.world.shake(10.0)
		if exit_lift != null:
			exit_lift.locked = false
		Game.world.on_boss_defeated(Vector2(clampf(global_position.x, arena.position.x + 60, arena.end.x - 60), floor_y - 60.0))
		await get_tree().create_timer(1.4).timeout
		if Game.world:
			bar_visible = false
			Game.world.hud.message("A Fornalha-Mãe apagou. O elevador para cima está livre.")


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var cooled := state == S.COOLED
	var rock := ROCK if not cooled else Color("1c1a1c")
	if flash > 0.0:
		rock = Color(1, 0.8, 0.7)
	var vein := MAGMA if not cooled else Color(0.3, 0.35, 0.45)
	var bob := sin(anim * 1.6) * 2.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing, 1))
	# Tronco
	draw_colored_polygon(PackedVector2Array([Vector2(-26, 0), Vector2(26, 0), Vector2(30, -50), Vector2(20, -72), Vector2(-20, -72), Vector2(-30, -50)]), rock)
	for i in 5:
		var y := -10.0 - i * 12.0
		draw_line(Vector2(-20 + i * 3, y), Vector2(14 - i * 2, y - 6), vein, 1.6)
	# Cabeça
	draw_rect(Rect2(-12, -88, 24, 18), rock)
	draw_rect(Rect2(-12, -88, 24, 3), ROCK_D)
	var eye := Color(1.0, 0.85, 0.4) if not cooled else Color(0.4, 0.5, 0.6)
	draw_rect(Rect2(2, -82, 7, 3), eye)
	draw_rect(Rect2(-8, -82, 5, 3), eye)
	# Braços / punhos
	var raise := 0.0
	if state == S.SLAM:
		raise = clampf(1.0 - t / 0.8, 0.0, 1.0) * 30.0
	draw_line(Vector2(24, -60), Vector2(42, -40 - raise), rock, 9.0)
	draw_rect(Rect2(36, -46 - raise, 14, 14), rock)
	draw_line(Vector2(-24, -60), Vector2(-38, -34), rock, 8.0)
	draw_rect(Rect2(-46, -38, 12, 12), rock)
	# Núcleo do peito (aberto quando resfriado)
	var core := Vector2(0, -20 - bob)
	if cooled:
		var pulse := 0.6 + 0.4 * sin(anim * 12.0)
		draw_circle(core, 11.0, Color(0.1, 0.08, 0.08))
		draw_circle(core, 8.0, Color(1.0, 0.55, 0.2, pulse))
		for i in CORE_HITS - core_hits:
			draw_circle(core + Vector2(-8 + i * 4, -14), 1.2, Color(1.0, 0.85, 0.4))
	else:
		draw_circle(core, 9.0, ROCK_D)
		draw_circle(core, 5.0, Color(1.0, 0.6, 0.2, 0.5))
	# Gaiola da conselheira no ombro de trás
	var cage := Vector2(-18, -86)
	draw_rect(Rect2(cage + Vector2(-7, -16), Vector2(14, 16)), Color(0.2, 0.18, 0.2, 0.9))
	draw_rect(Rect2(cage + Vector2(-3, -13), Vector2(6, 10)), Color("6a2a4a"))
	draw_circle(cage + Vector2(0, -14), 2.5, Color("e8c6a0"))
	for i in 4:
		draw_line(cage + Vector2(-7 + i * 4.6, -16), cage + Vector2(-7 + i * 4.6, 0), Color("8a6a2a"), 1.0)
	draw_line(cage + Vector2(-8, -16), cage + Vector2(8, -16), Color("8a6a2a"), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Aviso da martelada
	if state == S.SLAM:
		var hit_x: float = ((min_x - 34.0) if slam_side < 0 else (max_x + 34.0)) - global_position.x
		var k := 0.5 + 0.5 * sin(anim * 30.0)
		draw_rect(Rect2(Vector2(hit_x - 12, -3), Vector2(24, 3)), Color(1.0, 0.3, 0.1, 0.4 + 0.4 * k))
