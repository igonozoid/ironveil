extends Node2D
## Constrói uma fase a partir das telas ASCII: colisão, desenho dos blocos,
## fundo procedural e todas as entidades (com seus vínculos).

const TILE := 20
const SW := 32
const SH := 18

const GuardScript := preload("res://scripts/entities/guard.gd")
const DroneScript := preload("res://scripts/entities/drone.gd")
const VentScript := preload("res://scripts/entities/steam_vent.gd")
const ValveScript := preload("res://scripts/entities/valve.gd")
const LeverScript := preload("res://scripts/entities/lever.gd")
const PanelScript := preload("res://scripts/entities/panel.gd")
const LiftScript := preload("res://scripts/entities/lift.gd")
const BossScript := preload("res://scripts/entities/boss.gd")
const DoorScript := preload("res://scripts/entities/door.gd")
const GrateScript := preload("res://scripts/entities/grate.gd")
const FallingGrateScript := preload("res://scripts/entities/falling_grate.gd")
const JunctionScript := preload("res://scripts/entities/junction_box.gd")
const GrappleScript := preload("res://scripts/entities/grapple_point.gd")
const PickupScript := preload("res://scripts/entities/pickup.gd")
const HintScript := preload("res://scripts/entities/hint.gd")
const NpcScript := preload("res://scripts/entities/npc.gd")
const CoverScript := preload("res://scripts/entities/cover_spot.gd")
const TomeScript := preload("res://scripts/entities/tome.gd")
const ZiplineScript := preload("res://scripts/entities/zipline.gd")
const PlankScript := preload("res://scripts/entities/plank.gd")
const SearchlightScript := preload("res://scripts/entities/searchlight.gd")
const CivilianScript := preload("res://scripts/entities/civilian.gd")
const LiraScript := preload("res://scripts/entities/ally_lira.gd")
const AirshipScript := preload("res://scripts/entities/airship.gd")
const HarpoonScript := preload("res://scripts/entities/harpoon_cannon.gd")
const LogbookScript := preload("res://scripts/entities/logbook.gd")
const PlatformScript := preload("res://scripts/entities/moving_platform.gd")
const CrusherScript := preload("res://scripts/entities/crusher.gd")
const TurretScript := preload("res://scripts/entities/turret.gd")
const AutomatonScript := preload("res://scripts/entities/automaton.gd")
const RegulatorScript := preload("res://scripts/entities/regulator.gd")
const BrakeScript := preload("res://scripts/entities/pendulum_brake.gd")
const Light := preload("res://scripts/fx/light.gd")
const LavaScript := preload("res://scripts/entities/lava.gd")
const ValveCoolScript := preload("res://scripts/entities/cooling_valve.gd")
const GolemScript := preload("res://scripts/entities/forge_golem.gd")
const WeaverScript := preload("res://scripts/entities/weaver.gd")

const C_DEEP := Color("332b28")
const C_HATCH := Color("3b322e")
const C_IRON := Color("3d3735")
const C_IRON2 := Color("443d3a")
const C_RIM := Color("8a5a2b")
const C_RIM_L := Color("c07a3a")
const C_RUST := Color("6e2f18")
const C_RIVET := Color("5e5450")

var screens: Dictionary = {}       # Vector2i -> Array (linhas)
var solid: Dictionary = {}         # Vector2i -> true
var oneway: Dictionary = {}        # Vector2i -> true
var markers: Dictionary = {}       # String -> Array[Vector2i]
var hang_points: Array = []        # Vector2 (pontos de agarrar extras: rebites)
var player_start := Vector2(70, 300)
var phase_index := 0
var warm_light := false
var exit_prompt := "A: subir"
## "boiler" (Ato 1), "market" (Ato 2), "tower" (Ato 3), "foundry" (Ato 4) ou "veil" (Ato 5).
var theme := "boiler"
## Sem chão abaixo das telas de baixo: cair é morte.
var abyss := false

var lifts: Array = []
var boss = null
var boss_spawn := Vector2.INF
var doors: Array = []
var falling_grates: Array = []
## Luzes 2D fixas do cenário: [luz, tela]. Só as da tela atual ficam acesas.
var lights: Array = []
var lights_made := false
var npc_spots: Array = []
## Esteiras: célula -> direção (+1 direita, -1 esquerda). Contam como sólidas.
var belts: Dictionary = {}
var lit_screen := Vector2i(99999, 99999)


# ---------------------------------------------------------------- consultas

func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


func screen_of_cell(c: Vector2i) -> Vector2i:
	return Vector2i(floori(float(c.x) / SW), floori(float(c.y) / SH))


func screen_of_pos(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / (SW * TILE)), floori(p.y / (SH * TILE)))


func has_screen(s: Vector2i) -> bool:
	return screens.has(s)


func screen_rect(s: Vector2i) -> Rect2:
	return Rect2(Vector2(s.x * SW * TILE, s.y * SH * TILE), Vector2(SW * TILE, SH * TILE))


## Célula sólida (blocos estáticos). Fora das telas existentes conta como sólido.
func is_solid(c: Vector2i) -> bool:
	if solid.has(c) or belts.has(c):
		return true
	return not screens.has(screen_of_cell(c))


func is_oneway(c: Vector2i) -> bool:
	return oneway.has(c)


func cell_bottom_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, (c.y + 1) * TILE)


func cell_top_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, c.y * TILE)


func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, c.y * TILE + TILE * 0.5)


func _marks(ch: String) -> Array:
	return markers.get(ch, [])


# ---------------------------------------------------------------- construção

func build(data: Dictionary) -> void:
	phase_index = int(data.get("index", 0))
	warm_light = bool(data.get("warm_light", false))
	exit_prompt = String(data.get("exit_prompt", "A: subir"))
	theme = String(data.get("theme", "boiler"))
	abyss = bool(data.get("abyss", false))
	var scr: Dictionary = data["screens"]
	var hints: Dictionary = data.get("hints", {})
	for key in scr.keys():
		var parts := String(key).split(",")
		screens[Vector2i(int(parts[0]), int(parts[1]))] = scr[key]

	for s in screens.keys():
		var rows: Array = screens[s]
		var hint_list: Array = hints.get("%d,%d" % [s.x, s.y], [])
		var hi := 0
		for ly in rows.size():
			var row: String = rows[ly]
			for lx in row.length():
				var ch := row[lx]
				var c := Vector2i(s.x * SW + lx, s.y * SH + ly)
				if ch == "#":
					solid[c] = true
				elif ch == "-":
					oneway[c] = true
				elif ch == ">" or ch == "<":
					belts[c] = 1 if ch == ">" else -1
				elif ch == "?":
					# Morador que dá a dica conversando (texto vazio = ninguém).
					var txt := ""
					if hi < hint_list.size():
						txt = String(hint_list[hi])
					hi += 1
					if txt != "":
						npc_spots.append([c, txt])
				elif ch != ".":
					if not markers.has(ch):
						markers[ch] = []
					markers[ch].append(c)

	_build_collision()
	_build_belts()
	_build_screen_walls()
	_spawn_entities()
	_spawn_npcs()

	var bg := Backdrop.new()
	bg.level = self
	bg.z_index = -20
	add_child(bg)
	queue_redraw()


