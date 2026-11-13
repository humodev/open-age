shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Terreno de maqueta: verde apagado con variación suave, tierra alrededor de las bases,
// grilla visible al construir y borde oscuro fuera del mapa (docs/07).
uniform vec3 color_a : source_color;
uniform vec3 color_b : source_color;
uniform vec3 dirt : source_color;
uniform float map_size = 128.0;
uniform float grid_alpha = 0.0;
uniform vec4 bases = vec4(-100.0);

uniform vec3 rock : source_color = vec3(0.55, 0.52, 0.46);
varying vec3 wpos;
varying vec3 wnorm;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
// Niebla: 0 sin explorar, 1 explorado, 2 visible (bytes crudos de SimFog).
uniform sampler2D fog_tex : filter_linear;
uniform bool fog_on = false;

float fbm(vec2 p) {
	return texture(noise_tex, p).r;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = wpos.xz;
	float n = fbm(p * 0.009);
	vec3 col = mix(color_a, color_b, smoothstep(0.3, 0.7, n));
	col *= 0.94 + 0.12 * fbm(p * 0.13 + vec2(0.37, 0.71));
	// Tierra pisada alrededor de cada base.
	float edge = fbm(p * 0.05) * 3.0;
	float d0 = length(p - bases.xy) + edge;
	float d1 = length(p - bases.zw) + edge;
	float dirt_amt = (1.0 - smoothstep(5.0, 7.5, d0)) + (1.0 - smoothstep(5.0, 7.5, d1));
	col = mix(col, dirt * (0.9 + fbm(p * 0.3) * 0.15), clamp(dirt_amt, 0.0, 1.0) * 0.6);
	// Altura y laderas: arriba más seco, laderas de piedra, orillas de barro.
	col = mix(col, col * vec3(1.08, 1.04, 0.9), clamp(wpos.y / 2.5, 0.0, 1.0) * 0.5);
	float slope = 1.0 - wnorm.y;
	col = mix(col, rock * (0.9 + fbm(p * 0.2) * 0.2), smoothstep(0.1, 0.32, slope) * 0.7);
	col = mix(col, dirt * 0.75, smoothstep(-0.05, -0.35, wpos.y));
	// Grilla de construcción.
	vec2 g = abs(fract(p) - 0.5);
	float gw = fwidth(p.x) * 1.2;
	float line = smoothstep(0.5 - gw, 0.5, max(g.x, g.y));
	col = mix(col, vec3(1.0), line * grid_alpha);
	// Fuera del mapa.
	float inside = step(0.0, p.x) * step(0.0, p.y) * step(p.x, map_size) * step(p.y, map_size);
	col = mix(col * 0.28, col, inside);
	if (fog_on) {
		float f = texture(fog_tex, p / map_size).r * 255.0 / 2.0;
		float light = f < 0.5 ? mix(0.04, 0.42, f * 2.0) : mix(0.42, 1.0, (f - 0.5) * 2.0);
		col *= light;
	}
	ALBEDO = col;
	ROUGHNESS = 0.97;
}
