// Pós-processamento da tela de jogo (Godot 4.7, Compatibility).
// Lê o que já foi desenhado e aplica: brilho (bloom barato), gradação de cor
// por ato (sombras/realces), vinheta, grão de filme, aberração cromática ao
// levar dano e dessaturação com a vida baixa.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 shadow_tint : source_color = vec4(0.55, 0.42, 0.38, 1.0);
uniform vec4 highlight_tint : source_color = vec4(1.0, 0.92, 0.8, 1.0);
uniform float grade_amount : hint_range(0.0, 1.0) = 0.35;
uniform float contrast : hint_range(0.5, 1.6) = 1.08;
uniform float saturation : hint_range(0.0, 1.6) = 1.05;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.62;
uniform float bloom_strength : hint_range(0.0, 2.0) = 0.55;
uniform float bloom_radius : hint_range(0.5, 8.0) = 3.0;
uniform float vignette : hint_range(0.0, 1.5) = 0.4;
uniform float grain : hint_range(0.0, 0.2) = 0.02;
uniform float hurt : hint_range(0.0, 1.0) = 0.0;
uniform float low_hp : hint_range(0.0, 1.0) = 0.0;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 bright(vec2 uv) {
	vec3 c = textureLod(screen_tex, uv, 1.0).rgb;
	return c * smoothstep(bloom_threshold, 1.0, luma(c));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	// Aberração cromática (só quando Sera leva dano)
	vec2 off = (uv - 0.5) * px * 6.0 * hurt;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;

	// Bloom: anel de 8 amostras dos pontos claros, em duas distâncias
	vec3 glow = vec3(0.0);
	float r = bloom_radius;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 d = vec2(cos(a), sin(a)) * px;
		glow += bright(uv + d * r);
		glow += bright(uv + d * r * 2.5) * 0.6;
	}
	col += glow / 12.8 * bloom_strength;

	// Gradação: sombras puxadas para uma cor, realces para outra
	float l = luma(col);
	// Tintas normalizadas pela luminância: mudam o matiz sem escurecer a imagem.
	vec3 st = shadow_tint.rgb / max(luma(shadow_tint.rgb), 0.01);
	vec3 ht = highlight_tint.rgb / max(luma(highlight_tint.rgb), 0.01);
	vec3 graded = col * mix(st, ht, smoothstep(0.05, 0.75, l));
	col = mix(col, graded, grade_amount);
	col = (col - 0.5) * contrast + 0.5;
	col = mix(vec3(luma(col)), col, saturation * (1.0 - low_hp * 0.55));

	// Vida baixa: bordas pulsando em vermelho
	vec2 v = uv - 0.5;
	float edge = dot(v, v) * 2.2;
	col = mix(col, vec3(0.45, 0.02, 0.02), low_hp * edge * (0.55 + 0.25 * sin(TIME * 5.0)));

	// Vinheta e grão
	col *= 1.0 - vignette * smoothstep(0.18, 0.75, dot(v * vec2(1.0, 0.8), v * vec2(1.0, 0.8)) * 2.0);
	col += (hash(uv * 640.0 + fract(TIME) * 37.0) - 0.5) * grain;
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
