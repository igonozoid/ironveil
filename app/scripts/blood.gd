extends Node2D
## Sangue e destroços. Gotas voam com gravidade e, ao bater em chão, parede ou
## teto, viram manchas permanentes (algumas escorrem pela parede). Corpos
## deixam poças que crescem. Pedaços ("gibs") quicam e deixam rastro.
## Gotas também grudam nos personagens (grupo "splat_target"), mancham a
## parede do fundo do cenário e, perto de Sera, espirram na tela.
## Com a opção "Sangue e gore" desligada, tudo vira faíscas e poeira.

const Fx := preload("res://scripts/fx.gd")
const TILE := 20
const GRAV := 900.0
## Limites crescem com a dificuldade (Intenso/Insano: gore absurdo).
var MAX_DROPS := 700
const MAX_STAINS := 3000
var MAX_GIBS := 180
const MAX_POOLS := 60

const BLOOD := Color(0.62, 0.04, 0.04)

var level = null
var stains: StainLayer

# Gotas (arrays paralelos, remoção por troca com o último)
var d_pos := PackedVector2Array()
var d_vel := PackedVector2Array()
var d_size := PackedFloat32Array()
var d_life := PackedFloat32Array()
var d_col := PackedColorArray()
var d_age := PackedFloat32Array()
var screen_cd := 0.0

# Pedaços
var g_pos := PackedVector2Array()
var g_vel := PackedVector2Array()
var g_rot := PackedFloat32Array()
var g_rv := PackedFloat32Array()
var g_size := PackedVector2Array()
var g_col := PackedColorArray()
var g_rest := PackedByteArray()
var g_bleed := PackedByteArray()

# Escorridos na parede: [pos, restante, velocidade, tamanho, cor, tipo, px desde a última mancha]
var drips: Array = []


func _ready() -> void:
	var fx := Game.fx_level()
	MAX_DROPS = 700 * (1 + fx)
	MAX_GIBS = 120 * (1 + fx)
	z_index = 7
	stains = StainLayer.new()
	stains.level = level
	stains.z_index = -6   # relativo: fica atrás dos personagens, sobre o cenário
	add_child(stains)


static func blood_color() -> Color:
	var k := randf()
	return Color(lerpf(0.42, 0.7, k), lerpf(0.02, 0.07, randf()), lerpf(0.02, 0.05, randf()), 0.95)


func _gore() -> bool:
	return Game.gore_enabled()


# ---------------------------------------------------------------- API

## Jato de gotas a partir de `pos` na direção `dir` (com abertura `spread` em rad).
func spray(pos: Vector2, dir: Vector2, amount: int, speed: float, spread: float = 0.6, size: float = 1.4) -> void:
	if not _gore():
		Fx.sparks(get_parent(), pos)
		return
	var base := dir.angle() if dir != Vector2.ZERO else -PI * 0.5
	amount = int(amount * Game.gore_mult())
	speed *= 1.0 + 0.18 * Game.fx_level()
	spread = minf(PI, spread * (1.0 + 0.25 * Game.fx_level()))
	for i in amount:
		if d_pos.size() >= MAX_DROPS:
			_remove_drop(0)
		var a := base + randf_range(-spread, spread)
		d_pos.append(pos + Vector2(randf_range(-2, 2), randf_range(-2, 2)))
		d_vel.append(Vector2.from_angle(a) * speed * randf_range(0.25, 1.0))
		d_size.append(size * randf_range(0.45, 1.5))
		d_life.append(randf_range(1.0, 2.0))
		d_col.append(blood_color())
		d_age.append(0.0)
	_maybe_screen(pos, dir, amount, speed)


## Sangue na tela quando a carnificina é bem perto de Sera.
func _maybe_screen(pos: Vector2, dir: Vector2, amount: int, speed: float) -> void:
	if Game.world == null or Game.world.player == null or amount < 12 or screen_cd > 0.0:
		return
	var sb = Game.world.get("screen_blood")
	if sb == null:
		return
	var pc: Vector2 = Game.world.player.center()
	var d := pos.distance_to(pc)
	var reach := (70.0 + amount * 1.2 + speed * 0.08) * (1.0 + 0.8 * Game.fx_level())
	if d > reach:
		return
	var k := clampf(1.0 - d / reach, 0.15, 1.0) * clampf(amount / 40.0, 0.4, 1.6)
	var cam: Vector2 = Game.world.camera.position
	sb.splat(pos - cam, dir, k)
	screen_cd = 0.12 / (1.0 + Game.fx_level())


