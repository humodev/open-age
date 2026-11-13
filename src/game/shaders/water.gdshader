shader_type spatial;
render_mode specular_schlick_ggx, cull_disabled, depth_draw_always;

// Agua (docs/10): color por profundidad real, espuma en la orilla y corriente
// que sigue el trazo de cada río. Los lagos quedan quietos.
uniform vec3 deep : source_color = vec3(0.07, 0.2, 0.3);
uniform vec3 shallow : source_color = vec3(0.24, 0.42, 0.4);
uniform vec3 silt : source_color = vec3(0.42, 0.42, 0.3); // borde turbio de los ríos
uniform vec3 foam_col : source_color = vec3(0.86, 0.9, 0.88);
// R: profundidad (0 orilla, 1 hondo). G: es río (0 lago). BA: dirección de la corriente.
uniform sampler2D water_tex : filter_linear;
uniform sampler2D ripple : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D fog_tex : filter_linear;
uniform bool fog_on = false;
uniform float map_size = 128.0;
uniform float flow_speed = 0.35;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	vec4 wt = texture(water_tex, (p + 0.5) / (map_size + 1.0));
	float depth = wt.r;
	float is_river = wt.g;
	vec2 flow = (wt.ba * 2.0 - 1.0) * is_river;

	// Corriente con dos fases cruzadas para que la textura no se estire.
	float t = TIME * flow_speed;
	float ph0 = fract(t);
	float ph1 = fract(t + 0.5);
	float blend = abs(ph0 - 0.5) * 2.0;
	vec2 uv = p * 0.18;
	vec3 n0 = texture(ripple, uv - flow * ph0 * 1.4).rgb;
	vec3 n1 = texture(ripple, uv - flow * ph1 * 1.4 + 0.37).rgb;
	vec3 nflow = mix(n0, n1, blend);
	// Ondas lentas de viento, para lagos y para dar vida al río.
	vec3 nwind = texture(ripple, p * 0.07 + vec2(TIME * 0.012, TIME * 0.009)).rgb;
	vec3 nrm = normalize(mix(nwind, nflow, 0.55 * is_river + 0.0) * 2.0 - 1.0);
	NORMAL_MAP = nrm * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.55;

	float dd = smoothstep(0.0, 0.85, depth);
	vec3 col = mix(shallow, deep, dd);
	col = mix(col, silt, (1.0 - dd) * 0.45 * is_river);
	// Espuma: banda fina en la orilla, que se mueve con la corriente.
	float fn = texture(foam_noise, p * 0.45 - flow * TIME * 0.5 + vec2(TIME * 0.02)).r;
	float shore = 1.0 - smoothstep(0.01, 0.11, depth);
	float foam = smoothstep(0.62, 0.92, fn + shore * 0.45) * shore;
	col = mix(col, foam_col, foam * 0.5);

	if (fog_on) {
		float f = texture(fog_tex, p / map_size).r * 255.0 / 2.0;
		col *= f < 0.5 ? mix(0.04, 0.42, f * 2.0) : mix(0.42, 1.0, (f - 0.5) * 2.0);
	}
	ALBEDO = col;
	ROUGHNESS = mix(0.05, 0.4, foam);
	SPECULAR = 0.6;
	METALLIC = 0.0;
	ALPHA = clamp(mix(0.45, 0.93, sqrt(dd)) + foam * 0.3, 0.0, 1.0);
}
