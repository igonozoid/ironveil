extends CanvasLayer
## Sangue que espirra "na lente": manchas na tela quando alguém é estraçalhado
## perto de Sera. Escorrem devagar e somem em alguns segundos.

const Dot := preload("res://scripts/fx/dot.gd")

var MAX_BLOBS := 16
var HOLD := 2.6
const FADE := 2.4

var blobs: Array = []
var canvas: Node2D


func _ready() -> void:
	MAX_BLOBS = 16 * (1 + Game.fx_level())
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
		blobs[0].queue_free()
		blobs.remove_at(0)
	var b := Blob.new()
	b.pos = p
	b.setup(size, HOLD, FADE)
	add_child(b)
	blobs.append(b)


func clear() -> void:
	for b in blobs:
		b.queue_free()
	blobs.clear()
	canvas.queue_redraw()


func _process(_delta: float) -> void:
	if blobs.is_empty():
		return
	canvas.queue_redraw()
	var i := 0
	while i < blobs.size():
		if blobs[i].done:
			blobs[i].queue_free()
			blobs.remove_at(i)
		else:
			i += 1


## Uma mancha na lente (só o estado; o desenho é feito em lote em _paint).
class Blob extends Node:
	var pos := Vector2.ZERO
	var parts: Array = []   # [off, r]
	var drips: Array = []   # [off, len, max, speed, w]
	var col: Color
	var t := 0.0
	var hold := 2.6
	var fade := 2.4
	var done := false
	var alpha := 1.0

	func setup(size: float, h: float, f: float) -> void:
		hold = h
		fade = f
		parts.append([Vector2.ZERO, size])
		for i in randi_range(4, 9):
			var a := randf() * TAU
			var d := randf_range(size * 0.5, size * 1.9)
			parts.append([Vector2.from_angle(a) * d, size * randf_range(0.12, 0.45)])
		for i in randi_range(1, 3):
			drips.append([Vector2(randf_range(-size * 0.6, size * 0.6), size * 0.4), 0.0,
				randf_range(size * 1.5, size * 5.0), randf_range(6.0, 16.0), randf_range(1.2, size * 0.35)])
		col = Color(randf_range(0.42, 0.6), 0.02, 0.03, 0.82)

	func _process(delta: float) -> void:
		t += delta
		for d in drips:
			if float(d[1]) < float(d[2]):
				d[1] = minf(float(d[1]) + float(d[3]) * delta, float(d[2]))
		alpha = 1.0 if t < hold else maxf(0.0, 1.0 - (t - hold) / fade)
		done = t > hold + fade


## Tudo num lote só: primeiro os círculos de todas as manchas, depois as
## linhas (trocar de tipo a cada mancha quebrava o lote na placa de vídeo).
func _paint() -> void:
	for b in blobs:
		var col: Color = b.col
		col.a *= b.alpha
		for part in b.parts:
			Dot.draw(canvas, b.pos + part[0], part[1], col)
		for d in b.drips:
			Dot.draw(canvas, b.pos + d[0] + Vector2(0, float(d[1])), float(d[4]) * 0.7, col)
	for b in blobs:
		var main: Array = b.parts[0]
		Dot.draw(canvas, b.pos + Vector2(-0.3, -0.3) * float(main[1]), float(main[1]) * 0.3, Color(1.0, 0.6, 0.6, 0.18 * b.alpha))
	for b in blobs:
		var col: Color = b.col
		col.a *= b.alpha
		for d in b.drips:
			var o: Vector2 = b.pos + d[0]
			canvas.draw_line(o, o + Vector2(0, float(d[1])), col, d[4])
