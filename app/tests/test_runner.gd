extends Node
# Teste de fumaça automatizado: simula entradas e verifica as mecânicas principais.
# Rodar: godot --headless --path . res://tests/test_runner.tscn

var g = null
var fails := 0


func _ready() -> void:
	# Não depende (nem estraga) o save do jogador.
	var backup := ""
	if FileAccess.file_exists(Game.SAVE_PATH):
		backup = FileAccess.get_file_as_string(Game.SAVE_PATH)
	var saved_cp: Dictionary = Game.checkpoint.duplicate()
	var saved_prog: Dictionary = Game.progress.duplicate(true)
	Game.checkpoint = {}
	# Testes sem upgrades (vida 4, sem couraça) e sem música.
	Game.progress["upgrades"] = []
	Music.stop()
	await _phase0()
	await _phase1()
	await _phase2()
	await _boss()
	await _act2()
	await _act3()
	await _features()
	await _act45()
	await _extras()
	Game.checkpoint = saved_cp
	Game.progress = saved_prog
	if backup != "":
		var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	print("RESULT: ", "ALL PASS" if fails == 0 else "%d FAIL(S)" % fails)
	get_tree().quit()


func check(cond: bool, label: String) -> void:
	print(("PASS " if cond else "FAIL ") + label)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func tap(a: String) -> void:
	Input.action_press(a)
	await frames(2)
	Input.action_release(a)
	await frames(1)


func release_all() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "jump", "shoot", "roll", "interact", "use_tool"]:
		Input.action_release(a)


func load_phase(i: int) -> void:
	if g != null:
		g.queue_free()
		await frames(2)
	Game.phase = i
	Game.hp = 4
	Game.show_story = false
	g = load("res://scenes/game.tscn").instantiate()
	add_child(g)
	await frames(5)


func place(pos: Vector2, facing: int = 1) -> void:
	var p = g.player
	p.global_position = pos
	p.velocity = Vector2.ZERO
	p.facing = facing
	p.vis_scale = facing
	p.state = 0
	await frames(3)


func _phase0() -> void:
	await load_phase(0)
	var p = g.player
	check(p != null and p.is_on_floor(), "p0 player spawned on floor")
	# Correr
	Input.action_press("move_right")
	await frames(50)
	check(absf(p.velocity.x) > 140.0, "p0 run speed reached (%.0f)" % p.velocity.x)
	Input.action_release("move_right")
	await frames(30)
	# Virar com animação
	await place(Vector2(200, 299.5), 1)
	Input.action_press("move_left")
	await frames(3)
	check(p.turn_timer > 0.0, "p0 turn animation starts")
	await frames(20)
	check(p.facing == -1, "p0 turned left")
	release_all()
	# Agarrar borda (bloco col 15-17, topo y=240)
	await place(Vector2(292, 299.5), 1)
	Input.action_press("move_right")
	await tap("jump")
	var hung := false
	for i in 60:
		await frames(1)
		if p.state == p.S.HANG:
			hung = true
			break
	release_all()
	check(hung, "p0 ledge grab")
	await tap("move_up")
	await frames(40)
	check(p.state == p.S.NORMAL and absf(p.global_position.y - 240.0) < 1.5, "p0 climbed ledge (y=%.1f)" % p.global_position.y)
	# Descer pela borda direita do bloco (x=360)
	await place(Vector2(352, 239.5), 1)
	Input.action_press("move_down")
	await frames(3)
	await tap("jump")
	Input.action_release("move_down")
	await frames(40)
	check(p.state == p.S.HANG, "p0 descend into hang (state=%d)" % p.state)
	await tap("move_down")
	await frames(40)
	check(p.is_on_floor() and absf(p.global_position.y - 300.0) < 1.5, "p0 dropped to floor")
	# Túnel agachada até a tela 2
	await place(Vector2(450, 299.5), 1)
	Input.action_press("move_down")
	Input.action_press("move_right")
	await frames(400)
	release_all()
	await frames(20)
	check(g.current_screen == Vector2i(1, 0), "p0 crawled through tunnel to screen 1 (x=%.0f)" % p.global_position.x)
	# Encostar e guarda não atira
	var guard = get_tree().get_nodes_in_group("guard")[0]
	await place(Vector2(640 + 310, 299.5), 1)
	await tap("move_up")
	check(p.in_cover, "p0 entered cover")
	var hp_before: int = Game.hp
	guard.global_position = Vector2(640 + 420, 299.5)
	guard.facing = -1
	guard.state = guard.S.AIM
	guard.t = 0.3
	await frames(120)
	check(guard.state == guard.S.WAIT or guard.state == guard.S.PATROL, "p0 guard waits while in cover (state=%d)" % guard.state)
	check(Game.hp == hp_before, "p0 no damage while in cover")
	await frames(150)
	check(guard.state == guard.S.PATROL or guard.state == guard.S.PAUSE, "p0 guard returns to patrol (state=%d)" % guard.state)
	await tap("move_down")
	check(not p.in_cover, "p0 left cover")
	# Guarda atira em Sera de pé
	await place(Vector2(640 + 330, 299.5), 1)
	guard.global_position = Vector2(640 + 450, 299.5)
	guard.facing = -1
	guard.state = guard.S.PATROL
	await frames(150)
	check(Game.hp < hp_before, "p0 guard shot standing Sera (hp=%d)" % Game.hp)
	Game.hp = 4
	p.invuln = 0.0
	# Dois rebites derrotam o guarda (fora do abrigo)
	guard.state = guard.S.AIM
	guard.t = 5.0
	await tap("shoot")
	await frames(25)
	guard.state = guard.S.AIM
	guard.t = 5.0
	await tap("shoot")
	await frames(25)
	check(guard.state == guard.S.DEAD, "p0 guard down after 2 rivets (state=%d hp=%d)" % [guard.state, guard.hp])
	Game.hp = 4
	# Válvula
	await place(Vector2(640 + 210, 299.5), 1)
	await tap("interact")
	var vents_on := 0
	for v in get_tree().get_nodes_in_group("vent"):
		if v.active:
			vents_on += 1
	check(vents_on == 2, "p0 valve fires 2 vents (%d)" % vents_on)
	# Carga de vapor destrói grade (tela 2, grade col 10)
	Game.inv["charge"] = 2
	Game.tool_index = 0
	await place(Vector2(1280 + 140, 299.5), 1)
	await frames(5)
	await tap("use_tool")
	Input.action_press("move_left")
	await frames(40)
	Input.action_release("move_left")
	await frames(110)
	check(get_tree().get_nodes_in_group("breakable").is_empty(), "p0 steam charge destroyed grate")
	check(Game.inv["charge"] == 1, "p0 charge consumed")
	# Elevador de saída: subir
	Game.hp = 4
	await place(Vector2(1280 + 27 * 20 + 10, 299.5), 1)
	await frames(5)
	check(p.current_prompt != "", "p0 exit prompt shown: '%s'" % p.current_prompt)


