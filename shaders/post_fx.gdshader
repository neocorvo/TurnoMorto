shader_type canvas_item;
// Pós-efeto discreto de "equipamento de trabalho": vinheta, grão de sensor
// e aberração cromática mínima. Não interfere em gameplay nem na HUD lógica.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float grain_strength : hint_range(0.0, 0.25) = 0.05;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.42;
uniform float vignette_radius : hint_range(0.2, 0.9) = 0.62;
uniform float aberration : hint_range(0.0, 4.0) = 0.9;

float hash_noise(vec2 coordinate) {
	return fract(sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 color;
	color.r = texture(screen_tex, uv + vec2(aberration * 0.00055, 0.0)).r;
	color.g = texture(screen_tex, uv).g;
	color.b = texture(screen_tex, uv - vec2(aberration * 0.00055, 0.0)).b;

	float distance_from_center = distance(uv, vec2(0.5));
	color *= 1.0 - vignette_strength * smoothstep(vignette_radius, 0.98, distance_from_center);

	float grain = hash_noise(uv * vec2(917.0, 541.0) + vec2(TIME * 37.0, TIME * 53.0)) - 0.5;
	color += grain * grain_strength;

	COLOR = vec4(color, 1.0);
}
