extends RefCounted
## Manchas de sangue grudadas no corpo de um personagem. Guardadas em
## coordenadas "olhando para a direita" e em fração da altura do corpo, para
## acompanharem o personagem quando ele vira, agacha ou anda.

const Dot := preload("res://scripts/fx/dot.gd")
const MAX := 48

## Cada item: [x (px, lado da frente > 0), h (0 = pés, 1 = topo), raio, cor, escorrido (px), criado (s)]
var items: Array = []
var ring := 0


## `local` = ponto do impacto relativo à origem (pés) do personagem.
func add(local: Vector2, facing: int, height: float, half_w: float, r: float, col: Color) -> void:
	var x := clampf(local.x * float(facing), -half_w, half_w)
	var h := clampf(-local.y / height, 0.05, 1.0)
	var drip := randf_range(0.0, 3.5) if r > 1.0 and randf() < 0.45 else 0.0
	var it := [x, h, clampf(r, 0.5, 1.8), col.darkened(randf_range(0.0, 0.25)), drip, Time.get_ticks_msec() / 1000.0]
	if items.size() < MAX:
		items.append(it)
	else:
		items[ring] = it
		ring = (ring + 1) % MAX


## Remove as manchas com mais de `max_age` segundos.
func expire(max_age: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var keep: Array = []
	for it in items:
		if it.size() < 6 or now - float(it[5]) < max_age:
			keep.append(it)
	if keep.size() != items.size():
		items = keep
		ring = 0


func clear() -> void:
	items.clear()
	ring = 0


func count() -> int:
	return items.size()


## Desenha no CanvasItem já transformado (espelhado pelo facing do dono).
func draw_on(ci: CanvasItem, height: float, x_scale: float = 1.0, limit: int = -1) -> void:
	# Círculos primeiro, escorridos depois: menos trocas de tipo = menos
	# chamadas de desenho.
	var n := mini(items.size(), limit) if limit >= 0 else items.size()
	for i in n:
		var it: Array = items[i]
		var p := Vector2(float(it[0]) * x_scale, -float(it[1]) * height)
		var r: float = it[2]
		var col: Color = it[3]
		Dot.draw(ci, p, r * 0.75, col)
		if r > 1.0:
			Dot.draw(ci, p + Vector2(r * 0.6, r * 0.3), r * 0.4, col)
	for i in n:
		var it: Array = items[i]
		var d: float = it[4]
		if d > 0.0:
			var p := Vector2(float(it[0]) * x_scale, -float(it[1]) * height)
			ci.draw_line(p, p + Vector2(0, d), it[3], maxf(0.5, float(it[2]) * 0.45))


func to_array() -> Array:
	return items.duplicate(true)


func from_array(a: Array) -> void:
	items = a.duplicate(true)
	ring = 0