func _phase1() -> void:
	await load_phase(1)
	var p = g.player
	# Alavanca -> elevador sobe levando Sera
	await place(Vector2(150, 299.5), 1)
	await tap("interact")
	await place(Vector2(190, 299.5), 1)
	await frames(200)
	check(absf(p.global_position.y - 140.0) < 2.0, "p1 rode lift up (y=%.1f)" % p.global_position.y)
	# Caixa de força: tiro para trás derruba a grade
	var guard = get_tree().get_nodes_in_group("guard")[0]
	guard.global_position = Vector2(470, 139.5)
	guard.state = guard.S.PAUSE
	guard.t = 99.0
	await place(Vector2(200, 139.5), -1)
	await tap("shoot")
	await frames(60)
	var fg = g.level.falling_grates[0]
	check(fg.state == "landed", "p1 falling grate dropped (%s)" % fg.state)
	check(guard.state == guard.S.DEAD, "p1 grate crushed guard")
	# Painel abre porta blindada
	var door = null
	for d in get_tree().get_nodes_in_group("door"):
		if d.kind == "blast":
			door = d
	await place(Vector2(640 + 14 * 20 + 10, 299.5), 1)
	await tap("interact")
	await frames(10)
	check(door.opened, "p1 panel opened blast door")
	# Cartão abre porta de segurança
	Game.inv["card"] = 1
	Game.tool_index = 2
	await place(Vector2(1280 + 90, 299.5), 1)
	await tap("use_tool")
	var sdoor = get_tree().get_nodes_in_group("security_door")[0]
	check(sdoor.opened and Game.inv["card"] == 0, "p1 card opened security door")
	# Rebite de escalada e subida pelo pino
	await place(Vector2(1280 + 268, 299.5), 1)
	Input.action_press("move_up")
	await tap("shoot")
	Input.action_release("move_up")
	await frames(20)
	var gp = get_tree().get_nodes_in_group("grapple")[0]
	check(gp.anchored, "p1 grapple anchored")
	await place(Vector2(1280 + 270, 299.5), 1)
	await tap("jump")
	var hung := false
	for i in 60:
		await frames(1)
		if p.state == p.S.HANG:
			hung = true
			break
	check(hung and p.hang_is_peg, "p1 grabbed peg")
	await tap("move_up")
	await frames(40)
	check(absf(p.global_position.y - 240.0) < 2.0 and p.is_on_floor(), "p1 standing on peg (y=%.1f)" % p.global_position.y)
	await tap("jump")
	hung = false
	for i in 60:
		await frames(1)
		if p.state == p.S.HANG:
			hung = true
			break
	check(hung and not p.hang_is_peg, "p1 grabbed wall ledge from peg")
	await tap("move_up")
	await frames(40)
	check(absf(p.global_position.y - 180.0) < 2.0, "p1 climbed to upper level (y=%.1f)" % p.global_position.y)


func _phase2() -> void:
	await load_phase(2)
	var p = g.player
	var tome = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("_on_dialog_done"))[0]
	await place(Vector2(640 + 18 * 20 + 10, 299.5), 1)
	await tap("interact")
	check(g.dialog.active, "p2 dialog opened")
	for i in 30:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	check(not g.dialog.active and tome.talked, "p2 dialog finished")
	check(not tome.crane.locked, "p2 crane unlocked")
	await frames(30)
	await place(Vector2(640 + 24 * 20 + 10, 299.5), 1)
	await frames(560)
	check(absf(p.global_position.y - (-180.0)) < 3.0, "p2 crane carried Sera up (y=%.1f)" % p.global_position.y)
	check(g.current_screen == Vector2i(1, -1), "p2 camera on top screen")
	# Drone explode ao tocar
	var hp0: int = Game.hp
	var dr = get_tree().get_nodes_in_group("drone")[0]
	await place(dr.global_position + Vector2(0, 20), 1)
	await frames(10)
	check(Game.hp < hp0, "p2 drone hurt Sera on touch")


