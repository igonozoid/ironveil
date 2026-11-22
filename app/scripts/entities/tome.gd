extends Node2D
## Tomé, operador do guindaste. Conversar com ele destrava o gancho do
## guindaste, que abre um atalho vertical pelo poço.

var crane = null
var talked := false
var prompt := "A: falar com Tomé"
var t := 0.0

const LINES := [
	["Tomé", "Sera? Pelos canos de Ironveil... dizem que foi você que explodiu a Caldeira Sul."],
	["Sera", "Eu estava tentando impedir. Alguém no Diretório quer a culpa nas minhas costas."],
	["Tomé", "Trinta anos neste guindaste e nunca vi engenheira sabotar a própria máquina."],
	["Tomé", "Sobe no gancho. Eu te levo até o topo do poço — de lá, o elevador velho chega ao Mercado Suspenso."],
	["Sera", "Obrigada, Tomé. Não vou esquecer."],
	["Tomé", "Vai logo, antes que a ronda volte."],
]
const REPEAT := [["Tomé", "O gancho está pronto. Fica parada em cima dele que eu cuido do resto."]]


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
	prompt = "A: falar com Tomé"
	if crane != null:
		crane.locked = false
	Sfx.play("lift", -2.0)
	Game.world.hud.message("O guindaste foi destravado: suba no gancho")


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	# Console do guindaste
	draw_rect(Rect2(10, -18, 14, 18), Color("3a3330"))
	draw_rect(Rect2(10, -18, 14, 3), Color("b87333"))
	draw_rect(Rect2(12, -13, 4, 3), Color(0.4, 1.0, 0.5) if talked else Color(1.0, 0.4, 0.2))
	draw_line(Vector2(19, -15), Vector2(21, -24), Color("8a8f96"), 1.5)
	draw_circle(Vector2(21, -24), 1.8, Color("c03020"))
	# Tomé: robusto, macacão ocre, boné
	var bob := sin(t * 1.8) * 0.4
	draw_line(Vector2(-3, -12), Vector2(-3, 0), Color("6a5a2a"), 4.0)
	draw_line(Vector2(3, -12), Vector2(3, 0), Color("6a5a2a"), 4.0)
	draw_rect(Rect2(-7, -25 + bob, 14, 14), Color("c9a24a"))
	draw_rect(Rect2(-4, -25 + bob, 8, 6), Color("a8842e"))
	draw_line(Vector2(6, -23 + bob), Vector2(10, -16), Color("c9a24a"), 3.0)
	draw_line(Vector2(-6, -23 + bob), Vector2(-8, -13), Color("a8842e"), 3.0)
	draw_circle(Vector2(0, -29 + bob), 4.2, Color("d4a888"))
	draw_rect(Rect2(-4.5, -34 + bob, 9, 3), Color("4a5a3a"))
	draw_rect(Rect2(0, -32 + bob, 6, 1.5), Color("4a5a3a"))
	draw_line(Vector2(-2, -27 + bob), Vector2(3, -27 + bob), Color("dcdcdc"), 1.5)
	if not talked:
		var a := 0.5 + 0.5 * sin(t * 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(-3, -40), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.9, 0.6, a))
