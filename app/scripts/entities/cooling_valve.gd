extends Node2D
## Registro de resfriamento (Ato 4): a alavanca `j` abre o bico `q` mais
## próximo, que despeja água por 1,3 s numa coluna até o chão. A água cria
## crosta no ferro fundido que atingir e esfria a Fornalha-Mãe se ela estiver
## embaixo. Recarrega em 5 s.

const Fx := preload("res://scripts/fx.gd")
const POUR := 1.3
const COOLDOWN := 5.0

var nozzle := Vector2.ZERO
var floor_y := 0.0
var pour := 0.0
var cd := 0.0
var t := 0.0
var pulled := 0.0
var prompt := "A: abrir o registro"
var hit_lava: Array = []
var boss_hit := false


func setup(pos: Vector2, nozzle_pos: Vector2, floor_world_y: float) -> void:
	position = pos
	nozzle = nozzle_pos
	floor_y = floor_world_y
	z_index = 3


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cooling_valve")


func can_interact() -> bool:
	return cd <= 0.0 and pour <= 0.0


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 20.0 and absf(p.global_position.y - global_position.y) < 22.0


func interact(_p) -> void:
	if not can_interact():
		return
	pour = POUR
	cd = COOLDOWN
	pulled = 0.6
	boss_hit = false
	hit_lava.clear()
	Sfx.play("lever", 0.0, 0.7)
	Sfx.play("steam", -2.0, 0.5)


func column() -> Rect2:
	return Rect2(Vector2(nozzle.x - 8.0, nozzle.y), Vector2(16.0, floor_y - nozzle.y))


func _physics_process(delta: float) -> void:
	t += delta
	pulled = maxf(pulled - delta, 0.0)
	if pour > 0.0:
		pour -= delta
		var col := column()
		for l in get_tree().get_nodes_in_group("lava"):
			if col.intersects(l.rect) and not hit_lava.has(l):
				hit_lava.append(l)
				l.cool(6.0)
		var b = Game.world.boss if Game.world else null
		if b != null and not boss_hit and b.has_method("cool_hit") and b.is_alive() and col.intersects(b.rect()):
			boss_hit = true
			b.cool_hit()
		if fmod(t, 0.08) < delta:
			Fx.steam_puff(get_parent(), Vector2(nozzle.x, floor_y - 4.0), 3)
	elif cd > 0.0:
		cd -= delta
	prompt = "A: abrir o registro" if can_interact() else ""
	queue_redraw()


func _draw() -> void:
	# Alavanca na parede
	draw_rect(Rect2(-6, -22, 12, 14), Color("2c2a2e"))
	draw_rect(Rect2(-6, -22, 12, 2), Color("5a7a8a"))
	var ang := -0.7 if pulled <= 0.0 else 0.7
	var tip := Vector2(0, -15) + Vector2(sin(ang), -cos(ang)) * 12.0
	draw_line(Vector2(0, -15), tip, Color("7a7470"), 2.5)
	draw_circle(tip, 2.4, Color("3a6a8a"))
	draw_circle(Vector2(4, -10), 1.5, Color(0.3, 0.8, 1.0) if can_interact() else Color(0.4, 0.2, 0.15))
	# Bico e jato de água (em coordenadas do mundo)
	var n := nozzle - global_position
	draw_rect(Rect2(n + Vector2(-6, -6), Vector2(12, 8)), Color("3a3640"))
	draw_rect(Rect2(n + Vector2(-3, 2), Vector2(6, 3)), Color("5a7a8a"))
	if pour > 0.0:
		var bottom := floor_y - global_position.y
		var w := 7.0 + sin(t * 30.0) * 1.0
		draw_rect(Rect2(Vector2(n.x - w * 0.5, n.y + 4), Vector2(w, bottom - n.y - 4)), Color(0.55, 0.8, 1.0, 0.55))
		draw_rect(Rect2(Vector2(n.x - 1.5, n.y + 4), Vector2(3, bottom - n.y - 4)), Color(0.85, 0.95, 1.0, 0.7))