func _boss() -> void:
	# Preserva o save real do jogador.
	var backup := ""
	if FileAccess.file_exists(Game.SAVE_PATH):
		backup = FileAccess.get_file_as_string(Game.SAVE_PATH)
	var saved_cp: Dictionary = Game.checkpoint.duplicate()
	Game.checkpoint = {}
	await load_phase(2)
	var p = g.player
	var boss = g.boss
	check(boss != null, "boss spawned")
	check(boss.exit_lift != null and boss.exit_lift.locked, "boss locks exit lift")
	await place(Vector2(770, -180.5), 1)
	await tap("interact")
	check(g.cutscene, "arena lift started")
	await frames(230)
	check(absf(p.global_position.y - (-420.0)) < 3.0, "arena lift carried Sera up (y=%.1f)" % p.global_position.y)
	check(g.current_screen == Vector2i(1, -2), "camera on arena")
	check(bool(Game.checkpoint.get("boss", false)), "boss checkpoint saved")
	await frames(10)
	check(g.dialog.active, "boss intro dialog")
	for i in 30:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	check(not g.dialog.active and boss.bar_visible and boss.state == 2, "boss fight started")
	# Rebite nas costas
	boss.state = 6
	boss.t = 99.0
	boss.core_open = 0.0
	boss.facing = -1
	boss.velocity = Vector2.ZERO
	var hp0: int = boss.hp
	await place(Vector2(boss.global_position.x + 80, -420.5), -1)
	await frames(30)
	await tap("shoot")
	await frames(12)
	check(boss.hp == hp0 - 1, "rivet in the back hurts boss (%d)" % boss.hp)
	# Frente blindada
	await place(Vector2(boss.global_position.x - 80, -420.5), 1)
	await frames(20)
	boss.core_open = 0.0
	hp0 = boss.hp
	await tap("shoot")
	await frames(12)
	check(boss.hp == hp0, "front armor blocks rivet")
	boss.core_open = 5.0
	await frames(20)
	await tap("shoot")
	await frames(12)
	check(boss.hp == hp0 - 1, "open core takes rivet")
	# Vapor do chão + válvula
	boss.core_open = 0.0
	boss.global_position.x = 640 + 14 * 20 + 10
	await frames(3)
	hp0 = boss.hp
	await place(Vector2(640 + 10 * 20 + 10, -420.5), 1)
	await tap("interact")
	await frames(30)
	check(boss.hp == hp0 - 2 and boss.state == 8, "steam jet stuns boss (hp %d, state %d)" % [boss.hp, boss.state])
	# Martelada: onda de choque
	await frames(150)
	Game.hp = 4
	p.invuln = 0.0
	boss.global_position.x = 1110
	await place(Vector2(1010, -420.5), 1)
	boss.facing = -1
	boss.state = 5
	boss.t = 0.01
	boss.slams_left = 0
	await frames(50)
	check(Game.hp < 4, "shockwave hurts Sera (hp %d)" % Game.hp)
	check(boss.core_open > 0.0 or boss.state != 6, "slam opens core")
	# Derrota
	Game.hp = 4
	await frames(70)
	boss.state = 6
	boss.t = 99.0
	boss.core_open = 5.0
	boss.facing = -1
	boss.hp = 1
	await place(Vector2(boss.global_position.x - 80, -420.5), 1)
	await frames(20)
	await tap("shoot")
	await frames(12)
	check(boss.state == 9, "boss dying")
	await frames(240)
	check(boss.state == 10, "boss destroyed")
	check(not boss.exit_lift.locked, "exit lift unlocked")
	# Checkpoint do chefão ao recarregar
	await load_phase(2)
	check(g.current_screen == Vector2i(1, -2) and absf(g.player.global_position.y - (-420.0)) < 3.0, "respawn at boss checkpoint")
	release_all()
	Game.checkpoint = saved_cp
	if backup != "":
		var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()


