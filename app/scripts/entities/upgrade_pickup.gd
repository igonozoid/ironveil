extends Node2D
## Prêmio deixado por um chefão derrotado. Ao pegar: upgrade permanente
## (vida extra, arpão de mão ou couraça), vida cheia e um aviso grande.

const Light := preload("res://scripts/fx/light.gd")
const Fx := preload("res://scripts/fx.gd")

var id := "vida"
var t := 0.0
var y0 := 0.0
var taken := false


func setup(pos: Vector2, upgrade_id: String) -> void:
	position = pos
	y0 = pos.y
	id = upgrade_id
	z_index = 6


func _ready() -> void:
	add_to_group("upgrade")
	Light.make(self, Vector2.ZERO, Color(1.0, 0.8, 0.45), 70.0, 1.0, 0.15)
	Fx.burst(get_parent(), global_position, Color(1.0, 0.85, 0.5), 20, 120.0, 0.6, Vector2.ZERO, 1.5)


func _physics_process(delta: float) -> void:
	t += delta
	position.y = y0 + sin(t * 2.5) * 3.0
	queue_redraw()
	var p = Game.world.player if Game.world else null
	if taken or p == null or p.is_dead():
		return
	if p.hitbox().grow(8.0).has_point(global_position):
		collect(p)


func collect(p) -> void:
	taken = true
	Game.grant_upgrade(id)
	Game.hp = Game.max_hp()
	if p.has_method("on_upgrade"):
		p.on_upgrade(id)
	var info: Array = Game.UPGRADES[id]
	Game.world.hud.show_upgrade(String(info[1]), Game.fmt(tr(String(info[2]))))
	Sfx.play("heal", 0.0, 0.8)
	Sfx.play("pickup", -2.0, 0.7)
	Fx.burst(get_parent(), global_position, Color(1.0, 0.9, 0.6), 30, 180.0, 0.7, Vector2.ZERO, 2.0)
	queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	draw_circle(Vector2.ZERO, 14.0 + pulse * 3.0, Color(1.0, 0.8, 0.4, 0.12))
	draw_circle(Vector2.ZERO, 9.0, Color("2a2420"))
	draw_arc(Vector2.ZERO, 9.0, 0, TAU, 20, Color("e0b860"), 1.6)
	match id:
		"vida":
			# Quadrado de vida
			draw_rect(Rect2(-5, -4, 10, 8), Color("7fd4ff"))
			draw_rect(Rect2(-5, -4, 10, 2.5), Color("c8efff"))
		"arpao":
			draw_line(Vector2(-6, 4), Vector2(5, -5), Color("c8c4bc"), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(7, -7), Vector2(2, -6), Vector2(6, -2)]), Color("e0b860"))
		_:
			# Placa de couraça
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -5), Vector2(6, -5), Vector2(5, 3), Vector2(0, 7), Vector2(-5, 3)]), Color("a07a38"))
			draw_line(Vector2(0, -5), Vector2(0, 6), Color("e0b860"), 1.0)