## Explosão de sangue em todas as direções.
func burst(pos: Vector2, amount: int, speed: float = 220.0) -> void:
	spray(pos, Vector2.UP, amount, speed, PI, 1.6)


## Poça que cresce no chão abaixo de `pos`.
func pool(pos: Vector2, radius: float) -> void:
	if not _gore():
		return
	var c: Vector2i = level.world_to_cell(pos + Vector2(0, 2))
	var tries := 0
	while not level.is_solid(c) and tries < 6:
		c.y += 1
		tries += 1
	if not level.is_solid(c):
		return
	stains.add_pool(Vector2(pos.x, c.y * TILE), radius * (1.0 + 0.45 * Game.fx_level()))


## Pedaços que voam, quicam e (se `bleed`) sangram.
func gibs(pos: Vector2, amount: int, colors: Array, bleed: bool = true, speed: float = 260.0) -> void:
	if bleed and not _gore():
		Fx.debris(get_parent(), pos)
		return
	amount = int(amount * (Game.gore_mult() if bleed else 1.0 + 0.5 * Game.fx_level()))
	speed *= 1.0 + 0.2 * Game.fx_level()
	for i in amount:
		if g_pos.size() >= MAX_GIBS:
			_settle_gib(0)
		var idx := g_pos.size()
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		var vel := Vector2.from_angle(a) * speed * randf_range(0.35, 1.0)
		var sz := Vector2(randf_range(2.0, 4.5), randf_range(1.5, 3.5))
		var col: Color = colors[randi() % colors.size()]
		if idx == g_pos.size():
			g_pos.append(pos)
			g_vel.append(vel)
			g_rot.append(randf() * TAU)
			g_rv.append(randf_range(-14, 14))
			g_size.append(sz)
			g_col.append(col)
			g_rest.append(0)
			g_bleed.append(1 if bleed else 0)
		else:
			g_pos[idx] = pos
			g_vel[idx] = vel
			g_rot[idx] = randf() * TAU
			g_rv[idx] = randf_range(-14, 14)
			g_size[idx] = sz
			g_col[idx] = col
			g_rest[idx] = 0
			g_bleed[idx] = 1 if bleed else 0


# ---------------------------------------------------------------- simulação

## Pedaço que parou de vez: vira desenho fixo na camada de manchas.
func _settle_gib(j: int, keep: bool = true) -> void:
	if keep:
		stains.add_gib(g_pos[j], g_rot[j], g_size[j], g_col[j])
	var last := g_pos.size() - 1
	g_pos[j] = g_pos[last]
	g_vel[j] = g_vel[last]
	g_rot[j] = g_rot[last]
	g_rv[j] = g_rv[last]
	g_size[j] = g_size[last]
	g_col[j] = g_col[last]
	g_rest[j] = g_rest[last]
	g_bleed[j] = g_bleed[last]
	g_pos.resize(last)
	g_vel.resize(last)
	g_rot.resize(last)
	g_rv.resize(last)
	g_size.resize(last)
	g_col.resize(last)
	g_rest.resize(last)
	g_bleed.resize(last)


func _remove_drop(i: int) -> void:
	var last := d_pos.size() - 1
	d_pos[i] = d_pos[last]
	d_vel[i] = d_vel[last]
	d_size[i] = d_size[last]
	d_life[i] = d_life[last]
	d_col[i] = d_col[last]
	d_pos.resize(last)
	d_vel.resize(last)
	d_size.resize(last)
	d_life.resize(last)
	d_col.resize(last)
	d_age[i] = d_age[last]
	d_age.resize(last)


