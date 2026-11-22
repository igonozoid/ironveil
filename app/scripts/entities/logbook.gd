extends Node2D
## Livro de válvulas da Caldeira Sul, num armário do arquivo do Diretório.
## Pegar (A) mostra o registro que incrimina a Torre.

const LINES := [
	["Livro de válvulas", "Caldeira Sul — noite do acidente. 23h40: válvulas 4 a 9 abertas por ordem remota. Autorização: TORRE / Conselho do Diretório."],
	["Livro de válvulas", "Observação a lápis: \"Culpar a manutenção. Engenheira V. de plantão.\""],
	["Sera", "Eles abriram as válvulas da Torre... e escolheram a mim para levar a culpa."],
]

var taken := false
var prompt := "A: abrir o armário do arquivo"
var t := 0.0


func _ready() -> void:
	add_to_group("interactable")
	z_index = 2


func can_interact() -> bool:
	return not taken


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 20.0 and absf(p.global_position.y - global_position.y) < 24.0


func interact(_p) -> void:
	if taken:
		return
	taken = true
	Sfx.play("pickup")
	Game.world.dialog.start(LINES, func(): Game.world.hud.message("Livro de válvulas guardado"))


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-10, -32, 20, 32), Color("3a2e26"))
	draw_rect(Rect2(-10, -32, 20, 2), Color("a07038"))
	for i in 3:
		draw_rect(Rect2(-8, -29 + i * 10, 16, 8), Color("2a2220"))
		draw_circle(Vector2(0, -25 + i * 10), 1.0, Color("b87333"))
	if not taken:
		var a := 0.5 + 0.5 * sin(t * 4.0)
		draw_rect(Rect2(-5, -19, 10, 7), Color("6e2f18"))
		draw_rect(Rect2(-5, -19, 10, 1.5), Color("ffd27a"))
		draw_circle(Vector2(0, -16), 9.0, Color(1.0, 0.85, 0.4, 0.12 * a))
