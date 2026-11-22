extends CanvasLayer
## Borda da câmera ligada à vida: transparente com a vida cheia, vermelha e
## mais grossa conforme Sera perde vida, fechando em preto na morte. Ao se
## curar, volta a clarear. Sempre ativa (é informação de jogo, não efeito).

const SHADER_CODE := """
shader_type canvas_item;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform float death : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 v = UV - 0.5;
	v.x *= 1.5;
	float d = length(v);
	float inner = mix(0.78, 0.32, damage) - pulse * 0.04;
	float a = smoothstep(inner, inner + 0.42, d) * clamp(damage * 1.25, 0.0, 1.0);
	vec3 col = mix(vec3(0.6, 0.02, 0.03), vec3(0.08, 0.0, 0.0), clamp(damage * damage, 0.0, 1.0));
	// Morte: a borda fecha em preto até cobrir a tela.
	float close = smoothstep(mix(0.95, -0.25, death), mix(1.25, 0.05, death), d) * death;
	col = mix(col, vec3(0.0), clamp(death * 1.3, 0.0, 1.0));
	COLOR = vec4(col, clamp(max(a * 0.9, close), 0.0, 1.0));
}
"""

var rect: ColorRect
var mat: ShaderMaterial
var damage := 0.0
var death := 0.0
var t := 0.0


func _ready() -> void:
	layer = 9
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER_CODE
	mat = ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	add_child(rect)
	damage = _target()


func _target() -> float:
	return clampf(1.0 - float(Game.hp) / float(maxi(1, Game.max_hp())), 0.0, 1.0)


func _process(delta: float) -> void:
	var real_dt := delta / maxf(Engine.time_scale, 0.05)
	t += real_dt
	var p = Game.world.player if Game.world else null
	var dead: bool = p != null and p.is_dead()
	damage = move_toward(damage, 1.0 if dead else _target(), real_dt * 0.9)
	death = move_toward(death, 1.0 if dead else 0.0, real_dt * (0.7 if dead else 2.0))
	var pulse := 0.0
	if Game.hp == 1 and not dead:
		pulse = 0.5 + 0.5 * sin(t * 6.0)
	mat.set_shader_parameter("damage", damage)
	mat.set_shader_parameter("death", death)
	mat.set_shader_parameter("pulse", pulse)