func _bounds() -> Rect2i:
	var mn := Vector2i(1 << 20, 1 << 20)
	var mx := Vector2i(-(1 << 20), -(1 << 20))
	for s in screens.keys():
		mn.x = mini(mn.x, s.x * SW)
		mn.y = mini(mn.y, s.y * SH)
		mx.x = maxi(mx.x, s.x * SW + SW - 1)
		mx.y = maxi(mx.y, s.y * SH + SH - 1)
	return Rect2i(mn, mx - mn + Vector2i.ONE)


## Junta células em retângulos (corridas horizontais estendidas para baixo).
func _merge_cells(cells: Dictionary) -> Array:
	var b := _bounds()
	var result: Array = []
	var open: Dictionary = {}
	for y in range(b.position.y, b.end.y + 1):
		var runs: Array = []
		var x := b.position.x
		while x < b.end.x:
			if cells.has(Vector2i(x, y)):
				var x0 := x
				while x < b.end.x and cells.has(Vector2i(x, y)):
					x += 1
				runs.append(Vector2i(x0, x - 1))
			else:
				x += 1
		var new_open: Dictionary = {}
		for k in runs:
			if open.has(k):
				var r: Rect2i = open[k]
				r.size.y += 1
				new_open[k] = r
			else:
				new_open[k] = Rect2i(k.x, y, k.y - k.x + 1, 1)
		for k in open.keys():
			if not new_open.has(k):
				result.append(open[k])
		open = new_open
	for k in open.keys():
		result.append(open[k])
	return result


func _add_rect_shape(body: CollisionObject2D, r: Rect2) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.position + r.size * 0.5
	body.add_child(cs)
	return cs


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Solids"
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("solid")
	add_child(body)
	for r in _merge_cells(solid):
		var rr: Rect2i = r
		_add_rect_shape(body, Rect2(Vector2(rr.position * TILE), Vector2(rr.size * TILE)))
	if not oneway.is_empty():
		var ow := StaticBody2D.new()
		ow.name = "OneWay"
		ow.collision_layer = 16
		ow.collision_mask = 0
		add_child(ow)
		for c in oneway.keys():
			var cs := _add_rect_shape(ow, Rect2(Vector2(c.x * TILE, c.y * TILE), Vector2(TILE, 6)))
			cs.one_way_collision = true


## Paredes invisíveis nas bordas de telas sem vizinha.
func _build_screen_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "ScreenWalls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var w := SW * TILE
	var h := SH * TILE
	for s in screens.keys():
		var o := Vector2(s.x * w, s.y * h)
		if not screens.has(s + Vector2i(1, 0)):
			_add_rect_shape(body, Rect2(o + Vector2(w, 0), Vector2(TILE, h)))
		if not screens.has(s + Vector2i(-1, 0)):
			_add_rect_shape(body, Rect2(o + Vector2(-TILE, 0), Vector2(TILE, h)))
		if not screens.has(s + Vector2i(0, 1)) and not abyss:
			_add_rect_shape(body, Rect2(o + Vector2(0, h), Vector2(w, TILE)))
		if not screens.has(s + Vector2i(0, -1)):
			_add_rect_shape(body, Rect2(o + Vector2(0, -TILE), Vector2(w, TILE)))


func _scan_free(c: Vector2i, dir: Vector2i, max_cells: int) -> int:
	var n := 0
	var cur := c
	while n < max_cells and not is_solid(cur):
		n += 1
		cur += dir
	return n


func _nearest(list: Array, pos: Vector2, filter: Callable = Callable()):
	var best = null
	var best_d := INF
	for n in list:
		if filter.is_valid() and not filter.call(n):
			continue
		var d: float = n.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = n
	return best