func _physics_process(delta: float) -> void:
	if level == null:
		return
	screen_cd = maxf(screen_cd - delta, 0.0)
	var targets := _targets()
	var i := 0
	while i < d_pos.size():
		var v := d_vel[i]
		v.y += GRAV * delta
		v *= 1.0 - 0.5 * delta
		var p := d_pos[i]
		var np := p + v * delta
		d_life[i] -= delta
		d_age[i] += delta
		var c: Vector2i = level.world_to_cell(np)
		if level.is_solid(c):
			_hit_surface(p, np, v, d_size[i], d_col[i])
			_remove_drop(i)
			continue
		if d_age[i] > 0.07 and _hit_target(targets, np, d_size[i], d_col[i]):
			_remove_drop(i)
			continue
		# Parede do fundo: parte das gotas se espatifa no cenário atrás da ação.
		if d_age[i] > 0.05 and d_size[i] > 0.9 and randf() < 1.1 * delta:
			_hit_backdrop(np, v, d_size[i], d_col[i])
			_remove_drop(i)
			continue
		if d_life[i] <= 0.0:
			_remove_drop(i)
			continue
		d_pos[i] = np
		d_vel[i] = v
		i += 1

	# Escorridos
	var k := 0
	while k < drips.size():
		var dr: Array = drips[k]
		var step: float = float(dr[2]) * delta
		dr[0] = (dr[0] as Vector2) + Vector2(0, step)
		dr[1] = float(dr[1]) - step
		dr[2] = maxf(float(dr[2]) * (1.0 - 0.4 * delta), 3.0)
		var dk: int = int(dr[5])
		# Uma mancha a cada pixel escorrido (não a cada passo da física).
		dr[6] = float(dr[6]) + step
		if float(dr[6]) >= 1.0:
			dr[6] = 0.0
			stains.add_stain(dr[0], float(dr[3]) * randf_range(0.7, 1.0), dk, dr[4])
		if float(dr[1]) <= 0.0:
			stains.add_stain(dr[0] + Vector2(0, 0.6), float(dr[3]) * 1.5, 1, dr[4])
			drips.remove_at(k)
		else:
			k += 1

	# Pedaços (os que param são assados e saem da lista)
	var j := 0
	while j < g_pos.size():
		if g_rest[j] == 1:
			_settle_gib(j)
			continue
		var gv := g_vel[j]
		gv.y += GRAV * delta
		var gp := g_pos[j]
		var ngp := gp + gv * delta
		var gc: Vector2i = level.world_to_cell(ngp)
		if level.is_solid(level.world_to_cell(gp)):
			# Nasceu dentro da parede: some.
			_settle_gib(j, false)
			continue
		if level.is_solid(gc):
			var side: Vector2i = level.world_to_cell(Vector2(ngp.x, gp.y))
			if level.is_solid(side):
				gv.x *= -0.4
				ngp.x = gp.x
			# Bateu de lado e ainda tem chão/teto: trata o vertical também
			# (antes o pedaço atravessava o chão e caía para sempre).
			gc = level.world_to_cell(ngp)
			if level.is_solid(gc):
				if gv.y > 0.0:
					ngp.y = gc.y * TILE - g_size[j].y * 0.5
					if g_bleed[j] == 1 and _gore() and absf(gv.y) > 80.0:
						stains.add_stain(Vector2(ngp.x, gc.y * TILE), randf_range(1.5, 3.0), 0, blood_color())
				else:
					ngp.y = gp.y
				gv.y *= -0.32
				gv.x *= 0.6
				g_rv[j] *= 0.5
				if absf(gv.y) < 45.0 and absf(gv.x) < 30.0:
					g_rest[j] = 1
					gv = Vector2.ZERO
		g_pos[j] = ngp
		g_vel[j] = gv
		g_rot[j] += g_rv[j] * delta
		if g_bleed[j] == 1 and _gore() and randf() < 0.35 and d_pos.size() < MAX_DROPS:
			d_pos.append(ngp)
			d_vel.append(gv * 0.2 + Vector2(randf_range(-15, 15), 0))
			d_size.append(randf_range(0.5, 1.0))
			d_life.append(1.2)
			d_col.append(blood_color())
			d_age.append(0.0)
		j += 1
	queue_redraw()


## Personagens vivos na tela atual que podem ficar manchados.
func _targets() -> Array:
	var out: Array = []
	if d_pos.is_empty() or Game.world == null:
		return out
	for n in get_tree().get_nodes_in_group("splat_target"):
		if n.has_method("splat_rect") and Game.world.is_active(n.global_position):
			out.append(n)
	return out


