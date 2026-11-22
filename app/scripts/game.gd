extends Node2D
## Mundo em jogo: monta a fase atual, controla a câmera fixa por tela, morte,
## transição entre fases e as camadas de interface.

const LevelScript := preload("res://scripts/level.gd")
const PlayerScript := preload("res://scripts/player.gd")
const LevelData := preload("res://scripts/levels/level_data.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const DialogScript := preload("res://scripts/ui/dialog_box.gd")
const PauseScript := preload("res://scripts/ui/pause_menu.gd")
const BloodScript := preload("res://scripts/blood.gd")
const ScreenBloodScript := preload("res://scripts/ui/screen_blood.gd")
const PostFxScript := preload("res://scripts/ui/post_fx.gd")
const TouchScript := preload("res://scripts/ui/touch_controls.gd")
## Escurecimento do mundo por tema (as luzes 2D clareiam por cima).
const AMBIENT := {
	"boiler": Color(0.86, 0.79, 0.77),
	"market": Color(0.9, 0.82, 0.84),
	"tower": Color(0.82, 0.82, 0.94),
}
const Fx := preload("res://scripts/fx.gd")

var level = null
var boss = null
var blood = null
var screen_blood = null
var post_fx = null
## Tremor de tela por "trauma" (0..1) que decai em tempo real.
var trauma := 0.0
var shake_t := 0.0
var hitstop_id := 0
var ambient: Array = []
var hitstop_left := 0.0
var player = null
var hud = null
var dialog = null
var pause_menu = null
var camera: Camera2D
var current_screen := Vector2i.ZERO
var phase_data: Dictionary = {}
var input_lock := 0.0
var cutscene := false
var finishing := false
var shake_amt := 0.0
var fade_rect: ColorRect


func _ready() -> void:
	Game.world = self
	phase_data = LevelData.phase(Game.phase)

	level = LevelScript.new()
	level.name = "Level"
	add_child(level)
	level.build(phase_data)
	blood = BloodScript.new()
	blood.name = "Blood"
	blood.level = level
	level.add_child(blood)
	_build_ambient()
	var cm := CanvasModulate.new()
	cm.color = AMBIENT.get(level.theme, AMBIENT["boiler"])
	add_child(cm)

	boss = level.boss
	player = PlayerScript.new()
	player.name = "Sera"
	player.position = level.player_start
	if at_boss_checkpoint():
		for l in level.lifts:
			if l.mode == "arena":
				l.position = l.pos_b
				l.at_b = true
				player.position = l.pos_b - Vector2(0, 0.5)
		if level.boss_spawn != Vector2.INF:
			player.position = level.boss_spawn
	add_child(player)

	camera = Camera2D.new()
	camera.ignore_rotation = false
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()
	current_screen = level.screen_of_pos(player.position + Vector2(0, -14))
	_apply_camera()

	hud = HudScript.new()
	add_child(hud)
	screen_blood = ScreenBloodScript.new()
	add_child(screen_blood)
	post_fx = PostFxScript.new()
	add_child(post_fx)
	post_fx.apply_theme(level.theme)
	add_child(TouchScript.new())
	dialog = DialogScript.new()
	add_child(dialog)
	pause_menu = PauseScript.new()
	add_child(pause_menu)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 50
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.8)

	Sfx.start_ambient()
	if at_boss_checkpoint():
		hud.show_title(String(phase_data.get("boss_title", "Plataforma do Elevador")))
	else:
		hud.show_title(String(phase_data.get("title", "")))


func _process(delta: float) -> void:
	if input_lock > 0.0:
		input_lock -= delta
	# Tremor: trauma² com senos de frequências diferentes (sem chiado aleatório),
	# decaindo em tempo real para não congelar fora do centro no hitstop.
	if trauma > 0.0:
		var real_dt := delta / maxf(Engine.time_scale, 0.0001)
		trauma = maxf(0.0, trauma - 1.4 * real_dt)
		shake_t += real_dt * 30.0
		var k := trauma * trauma
		camera.offset = Vector2(14.0 * k * sin(shake_t * 1.7), 9.0 * k * sin(shake_t * 2.3))
		camera.rotation = 0.012 * k * sin(shake_t * 1.1)
	else:
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	if level.abyss and not player.is_dead():
		var fs: Vector2i = level.screen_of_pos(player.global_position + Vector2(0, -30))
		if not level.has_screen(fs) and level.has_screen(fs - Vector2i(0, 1)):
			player.fall_into_abyss()
			return
	var s: Vector2i = level.screen_of_pos(player.global_position + Vector2(0, -14))
	if s != current_screen and level.has_screen(s):
		current_screen = s
		_apply_camera()
		# Entrou na arena por uma passagem (sem elevador): checkpoint do chefão.
		if boss != null and level.boss_spawn != Vector2.INF and level.screen_of_pos(level.boss_spawn) == s:
			on_arena_reached()


func _apply_camera() -> void:
	var r: Rect2 = level.screen_rect(current_screen)
	camera.position = r.position
	camera.reset_smoothing()
	level.light_screen(current_screen)
	for a in ambient:
		a.position = r.position + r.size * 0.5
		a.restart()


