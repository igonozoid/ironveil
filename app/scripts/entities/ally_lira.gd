extends Node2D
## Lira, contrabandista do Bazar. Ao conversar, abre a passagem escondida atrás
## da barraca dela (a porta blindada mais próxima).

const LINES := [
	["Lira", "Você é a engenheira dos cartazes? Ha. Metade do Mercado acha que você é heroína."],
	["Sera", "Eu não explodi nada. Preciso chegar aos telhados do Diretório."],
	["Lira", "O livro de válvulas da Caldeira Sul está no arquivo deles. Se alguém mandou abrir as válvulas, está escrito lá."],
	["Lira", "Atrás da minha barraca tem uma passagem dos contrabandistas. Vai. E fique no meio do povo: os guardas não atiram com gente na frente."],
]
const REPEAT := [
	["Lira", "A passagem está aberta. Os holofotes não enxergam quem está na multidão — nem quem está encostado."],
]

var door = null
var talked := false
var prompt := "A: falar com a mulher de capuz"
var t := 0.0


func _ready() -> void:
	add_to_group("interactable")
	z_index = 2


func can_interact() -> bool:
	return true


func is_in_reach(p) -> bool:
	return absf(p.global_position.x - global_position.x) < 26.0 and absf(p.global_position.y - global_position.y) < 24.0


func interact(_p) -> void:
	if talked:
		Game.world.dialog.start(REPEAT, Callable())
	else:
		Game.world.dialog.start(LINES, _on_dialog_done)


func _on_dialog_done() -> void:
	talked = true
	prompt = "A: falar com Lira"
	if door != null:
		door.open()
	Game.world.hud.message("Lira abriu a passagem dos contrabandistas")


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	# Barraca
	draw_rect(Rect2(-26, -34, 22, 2), Color("6e4a2c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-28, -34), Vector2(-2, -34), Vector2(-6, -40), Vector2(-24, -40)]), Color("7a2a1e"))
	draw_line(Vector2(-25, -34), Vector2(-25, 0), Color("4a3020"), 1.5)
	draw_line(Vector2(-5, -34), Vector2(-5, 0), Color("4a3020"), 1.5)
	draw_rect(Rect2(-26, -14, 22, 14), Color("4a3020"))
	draw_rect(Rect2(-24, -18, 5, 4), Color("c9a24a"))
	draw_rect(Rect2(-17, -17, 4, 3), Color("8aa0a0"))
	draw_rect(Rect2(-11, -19, 4, 5), Color("a0522d"))
	# Lira: capuz verde-musgo, cachecol cobre
	var bob := sin(t * 1.6) * 0.4
	draw_line(Vector2(-2, -12), Vector2(-2, 0), Color("2e2826"), 3.0)
	draw_line(Vector2(2, -12), Vector2(2, 0), Color("2e2826"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -25 + bob), Vector2(6, -25 + bob), Vector2(7, -10), Vector2(-7, -10)]), Color("3e4a36"))
	draw_rect(Rect2(-5, -26 + bob, 10, 3), Color("b87333"))
	draw_circle(Vector2(0, -29 + bob), 3.4, Color("c89a78"))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -27 + bob), Vector2(-3, -32 + bob), Vector2(0, -36 + bob), Vector2(3, -32 + bob), Vector2(5, -27 + bob), Vector2(3, -30 + bob), Vector2(-3, -30 + bob)]), Color("33402e"))
	draw_line(Vector2(1, -29 + bob), Vector2(3, -29 + bob), Color("1a1c24"), 1.0)
	if not talked:
		var a := 0.5 + 0.5 * sin(t * 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(-3, -42), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.9, 0.6, a))
