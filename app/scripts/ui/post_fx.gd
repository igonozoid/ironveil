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
	"foundry": [Color(0.5, 0.3, 0.3), Color(1.0, 0.75, 0.45), 0.4, 1.1, 0.45],
	"veil": [Color(0.4, 0.46, 0.6), Color(1.0, 0.96, 0.85), 0.35, 0.95, 0.6],
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
	# Intenso/Insano: tudo mais forte — brilho, vinheta, grão, cor e contraste.
	var fx := Game.fx_level()
	mat.set_shader_parameter("bloom_strength", 0.55 + 0.35 * fx)
	mat.set_shader_parameter("bloom_threshold", float(g[4]) - 0.08 * fx)
	mat.set_shader_parameter("vignette", 0.4 + 0.18 * fx)
	mat.set_shader_parameter("grain", 0.02 + 0.02 * fx)
	mat.set_shader_parameter("saturation", float(g[3]) * (1.0 + 0.15 * fx))
	mat.set_shader_parameter("contrast", 1.08 + 0.08 * fx)
	mat.set_shader_parameter("grade_amount", float(g[2]) * (1.0 + 0.3 * fx))


func _process(delta: float) -> void:
	visible = Game.fx_enabled()
	if not visible:
		return
	if last_hp >= 0 and Game.hp < last_hp:
		hurt = 1.0
	last_hp = Game.hp
	# Tempo real: o efeito continua decaindo durante o hitstop.
	hurt = maxf(0.0, hurt - delta / maxf(Engine.time_scale, 0.05) * 2.5)
	var wobble := 0.0
	if Game.fx_level() >= 2:
		# Insano: as cores nunca ficam no lugar.
		wobble = 0.16 + 0.1 * sin(Time.get_ticks_msec() / 180.0)
	mat.set_shader_parameter("hurt", maxf(hurt, wobble))
	# A vida baixa agora é mostrada pela borda de vida (health_border.gd).
	mat.set_shader_parameter("low_hp", 0.0)
