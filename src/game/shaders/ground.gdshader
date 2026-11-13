shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Suelo con mezcla de materiales (docs/10, "Materiales del suelo"):
// pasto y pasto seco por bioma, tierra pisada pintada alrededor de edificios,
// barro en las orillas y roca triplanar en las laderas. Texturas CC0 (assets/CREDITOS.md).
uniform sampler2D t_grass : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_dry : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_dirt : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_mud : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_rock : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D n_grass : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D n_dirt : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D n_rock : hint_normal, filter_linear_mipmap, repeat_enable;
// Mezcla por casilla: R tierra pisada, G barro, B pasto seco.
uniform sampler2D splat : filter_linear;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
// Niebla: 0 sin explorar, 1 explorado, 2 visible (bytes crudos de SimFog).
uniform sampler2D fog_tex : filter_linear;
uniform bool fog_on = false;
uniform float map_size = 128.0;
uniform float grid_alpha = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float tex_scale = 0.22;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Muestra a dos escalas mezcladas por ruido para disimular la repetición.
vec3 detiled(sampler2D t, vec2 uv, float n) {
	vec3 a = texture(t, uv).rgb;
	vec3 b = texture(t, uv * 0.43 + vec2(0.31, 0.77)).rgb;
	return mix(a, b, smoothstep(0.3, 0.7, n));
}

void fragment() {
	vec2 p = wpos.xz;
	vec2 uv = p * tex_scale;
	float n_big = texture(noise_tex, p * 0.008).r;
	float n_mid = texture(noise_tex, p * 0.06 + vec2(0.5)).r;
	float n_fine = texture(noise_tex, p * 0.35).r;
	vec4 sp = texture(splat, p / map_size);

	vec3 col = detiled(t_grass, uv, n_mid);
	vec3 nrm = texture(n_grass, uv).rgb;
	// Pasto seco por bioma y altura, con bordes irregulares.
	float dry = clamp(sp.b + (n_big - 0.5) * 0.8 + wpos.y * 0.06, 0.0, 1.0);
	col = mix(col, detiled(t_dry, uv * 0.9, n_mid), smoothstep(0.35, 0.8, dry));
	// Barro en las orillas.
	float mud = smoothstep(0.25, 0.7, sp.g + (n_fine - 0.5) * 0.5);
	col = mix(col, detiled(t_mud, uv * 1.2, n_mid), mud);
	// Tierra pisada alrededor de edificios, caminos y bases.
	float dirt = smoothstep(0.3, 0.62, sp.r + (n_fine - 0.5) * 0.45 + (n_mid - 0.5) * 0.2);
	col = mix(col, detiled(t_dirt, uv * 1.1, n_mid), dirt);
	nrm = mix(nrm, texture(n_dirt, uv * 1.1).rgb, dirt);
	// Roca triplanar en laderas y barrancos.
	vec3 w = pow(abs(wnorm), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 rock = texture(t_rock, wpos.zy * 0.25).rgb * w.x + texture(t_rock, p * 0.25).rgb * w.y + texture(t_rock, wpos.xy * 0.25).rgb * w.z;
	float slope = 1.0 - wnorm.y;
	float rk = smoothstep(0.13, 0.33, slope + (n_mid - 0.5) * 0.12);
	col = mix(col, rock, rk);
	nrm = mix(nrm, texture(n_rock, p * 0.25).rgb, rk);
	// Lecho bajo el agua.
	col = mix(col, col * vec3(0.55, 0.6, 0.55), smoothstep(-0.1, -0.5, wpos.y));
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
	NORMAL_MAP_DEPTH = 0.7;
	ROUGHNESS = 0.93;
}