func _act2() -> void:
	var backup := ""
	if FileAccess.file_exists(Game.SAVE_PATH):
		backup = FileAccess.get_file_as_string(Game.SAVE_PATH)
	var saved_cp: Dictionary = Game.checkpoint.duplicate()
	var saved_prog: Dictionary = Game.progress.duplicate(true)
	Game.checkpoint = {}
	# ---------------- Fase 4: Docas de Carga
	await load_phase(3)
	Game.hp = 99
	var p = g.player
	check(g.level.abyss and g.level.theme == "market", "p3 market theme + abyss")
	# Tábua podre
	var plank = get_tree().get_nodes_in_group("plank")[2]
	await place(plank.global_position + Vector2(10, -0.5), 1)
	await frames(36)
	check(plank.state == 2, "p3 rotten plank fell (state %d)" % plank.state)
	await place(Vector2(60, 299.5), 1)
	await frames(260)
	check(plank.state == 0, "p3 plank respawned")
	# Tirolesa
	var zl = get_tree().get_nodes_in_group("zipline")[0]
	var start: Vector2 = zl.point(0.3)
	await place(start + Vector2(0, 26 + 2), 1)
	p.velocity = Vector2(20, 10)
	await frames(3)
	check(p.state == 7, "p3 grabbed zipline (state %d)" % p.state)
	await frames(150)
	check(p.state != 7 and absf(p.global_position.x - zl.b.x) < 30.0, "p3 zipline carried Sera to the end (x=%.0f)" % p.global_position.x)
	await frames(30)
	check(g.current_screen == Vector2i(1, 0), "p3 zipline crossed to next screen")
	# Holofote
	var lamp = get_tree().get_nodes_in_group("searchlight")[0]
	var guards0 := get_tree().get_nodes_in_group("guard").size()
	await place(lamp.global_position + Vector2(lamp.facing * 70, -0.5), lamp.facing)
	var seen := false
	for i in 300:
		await frames(1)
		if lamp.alarm > 0.0:
			seen = true
			break
	check(seen, "p3 searchlight spotted Sera")
	await frames(80)
	check(get_tree().get_nodes_in_group("guard").size() > guards0, "p3 alarm brought reinforcement")
	# Quebrar o holofote por trás (sem guardas no caminho)
	for gd in get_tree().get_nodes_in_group("guard"):
		if not gd.shielded:
			gd.queue_free()
	await frames(2)
	await place(lamp.global_position + Vector2(-lamp.facing * 60, -0.5), lamp.facing)
	await frames(10)
	await tap("shoot")
	await frames(12)
	check(lamp.broken, "p3 rivet broke searchlight")
	# Encostada, a luz não vê
	# Guarda com escudo
	await place(Vector2(1280 + 60, 299.5), 1)
	var sg = null
	for gd in get_tree().get_nodes_in_group("guard"):
		if gd.shielded:
			sg = gd
	check(sg != null, "p3 shield guard exists")
	if sg != null:
		sg.state = 1
		sg.t = 99.0
		sg.facing = -1
		await place(sg.global_position + Vector2(-90, 0), 1)
		await frames(12)
		await tap("shoot")
		await frames(15)
		check(sg.hp == 2, "p3 shield blocks frontal rivet")
		sg.state = 1
		sg.t = 99.0
		sg.facing = -1
		await place(sg.global_position + Vector2(90, 0), -1)
		await frames(12)
		await tap("shoot")
		await frames(15)
		check(sg.hp == 1, "p3 rivet in the back hurts shield guard")
	# ---------------- Fase 5: Bazar
	await load_phase(4)
	Game.hp = 99
	p = g.player
	var civ = get_tree().get_nodes_in_group("civilian")[1]
	civ.pause_t = 99.0
	await place(civ.global_position + Vector2(0, -0.5), 1)
	p.since_shot = 5.0
	await frames(3)
	check(p.hidden_in_crowd(), "p4 Sera hidden in crowd")
	var gd2 = get_tree().get_nodes_in_group("guard")[0]
	gd2.facing = -1 if gd2.global_position.x > p.global_position.x else 1
	check(not gd2._sees(p, true), "p4 guard can't see Sera in crowd")
	await place(Vector2(civ.global_position.x - 40, 299.5), 1)
	check(gd2._civilian_in_line(p), "p4 civilian in line of fire")
	# Lira
	var lira = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("_on_dialog_done") and n.get("door") != null)[0]
	await place(lira.global_position + Vector2(10, -0.5), -1)
	await tap("interact")
	for i in 30:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	check(lira.talked and lira.door.opened, "p4 Lira opened the smugglers' door")
	# ---------------- Fase 6: Telhados + dirigível
	await load_phase(5)
	Game.hp = 99
	p = g.player
	var lb = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("_draw") and n.get("taken") != null)[0]
	await place(lb.global_position + Vector2(0, -0.5), 1)
	await tap("interact")
	check(lb.taken and g.dialog.active, "p5 logbook taken")
	for i in 30:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	var ship = g.boss
	check(ship != null and ship.exit_lift != null and ship.exit_lift.locked, "p5 airship locks exit")
	await place(Vector2(1280 + 80, 299.5), 1)
	await frames(10)
	check(g.current_screen == Vector2i(2, 0) and bool(Game.cp().get("boss", false)), "p5 arena checkpoint")
	check(g.dialog.active, "p5 airship intro dialog")
	for i in 30:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	check(ship.bar_visible and ship.state == 2, "p5 airship fight started")
	# Arpão
	var cannon = get_tree().get_nodes_in_group("harpoon")[0]
	ship.state = 8
	ship.t = 99.0
	ship.position = Vector2(cannon.global_position.x, ship.hover_y)
	var hp0: int = ship.hp
	await place(cannon.global_position + Vector2(0, -0.5), 1)
	await frames(20)
	check(cannon.ship_in_line(), "p5 cannon has ship in line")
	await tap("interact")
	await frames(40)
	check(ship.hp == hp0 - 4, "p5 harpoon hit the airship (hp %d)" % ship.hp)
	# Âncora
	ship.state = 2
	ship.t = 99.0
	ship.target_x = ship.position.x
	ship._launch_anchor()
	await frames(60)
	var anchor_world: Vector2 = ship.global_position + ship.anchor_pos
	hp0 = ship.hp
	await place(Vector2(anchor_world.x - 80, 299.5), 1)
	for i in 3:
		await frames(20)
		await tap("shoot")
	await frames(15)
	check(ship.hp == hp0 - 3 and not ship.anchor_out, "p5 anchor cut hurts airship (hp %d)" % ship.hp)
	# Bomba explode no chão
	ship.state = 2
	ship._drop_bomb(p)
	await frames(90)
	check(true, "p5 bomb dropped without errors")
	# Derrota
	ship.hp = 1
	ship.state = 8
	ship.t = 99.0
	ship.position = Vector2(cannon.global_position.x, ship.hover_y)
	cannon.reload = 0.0
	await place(cannon.global_position + Vector2(0, -0.5), 1)
	await frames(10)
	await tap("interact")
	await frames(40)
	check(ship.state == 9, "p5 airship dying")
	await frames(260)
	check(ship.state == 10 and not ship.exit_lift.locked, "p5 airship down, exit unlocked")
	# Respawn no checkpoint do chefão
	await load_phase(5)
	check(g.current_screen == Vector2i(2, 0), "p5 respawn at arena checkpoint")
	# Mapa
	release_all()
	var map = load("res://scenes/progress_map.tscn").instantiate()
	add_child(map)
	await frames(5)
	check(map.sel >= 0, "map scene loads")
	map.queue_free()
	Game.checkpoint = saved_cp
	Game.progress = saved_prog
	if backup != "":
		var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()


