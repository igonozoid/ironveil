extends CanvasLayer
## Pós-processamento por cima do mundo (abaixo do sangue na tela e do HUD).
## Cada ato tem sua gradação de cor. Pisca aberração cromática quando Sera
## leva dano e tinge as bordas de vermelho com a vida baixa.
## Desliga com a opção "Efeitos de tela".

const SHADER := preload("res://scripts/fx/post_process.gdshader")

## Paletas por tema: [sombras, realces, quantidade, saturação, limiar do brilho]
const GRADES := {
	"boiler": [Color(0.62, 0.4, 0.32), Color(1.0, 0.9, 0.74), 0.4, 1.08, 0.6],
	"market": [Color(0.48, 0.38, 0.55), Color(1.0, 0.86, 0.66), 0.42, 1.1, 0.58],
	"tower": [Color(0.36, 0.42, 0.6), Color(1.0, 0.9, 0.7), 0.32, 1.02, 0.6],
}

var rect: ColorRect
var mat: ShaderMaterial
var hurt := 0.0
var last_hp := -1


func _ready() -> void:
	layer = 8
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	rect.material = mat
	add_child(rect)
	apply_theme("boiler")
	visible = Game.fx_enabled()


func apply_theme(theme: String) -> void:
	var g: Array = GRADES.get(theme, GRADES["boiler"])
	mat.set_shader_parameter("shadow_tint", g[0])
	mat.set_shader_parameter("highlight_tint", g[1])
	mat.set_shader_parameter("grade_amount", g[2])
	mat.set_shader_parameter("saturation", g[3])
	mat.set_shader_parameter("bloom_threshold", g[4])


func _process(delta: float) -> void:
	visible = Game.fx_enabled()
	if not visible:
		return
	if last_hp >= 0 and Game.hp < last_hp:
		hurt = 1.0
	last_hp = Game.hp
	# Tempo real: o efeito continua decaindo durante o hitstop.
	hurt = maxf(0.0, hurt - delta / maxf(Engine.time_scale, 0.05) * 2.5)
	mat.set_shader_parameter("hurt", hurt)
	var low := 0.0
	if Game.hp == 1:
		low = 1.0
	mat.set_shader_parameter("low_hp", low)
