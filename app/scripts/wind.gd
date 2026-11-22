extends Node2D
## Vento do Véu de Ferro (Ato 5): ciclos de calmaria, aviso (riscos finos e
## assobio) e rajada que empurra Sera para um lado. Agachada ela é empurrada
## bem menos; encostada ou pendurada, nada. Os riscos atravessam a tela.

var strength := 0.0
var state := 0          # 0 calmaria, 1 aviso, 2 rajada
var t := 0.0
var dir := 1
var streaks: Array = []   # [pos, vel, life]


func setup(s: float) -> void:
	strength = s
	t = 2.5
	z_index = 9


## Força horizontal atual (px/s²) sobre Sera.
func force() -> float:
	if state != 2 or strength <= 0.0:
		return 0.0
	return dir * strength * 6.0


func _physics_process(delta: float) -> void:
	if strength <= 0.0:
		state = 0
		streaks.clear()
		queue_redraw()
		return
	t -= delta
	if t <= 0.0:
		match state:
			0:
				state = 1
				t = 1.1
				dir = 1 if randf() < 0.5 else -1
				Sfx.play("steam", -14.0, 0.4)
			1:
				state = 2
				t = randf_range(1.6, 2.4)
				Sfx.play("steam", -6.0, 0.3)
			_:
				state = 0
				t = randf_range(2.5, 4.0)
	var cam: Vector2 = Game.world.camera.position if Game.world else Vector2.ZERO
	var rate := 0.0
	if state == 1:
		rate = 18.0
	elif state == 2:
		rate = 70.0
	if randf() < rate * delta * 3.0:
		var y := cam.y + randf_range(20, 340)
		var x := cam.x - 20.0 if dir > 0 else cam.x + 660.0
		streaks.append([Vector2(x, y), Vector2(dir * randf_range(500, 800), randf_range(-10, 20)), 1.5])
	var i := 0
	while i < streaks.size():
		var s: Array = streaks[i]
		s[0] = (s[0] as Vector2) + (s[1] as Vector2) * delta
		s[2] = float(s[2]) - delta
		if float(s[2]) <= 0.0:
			streaks.remove_at(i)
		else:
			i += 1
	queue_redraw()


func _draw() -> void:
	for s in streaks:
		var p: Vector2 = s[0]
		var v: Vector2 = s[1]
		var a := clampf(float(s[2]), 0.0, 1.0) * (0.35 if state == 2 else 0.18)
		draw_line(p, p - v.normalized() * 26.0, Color(0.85, 0.9, 1.0, a), 1.0)