func _act3() -> void:
	var backup := ""
	if FileAccess.file_exists(Game.SAVE_PATH):
		backup = FileAccess.get_file_as_string(Game.SAVE_PATH)
	var saved_cp: Dictionary = Game.checkpoint.duplicate()
	var saved_prog: Dictionary = Game.progress.duplicate(true)
	var saved_gore: bool = Game.gore_enabled()
	Game.settings["gore"] = true
	Game.checkpoint = {}
	Game.clean_sera()
	# ---------------- Fase 7: Átrio de Bronze
	await load_phase(6)
	Game.hp = 99
	var p = g.player
	check(g.level.theme == "tower", "p6 tower theme")
	# Gore: sangue gruda em Sera, em outro guarda, no fundo e na tela.
	var GuardS = load("res://scripts/entities/guard.gd")
	await place(Vector2(100, 299.5), 1)
	var victim = GuardS.new()
	victim.position = Vector2(118, 299.5)
	g.level.add_child(victim)
	var witness = GuardS.new()
	witness.position = Vector2(150, 299.5)
	g.level.add_child(witness)
	await frames(3)
	victim.blast_hit(2, Vector2(110, 285))
	await frames(70)
	check(p.splats.count() > 0, "gore blood sticks to Sera's suit (%d)" % p.splats.count())
	check(witness.splats.count() > 0, "gore blood sticks to a nearby guard (%d)" % witness.splats.count())
	var bg_stains := 0
	for k in g.blood.stains.s_kind:
		if k == 3:
			bg_stains += 1
	check(bg_stains > 0, "gore blood stains the backdrop (%d)" % bg_stains)
	check(g.screen_blood.blobs.size() > 0, "gore blood splashes the screen (%d)" % g.screen_blood.blobs.size())
	witness.queue_free()
	await frames(2)
	# Sujeira acompanha a vida; curar limpa
	Game.hp = Game.max_hp()
	await frames(2)
	var clean: int = p._wound_count()
	Game.hp = 1
	await frames(2)
	var dirty: int = p._wound_count()
	Game.hp = Game.max_hp()
	await frames(3)
	check(clean == 0 and dirty > 20 and p._wound_count() == 0 and p.splats.count() == 0,
		"dirt follows HP and healing cleans (%d -> %d)" % [clean, dirty])
	Game.hp = 99
	# Rolamento atravessa tiros
	await place(Vector2(60, 299.5), 1)
	await tap("roll")
	check(p.state == p.S.ROLL, "p6 roll started")
	var BulletS = load("res://scripts/entities/enemy_bullet.gd")
	var bl = BulletS.new()
	bl.setup(p.global_position + Vector2(40, -18), -1)
	g.level.add_child(bl)
	await frames(14)
	check(Game.hp == 99, "p6 rolling dodges a bullet")
	await frames(30)
	check(p.state == 0, "p6 roll ended")
	# Rola para dentro da grade baixa e sai agachada do outro lado
	await place(Vector2(200, 299.5), 1)
	Input.action_press("move_right")
	await frames(2)
	await tap("roll")
	await frames(30)
	check(p.crouching and p.global_position.x > 240.0, "p6 rolled under the low grate (x=%.0f)" % p.global_position.x)
	await frames(240)
	Input.action_release("move_right")
	await frames(10)
	check(p.global_position.x > 380.0 and not p.crouching, "p6 crossed the low grate (x=%.0f)" % p.global_position.x)
	# Torreta: 3 rebites
	var tur = get_tree().get_nodes_in_group("turret")[0]
	await place(tur.global_position + Vector2(-110, -0.5), 1)
	for i in 3:
		await frames(20)
		await tap("shoot")
	await frames(15)
	check(tur.broken, "p6 three rivets destroy the turret")
	# Pistão esmagador
	var cr = get_tree().get_nodes_in_group("crusher")[0]
	await place(Vector2(cr.global_position.x - 60, 299.5), 1)
	await frames(5)
	var crushed = GuardS.new()
	crushed.position = Vector2(cr.global_position.x, 299.5)
	g.level.add_child(crushed)
	var dead := false
	for i in 260:
		await frames(1)
		crushed.global_position.x = cr.global_position.x
		if not crushed.is_alive():
			dead = true
			break
	check(dead, "p6 crusher squashes a guard")
	var hp0: int = Game.hp
	for i in 260:
		await frames(1)
		p.global_position = Vector2(cr.global_position.x, 299.5)
		if Game.hp < hp0:
			break
	check(Game.hp <= hp0 - Game.max_hp(), "p6 crusher crushes Sera (hp %d)" % Game.hp)
	# Autômato: couraça na frente, ponto fraco nas costas
	var au = get_tree().get_nodes_in_group("automaton")[0]
	au.state = au.S.PAUSE
	au.t = 99.0
	au.facing = -1
	await place(au.global_position + Vector2(-90, 0), 1)
	au.state = au.S.STUN
	au.t = 99.0
	await frames(5)
	await tap("shoot")
	await frames(15)
	check(au.hp == 2, "p6 automaton armor blocks frontal rivet")
	au.facing = -1
	au.state = au.S.STUN
	au.t = 99.0
	await place(au.global_position + Vector2(90, 0), -1)
	await frames(5)
	await tap("shoot")
	await frames(15)
	check(au.hp == 1, "p6 rivet in the wind-up key hurts the automaton")
	# Investida machuca; rolando, passa
	p.invuln = 0.0
	var hp1: int = Game.hp
	au.facing = 1
	au.state = au.S.CHARGE
	au.t = 1.0
	au.hit_done = false
	await place(au.global_position + Vector2(30, 0), -1)
	await frames(20)
	check(Game.hp < hp1, "p6 automaton charge hurts")
	p.invuln = 0.0
	var hp2: int = Game.hp
	au.facing = 1
	au.state = au.S.CHARGE
	au.t = 1.0
	au.hit_done = false
	await place(au.global_position + Vector2(36, 0), -1)
	await tap("roll")
	await frames(20)
	check(Game.hp == hp2, "p6 rolling through the automaton's charge avoids the hit")
	# Plataforma de engrenagem leva Sera
	var plat = get_tree().get_nodes_in_group("platform")[0]
	await place(plat.global_position + Vector2(0, -0.5), 1)
	p.global_position = plat.global_position + Vector2(0, -0.5)
	var x0: float = p.global_position.x
	await frames(90)
	check(p.is_on_floor() and absf(p.global_position.x - x0) > 30.0, "p6 gear platform carries Sera (dx %.0f)" % (p.global_position.x - x0))
	# ---------------- Fase 8
	await load_phase(7)
	check(get_tree().get_nodes_in_group("platform").size() == 1 and get_tree().get_nodes_in_group("crusher").size() == 4,
		"p7 loads (platform + crushers)")
	# ---------------- Fase 9: o Regulador
	Game.checkpoint = {}
	await load_phase(8)
	Game.hp = 99
	p = g.player
	var reg = g.boss
	check(reg != null and reg.exit_lift != null and reg.exit_lift.locked, "p8 regulator locks exit")
	await place(Vector2(640 + 60, 299.5), 1)
	await frames(10)
	check(g.current_screen == Vector2i(1, 0) and bool(Game.cp().get("boss", false)), "p8 arena checkpoint")
	check(g.dialog.active, "p8 regulator intro dialog")
	for i in 40:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	check(reg.bar_visible and reg.state == reg.S.WAIT, "p8 regulator fight started")
	# Pêndulo varre o centro: em pé, Sera apanha
	reg.seq_i = 0
	reg._next_attack(p)
	check(reg.state == reg.S.SWING, "p8 pendulum released")
	var hp3: int = Game.hp
	var hit := false
	for i in 200:
		await frames(1)
		p.global_position = Vector2(reg.pivot.x, 299.5)
		p.velocity = Vector2.ZERO
		if Game.hp < hp3:
			hit = true
			break
	check(hit, "p8 pendulum blade hits standing Sera")
	# Freio na hora certa
	await place(Vector2(640 + 70, 299.5), 1)
	var ready_side := 0
	for i in 400:
		await frames(1)
		if reg.brake_ready(-1):
			ready_side = -1
			break
		if reg.brake_ready(1):
			ready_side = 1
			break
		if reg.state != reg.S.SWING:
			reg.seq_i = 0
			reg._next_attack(p)
	check(ready_side != 0, "p8 a brake became ready")
	var brake = null
	for b in get_tree().get_nodes_in_group("brake"):
		if b.side == ready_side:
			brake = b
	var hp_b: int = reg.hp
	await place(brake.global_position + Vector2(0, -0.5), 1)
	brake.interact(p)
	check(reg.hp == hp_b - reg.BRAKE_DMG and reg.state == reg.S.EXPOSED, "p8 brake jams pendulum (hp %d)" % reg.hp)
	await frames(30)
	await place(reg.core_pos() + Vector2(-90 * ready_side, 18).floor() + Vector2(0, -0.5), ready_side)
	p.global_position.y = 299.5
	await frames(5)
	for i in 4:
		await tap("shoot")
		await frames(20)
	check(reg.hp == hp_b - reg.BRAKE_DMG - reg.CORE_HITS, "p8 rivets hit exposed core (hp %d)" % reg.hp)
	check(reg.state == reg.S.RISE or reg.state == reg.S.WAIT, "p8 booth rises after core hits")
	# Derrota
	reg._damage(reg.hp)
	check(reg.state == reg.S.DYING, "p8 regulator dying")
	await frames(300)
	check(reg.state == reg.S.DEAD and not reg.exit_lift.locked, "p8 regulator destroyed, exit unlocked")
	await load_phase(8)
	check(g.current_screen == Vector2i(1, 0), "p8 respawn at arena checkpoint")
	# Save antigo parado no fim do Ato 2 vira começo do Ato 3
	release_all()
	var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"phase": 5, "hp": 2, "boss": true, "boss_seen": true, "inv": {"charge": 4},
		"progress": {"completed": [0, 1, 2, 3, 4, 5], "acts_complete": [0, 1]}, "settings": {"gore": true}}))
	f.close()
	Game.load_save()
	check(int(Game.checkpoint.get("phase", -1)) == 6 and not Game.checkpoint.has("boss"), "old end-of-act-2 save moves to Act 3")
	var map = load("res://scenes/progress_map.tscn").instantiate()
	add_child(map)
	await frames(5)
	check(map.sel == 6, "map opens on Act 3 (sel %d)" % map.sel)
	map.queue_free()
	var es = load("res://scenes/end_screen.tscn").instantiate()
	Game.end_act = 4
	add_child(es)
	await frames(5)
	check(es.title.text.contains("Fim"), "finale end screen")
	es.queue_free()
	await frames(2)
	Game.settings["gore"] = saved_gore
	Game.checkpoint = saved_cp
	Game.progress = saved_prog
	Game.clean_sera()
	if backup != "":
		var f2 := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		f2.store_string(backup)
		f2.close()