func _spawn_entities() -> void:
	# Início de Sera
	for c in _marks("@"):
		player_start = cell_bottom_center(c) - Vector2(0, 0.5)

	# Elevadores de carga (E -> e), guindaste (K -> k) e saída (X)
	for pair in [["E", "e", "lift"], ["K", "k", "crane"]]:
		for c in _marks(pair[0]):
			var dest: Vector2i = c
			var best := 1 << 20
			for d in _marks(pair[1]):
				if d.x == c.x and absi(d.y - c.y) < best:
					best = absi(d.y - c.y)
					dest = d
			var lift = LiftScript.new()
			lift.setup(cell_top_center(c), cell_top_center(dest), pair[2], self)
			add_child(lift)
			lifts.append(lift)
	for c in _marks("Y"):
		var dest: Vector2i = c
		for d in _marks("y"):
			if d.x == c.x:
				dest = d
		var al = LiftScript.new()
		al.setup(cell_top_center(c), cell_top_center(dest), "arena", self)
		al.prompt = "A: subir pelo poço"
		add_child(al)
		lifts.append(al)
	for c in _marks("X"):
		var lift = LiftScript.new()
		lift.setup(cell_top_center(c), cell_top_center(c) - Vector2(0, 7 * TILE), "exit", self)
		lift.prompt = exit_prompt
		add_child(lift)
		lifts.append(lift)

	# Portas
	for pair in [["B", "blast"], ["S", "security"]]:
		for c in _marks(pair[0]):
			var cells := _scan_free(c, Vector2i(0, 1), 6)
			var door = DoorScript.new()
			door.setup(Vector2(c.x * TILE, c.y * TILE), float(cells * TILE), pair[1])
			add_child(door)
			doors.append(door)

	# Jatos de vapor
	var vents: Array = []
	var vent_index := 0
	for pair in [["v", -1, "trigger"], ["w", 1, "trigger"], ["p", -1, "periodic"]]:
		for c in _marks(pair[0]):
			var dir: int = pair[1]
			var length := _scan_free(c, Vector2i(0, dir), 5) * TILE
			var origin := cell_bottom_center(c) if dir < 0 else cell_top_center(c)
			var vent = VentScript.new()
			vent.setup(origin, dir, float(length), pair[2], vent_index * 1.3)
			vent_index += 1
			add_child(vent)
			vents.append(vent)

	for c in _marks("V"):
		var valve = ValveScript.new()
		valve.position = cell_bottom_center(c)
		var my_screen := screen_of_cell(c)
		for v in vents:
			if v.mode == "trigger" and screen_of_pos(v.position + Vector2(0, -2 * v.dir)) == my_screen:
				valve.vents.append(v)
		add_child(valve)

	for c in _marks("L"):
		var lever = LeverScript.new()
		lever.position = cell_bottom_center(c)
		lever.lift = _nearest(lifts, cell_center(c), func(l): return l.mode == "lift")
		add_child(lever)

	for c in _marks("P"):
		var panel = PanelScript.new()
		panel.position = cell_bottom_center(c)
		panel.door = _nearest(doors, cell_center(c), func(d): return d.kind == "blast")
		add_child(panel)

	# Grades quebráveis: colunas contíguas de H viram uma grade só.
	var hset: Dictionary = {}
	for c in _marks("H"):
		hset[c] = true
	var visited: Dictionary = {}
	for c in _marks("H"):
		if visited.has(c) or hset.has(c + Vector2i(0, -1)):
			continue
		var n := 0
		var cur: Vector2i = c
		while hset.has(cur):
			visited[cur] = true
			n += 1
			cur += Vector2i(0, 1)
		var grate = GrateScript.new()
		grate.setup(Rect2(Vector2(c.x * TILE, c.y * TILE), Vector2(TILE, n * TILE)))
		add_child(grate)

	for c in _marks("F"):
		var up := _scan_free(c + Vector2i(0, -1), Vector2i(0, -1), 12)
		var fg = FallingGrateScript.new()
		fg.setup(cell_top_center(c) + Vector2(0, 4), float(c.y * TILE - up * TILE), self)
		add_child(fg)
		falling_grates.append(fg)

	for c in _marks("J"):
		var j = JunctionScript.new()
		j.position = cell_center(c)
		j.grate = _nearest(falling_grates, cell_center(c))
		add_child(j)

	for c in _marks("O"):
		var gp = GrappleScript.new()
		gp.position = cell_top_center(c)
		add_child(gp)

	for pair in [["1", "charge", 2], ["2", "sealant", 1], ["3", "card", 1]]:
		for c in _marks(pair[0]):
			var pk = PickupScript.new()
			pk.setup(cell_center(c), pair[1], pair[2])
			add_child(pk)

	for c in _marks("R"):
		var cv = CoverScript.new()
		cv.position = cell_bottom_center(c)
		add_child(cv)
		add_light(cell_bottom_center(c) + Vector2(0, -36), Color(1.0, 0.68, 0.32), 46.0, 0.8, 0.08)

	for c in _marks("T"):
		var tome = TomeScript.new()
		tome.position = cell_bottom_center(c)
		tome.crane = _nearest(lifts, cell_center(c), func(l): return l.mode == "crane")
		add_child(tome)

	for pair in [["G", false], ["g", true]]:
		for c in _marks(pair[0]):
			var g = GuardScript.new()
			g.position = cell_bottom_center(c) - Vector2(0, 0.5)
			g.shielded = pair[1]
			add_child(g)
			# Intenso/Insano: mais guardas por posição.
			for pos in _extra_spots(cell_bottom_center(c), Game.extra_enemies()):
				var e = GuardScript.new()
				e.position = pos
				e.shielded = pair[1] and randf() < 0.5
				add_child(e)

	# Tirolesas: cada Z liga ao z mais próximo.
	for c in _marks("Z"):
		var best = null
		var bd := INF
		for d in _marks("z"):
			var dd: float = Vector2(d - c).length()
			if dd < bd:
				bd = dd
				best = d
		if best != null:
			var zl = ZiplineScript.new()
			zl.setup(cell_center(c), cell_center(best))
			add_child(zl)

	for c in _marks("b"):
		var pl = PlankScript.new()
		pl.setup(Vector2(c.x * TILE, c.y * TILE))
		add_child(pl)

	var lamp_i := 0
	for c in _marks("N"):
		var sl = SearchlightScript.new()
		var r := screen_rect(screen_of_cell(c))
		var f := 1 if cell_bottom_center(c).x < r.get_center().x else -1
		sl.setup(cell_bottom_center(c), f, lamp_i * 1.7)
		lamp_i += 1
		add_child(sl)

	var civ_i := 0
	for c in _marks("c"):
		var cv = CivilianScript.new()
		cv.setup(cell_bottom_center(c), civ_i + phase_index * 31)
		civ_i += 1
		add_child(cv)

	for c in _marks("l"):
		var lira = LiraScript.new()
		lira.position = cell_bottom_center(c)
		lira.door = _nearest(doors, cell_center(c), func(d): return d.kind == "blast")
		add_child(lira)

	for c in _marks("Q"):
		var lb = LogbookScript.new()
		lb.position = cell_bottom_center(c)
		add_child(lb)

	for c in _marks("&"):
		boss_spawn = cell_bottom_center(c) - Vector2(0, 0.5)

	for c in _marks("h"):
		var hc = HarpoonScript.new()
		hc.position = cell_bottom_center(c)
		add_child(hc)

	for c in _marks("A"):
		var scr := screen_of_cell(c)
		var fy: Vector2i = c
		var n := 0
		while n < 30 and not is_solid(fy):
			fy.y += 1
			n += 1
		var ship = AirshipScript.new()
		ship.setup(cell_center(c), screen_rect(scr), float(fy.y * TILE))
		add_child(ship)
		boss = ship
		for l in lifts:
			if l.mode == "exit" and screen_of_pos(l.position + Vector2(0, -4)) == scr:
				l.locked = true
				ship.exit_lift = l

	for c in _marks("M"):
		boss = BossScript.new()
		var scr := screen_of_cell(c)
		boss.setup(cell_bottom_center(c) - Vector2(0, 0.5), screen_rect(scr))
		add_child(boss)
		for l in lifts:
			if l.mode == "exit" and screen_of_pos(l.position + Vector2(0, -4)) == scr:
				l.locked = true
				boss.exit_lift = l

	# Ato 3 — plataformas de engrenagem: cada m vai até o n mais próximo.
	var plat_i := 0
	for c in _marks("m"):
		var best = null
		var bd := INF
		for d in _marks("n"):
			var dd: float = Vector2(d - c).length()
			if dd < bd:
				bd = dd
				best = d
		var top := Vector2(c.x * TILE + TILE * 0.5, c.y * TILE + 2.0)
		var dest := top
		if best != null:
			dest = Vector2(best.x * TILE + TILE * 0.5, best.y * TILE + 2.0)
		var mp = PlatformScript.new()
		mp.setup(top, dest, fmod(plat_i * 0.37, 1.0))
		plat_i += 1
		add_child(mp)

	var crush_i := 0
	for c in _marks("u"):
		var up := _scan_free(c, Vector2i(0, -1), 18)
		var down := _scan_free(c, Vector2i(0, 1), 18)
		var cr = CrusherScript.new()
		cr.setup(c.x * TILE + TILE * 0.5, float((c.y - up + 1) * TILE), float((c.y + down) * TILE), crush_i * 0.7)
		crush_i += 1
		add_child(cr)

	var tur_i := 0
	for c in _marks("t"):
		var tu = TurretScript.new()
		var r := screen_rect(screen_of_cell(c))
		var f := 1 if cell_bottom_center(c).x < r.get_center().x else -1
		tu.setup(cell_bottom_center(c), f, tur_i * 1.3)
		tur_i += 1
		add_child(tu)

	for c in _marks("a"):
		var au = AutomatonScript.new()
		au.position = cell_bottom_center(c) - Vector2(0, 0.5)
		add_child(au)
		for pos in _extra_spots(cell_bottom_center(c), 1 if Game.extra_enemies() >= 2 else 0):
			var ea = AutomatonScript.new()
			ea.position = pos
			add_child(ea)

	for c in _marks("f"):
		var br = BrakeScript.new()
		var r := screen_rect(screen_of_cell(c))
		br.setup(cell_bottom_center(c), -1 if cell_bottom_center(c).x < r.get_center().x else 1)
		add_child(br)

	for c in _marks("W"):
		var scr := screen_of_cell(c)
		var fy: Vector2i = c
		var n := 0
		while n < 30 and not is_solid(fy):
			fy.y += 1
			n += 1
		var reg = RegulatorScript.new()
		reg.setup(cell_center(c), screen_rect(scr), float(fy.y * TILE))
		add_child(reg)
		boss = reg
		for l in lifts:
			if l.mode == "exit" and screen_of_pos(l.position + Vector2(0, -4)) == scr:
				l.locked = true
				reg.exit_lift = l

	# Ato 4 — ferro fundido: cada trecho horizontal de ~ vira uma poça.
	var seen_lava: Dictionary = {}
	for c in _marks("~"):
		if seen_lava.has(c) or _marks("~").has(c + Vector2i(-1, 0)):
			continue
		var n2 := 0
		var cur2: Vector2i = c
		while _marks("~").has(cur2):
			seen_lava[cur2] = true
			n2 += 1
			cur2 += Vector2i(1, 0)
		var lv = LavaScript.new()
		lv.setup(Rect2(Vector2(c.x * TILE, c.y * TILE), Vector2(n2 * TILE, TILE)))
		add_child(lv)

	# Registros de resfriamento: alavanca j -> bico q mais próximo
	for c in _marks("j"):
		var best_q = null
		var bq := INF
		for q in _marks("q"):
			var dq: float = Vector2(q - c).length()
			if dq < bq:
				bq = dq
				best_q = q
		if best_q == null:
			continue
		var fl: Vector2i = best_q + Vector2i(0, 1)
		var guard_n := 0
		while guard_n < 20 and not solid.has(fl):
			fl.y += 1
			guard_n += 1
		var cv2 = ValveCoolScript.new()
		cv2.setup(cell_bottom_center(c), cell_center(best_q), float(fl.y * TILE))
		add_child(cv2)

	for c in _marks("U"):
		var scr := screen_of_cell(c)
		# A poça mais larga da tela é a casa do golem.
		var lx0 := INF
		var lx1 := -INF
		var ly := 0.0
		for lc in _marks("~"):
			if screen_of_cell(lc) == scr:
				lx0 = minf(lx0, lc.x * TILE)
				lx1 = maxf(lx1, (lc.x + 1) * TILE)
				ly = lc.y * TILE + 6.0
		var gol = GolemScript.new()
		gol.setup(cell_bottom_center(c), screen_rect(scr), ly, lx0, lx1)
		add_child(gol)
		boss = gol
		for l in lifts:
			if l.mode == "exit" and screen_of_pos(l.position + Vector2(0, -4)) == scr:
				l.locked = true
				gol.exit_lift = l

	for c in _marks("I"):
		var scr := screen_of_cell(c)
		var fy2: Vector2i = c
		var n3 := 0
		while n3 < 30 and not is_solid(fy2):
			fy2.y += 1
			n3 += 1
		var wv = WeaverScript.new()
		wv.setup(cell_center(c), screen_rect(scr), float(fy2.y * TILE))
		add_child(wv)
		boss = wv
		for l in lifts:
			if l.mode == "exit" and screen_of_pos(l.position + Vector2(0, -4)) == scr:
				l.locked = true
				wv.exit_lift = l

	for pair in [["D", "h"], ["d", "v"], ["o", "o"]]:
		for c in _marks(pair[0]):
			var dr = DroneScript.new()
			dr.setup(cell_center(c) + Vector2(0, 6), pair[1])
			add_child(dr)


