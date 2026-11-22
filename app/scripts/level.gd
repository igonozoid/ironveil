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
const BackdropScript := preload("res://scripts/backdrop.gd")
const PropsScript := preload("res://scripts/backdrop_props.gd")
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
## Tela -> {tiles, mid, far: Sprite2D, props: Array}
var baked: Dictionary = {}
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

	_bake_all()


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


# ---------------------------------------------------------------- cenário assado

## Cada tela vira texturas desenhadas uma vez só (SubViewport que não
## atualiza mais): blocos, fundo do meio e fundo de longe (com parallax).
## Antes, os blocos de TODAS as telas eram redesenhados a cada quadro.
func _bake_all() -> void:
	var par := BackdropScript.parallax_of(theme)
	for s in screens.keys():
		var sc: Vector2i = s
		var info := {}
		if par > 0.0:
			info["far"] = _bake(sc, _painter(sc, "far", par + 2.0), par + 2.0, -21)
		info["mid"] = _bake(sc, _painter(sc, "mid", 0.0), 0.0, -20)
		var tiles := TilePainter.new()
		tiles.level = self
		tiles.screen = sc
		var ts := _bake(sc, tiles, 0.0, 0)
		move_child(ts, 0)
		info["tiles"] = ts
		info["props"] = []
		baked[sc] = info


func _painter(s: Vector2i, layer: String, margin: float) -> Node2D:
	var p = BackdropScript.new()
	p.level = self
	p.screen = s
	p.layer = layer
	p.margin = margin
	return p


func _bake(s: Vector2i, painter: Node2D, margin: float, z: int) -> Sprite2D:
	var r := screen_rect(s)
	var vp := SubViewport.new()
	vp.size = Vector2i(r.size + Vector2(margin, margin) * 2.0)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	painter.position = -r.position + Vector2(margin, margin)
	vp.add_child(painter)
	add_child(vp)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture = vp.get_texture()
	spr.position = r.position - Vector2(margin, margin)
	spr.z_index = z
	spr.set_meta("base", spr.position)
	# A textura vem com alfa pré-multiplicado.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	spr.material = mat
	add_child(spr)
	return spr


## O pintor de uma camada terminou: guarda as luzes e cria as peças animadas.
func backdrop_report(s: Vector2i, layer: String, spots: Array, prop_list: Array) -> void:
	for sp in spots:
		add_light(sp[0], sp[1], sp[2], sp[3], sp[4])
	if not prop_list.is_empty() and baked.has(s):
		var spr: Sprite2D = baked[s][layer]
		var pr = PropsScript.new()
		pr.position = -(spr.get_meta("base") as Vector2)
		pr.build(prop_list)
		spr.add_child(pr)
		(baked[s]["props"] as Array).append(pr)
		pr.set_active(s == lit_screen)
	if s == lit_screen:
		for e in lights:
			if is_instance_valid(e[0]) and e[1] == s:
				e[0].enabled = true


## Parallax: a camada de longe acompanha um pouco a posição de Sera na tela.
func _process(delta: float) -> void:
	if not baked.has(lit_screen) or not baked[lit_screen].has("far"):
		return
	var w = Game.world
	if w == null or w.player == null:
		return
	var spr: Sprite2D = baked[lit_screen]["far"]
	var r := screen_rect(lit_screen)
	var par := BackdropScript.parallax_of(theme)
	var k: Vector2 = ((w.player.global_position - r.get_center()) / (r.size * 0.5)).clamp(Vector2(-1, -1), Vector2(1, 1))
	var want: Vector2 = (spr.get_meta("base") as Vector2) - Vector2(k.x * par, k.y * par * 0.4)
	spr.position = spr.position.lerp(want, minf(1.0, delta * 4.0)).round()


## Acende só as luzes da tela atual (e as vizinhas, para as que vazam a borda).
func light_screen(s: Vector2i) -> void:
	lit_screen = s
	for k in baked.keys():
		for pr in baked[k]["props"]:
			pr.set_active(k == s)
	for e in lights:
		var l = e[0]
		var ls: Vector2i = e[1]
		if is_instance_valid(l):
			l.enabled = ls == s


# ---------------------------------------------------------------- desenho

## Desenha os blocos de UMA tela em `ci` (um pincel dentro do SubViewport).
func draw_tiles(ci: CanvasItem, s: Vector2i) -> void:
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
	var c0 := Vector2i(s.x * SW, s.y * SH)
	var screen_cells: Array = []
	var screen_oneway: Array = []
	for y in SH:
		for x in SW:
			var cc := c0 + Vector2i(x, y)
			if solid.has(cc):
				screen_cells.append(cc)
			elif oneway.has(cc):
				screen_oneway.append(cc)
	for c in screen_cells:
		var cell: Vector2i = c
		var r := Rect2(Vector2(cell * TILE), Vector2(TILE, TILE))
		var open_up := not is_solid(cell + Vector2i(0, -1))
		var open_down := not is_solid(cell + Vector2i(0, 1))
		var open_l := not is_solid(cell + Vector2i(-1, 0))
		var open_r := not is_solid(cell + Vector2i(1, 0))
		var exposed := open_up or open_down or open_l or open_r
		if not exposed:
			ci.draw_rect(r, c_deep)
			if (cell.x + cell.y) % 2 == 0:
				ci.draw_line(r.position + Vector2(2, TILE - 2), r.position + Vector2(TILE - 2, 2), c_hatch, 1.0)
			continue
		var base := c_iron if (cell.x + cell.y) % 2 == 0 else c_iron2
		ci.draw_rect(r, base)
		if open_l:
			ci.draw_rect(Rect2(r.position, Vector2(2, TILE)), c_rust)
		if open_r:
			ci.draw_rect(Rect2(r.position + Vector2(TILE - 2, 0), Vector2(2, TILE)), Color("2a2523"))
		if open_down:
			ci.draw_rect(Rect2(r.position + Vector2(0, TILE - 3), Vector2(TILE, 3)), Color("2a2523"))
		if market and open_down and not open_up:
			# Vigas de madeira sob as plataformas do Mercado
			ci.draw_line(r.position + Vector2(2, TILE - 3), r.position + Vector2(TILE - 2, TILE - 3), Color("5a3e28"), 1.0)
		if open_up:
			ci.draw_rect(Rect2(r.position, Vector2(TILE, 4)), c_rim)
			ci.draw_rect(Rect2(r.position, Vector2(TILE, 1)), c_rim_l)
			if (cell.x * 7 + cell.y * 3) % 5 == 0:
				ci.draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(3, 6)), c_rust)
		if tower and (cell.x + cell.y) % 4 == 0:
			ci.draw_line(r.position + Vector2(3, 8), r.position + Vector2(12, 15), Color(1, 1, 1, 0.04), 1.0)
		if (cell.x + cell.y * 2) % 3 == 0:
			ci.draw_circle(r.position + Vector2(5, 10), 1.2, C_RIVET)
			ci.draw_circle(r.position + Vector2(15, 10), 1.2, C_RIVET)
	for c in screen_oneway:
		var r := Rect2(Vector2(c.x * TILE, c.y * TILE), Vector2(TILE, 6))
		ci.draw_rect(r, c_rim)
		for i in 4:
			ci.draw_line(r.position + Vector2(i * 5 + 2, 1), r.position + Vector2(i * 5 + 4, 5), c_deep, 1.0)


## Pincel dos blocos de uma tela (vai dentro do SubViewport).
class TilePainter extends Node2D:
	var level = null
	var screen := Vector2i.ZERO

	func _draw() -> void:
		level.draw_tiles(self, screen)


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