func _features() -> void:
	var backup := ""
	if FileAccess.file_exists(Game.SAVE_PATH):
		backup = FileAccess.get_file_as_string(Game.SAVE_PATH)
	var saved_cp: Dictionary = Game.checkpoint.duplicate()
	var saved_prog: Dictionary = Game.progress.duplicate(true)
	var saved_settings: Dictionary = Game.settings.duplicate(true)
	Game.checkpoint = {}
	Game.progress["upgrades"] = []
	# ---------------- Teclas
	Game.rebind("jump", KEY_K)
	var has_k := false
	var has_z := false
	for ev in InputMap.action_get_events("jump"):
		if ev is InputEventKey:
			has_k = has_k or ev.keycode == KEY_K
			has_z = has_z or ev.keycode == KEY_Z
	check(has_k and not has_z and Game.fmt("[jump]") == "K", "rebind jump to K")
	Game.rebind("shoot", KEY_K)
	check(Game.keycode_of("shoot") == KEY_K and Game.keycode_of("jump") == KEY_X, "rebinding a used key swaps them")
	Game.reset_keys()
	check(Game.keycode_of("jump") == KEY_Z and Game.keycode_of("shoot") == KEY_X, "reset keys")
	var sm = load("res://scripts/ui/settings_menu.gd").new()
	add_child(sm)
	await frames(3)
	check(sm.key_buttons.size() == Game.REBINDABLE.size(), "settings screen lists every action")
	sm.queue_free()
	# ---------------- Abertura de fase
	Game.phase_intro = true
	await load_phase(6)
	var p = g.player
	check(g.cutscene and p.entering, "phase intro: Sera walks in, input locked")
	await frames(150)
	check(not p.entering and g.cutscene, "phase intro waits for a key")
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(5)
	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_SPACE
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await frames(3)
	check(not g.cutscene, "phase intro starts on key press")
	# ---------------- Trotar / correr
	Game.hp = 99
	Game.run_mode = true
	await place(Vector2(60, 299.5), 1)
	Input.action_press("move_right")
	await frames(40)
	var run_v: float = absf(p.velocity.x)
	Input.action_release("move_right")
	Game.run_mode = false
	check(run_v > 200.0, "run mode is faster (%.0f)" % run_v)
	# ---------------- Moradores que dão dicas
	var npcs := get_tree().get_nodes_in_group("npc")
	check(npcs.size() > 0, "hint NPCs spawned (%d)" % npcs.size())
	if npcs.size() > 0:
		var n = npcs[0]
		await place(n.global_position + Vector2(-14, 0), 1)
		await frames(5)
		await tap("interact")
		await frames(3)
		check(g.dialog.active, "talking to an NPC opens a dialog")
		for i in 20:
			await tap("interact")
			await frames(3)
			if not g.dialog.active:
				break
		n.react(n.global_position + Vector2(-10, -10))
		check(n.reaction != "", "NPC reacts to gore (%s)" % n.reaction)
	# ---------------- Upgrades
	await load_phase(6)
	p = g.player
	Game.hp = 2
	await place(Vector2(200, 299.5), 1)
	var UpS = load("res://scripts/entities/upgrade_pickup.gd")
	var up = UpS.new()
	up.setup(p.global_position + Vector2(0, -14), "vida")
	g.level.add_child(up)
	await frames(5)
	check(Game.has_upgrade("vida") and Game.max_hp() == 5 and Game.hp == 5, "boss prize: +1 life square")
	# Arpão de mão atravessa o escudo
	Game.grant_upgrade("arpao")
	var GuardS = load("res://scripts/entities/guard.gd")
	var sg = GuardS.new()
	sg.position = Vector2(330, 299.5)
	sg.shielded = true
	sg.facing = -1
	g.level.add_child(sg)
	await frames(3)
	sg.state = sg.S.PAUSE
	sg.t = 99.0
	Input.action_press("shoot")
	await frames(45)
	Input.action_release("shoot")
	await frames(20)
	check(not sg.is_alive(), "charged harpoon pierces a shield guard")
	# Couraça absorve um golpe
	Game.grant_upgrade("couraca")
	p.on_upgrade("couraca")
	p.invuln = 0.0
	var hp0: int = Game.hp
	p.hurt(1, "bullet")
	check(Game.hp == hp0 and p.armor == 0, "brass armor absorbs a hit")
	p.invuln = 0.0
	p.hurt(1, "bullet")
	check(Game.hp == hp0 - 1, "next hit goes through")
	check(get_tree().get_nodes_in_group("upgrade").size() == 0, "upgrade pickup collected")
	release_all()
	Game.settings = saved_settings
	Game.apply_keys()
	Game.checkpoint = saved_cp
	Game.progress = saved_prog
	if backup != "":
		var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()