## Esteiras: um corpo estático por trecho, com velocidade que arrasta quem
## estiver em cima (Sera, guardas, autômatos).
func _build_belts() -> void:
	if belts.is_empty():
		return
	var done: Dictionary = {}
	for c in belts.keys():
		if done.has(c) or belts.has(c + Vector2i(-1, 0)) and belts[c + Vector2i(-1, 0)] == belts[c]:
			continue
		var d: int = belts[c]
		var n := 0
		var cur: Vector2i = c
		while belts.has(cur) and belts[cur] == d:
			done[cur] = true
			n += 1
			cur += Vector2i(1, 0)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.constant_linear_velocity = Vector2(d * 55.0, 0)
		add_child(body)
		_add_rect_shape(body, Rect2(Vector2(c.x * TILE, c.y * TILE), Vector2(n * TILE, TILE)))
	var drawer := BeltDrawer.new()
	drawer.level = self
	drawer.z_index = 1
	add_child(drawer)


## Posições livres ao lado de um inimigo (chão firme, sem parede, mesma tela).
func _extra_spots(base: Vector2, n: int) -> Array:
	var out: Array = []
	if n <= 0:
		return out
	var scr := screen_of_pos(base + Vector2(0, -4))
	for k in 6:
		if out.size() >= n:
			break
		var off := (k / 2 + 1) * 38.0 * (1.0 if k % 2 == 0 else -1.0)
		var p := base + Vector2(off, 0)
		var floor_c := world_to_cell(p + Vector2(0, 4))
		var body_c := world_to_cell(p + Vector2(0, -12))
		if screen_of_pos(p + Vector2(0, -4)) == scr and (is_solid(floor_c) or is_oneway(floor_c)) and not is_solid(body_c) and _marks("~").find(world_to_cell(p + Vector2(0, -4))) < 0:
			out.append(p - Vector2(0, 0.5))
	return out


func _spawn_npcs() -> void:
	var i := 0
	for e in npc_spots:
		var c: Vector2i = e[0]
		var f: Vector2i = c
		var n := 0
		while n < 12 and not is_solid(f + Vector2i(0, 1)) and not is_oneway(f + Vector2i(0, 1)):
			f.y += 1
			n += 1
		var npc = NpcScript.new()
		npc.setup_npc(cell_bottom_center(f) - Vector2(0, 0.5), String(e[1]), theme, phase_index * 13 + i)
		add_child(npc)
		i += 1


# ---------------------------------------------------------------- luzes

func add_light(pos: Vector2, col: Color, radius: float, energy: float, flick: float = 0.0) -> void:
	# Intenso/Insano: luzes mais fortes e tremulando.
	var fx := Game.fx_level()
	var l = Light.make(self, pos, col, radius * (1.0 + 0.15 * fx), energy * (1.0 + 0.2 * fx), minf(0.9, flick + 0.2 * fx))
	l.z_index = 20
	l.enabled = false
	lights.append([l, screen_of_pos(pos)])


## Chamado pelo fundo depois do primeiro desenho, com os pontos de luz dele.
func make_backdrop_lights(spots: Array) -> void:
	if lights_made:
		return
	lights_made = true
	for sp in spots:
		add_light(sp[0], sp[1], sp[2], sp[3], sp[4])
	var s := lit_screen
	lit_screen = Vector2i(99999, 99999)
	if s.x != 99999:
		light_screen(s)