func _hit_target(targets: Array, p: Vector2, size: float, col: Color) -> bool:
	for n in targets:
		var r: Rect2 = n.splat_rect()
		if r.has_point(p):
			n.receive_splat(p, size, col)
			return randf() < 0.75
	return false


func _hit_backdrop(p: Vector2, v: Vector2, size: float, col: Color) -> void:
	var r := size * randf_range(0.9, 1.8)
	var bc := Color(col.darkened(0.25), 0.8)
	stains.add_stain(p, r, 3, bc)
	# Respingos em volta, alongados na direção do voo
	var dir := v.normalized()
	for k in randi_range(1, 3):
		stains.add_stain(p + dir * randf_range(2.0, 6.0) + Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5)), r * 0.35, 3, bc)
	if r > 1.8 and randf() < 0.4 and drips.size() < 80:
		drips.append([p, randf_range(6.0, 22.0), randf_range(6.0, 12.0), randf_range(0.4, 0.7), bc, 3, 1.0])


func _hit_surface(p: Vector2, np: Vector2, v: Vector2, size: float, col: Color) -> void:
	var side: Vector2i = level.world_to_cell(Vector2(np.x, p.y))
	var spd := v.length()
	var r := size * clampf(0.7 + spd / 260.0, 0.7, 2.2)
	if level.is_solid(side):
		# Parede
		var wall_x := float(side.x * TILE) if v.x > 0.0 else float((side.x + 1) * TILE)
		var sp := Vector2(wall_x, p.y)
		stains.add_stain(sp, r, 1, col)
		if r > 1.4 and randf() < 0.28 and drips.size() < 80:
			drips.append([sp, randf_range(8.0, 30.0), randf_range(8.0, 18.0), randf_range(0.5, 0.9), col, 1, 1.0])
	else:
		var c: Vector2i = level.world_to_cell(np)
		if v.y > 0.0:
			stains.add_stain(Vector2(np.x, c.y * TILE), r, 0, col)
		else:
			stains.add_stain(Vector2(np.x, (c.y + 1) * TILE), r * 0.8, 2, col)


