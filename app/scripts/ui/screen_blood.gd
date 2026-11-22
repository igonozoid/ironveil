extends CanvasLayer
## Sangue que espirra "na lente": manchas na tela quando alguém é estraçalhado
## perto de Sera. Escorrem devagar e somem em alguns segundos.

var MAX_BLOBS := 16
var HOLD := 2.6
const FADE := 2.4

## Cada mancha: {pos, parts: [[off, r]], drips: [[off, len, max, speed, w]], t, col}
var blobs: Array = []
var canvas: Node2D


func _ready() -> void:
	MAX_BLOBS = 16 * (1 + Game.fx_level() * 2)
	HOLD = 2.6 + 1.6 * Game.fx_level()
	layer = 9
	canvas = Node2D.new()
	add_child(canvas)
	canvas.draw.connect(_paint)


## `pos` em coordenadas de tela (0..640, 0..360); `k` = intensidade (0.15..1.6).
func splat(pos: Vector2, dir: Vector2, k: float) -> void:
	if not Game.gore_enabled():
		return
	k *= 1.0 + 0.6 * Game.fx_level()
	var n := 1 + int(k * 2.2)
	for i in n:
		# Espalha em direção à "câmera": empurra para longe do ponto e para as bordas.
		var off := Vector2(randf_range(-140, 140), randf_range(-90, 90)) * (0.4 + k * 0.5)
		if dir != Vector2.ZERO:
			off += dir.normalized() * randf_range(20, 90) * k
		var p := (pos + off).clamp(Vector2(-10, -10), Vector2(650, 370))
		_add_blob(p, randf_range(5.0, 11.0) * clampf(k, 0.5, 1.4 + 0.4 * Game.fx_level()))
	# Insano: sangue escorrendo pelos cantos e bordas da tela.
	if Game.fx_level() >= 2:
		for i in 2:
			var edge: Vector2 = [Vector2(randf_range(0, 640), randf_range(-6, 14)), Vector2(randf_range(-6, 14), randf_range(0, 360)),
				Vector2(randf_range(626, 646), randf_range(0, 360)), Vector2(randf_range(0, 640), randf_range(346, 366))][randi() % 4]
			_add_blob(edge, randf_range(10.0, 20.0))


func _add_blob(p: Vector2, size: float) -> void:
	if blobs.size() >= MAX_BLOBS:
		blobs.remove_at(0)
	var parts: Array = [[Vector2.ZERO, size]]
	for i in randi_range(4, 9):
		var a := randf() * TAU
		var d := randf_range(size * 0.5, size * 1.9)
		parts.append([Vector2.from_angle(a) * d, size * randf_range(0.12, 0.45)])
	var drips: Array = []
	for i in randi_range(1, 3):
		drips.append([Vector2(randf_range(-size * 0.6, size * 0.6), size * 0.4), 0.0,
			randf_range(size * 1.5, size * 5.0), randf_range(6.0, 16.0), randf_range(1.2, size * 0.35)])
	var col := Color(randf_range(0.42, 0.6), 0.02, 0.03, 0.82)
	blobs.append({"pos": p, "parts": parts, "drips": drips, "t": 0.0, "col": col})


func clear() -> void:
	blobs.clear()
	canvas.queue_redraw()


func _process(delta: float) -> void:
	if blobs.is_empty():
		return
	var i := 0
	while i < blobs.size():
		var b: Dictionary = blobs[i]
		b["t"] = float(b["t"]) + delta
		for d in b["drips"]:
			if float(d[1]) < float(d[2]):
				d[1] = minf(float(d[1]) + float(d[3]) * delta, float(d[2]))
		if float(b["t"]) > HOLD + FADE:
			blobs.remove_at(i)
		else:
			i += 1
	canvas.queue_redraw()


func _paint() -> void:
	for b in blobs:
		var t: float = b["t"]
		var a := 1.0 if t < HOLD else 1.0 - (t - HOLD) / FADE
		var col: Color = b["col"]
		col.a *= a
		var hi := Color(1.0, 0.6, 0.6, 0.18 * a)
		var p: Vector2 = b["pos"]
		for part in b["parts"]:
			canvas.draw_circle(p + part[0], part[1], col)
		for d in b["drips"]:
			var o: Vector2 = p + d[0]
			var l: float = d[1]
			canvas.draw_line(o, o + Vector2(0, l), col, d[4])
			canvas.draw_circle(o + Vector2(0, l), float(d[4]) * 0.7, col)
		var main: Array = b["parts"][0]
		canvas.draw_circle(p + Vector2(-0.3, -0.3) * float(main[1]), float(main[1]) * 0.3, hi)
