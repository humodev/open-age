shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Suelo con mezcla de materiales (docs/10, "Materiales del suelo"; etapa 16):
// pasto, manchas de pasto alto, pasto seco por bioma, tierra pisada, barro y
// orilla húmeda, lecho bajo el agua y roca triplanar en laderas y al pie de los
// peñascos. Los tintes por bioma vienen de data/ambiente.json. Texturas CC0
// (assets/CREDITOS.md).
uniform sampler2D t_grass : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_dry : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_dirt : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_mud : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_rock : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n_grass : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D n_dirt : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D n_rock : hint_normal, filter_linear_mipmap, repeat_enable;
// Mezcla por casilla: R tierra pisada, G barro (cerca del agua), B pasto seco.
uniform sampler2D splat : filter_linear;
// R manchas de pasto alto, G pedregal al pie de los peñascos.
uniform sampler2D splat2 : filter_linear;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
// Niebla: 0 sin explorar, 1 explorado, 2 visible (bytes crudos de SimFog).
uniform sampler2D fog_tex : filter_linear;
uniform bool fog_on = false;
uniform float map_size = 128.0;
uniform float grid_alpha = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 dry_tint : source_color = vec3(1.0);
uniform vec3 dirt_tint : source_color = vec3(1.0);
uniform vec3 rock_tint : source_color = vec3(1.0);
uniform vec3 lush_col : source_color = vec3(0.56, 0.66, 0.38);
uniform float wet_k = 0.55;
uniform float tex_scale = 0.22;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Muestra a dos escalas mezcladas por ruido para disimular la repetición; de
// lejos pasa a una escala más grande, que es donde más se nota el mosaico.
vec3 detiled(sampler2D t, vec2 uv, float n, float far) {
	vec3 b = texture(t, uv * 0.43 + vec2(0.31, 0.77)).rgb;
	vec3 near_c = far < 0.99 ? mix(texture(t, uv).rgb, b, smoothstep(0.3, 0.7, n)) : b;
	vec3 far_c = far > 0.01 ? mix(b, texture(t, uv * 0.17 + vec2(0.61, 0.23)).rgb, 0.5) : b;
	return mix(near_c, far_c, far);
}

float luma(vec3 c) {
	return dot(c, vec3(0.3, 0.55, 0.15));
}

void fragment() {
	vec2 p = wpos.xz;
	vec2 uv = p * tex_scale;
	float far = smoothstep(28.0, 75.0, length(VERTEX));
	float n_big = texture(noise_tex, p * 0.008).r;
	float n_mac = texture(noise_tex, p * 0.023 + vec2(0.13, 0.71)).r;
	float n_mid = texture(noise_tex, p * 0.06 + vec2(0.5)).r;
	float n_fine = texture(noise_tex, p * 0.35).r;
	vec4 sp = texture(splat, p / map_size);
	vec2 sp2 = texture(splat2, p / map_size).rg;

	vec3 col = detiled(t_grass, uv, n_mid, far);
	vec3 nrm = texture(n_grass, uv).rgb;
	// Manchas de pasto alto: más verde y más oscuro, con borde irregular.
	float lush = smoothstep(0.2, 0.75, sp2.r + (n_fine - 0.5) * 0.35);
	col = mix(col, col * lush_col * 1.75, lush * 0.65);
	// Pasto seco por bioma y altura, con bordes irregulares.
	float dry = clamp(sp.b + (n_big - 0.5) * 0.8 + wpos.y * 0.06 - lush * 0.3, 0.0, 1.0);
	float dw = smoothstep(0.35, 0.8, dry);
	if (dw > 0.001) {
		col = mix(col, detiled(t_dry, uv * 0.9, n_mid, far) * dry_tint, dw);
	}
	// Variación grande de tono, para que el llano no sea un solo verde.
	col *= mix(vec3(0.86, 0.9, 0.86), vec3(1.08, 1.06, 0.98), n_mac);
	// Barro en las orillas.
	float mud = smoothstep(0.25, 0.7, sp.g + (n_fine - 0.5) * 0.5);
	if (mud > 0.001) {
		col = mix(col, detiled(t_mud, uv * 1.2, n_mid, far), mud);
	}
	// Tierra pisada alrededor de edificios, caminos y bases (rojiza en la selva).
	float dirt = smoothstep(0.3, 0.62, sp.r + (n_fine - 0.5) * 0.45 + (n_mid - 0.5) * 0.2);
	vec3 dirt_c = vec3(0.0);
	float under = smoothstep(-0.2, -0.32, wpos.y);
	// Franja húmeda: la casilla que toca el agua y lo que está a ras de ella.
	float wet = smoothstep(0.5, 0.9, sp.g + (n_fine - 0.5) * 0.3) * smoothstep(0.38, -0.08, wpos.y);
	if (dirt > 0.001 || under > 0.001 || wet > 0.001) {
		dirt_c = detiled(t_dirt, uv * 1.1, n_mid, far) * dirt_tint;
		col = mix(col, dirt_c, dirt);
		nrm = mix(nrm, texture(n_dirt, uv * 1.1).rgb, dirt);
	}
	// Roca triplanar en laderas y barrancos, mezclada por la altura de la piedra
	// para que el borde siga las grietas; pedregal al pie de los peñascos.
	float slope = 1.0 - wnorm.y;
	float rk0 = slope + (n_mid - 0.5) * 0.12;
	float scree = sp2.g * smoothstep(0.35, 0.65, n_fine + sp2.g * 0.3);
	float rk = 0.0;
	if (rk0 > 0.08 || scree > 0.001) {
		vec3 w = pow(abs(wnorm), vec3(4.0));
		w /= (w.x + w.y + w.z);
		vec3 rock = texture(t_rock, wpos.zy * 0.25).rgb * w.x + texture(t_rock, p * 0.25).rgb * w.y + texture(t_rock, wpos.xy * 0.25).rgb * w.z;
		rock *= rock_tint;
		float rl = luma(rock);
		rk = smoothstep(0.12, 0.3, rk0 + (rl - 0.4) * 0.25);
		rk = max(rk, scree * 0.85);
		col = mix(col, rock, rk);
		col *= 1.0 - 0.18 * rk * smoothstep(0.45, 0.2, rl); // grietas más oscuras
		nrm = mix(nrm, texture(n_rock, p * 0.25).rgb, rk);
	}
	// Orilla húmeda: tierra oscura y brillante en la franja que toca el agua.
	wet *= 1.0 - rk * 0.5;
	col = mix(col, dirt_c * vec3(0.8, 0.74, 0.64), wet * 0.7); // barro
	col *= mix(1.0, 1.0 - wet_k, wet);
	// Lecho bajo el agua: arena y canto rodado en lo bajo, oscuro en lo hondo.
	if (under > 0.001) {
		vec3 sand = mix(dirt_c, vec3(luma(dirt_c)), 0.3) * vec3(1.05, 1.0, 0.86);
		vec3 pebbles = texture(t_rock, p * 0.9 + vec2(0.37, 0.11)).rgb * vec3(1.0, 0.97, 0.9);
		sand = mix(sand, pebbles, smoothstep(0.35, 0.65, n_mid) * 0.7 + 0.2);
		col = mix(col, sand, under * 0.7);
		col *= mix(1.0, 0.5, smoothstep(-0.45, -0.85, wpos.y));
	}
	col *= tint.rgb;
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
	NORMAL_MAP = nrm;
	NORMAL_MAP_DEPTH = mix(0.7, 0.35, far);
	ROUGHNESS = mix(0.93, 0.32, wet);
	SPECULAR = mix(0.5, 0.65, wet);
}
