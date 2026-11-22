extends Node2D
## Reentrância na parede do fundo. Sera se encosta aqui (↑) e fica imune a tiros.


func _ready() -> void:
	add_to_group("cover")
	z_index = -5


func _draw() -> void:
	var r := Rect2(-10, -36, 20, 36)
	draw_rect(r.grow(2), Color("6e4a2c"))
	draw_rect(r, Color("0e0c0c"))
	draw_rect(Rect2(-10, -36, 20, 4), Color("1a1616"))
	draw_rect(Rect2(-8, -34, 16, 1), Color(0.9, 0.6, 0.3, 0.25))
	draw_circle(Vector2(0, -38.5), 1.5, Color(1.0, 0.7, 0.3, 0.7))