## Acende só as luzes da tela atual (e as vizinhas, para as que vazam a borda).
func light_screen(s: Vector2i) -> void:
	lit_screen = s
	for e in lights:
		var l = e[0]
		var ls: Vector2i = e[1]
		if is_instance_valid(l):
			l.enabled = ls == s


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var market := theme == "market"
	var tower := theme == "tower"
	var foundry := theme == "foundry"
	var veil := theme == "veil"
	var c_deep := Color("2b2422") if market else C_DEEP
	var c_hatch := Color("342a26") if market else C_HATCH
	var c_iron := Color("3e332c") if market else C_IRON
	var c_iron2 := Color("463a31") if market else C_IRON2
	var c_rim := Color("a07038") if market else C_RIM
	var c_rim_l := Color("e0b060") if market else C_RIM_L
	var c_rust := C_RUST
	if tower:
		# Pedra escura polida com frisos de latão.
		c_deep = Color("2f2b35")
		c_hatch = Color("3a3542")
		c_iron = Color("37333e")
		c_iron2 = Color("3d3844")
		c_rim = Color("a8843c")
		c_rim_l = Color("f0d27a")
		c_rust = Color("4a3a2a")
	elif foundry:
		# Rocha negra com veios de escória.
		c_deep = Color("1c1716")
		c_hatch = Color("261e1b")
		c_iron = Color("2e2422")
		c_iron2 = Color("342826")
		c_rim = Color("8a3a18")
		c_rim_l = Color("e06a28")
		c_rust = Color("5a2412")
	elif veil:
		# Chapas de ferro rebitadas, molhadas de chuva.
		c_deep = Color("23262e")
		c_hatch = Color("2c3039")
		c_iron = Color("3a3f4a")
		c_iron2 = Color("414654")
		c_rim = Color("7a8494")
		c_rim_l = Color("c8d2e0")
		c_rust = Color("4a3a32")
	for c in solid.keys():
		var cell: Vector2i = c
		var r := Rect2(Vector2(cell * TILE), Vector2(TILE, TILE))
		var open_up := not is_solid(cell + Vector2i(0, -1))
		var open_down := not is_solid(cell + Vector2i(0, 1))
		var open_l := not is_solid(cell + Vector2i(-1, 0))
		var open_r := not is_solid(cell + Vector2i(1, 0))
		var exposed := open_up or open_down or open_l or open_r
		if not exposed:
			draw_rect(r, c_deep)
			if (cell.x + cell.y) % 2 == 0:
				draw_line(r.position + Vector2(2, TILE - 2), r.position + Vector2(TILE - 2, 2), c_hatch, 1.0)
			continue
		var base := c_iron if (cell.x + cell.y) % 2 == 0 else c_iron2
		draw_rect(r, base)
		if open_l:
			draw_rect(Rect2(r.position, Vector2(2, TILE)), c_rust)
		if open_r:
			draw_rect(Rect2(r.position + Vector2(TILE - 2, 0), Vector2(2, TILE)), Color("2a2523"))
		if open_down:
			draw_rect(Rect2(r.position + Vector2(0, TILE - 3), Vector2(TILE, 3)), Color("2a2523"))
		if market and open_down and not open_up:
			# Vigas de madeira sob as plataformas do Mercado
			draw_line(r.position + Vector2(2, TILE - 3), r.position + Vector2(TILE - 2, TILE - 3), Color("5a3e28"), 1.0)
		if open_up:
			draw_rect(Rect2(r.position, Vector2(TILE, 4)), c_rim)
			draw_rect(Rect2(r.position, Vector2(TILE, 1)), c_rim_l)
			if (cell.x * 7 + cell.y * 3) % 5 == 0:
				draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(3, 6)), c_rust)
		if tower and (cell.x + cell.y) % 4 == 0:
			draw_line(r.position + Vector2(3, 8), r.position + Vector2(12, 15), Color(1, 1, 1, 0.04), 1.0)
		if (cell.x + cell.y * 2) % 3 == 0:
			draw_circle(r.position + Vector2(5, 10), 1.2, C_RIVET)
			draw_circle(r.position + Vector2(15, 10), 1.2, C_RIVET)
	for c in oneway.keys():
		var r := Rect2(Vector2(c.x * TILE, c.y * TILE), Vector2(TILE, 6))
		draw_rect(r, c_rim)
		for i in 4:
			draw_line(r.position + Vector2(i * 5 + 2, 1), r.position + Vector2(i * 5 + 4, 5), c_deep, 1.0)