func _act45() -> void:
	var backup := ""
	if FileAccess.file_exists(Game.SAVE_PATH):
		backup = FileAccess.get_file_as_string(Game.SAVE_PATH)
	var saved_cp: Dictionary = Game.checkpoint.duplicate()
	var saved_prog: Dictionary = Game.progress.duplicate(true)
	Game.checkpoint = {}
	Game.progress["upgrades"] = []
	# ---------------- Fase 10: Poço de Escória
	await load_phase(9)
	Game.hp = 99
	var p = g.player
	check(g.level.theme == "foundry" and not g.level.belts.is_empty(), "p9 foundry theme with belts")
	# Esteira arrasta Sera
	var belt_cell: Vector2i = g.level.belts.keys()[0]
	var bx: float = belt_cell.x * 20.0 + 10.0
	await place(Vector2(bx, belt_cell.y * 20.0 - 0.5), 1)
	var x0: float = p.global_position.x
	await frames(30)
	check(p.global_position.x - x0 > 10.0, "p9 conveyor belt drags Sera (dx %.0f)" % (p.global_position.x - x0))
	# Ferro fundido mata, mesmo rolando
	var lava = get_tree().get_nodes_in_group("lava")[0]
	await place(Vector2(lava.rect.get_center().x, lava.rect.position.y - 20.0), 1)
	await frames(30)
	check(p.is_dead(), "p9 molten iron kills Sera")
	await load_phase(9)
	Game.hp = 99
	p = g.player
	# Registro de resfriamento faz crosta
	var valves := get_tree().get_nodes_in_group("cooling_valve")
	check(valves.size() == 1, "p9 cooling valve spawned")
	var v = valves[0]
	await place(v.global_position + Vector2(0, -0.5), 1)
	await tap("interact")
	await frames(20)
	var crusted := false
	for l in get_tree().get_nodes_in_group("lava"):
		if l.is_crusted():
			crusted = true
			# Anda por cima da crosta
			await place(Vector2(l.rect.get_center().x, l.rect.position.y - 2.0), 1)
			await frames(20)
			check(not p.is_dead() and p.is_on_floor(), "p9 Sera walks on the crust")
	check(crusted, "p9 water crusts the molten iron")
	# Botas de Pressão: impulso no ar
	Game.grant_upgrade("botas")
	await place(Vector2(80, 299.5), 1)
	await frames(3)
	Input.action_press("jump")
	await frames(6)
	Input.action_release("jump")
	await frames(4)
	var ax: float = p.global_position.x
	await tap("roll")
	await frames(10)
	check(p.global_position.x - ax > 30.0 and p.state != p.S.ROLL, "pressure boots air dash (dx %.0f)" % (p.global_position.x - ax))
	# ---------------- Fase 12: Fornalha-Mãe
	await load_phase(11)
	Game.hp = 99
	p = g.player
	var gol = g.boss
	check(gol != null and gol.exit_lift != null and gol.exit_lift.locked, "p11 forge golem locks exit")
	await place(Vector2(640 + 60, 299.5), 1)
	await frames(10)
	check(g.dialog.active, "p11 golem intro dialog")
	for i in 30:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	check(gol.bar_visible and gol.state == gol.S.WADE, "p11 golem fight started")
	await frames(30)
	# Água fria em cima do golem
	var gv = null
	var best := INF
	for vv in get_tree().get_nodes_in_group("cooling_valve"):
		var d: float = absf(vv.nozzle.x - gol.global_position.x)
		if d < best:
			best = d
			gv = vv
	gol.position.x = gv.nozzle.x
	gol.target_x = gv.nozzle.x
	gol.state = gol.S.THROW
	gol.throws_left = 0
	gol.t = 99.0
	var hp0: int = gol.hp
	await place(gv.global_position + Vector2(0, -0.5), 1)
	await tap("interact")
	await frames(10)
	check(gol.state == gol.S.COOLED and gol.hp == hp0 - gol.COOL_DMG, "p11 water cools the golem (hp %d)" % gol.hp)
	# Rebites no núcleo exposto
	var side := -1 if gv.global_position.x < gol.global_position.x else 1
	await place(Vector2(gv.global_position.x, 299.5), -side)
	await frames(6)
	for i in 3:
		await tap("shoot")
		await frames(20)
	check(gol.hp == hp0 - gol.COOL_DMG - 3, "p11 rivets hit the cooled core (hp %d)" % gol.hp)
	gol._damage(gol.hp)
	await frames(260)
	check(gol.state == gol.S.DEAD and not gol.exit_lift.locked, "p11 golem defeated, exit unlocked")
	check(get_tree().get_nodes_in_group("upgrade").size() == 1, "p11 golem drops the pressure boots")
	# ---------------- Fase 13: vento
	await load_phase(12)
	Game.hp = 99
	p = g.player
	check(g.wind != null and g.wind.strength > 0.0, "p12 wind phase")
	g.wind.state = 2
	g.wind.t = 5.0
	g.wind.dir = 1
	await place(Vector2(120, 299.5), 1)
	p.velocity = Vector2.ZERO
	p.global_position.y = 200.0
	await frames(10)
	check(p.velocity.x > 20.0, "p12 gust pushes Sera in the air (vx %.0f)" % p.velocity.x)
	# ---------------- Fase 15: o Tecelão
	await load_phase(14)
	Game.hp = 99
	p = g.player
	var wv = g.boss
	check(wv != null and wv.exit_lift.locked, "p14 weaver locks exit")
	await place(Vector2(640 + 60, 299.5), 1)
	await frames(10)
	for i in 40:
		await tap("interact")
		await frames(4)
		if not g.dialog.active:
			break
	check(wv.bar_visible and wv.state == wv.S.WAIT, "p14 weaver fight started")
	# Lançadeira atravessa e fere quem estiver em pé
	wv.seq_i = 0
	wv._next_attack(p)
	wv.sh_y = wv.floor_y - 22.0
	var hp1: int = Game.hp
	for i in 120:
		await frames(1)
		p.global_position = Vector2(640 + 320, 299.5)
		if Game.hp < hp1:
			break
	check(Game.hp < hp1, "p14 shuttle hits standing Sera")
	for i in 60:
		await frames(1)
		if wv.state == wv.S.OPEN:
			break
	check(wv.state == wv.S.OPEN, "p14 the loom eye opens after an attack")
	# Da plataforma da esquerda, rebites no olho
	await place(Vector2(640 + 150, 179.5), 1)
	p.invuln = 99.0
	await frames(5)
	var whp: int = wv.hp
	for i in 3:
		await tap("shoot")
		await frames(20)
	check(wv.hp < whp, "p14 rivets hit the loom eye (hp %d)" % wv.hp)
	wv._damage(wv.hp - 12)
	check(wv.stage == 3 and g.wind.strength > 0.0, "p14 stage 3 brings the wind")
	wv._damage(wv.hp)
	await frames(300)
	check(wv.state == wv.S.DEAD and not wv.exit_lift.locked and g.wind.strength == 0.0, "p14 weaver destroyed, exit unlocked")
	# ---------------- Mapa e saves
	release_all()
	var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"phase": 8, "hp": 5, "boss": true, "boss_seen": true, "inv": {"charge": 2},
		"progress": {"completed": [0, 1, 2, 3, 4, 5, 6, 7, 8], "acts_complete": [0, 1, 2]}, "settings": {"gore": true}}))
	f.close()
	Game.load_save()
	check(int(Game.checkpoint.get("phase", -1)) == 9 and Game.has_upgrade("couraca"), "end-of-act-3 save continues into Act 4")
	var map = load("res://scenes/progress_map.tscn").instantiate()
	add_child(map)
	await frames(5)
	check(map.NODES.size() == Game.PHASE_COUNT and map.sel == 9, "map has 15 phases and opens on Act 4")
	map.queue_free()
	for act in [2, 3, 4]:
		var es = load("res://scenes/end_screen.tscn").instantiate()
		Game.end_act = act
		add_child(es)
		await frames(3)
		es.queue_free()
		await frames(2)
	check(true, "end screens for acts 3-5 load")
	Game.checkpoint = saved_cp
	Game.progress = saved_prog
	if backup != "":
		var f2 := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		f2.store_string(backup)
		f2.close()