## Partículas de ambiente na tela atual: brasas e poeira (Caldeiras),
## gotejamento (Bombas), poeira dourada (Poço).
func _build_ambient() -> void:
	var specs: Array = []
	var idx := int(phase_data.get("index", 0))
	if idx >= 6:
		idx = 100
	match idx:
		100:
			# Torre: poeira dourada flutuando e faíscas de engrenagem.
			specs = [[Color(1.0, 0.9, 0.6, 0.45), 40, Vector2(1, 0), 5.0, Vector2(0, 1), 1.0, 1.8, 10.0],
				[Color(1.0, 0.75, 0.35, 0.8), 14, Vector2(0, 1), 30.0, Vector2(0, 160), 0.8, 1.4, 1.8]]
		0:
			specs = [[Color(1.0, 0.55, 0.2, 0.9), 45, Vector2(0, -1), 12.0, Vector2(0, -6), 1.0, 2.2, 7.0],
				[Color(0.7, 0.65, 0.6, 0.35), 35, Vector2(1, 0), 6.0, Vector2(0, 2), 1.0, 2.0, 9.0]]
		1:
			specs = [[Color(0.6, 0.75, 0.85, 0.7), 30, Vector2(0, 1), 40.0, Vector2(0, 260), 0.8, 1.4, 1.6],
				[Color(0.7, 0.7, 0.7, 0.3), 30, Vector2(1, 0), 6.0, Vector2(0, 2), 1.0, 2.0, 9.0]]
		_:
			specs = [[Color(1.0, 0.85, 0.45, 0.7), 40, Vector2(0, -1), 8.0, Vector2(0, -4), 1.0, 2.0, 8.0],
				[Color(1.0, 0.55, 0.2, 0.8), 25, Vector2(0, -1), 14.0, Vector2(0, -8), 1.0, 2.0, 6.0]]
	for s in specs:
		var p := CPUParticles2D.new()
		p.amount = s[1]
		p.lifetime = s[7]
		p.preprocess = s[7]
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(330, 185)
		p.direction = s[2]
		p.spread = 40.0
		p.initial_velocity_min = float(s[3]) * 0.4
		p.initial_velocity_max = s[3]
		p.gravity = s[4]
		p.scale_amount_min = s[5]
		p.scale_amount_max = s[6]
		var g := Gradient.new()
		var col: Color = s[0]
		g.set_color(0, Color(col, 0.0))
		g.add_point(0.2, col)
		g.add_point(0.8, col)
		g.set_color(g.get_point_count() - 1, Color(col, 0.0))
		p.color_ramp = g
		p.z_index = 8
		level.add_child(p)
		ambient.append(p)


## Congela o jogo por um instante (impacto). Só a chamada mais nova devolve o
## tempo normal, então dois impactos seguidos não se atrapalham.
func hitstop(duration: float) -> void:
	hitstop_id += 1
	var my_id := hitstop_id
	hitstop_left = duration
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if my_id == hitstop_id:
		Engine.time_scale = 1.0
		hitstop_left = 0.0


# ---------------------------------------------------------------- API para entidades

func is_active(pos: Vector2) -> bool:
	return level != null and level.screen_of_pos(pos) == current_screen


func is_input_locked() -> bool:
	return cutscene or finishing or input_lock > 0.0 or (dialog != null and dialog.active)


func add_entity(n: Node) -> void:
	level.add_child(n)


## `amount` na escala antiga (≈2 leve, 6 forte, 12 enorme); vira trauma somado.
func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)
	trauma = clampf(trauma + amount / 12.0, 0.0, 1.0)


## Checkpoint antes do chefão (salvo ao chegar à arena).
func at_boss_checkpoint() -> bool:
	var c: Dictionary = Game.cp()
	return boss != null and bool(c.get("boss", false)) and int(c.get("phase", -1)) == Game.phase


func on_arena_reached() -> void:
	if at_boss_checkpoint():
		return
	var seen := bool(Game.cp().get("boss_seen", false))
	Game.save_checkpoint()
	Game.cp()["boss"] = true
	Game.cp()["boss_seen"] = seen
	if not Game.replay:
		Game.write_save()
	hud.message("Checkpoint salvo")


func on_player_died() -> void:
	if finishing:
		return
	finishing = true
	hud.message("Sera caiu...")
	await get_tree().create_timer(1.6).timeout
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.7)
	await tw.finished
	Game.restore_checkpoint()
	get_tree().reload_current_scene()


func restart_phase() -> void:
	Game.restore_checkpoint()
	get_tree().paused = false
	get_tree().reload_current_scene()


func begin_exit() -> void:
	cutscene = true
	hud.message("Subindo...")


func complete_phase() -> void:
	if finishing:
		return
	finishing = true
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await tw.finished
	var done_phase: int = Game.phase
	Game.mark_phase_complete(done_phase)
	if Game.replay:
		# Repetição concluída: volta ao mapa e recupera o checkpoint de verdade.
		Game.replay = false
		Game.restore_checkpoint()
		Game.open_map("browse", done_phase)
		return
	var last_of_act: bool = Game.is_last_of_act(done_phase)
	if done_phase + 1 < Game.PHASE_COUNT:
		Game.phase = done_phase + 1
		if last_of_act:
			Game.hp = Game.MAX_HP
		Game.save_checkpoint()
	if last_of_act:
		Game.end_act = Game.act_of(done_phase)
		Game.map_from = done_phase
		Sfx.stop_ambient()
		get_tree().change_scene_to_file("res://scenes/end_screen.tscn")
	else:
		Game.open_map("travel", done_phase)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if Game.world == self:
		Game.world = null
