shader_type spatial;
render_mode specular_schlick_ggx, cull_disabled;

// Agua de maqueta: azul profundo con ondas suaves y borde más claro.
uniform vec3 deep : source_color = vec3(0.13, 0.27, 0.36);
uniform vec3 shallow : source_color = vec3(0.30, 0.48, 0.52);
uniform sampler2D fog_tex : filter_linear;
uniform bool fog_on = false;
uniform float map_size = 128.0;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float w = sin(p.x * 1.7 + TIME * 1.1) * sin(p.y * 1.3 - TIME * 0.8) * 0.5 + 0.5;
	vec3 col = mix(deep, shallow, w * 0.35);
	NORMAL_MAP = normalize(vec3(sin(p.x * 3.0 + TIME) * 0.15, cos(p.y * 2.6 - TIME * 1.2) * 0.15, 1.0)) * 0.5 + 0.5;
	if (fog_on) {
		float f = texture(fog_tex, p / map_size).r * 255.0 / 2.0;
		col *= f < 0.5 ? mix(0.04, 0.42, f * 2.0) : mix(0.42, 1.0, (f - 0.5) * 2.0);
	}
	ALBEDO = col;
	ROUGHNESS = 0.18;
	METALLIC = 0.0;
	ALPHA = 0.9;
}
