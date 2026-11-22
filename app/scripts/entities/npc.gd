extends "res://scripts/entities/civilian.gd"
## Morador que dá dicas (marca `?` nas fases). Fica parado, olha para Sera,
## mostra um balão quando ela chega perto e conversa com A. As falas vêm de
## level_data ("Nome|fala||Nome|outra fala"); marcas como [jump] viram a tecla
## atual. Reage a sangue como qualquer civil.

const OUTFITS := {
	"boiler": [Color("4a3a2c"), Color("3e4246"), Color("5a3e2a")],
	"market": [Color("5a4a3a"), Color("4a5248"), Color("6a5a40"), Color("4e4450")],
	"tower": [Color("2e2a36"), Color("3a3442"), Color("44382e")],
}

var npc_name := "Operário"
var lines: Array = []
var talked := false
var near := false
var theme := "boiler"
var prompt := "A: conversar"


func setup_npc(pos: Vector2, text: String, level_theme: String, seed_i: int) -> void:
	setup(pos, seed_i)
	theme = level_theme
	stationary = true
	basket = false
	var pal: Array = OUTFITS.get(theme, OUTFITS["boiler"])
	coat = pal[seed_i % pal.size()]
	hat = theme != "tower" or seed_i % 2 == 0
	lines = []
	for part in text.split("||"):
		var p := String(part).strip_edges()
		if p == "":
			continue
		var who := _default_name()
		var say := p
		if p.contains("|"):
			who = p.get_slice("|", 0).strip_edges()
			say = p.get_slice("|", 1).strip_edges()
		lines.append([who, say])
	if not lines.is_empty():
		npc_name = String(lines[0][0])


func _default_name() -> String:
	match theme:
		"market":
			return "Feirante"
		"tower":
			return "Criado da Torre"
	return "Operário"


func _ready() -> void:
	super._ready()
	add_to_group("interactable")
	add_to_group("npc")


func can_interact() -> bool:
	return reaction == "" and panic_t <= 0.0 and not lines.is_empty()


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 26.0 and absf(p.global_position.y - global_position.y) < 24.0


func interact(_p) -> void:
	if Game.world == null or Game.world.dialog.active:
		return
	talked = true
	var out: Array = []
	for l in lines:
		out.append([String(l[0]), Game.fmt(String(l[1]))])
	Sfx.play("blip", -6.0)
	Game.world.dialog.start(out, func(): pass)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var p = Game.world.player if Game.world else null
	near = p != null and absf(p.global_position.x - global_position.x) < 70.0 and absf(p.global_position.y - global_position.y) < 40.0
	prompt = "A: conversar com " + npc_name if can_interact() else ""
	prompt = Game.fmt(prompt.replace("A:", "[interact]:"))


func _draw() -> void:
	super._draw()
	if reaction != "" or panic_t > 0.0:
		return
	if theme == "boiler":
		# Fuligem no rosto e alça do macacão
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
		draw_line(Vector2(-3, -25.0 - tall), Vector2(3, -12), Color(0.8, 0.55, 0.25, 0.6), 1.0)
		draw_circle(Vector2(1.5, -25.0 - tall), 0.9, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif theme == "tower":
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
		for i in 3:
			draw_circle(Vector2(0, -20.0 - tall + i * 3.5), 0.6, Color("e0b860"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Balão de fala quando Sera chega perto
	if near and not lines.is_empty():
		var y := -42.0 - tall + sin(t * 3.0) * 1.0
		var col := Color(1.0, 0.95, 0.85, 0.85) if not talked else Color(0.8, 0.75, 0.7, 0.5)
		draw_rect(Rect2(-7, y - 5, 14, 9), col)
		draw_colored_polygon(PackedVector2Array([Vector2(-2, y + 4), Vector2(2, y + 4), Vector2(-1, y + 7)]), col)
		var dots := Color(0.2, 0.15, 0.12)
		if not talked:
			draw_rect(Rect2(-0.6, y - 3.5, 1.4, 4), dots)
			draw_rect(Rect2(-0.6, y + 1.2, 1.4, 1.4), dots)
		else:
			for i in 3:
				draw_circle(Vector2(-3 + i * 3, y), 0.8, dots)