## Fundo procedural: paredes do fundo, canos de cobre, janelas de caldeira
## brilhando e luz vinda de cima nos poços abertos.
class Backdrop extends Node2D:
	var level = null
	## Pontos de luz encontrados ao desenhar: [pos, cor, raio, energia, tremulação]
	var spots: Array = []

	func _spot(p: Vector2, col: Color, r: float, e: float, f: float = 0.0) -> void:
		spots.append([p, col, r, e, f])

	func _draw() -> void:
		spots.clear()
		for s in level.screens.keys():
			_draw_screen(s)
		level.call_deferred("make_backdrop_lights", spots.duplicate())

	func _draw_screen(s: Vector2i) -> void:
		var rect: Rect2 = level.screen_rect(s)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector3i(s.x, s.y, level.phase_index))
		if level.theme == "market":
			_draw_market(s, rect, rng)
			return
		if level.theme == "tower":
			_draw_tower(s, rect, rng)
			return
		if level.theme == "foundry":
			_draw_foundry(s, rect, rng)
			return
		if level.theme == "veil":
			_draw_veil(s, rect, rng)
			return
		# Faixas verticais de chapas
		var bands := 8
		for i in bands:
			var shade := 0.11 + 0.025 * float(i % 2) + rng.randf_range(-0.01, 0.01)
			draw_rect(Rect2(rect.position + Vector2(i * rect.size.x / bands, 0), Vector2(rect.size.x / bands, rect.size.y)),
				Color(shade * 1.15, shade, shade * 0.95))
		# Escurecimento no alto
		for i in 6:
			draw_rect(Rect2(rect.position + Vector2(0, i * 12), Vector2(rect.size.x, 12)), Color(0, 0, 0, 0.18 - i * 0.03))
		# Janelas de caldeira (brilho laranja)
		var boiler := Color("d0602a")
		if level.phase_index == 1:
			boiler = Color("7a9a8a")
		for i in rng.randi_range(2, 4):
			var p := rect.position + Vector2(rng.randf_range(40, rect.size.x - 60), rng.randf_range(80, rect.size.y - 90))
			var r := Rect2(p, Vector2(rng.randf_range(24, 44), rng.randf_range(14, 24)))
			_spot(r.get_center(), boiler.lightened(0.2), 70.0, 0.75, 0.18)
			draw_rect(r.grow(10), Color(boiler, 0.05))
			draw_rect(r.grow(4), Color(boiler, 0.08))
			draw_rect(r, Color(boiler, 0.28))
			draw_rect(r, Color("2c2422"), false, 2.0)
			for k in 3:
				var x := r.position.x + r.size.x * (k + 1) / 4.0
				draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color("2c2422"), 1.5)
		# Canos verticais
		for i in rng.randi_range(3, 5):
			var x := rect.position.x + rng.randf_range(10, rect.size.x - 10)
			var w := rng.randf_range(5, 12)
			draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(w, rect.size.y)), Color("4a3020"))
			draw_rect(Rect2(Vector2(x + 1, rect.position.y), Vector2(1.5, rect.size.y)), Color("6e4a2c"))
			var j := rect.position.y + rng.randf_range(20, 80)
			while j < rect.end.y:
				draw_rect(Rect2(Vector2(x - 1.5, j), Vector2(w + 3, 4)), Color("5a3a24"))
				j += rng.randf_range(60, 120)
		# Canos horizontais
		for i in rng.randi_range(2, 3):
			var y := rect.position.y + rng.randf_range(60, rect.size.y - 60)
			var h := rng.randf_range(4, 9)
			draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, h)), Color("3f2a1e"))
			draw_rect(Rect2(Vector2(rect.position.x, y + 1), Vector2(rect.size.x, 1.2)), Color("6a4628"))
		# Manômetros
		for i in rng.randi_range(1, 3):
			var c := rect.position + Vector2(rng.randf_range(30, rect.size.x - 30), rng.randf_range(60, rect.size.y - 60))
			draw_circle(c, 6, Color("2a2523"))
			draw_circle(c, 5, Color("a89c8a"))
			draw_line(c, c + Vector2.from_angle(rng.randf_range(-PI, 0)) * 4, Color("8a2a1a"), 1.2)
		# Luz vinda de cima onde a tela tem abertura no teto sem vizinha
		if not level.screens.has(s + Vector2i(0, -1)):
			var rows: Array = level.screens[s]
			var top: String = rows[0]
			var light := Color("ffd27a") if level.warm_light else Color("e0a060")
			var last_spot := -99
			for x in top.length():
				if top[x] != "#" and x - last_spot >= 5:
					last_spot = x
					_spot(Vector2(rect.position.x + x * 20.0 + 10.0, rect.position.y + 40.0), light, 120.0, 0.55)
				if top[x] != "#":
					var px := rect.position.x + x * 20.0
					for k in 10:
						var a := (0.22 if level.warm_light else 0.08) * (1.0 - k / 10.0)
						draw_rect(Rect2(Vector2(px - 2, rect.position.y + k * 18), Vector2(24, 18)), Color(light, a))


	## Mercado Suspenso: céu de entardecer enfumaçado, plataformas penduradas
	## por correntes ao longe, toldos, lanternas e o brilho das Caldeiras lá
	## embaixo, no abismo.
	func _draw_market(s: Vector2i, rect: Rect2, rng: RandomNumberGenerator) -> void:
		var depth := float(s.y)
		for i in 18:
			var k := i / 17.0
			var top := Color(0.16, 0.13, 0.17)
			var bottom := Color(0.32, 0.2, 0.14)
			var c := top.lerp(bottom, clampf(k + depth * 0.25, 0.0, 1.0))
			draw_rect(Rect2(rect.position + Vector2(0, i * 20), Vector2(rect.size.x, 20)), c)
		# Brilho das caldeiras subindo do abismo
		if not level.screens.has(s + Vector2i(0, 1)):
			for k in 3:
				_spot(rect.position + Vector2(110 + k * 210, rect.size.y + 10), Color(1.0, 0.45, 0.15), 170.0, 0.7, 0.12)
			for i in 8:
				draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 80 + i * 10), Vector2(rect.size.x, 10)), Color(0.9, 0.35, 0.1, 0.03 + i * 0.02))
		# Silhuetas distantes: plataformas penduradas
		for i in rng.randi_range(4, 6):
			var x := rect.position.x + rng.randf_range(-20, rect.size.x - 40)
			var y := rect.position.y + rng.randf_range(60, rect.size.y - 120)
			var w := rng.randf_range(50, 110)
			var col := Color(0.12, 0.1, 0.11, 0.85)
			draw_line(Vector2(x + 8, rect.position.y), Vector2(x + 8, y), Color(0.3, 0.27, 0.27, 0.5), 1.0)
			draw_line(Vector2(x + w - 8, rect.position.y), Vector2(x + w - 8, y), Color(0.3, 0.27, 0.27, 0.5), 1.0)
			draw_rect(Rect2(Vector2(x, y), Vector2(w, 8)), col)
			var hx := x + 6
			while hx < x + w - 14:
				var hh := rng.randf_range(14, 34)
				draw_rect(Rect2(Vector2(hx, y - hh), Vector2(rng.randf_range(12, 22), hh)), col)
				if rng.randf() < 0.7:
					draw_rect(Rect2(Vector2(hx + 4, y - hh + 6), Vector2(4, 3)), Color(1.0, 0.75, 0.35, rng.randf_range(0.25, 0.6)))
				hx += rng.randf_range(16, 26)
		# Correntes grossas em primeiro plano do fundo
		for i in rng.randi_range(2, 3):
			var x := rect.position.x + rng.randf_range(20, rect.size.x - 20)
			var y := rect.position.y
			while y < rect.end.y:
				draw_rect(Rect2(Vector2(x - 2, y), Vector2(4, 8)), Color("3a302a"))
				draw_rect(Rect2(Vector2(x - 1, y + 8), Vector2(2, 4)), Color("2a2420"))
				y += 12.0
		# Toldos e varais de bandeirolas
		for i in rng.randi_range(1, 2):
			var y := rect.position.y + rng.randf_range(50, 150)
			var x0 := rect.position.x
			var n := 16
			for k in n:
				var a := Vector2(x0 + k * rect.size.x / n, y + sin(k * 0.8) * 6.0)
				var b := Vector2(x0 + (k + 1) * rect.size.x / n, y + sin((k + 1) * 0.8) * 6.0)
				draw_line(a, b, Color(0.4, 0.35, 0.3, 0.6), 1.0)
				var col: Color = [Color("6e2a1e"), Color("8a6a2a"), Color("3e4a36"), Color("5a3a50")][k % 4]
				draw_colored_polygon(PackedVector2Array([a, a + Vector2(5, 0), a + Vector2(2.5, 8)]), Color(col, 0.7))
		# Lanternas
		for i in rng.randi_range(3, 5):
			var p := rect.position + Vector2(rng.randf_range(20, rect.size.x - 20), rng.randf_range(40, rect.size.y - 100))
			_spot(p, Color(1.0, 0.7, 0.32), 58.0, 0.85, 0.22)
			draw_circle(p, 14.0, Color(1.0, 0.7, 0.3, 0.05))
			draw_circle(p, 7.0, Color(1.0, 0.7, 0.3, 0.08))
			draw_rect(Rect2(p + Vector2(-2.5, -3), Vector2(5, 6)), Color(1.0, 0.78, 0.4, 0.75))
			draw_line(p + Vector2(0, -3), p + Vector2(0, -12), Color(0.3, 0.27, 0.27, 0.7), 1.0)


	## Torre do Diretório: paredes de pedra escura com frisos de latão, janelões
	## em arco mostrando a cidade à noite lá embaixo, engrenagens gigantes e
	## tubos pneumáticos.
	func _draw_tower(s: Vector2i, rect: Rect2, rng: RandomNumberGenerator) -> void:
		var height := -float(s.y)
		for i in 18:
			var k := i / 17.0
			var c := Color(0.11, 0.1, 0.13).lerp(Color(0.15, 0.13, 0.16), k)
			draw_rect(Rect2(rect.position + Vector2(0, i * 20), Vector2(rect.size.x, 20)), c)
		# Pilastras
		for i in 5:
			var x := rect.position.x + 20.0 + i * 150.0 + rng.randf_range(-10, 10)
			draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(22, rect.size.y)), Color(0.15, 0.14, 0.18))
			draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(2, rect.size.y)), Color(0.62, 0.48, 0.24, 0.35))
			draw_rect(Rect2(Vector2(x + 20, rect.position.y), Vector2(2, rect.size.y)), Color(0.05, 0.05, 0.06, 0.6))
		# Janelões em arco com a cidade à noite
		for i in rng.randi_range(2, 3):
			var w := rng.randf_range(54, 80)
			var x := rect.position.x + 60.0 + i * 200.0 + rng.randf_range(-20, 20)
			var y := rect.position.y + rng.randf_range(50, 90)
			var h := rng.randf_range(120, 170)
			var win := Rect2(Vector2(x, y), Vector2(w, h))
			_spot(win.get_center() + Vector2(0, h * 0.2), Color(0.55, 0.65, 1.0), 110.0, 0.45)
			draw_rect(win, Color(0.09, 0.08, 0.16))
			draw_circle(Vector2(x + w * 0.5, y), w * 0.5, Color(0.09, 0.08, 0.16))
			# Céu com estrelas e brilho das Caldeiras no horizonte
			for k in 8:
				draw_rect(Rect2(Vector2(x, y + h - 40 + k * 5), Vector2(w, 5)), Color(0.8, 0.35, 0.15, 0.02 + k * 0.012))
			for k in 6:
				draw_circle(Vector2(x + rng.randf_range(4, w - 4), y + rng.randf_range(-w * 0.3, h * 0.5)), 0.6, Color(1, 1, 0.9, 0.5))
			# Luzes da cidade lá embaixo (mais longe quanto mais alto)
			for k in 14:
				var lx := x + rng.randf_range(3, w - 3)
				var ly := y + h - rng.randf_range(4, 30 - height * 4.0)
				draw_rect(Rect2(Vector2(lx, ly), Vector2(1.5, 1.5)), Color(1.0, 0.75, 0.35, rng.randf_range(0.3, 0.8)))
			# Caixilhos de latão
			draw_rect(win, Color("8a6a2a"), false, 2.0)
			draw_arc(Vector2(x + w * 0.5, y), w * 0.5, PI, TAU, 16, Color("8a6a2a"), 2.0)
			draw_line(Vector2(x + w * 0.5, y - w * 0.5), Vector2(x + w * 0.5, y + h), Color("8a6a2a"), 1.5)
			for k in 3:
				draw_line(Vector2(x, y + h * (k + 1) / 4.0), Vector2(x + w, y + h * (k + 1) / 4.0), Color("6e5428"), 1.0)
		# Engrenagens gigantes ao fundo
		for i in rng.randi_range(1, 2):
			var c := rect.position + Vector2(rng.randf_range(60, rect.size.x - 60), rng.randf_range(60, rect.size.y - 120))
			var r := rng.randf_range(34, 60)
			var col := Color(0.2, 0.17, 0.16, 0.9)
			draw_circle(c, r, col)
			for k in 14:
				var a := k * TAU / 14.0
				draw_line(c + Vector2.from_angle(a) * r, c + Vector2.from_angle(a) * (r + 7.0), col, 7.0)
			draw_circle(c, r * 0.6, Color(0.12, 0.1, 0.12))
			for k in 5:
				var a := k * TAU / 5.0 + 0.3
				draw_line(c, c + Vector2.from_angle(a) * r * 0.62, col, 5.0)
			draw_circle(c, r * 0.18, Color(0.45, 0.36, 0.2))
		# Tubos pneumáticos de vidro e latão
		for i in rng.randi_range(2, 3):
			var x := rect.position.x + rng.randf_range(20, rect.size.x - 20)
			draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(8, rect.size.y)), Color(0.5, 0.7, 0.75, 0.08))
			draw_rect(Rect2(Vector2(x, rect.position.y), Vector2(1, rect.size.y)), Color(0.8, 0.9, 0.95, 0.15))
			var j := rect.position.y + rng.randf_range(10, 60)
			while j < rect.end.y:
				draw_rect(Rect2(Vector2(x - 2, j), Vector2(12, 3)), Color("6e5428"))
				j += rng.randf_range(50, 90)
			draw_rect(Rect2(Vector2(x + 1, rect.position.y + rng.randf_range(40, 280)), Vector2(6, 10)), Color("a07a38"))
		# Estandartes do Diretório (olho na engrenagem)
		for i in rng.randi_range(1, 2):
			var x := rect.position.x + rng.randf_range(40, rect.size.x - 60)
			var y := rect.position.y + rng.randf_range(20, 60)
			draw_rect(Rect2(Vector2(x, y), Vector2(24, 50)), Color(0.35, 0.08, 0.08, 0.85))
			draw_colored_polygon(PackedVector2Array([Vector2(x, y + 50), Vector2(x + 12, y + 58), Vector2(x + 24, y + 50)]), Color(0.35, 0.08, 0.08, 0.85))
			draw_arc(Vector2(x + 12, y + 22), 7.0, 0, TAU, 12, Color(0.75, 0.58, 0.26, 0.8), 1.5)
			draw_circle(Vector2(x + 12, y + 22), 2.5, Color(0.95, 0.8, 0.45, 0.8))
		# Luz quente das arandelas
		for i in rng.randi_range(2, 4):
			var p := rect.position + Vector2(rng.randf_range(30, rect.size.x - 30), rng.randf_range(80, rect.size.y - 90))
			_spot(p, Color(1.0, 0.74, 0.36), 60.0, 0.85, 0.1)
			draw_circle(p, 18.0, Color(1.0, 0.75, 0.35, 0.04))
			draw_circle(p, 8.0, Color(1.0, 0.75, 0.35, 0.07))
			draw_rect(Rect2(p + Vector2(-2, -3), Vector2(4, 6)), Color(1.0, 0.82, 0.45, 0.7))
			draw_rect(Rect2(p + Vector2(-3, 3), Vector2(6, 2)), Color("6e5428"))


	## Fundições Profundas: escuro de caverna, rios de ferro fundido ao longe,
	## cadinhos gigantes e correntes; quase nada de luz.
	func _draw_foundry(_s: Vector2i, rect: Rect2, rng: RandomNumberGenerator) -> void:
		draw_rect(rect, Color(0.07, 0.05, 0.05))
		# Paredes de rocha em camadas
		for i in 6:
			var y := rect.position.y + rng.randf_range(20, rect.size.y - 40)
			var pts := PackedVector2Array()
			var x := rect.position.x
			while x <= rect.end.x:
				pts.append(Vector2(x, clampf(y + rng.randf_range(-14, 14), rect.position.y, rect.end.y - 4.0)))
				x += 40.0
			pts.append(Vector2(rect.end.x, rect.end.y))
			pts.append(Vector2(rect.position.x, rect.end.y))
			draw_colored_polygon(pts, Color(0.1, 0.07, 0.065, 0.35))
		# Rio de ferro fundido ao fundo
		var ry := rect.position.y + rng.randf_range(rect.size.y * 0.45, rect.size.y * 0.7)
		for k in 5:
			draw_rect(Rect2(Vector2(rect.position.x, ry - 10 + k * 4), Vector2(rect.size.x, 4)), Color(0.9, 0.35, 0.08, 0.05 + k * 0.03))
		_spot(Vector2(rect.position.x + rect.size.x * 0.3, ry), Color(1.0, 0.45, 0.12), 150.0, 0.45, 0.2)
		_spot(Vector2(rect.position.x + rect.size.x * 0.75, ry), Color(1.0, 0.45, 0.12), 150.0, 0.45, 0.2)
		# Cadinhos pendurados
		for i in rng.randi_range(1, 2):
			var cx := rect.position.x + rng.randf_range(80, rect.size.x - 80)
			var cy := rect.position.y + rng.randf_range(60, 140)
			draw_line(Vector2(cx, rect.position.y), Vector2(cx, cy - 24), Color(0.25, 0.2, 0.18), 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 28, cy - 24), Vector2(cx + 28, cy - 24), Vector2(cx + 18, cy + 18), Vector2(cx - 18, cy + 18)]), Color(0.16, 0.12, 0.11))
			draw_rect(Rect2(Vector2(cx - 24, cy - 24), Vector2(48, 4)), Color(1.0, 0.5, 0.15, 0.5))
			_spot(Vector2(cx, cy - 26), Color(1.0, 0.5, 0.15), 70.0, 0.6, 0.25)
		# Correntes e engrenagens quebradas
		for i in rng.randi_range(2, 4):
			var x2 := rect.position.x + rng.randf_range(10, rect.size.x - 10)
			var y2 := rect.position.y
			var end_y := rect.position.y + rng.randf_range(80, 220)
			while y2 < end_y:
				draw_rect(Rect2(Vector2(x2 - 2, y2), Vector2(4, 7)), Color(0.2, 0.16, 0.14))
				y2 += 10.0
		# Brasas presas na rocha
		for i in 20:
			var p := rect.position + Vector2(rng.randf_range(0, rect.size.x), rng.randf_range(0, rect.size.y))
			draw_rect(Rect2(p, Vector2(1.5, 1.5)), Color(1.0, 0.5, 0.15, rng.randf_range(0.2, 0.6)))


	## Véu de Ferro: céu de tempestade, a curva gigante da cúpula rebitada,
	## guindastes de placas e luzes de aviso piscando.
	func _draw_veil(s: Vector2i, rect: Rect2, rng: RandomNumberGenerator) -> void:
		for i in 18:
			var k := i / 17.0
			draw_rect(Rect2(rect.position + Vector2(0, i * 20), Vector2(rect.size.x, 20)), Color(0.12, 0.13, 0.17).lerp(Color(0.2, 0.22, 0.27), k))
		# Nuvens de tempestade
		for i in 6:
			var c := rect.position + Vector2(rng.randf_range(0, rect.size.x), rng.randf_range(10, 120))
			draw_circle(c, rng.randf_range(30, 60), Color(0.08, 0.09, 0.12, 0.5))
		# A cúpula: grandes placas curvas com rebites
		var base_y := rect.position.y + 40.0 - float(s.x) * 6.0
		for i in 9:
			var x0 := rect.position.x - 40.0 + i * 82.0
			var y0 := base_y + absf(i - 4.0) * 10.0
			var plate := PackedVector2Array([Vector2(x0, y0), Vector2(x0 + 80, y0 - 6), Vector2(x0 + 84, y0 + 120), Vector2(x0 + 4, y0 + 126)])
			draw_colored_polygon(plate, Color(0.2, 0.22, 0.27, 0.9))
			draw_line(Vector2(x0, y0), Vector2(x0 + 80, y0 - 6), Color(0.45, 0.5, 0.58, 0.6), 1.5)
			for r in 5:
				draw_circle(Vector2(x0 + 10 + r * 15, y0 + 4 - r * 1.2), 1.3, Color(0.5, 0.55, 0.62))
		# Guindastes de placas e luzes vermelhas de aviso
		for i in rng.randi_range(1, 2):
			var gx := rect.position.x + rng.randf_range(60, rect.size.x - 60)
			draw_line(Vector2(gx, rect.end.y), Vector2(gx, rect.position.y + 150), Color(0.18, 0.19, 0.23), 5.0)
			draw_line(Vector2(gx, rect.position.y + 150), Vector2(gx + 90, rect.position.y + 140), Color(0.18, 0.19, 0.23), 4.0)
			draw_circle(Vector2(gx + 2, rect.position.y + 146), 3.0, Color(1.0, 0.2, 0.1, 0.8))
			_spot(Vector2(gx + 2, rect.position.y + 146), Color(1.0, 0.25, 0.15), 50.0, 0.7, 0.4)
		# Holofotes de serviço
		for i in rng.randi_range(1, 2):
			var p := rect.position + Vector2(rng.randf_range(40, rect.size.x - 40), rng.randf_range(160, 260))
			_spot(p, Color(0.8, 0.88, 1.0), 70.0, 0.55)
			draw_rect(Rect2(p + Vector2(-3, -2), Vector2(6, 4)), Color(0.85, 0.9, 1.0, 0.8))


## Esteiras: faixa de borracha com setas que andam.
class BeltDrawer extends Node2D:
	var level = null
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for c in level.belts.keys():
			var cell: Vector2i = c
			var d: int = level.belts[c]
			var r := Rect2(Vector2(cell * 20), Vector2(20, 20))
			draw_rect(r, Color("2a2422"))
			draw_rect(Rect2(r.position, Vector2(20, 5)), Color("3a3230"))
			var off := fposmod(t * 55.0 * d, 10.0)
			for k in 3:
				var x := r.position.x + fposmod(off + k * 10.0, 20.0)
				draw_line(Vector2(x, r.position.y + 1), Vector2(x + d * 3.0, r.position.y + 2.5), Color("8a6a2a"), 1.0)
				draw_line(Vector2(x + d * 3.0, r.position.y + 2.5), Vector2(x, r.position.y + 4), Color("8a6a2a"), 1.0)
			draw_circle(r.position + Vector2(5, 13), 3.5, Color("4a4240"))
			draw_circle(r.position + Vector2(15, 13), 3.5, Color("4a4240"))
