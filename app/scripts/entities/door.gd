extends StaticBody2D
## Porta que bloqueia passagem. "blast": abre por painel. "security": abre com
## o Cartão de acesso (consumido). A origem é o canto superior esquerdo da célula.

var kind := "blast"
var height := 60.0
var opened := false
var open_k := 0.0
var cs: CollisionShape2D
var prompt := ""


func setup(pos: Vector2, h: float, k: String) -> void:
	position = pos
	height = h
	kind = k
	prompt = "Porta blindada sem energia" if k == "blast" else "Porta de segurança — S: usar cartão"


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 2
	add_to_group("door")
	add_to_group("interactable")
	if kind == "security":
		add_to_group("security_door")
	cs = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, height)
	cs.shape = shape
	cs.position = Vector2(10, height * 0.5)
	add_child(cs)


func can_interact() -> bool:
	return not opened


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - (global_position.x + 10)) < 24.0 \
			and p.global_position.y > global_position.y and p.global_position.y <= global_position.y + height + 2.0


func interact(_p) -> void:
	if kind == "blast":
		Game.world.hud.message("Sem energia. Um painel de controle pode religá-la.")
	else:
		Game.world.hud.message("Selecione o Cartão de acesso (Q) e use com S.")


func open() -> void:
	if opened:
		return
	opened = true
	Sfx.play("door")
	cs.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(self, "open_k", 1.0, 0.9)


func _process(_delta: float) -> void:
	if opened and open_k < 1.0:
		queue_redraw()


func _draw() -> void:
	var h := height * (1.0 - open_k)
	if h <= 0.5:
		return
	var r := Rect2(3, 0, 14, h)
	if kind == "blast":
		draw_rect(r, Color("4a4542"))
		var y := 2.0
		while y < h - 2.0:
			draw_line(Vector2(4, y), Vector2(16, minf(y + 6.0, h)), Color("e8c547"), 2.0)
			y += 9.0
	else:
		draw_rect(r, Color("3a4250"))
		draw_rect(Rect2(5, 4, 10, minf(h - 8.0, 12.0)), Color("2a2f38"))
		if h > 30.0:
			draw_rect(Rect2(7, h * 0.5 - 4, 6, 8), Color("e8c547") if not opened else Color("6fbf73"))
	draw_rect(r, Color("1e1b1b"), false, 1.5)