func _extras() -> void:
	var backup := ""
	if FileAccess.file_exists(Game.SAVE_PATH):
		backup = FileAccess.get_file_as_string(Game.SAVE_PATH)
	var saved_cp: Dictionary = Game.checkpoint.duplicate()
	var saved_prog: Dictionary = Game.progress.duplicate(true)
	var saved_lang: String = Game.language()
	Game.checkpoint = {}
	Game.progress["upgrades"] = []
	# ---------------- Tradução
	TranslationServer.set_locale("en")
	check(tr("Novo jogo") == "New game" and tr("Fase 7 — Átrio de Bronze") == "Stage 7 — Bronze Atrium", "English translation loads")
	TranslationServer.set_locale("pt_BR")
	check(tr("Novo jogo") == "Novo jogo", "Portuguese stays as source")
	Game.apply_language()
	# ---------------- Console de testes
	await load_phase(0)
	var p = g.player
	var con = null
	for n in g.get_children():
		if n.has_method("run") and n.has_method("toggle"):
			con = n
	check(con != null, "test console exists")
	con.run("god")
	Game.hp = 2
	p.hurt(1, "bullet")
	check(Game.god_mode and Game.hp == 2, "console: god mode blocks damage")
	con.run("god")
	con.run("vida")
	con.run("municao")
	con.run("upgrades")
	check(Game.hp == Game.max_hp() and Game.tool_count("charge") == 9 and Game.has_upgrade("botas") and p.armor == 1, "console: health, ammo, upgrades, shield")
	Game.progress["upgrades"] = []
	# ---------------- Fresta: Sera atrás de quem passa e na sombra
	var cover = get_tree().get_nodes_in_group("cover")[0]
	await place(cover.global_position + Vector2(0, -0.5), 1)
	Input.action_press("move_up")
	await frames(4)
	Input.action_release("move_up")
	await frames(4)
	check(p.in_cover and p.z_index < 3 and p.fill_light.energy < p.fill_light.base_energy, "cover: Sera behind NPCs and in shadow")
	release_all()
	# ---------------- Indicadores de interação
	var has_markers := false
	for n in g.level.get_children():
		if n.has_method("_draw") and n.get_script() == load("res://scripts/interact_markers.gd"):
			has_markers = true
	check(has_markers, "interaction markers present")
	# ---------------- Arena trancada
	await load_phase(5)
	Game.hp = 99
	p = g.player
	await place(Vector2(1280 + 80, 299.5), 1)
	await frames(10)
	check(g.arena_walls != null, "boss arena is locked")
	for i in 30:
		if g.dialog.active:
			g.dialog._close()
		await frames(1)
	p.global_position = Vector2(1280 + 30, 299.5)
	Input.action_press("move_left")
	await frames(60)
	Input.action_release("move_left")
	check(p.global_position.x >= 1280.0 - 2.0, "cannot leave the boss arena (x=%.0f)" % p.global_position.x)
	release_all()
	Game.checkpoint = saved_cp
	Game.progress = saved_prog
	Game.settings["lang"] = saved_lang
	Game.apply_language()
	if backup != "":
		var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