func _draw() -> void:
	# Gotas em três espessuras, cada uma num único comando de desenho.
	var pts: Array = [PackedVector2Array(), PackedVector2Array(), PackedVector2Array()]
	var cols: Array = [PackedColorArray(), PackedColorArray(), PackedColorArray()]
	for i in d_pos.size():
		var p := d_pos[i]
		var sz := d_size[i]
		var k := 0 if sz < 1.0 else (1 if sz < 1.7 else 2)
		(pts[k] as PackedVector2Array).append(p - d_vel[i] * 0.012)
		(pts[k] as PackedVector2Array).append(p)
		(cols[k] as PackedColorArray).append(d_col[i])
	var widths := [0.8, 1.4, 2.2]
	for k in 3:
		if not (pts[k] as PackedVector2Array).is_empty():
			draw_multiline_colors(pts[k], cols[k], widths[k])
	for j in g_pos.size():
		draw_set_transform(g_pos[j], g_rot[j], Vector2.ONE)
		var s := g_size[j]
		draw_rect(Rect2(-s * 0.5, s), g_col[j])
		draw_rect(Rect2(-s * 0.5, Vector2(s.x, 0.8)), g_col[j].lightened(0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Camada de manchas. Cada tela tem uma textura própria (SubViewport que
## nunca é limpo): as manchas novas são desenhadas uma vez só e ficam
## "assadas" nela. Assim o custo não cresce com a quantidade de sangue.
## As poças crescem, então ficam num nó à parte que redesenha (são poucas).
class StainLayer extends Node2D:
	const SCREEN := Vector2(640, 360)
	## Quantas manchas de cada tipo já foram feitas (0 chão, 1 parede, 2 teto, 3 fundo).
	var kind_count := PackedInt32Array([0, 0, 0, 0])
	var total := 0
	var pools: Array = []   # [pos, r, alvo, cor]
	var pools_dirty := false
	var pool_node: Node2D
	## Vector2i(tela) -> {"vp": SubViewport, "pen": Node2D, "new": Array}
	var pages := {}
	var level = null

	func _ready() -> void:
		pool_node = Node2D.new()
		pool_node.draw.connect(_draw_pools)
		add_child(pool_node)

	func _page(s: Vector2i) -> Dictionary:
		if pages.has(s):
			return pages[s]
		var vp := SubViewport.new()
		vp.size = Vector2i(SCREEN)
		vp.transparent_bg = true
		vp.disable_3d = true
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(vp)
		var pen := Node2D.new()
		pen.position = -Vector2(s) * SCREEN
		vp.add_child(pen)
		var spr := Sprite2D.new()
		spr.centered = false
		spr.position = Vector2(s) * SCREEN
		spr.texture = vp.get_texture()
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		spr.material = mat
		add_child(spr)
		var pg := {"vp": vp, "pen": pen, "new": []}
		pen.draw.connect(_draw_page.bind(pg))
		pages[s] = pg
		return pg

	func add_stain(p: Vector2, r: float, kind: int, col: Color) -> void:
		kind_count[kind] += 1
		total += 1
		_put(p, r, [p, r, kind, col])

	func _put(p: Vector2, r: float, item: Array) -> void:
		# Uma mancha na divisa entre telas vai para as duas.
		var m := r * 1.5 + 1.0
		var a := Vector2i(floori((p.x - m) / SCREEN.x), floori((p.y - m) / SCREEN.y))
		var b := Vector2i(floori((p.x + m) / SCREEN.x), floori((p.y + m) / SCREEN.y))
		for sx in range(a.x, b.x + 1):
			for sy in range(a.y, b.y + 1):
				if level != null and not level.has_screen(Vector2i(sx, sy)):
					continue
				var pg := _page(Vector2i(sx, sy))
				var fresh: Array = pg["new"]
				if fresh.is_empty():
					(pg["pen"] as Node2D).queue_redraw()
					(pg["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
				fresh.append(item)

	func add_gib(p: Vector2, rot: float, size: Vector2, col: Color) -> void:
		_put(p, maxf(size.x, size.y), [p, rot, 4, col, size])

	func add_pool(p: Vector2, target: float) -> void:
		if pools.size() >= 60:
			pools.remove_at(0)
		pools.append([p, 1.0, target, Color(0.45, 0.02, 0.02, 0.92)])
		pools_dirty = true

	func _process(delta: float) -> void:
		for pl in pools:
			if float(pl[1]) < float(pl[2]):
				pl[1] = minf(float(pl[1]) + delta * 5.0, float(pl[2]))
				pools_dirty = true
		if pools_dirty:
			pools_dirty = false
			pool_node.queue_redraw()

	func _draw_pools() -> void:
		for pl in pools:
			var p: Vector2 = pl[0]
			var r: float = pl[1]
			var col: Color = pl[3]
			pool_node.draw_rect(Rect2(p.x - r, p.y - 0.6, r * 2.0, 2.4), col)
			pool_node.draw_rect(Rect2(p.x - r * 0.7, p.y - 1.1, r * 1.4, 0.6), col.darkened(0.2))
			pool_node.draw_rect(Rect2(p.x - r * 0.4, p.y - 0.6, r * 0.5, 0.5), Color(1, 0.5, 0.5, 0.25))

	## Desenha só as manchas novas; a textura guarda as antigas.
	func _draw_page(pg: Dictionary) -> void:
		var pen: Node2D = pg["pen"]
		var fresh: Array = pg["new"]
		for st in fresh:
			var p: Vector2 = st[0]
			var r: float = st[1]
			var col: Color = st[3]
			match int(st[2]):
				4:
					var gs: Vector2 = st[4]
					pen.draw_set_transform(p, float(st[1]), Vector2.ONE)
					pen.draw_rect(Rect2(-gs * 0.5, gs), col)
					pen.draw_rect(Rect2(-gs * 0.5, Vector2(gs.x, 0.8)), col.lightened(0.2))
					pen.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				3:
					pen.draw_circle(p, r * 0.85, col)
				0:
					pen.draw_rect(Rect2(p.x - r * 1.4, p.y - 0.3, r * 2.8, maxf(1.0, r * 0.7)), col)
					pen.draw_circle(Vector2(p.x + r * 0.6, p.y + r * 0.25), r * 0.45, col)
				1:
					pen.draw_circle(p, r * 0.8, col)
				_:
					pen.draw_rect(Rect2(p.x - r, p.y - maxf(1.0, r * 0.6), r * 2.0, maxf(1.0, r * 0.6)), col)
		fresh.clear()
