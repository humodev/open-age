shader_type spatial;
render_mode specular_schlick_ggx, cull_disabled, depth_draw_always;

// Agua (docs/10, etapa 16): el espesor real de la columna de agua sale del
// buffer de profundidad, así la orilla, la espuma y las olas siguen el contorno
// del terreno sin escalones. Color por bioma (data/ambiente.json), reflejo del
// cielo con fresnel, corriente por el trazo de cada río, vados con rápidos y
// ondas alrededor de las unidades que vadean.
uniform vec3 deep : source_color = vec3(0.07, 0.2, 0.3);
uniform vec3 shallow : source_color = vec3(0.24, 0.42, 0.4);
uniform vec3 silt : source_color = vec3(0.42, 0.42, 0.3); // agua turbia
uniform vec3 foam_col : source_color = vec3(0.86, 0.9, 0.88);
uniform vec3 sky_top : source_color = vec3(0.36, 0.5, 0.68);
uniform vec3 sky_hor : source_color = vec3(0.74, 0.78, 0.8);
uniform vec3 sun_dir = vec3(0.4, 0.75, 0.5); // hacia el sol, en el mundo
uniform float turbidity = 0.25;
uniform float reflect_k = 0.55;
// R: hondo (0 orilla, 1 hondo). G: es río (0 lago). BA: dirección de la corriente.
uniform sampler2D water_tex : filter_linear;
// R: vado (agua baja que se cruza).
uniform sampler2D ford_tex : filter_linear;
uniform sampler2D ripple : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D fog_tex : filter_linear;
uniform bool fog_on = false;
uniform float map_size = 128.0;
uniform float flow_speed = 0.35;
// Unidades en el agua: xy posición, z fase. Las actualiza OndasAgua.
uniform vec4 units[24];
uniform int unit_count = 0;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	vec2 muv = (p + 0.5) / (map_size + 1.0);
	vec4 wt = texture(water_tex, muv);
	float is_river = wt.g;
	float ford = texture(ford_tex, muv).r;
	vec2 flow = (wt.ba * 2.0 - 1.0) * is_river;

	// Espesor vertical del agua: superficie menos el fondo que dejó el terreno.
	float zr = texture(depth_tex, SCREEN_UV).r;
	vec4 vp = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, zr, 1.0);
	vp.xyz /= vp.w;
	vec3 bed = (INV_VIEW_MATRIX * vec4(vp.xyz, 1.0)).xyz;
	float thick = max(wpos.y - bed.y, 0.0);

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
	vec3 nwind2 = texture(ripple, p * 0.23 - vec2(TIME * 0.02, -TIME * 0.015)).rgb;
	vec3 nrm = mix(mix(nwind, nwind2, 0.4), nflow, 0.55 * is_river) * 2.0 - 1.0;

	// Ondas alrededor de las unidades que cruzan.
	float ring_foam = 0.0;
	for (int i = 0; i < unit_count; i++) {
		vec2 dv = p - units[i].xy;
		float d = length(dv);
		if (d < 1.4) {
			float fall = (1.0 - d / 1.4);
			fall *= fall;
			float w = sin(d * 15.0 - TIME * 6.0 + units[i].z);
			nrm.xy += dv / max(d, 0.05) * w * fall * 0.6;
			ring_foam = max(ring_foam, smoothstep(0.55, 1.0, w) * fall);
		}
	}
	nrm = normalize(nrm);
	NORMAL_MAP = nrm * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = mix(0.55, 0.8, ford);

	// Color por espesor: lo bajo deja ver el fondo, lo hondo absorbe.
	float dd = smoothstep(0.02, 0.6, thick) * mix(0.75, 1.0, wt.r);
	vec3 col = mix(shallow, deep, dd);
	col = mix(col, silt, turbidity * (1.0 - dd * 0.6) * (0.6 + 0.4 * is_river) * (1.0 - ford * 0.5));

	// Espuma de orilla y olas que llegan acompañando el contorno.
	float fn = texture(foam_noise, p * 0.45 - flow * TIME * 0.5 + vec2(TIME * 0.02)).r;
	float fn2 = texture(foam_noise, p * 0.9 + vec2(-TIME * 0.03, TIME * 0.025)).r;
	float edge = 1.0 - smoothstep(0.0, 0.05, thick);
	float near = 1.0 - smoothstep(0.03, 0.2, thick);
	float wave = sin(thick * 55.0 - TIME * (1.6 - 0.6 * is_river) + fn * 5.0);
	float waves = smoothstep(0.7, 1.0, wave) * near * (1.0 - 0.5 * is_river);
	float foam = smoothstep(0.55, 0.95, fn * 0.6 + fn2 * 0.4 + edge * 0.4) * edge;
	foam = max(foam, waves * smoothstep(0.35, 0.7, fn2) * 0.75);
	// Rápidos en los vados: estrías de espuma a lo largo de la corriente.
	vec2 fdir = length(flow) > 0.1 ? normalize(flow) : vec2(0.8, 0.6);
	vec2 fuv = vec2(dot(p, fdir) * 0.5 - TIME * 0.5, dot(p, vec2(-fdir.y, fdir.x)) * 2.4);
	float riffle = smoothstep(0.6, 0.85, texture(foam_noise, fuv).r) * smoothstep(0.3, 0.8, ford);
	foam = max(foam, riffle * 0.7);
	foam = max(foam, ring_foam * 0.7);
	col = mix(col, mix(col, vec3(0.72, 0.68, 0.52), 0.35), ford * 0.4); // fondo de arena del vado

	// Reflejo del cielo con fresnel, con la normal de las ondas.
	vec3 wn = normalize(vec3(nrm.x * 0.35, 1.0, nrm.y * 0.35));
	vec3 vdir = normalize(wpos - CAMERA_POSITION_WORLD);
	vec3 r = reflect(vdir, wn);
	vec3 sky = mix(sky_hor, sky_top, smoothstep(0.05, 0.8, r.y));
	float fres = 0.06 + 0.94 * pow(1.0 - clamp(dot(-vdir, wn), 0.0, 1.0), 4.0);
	float refl = reflect_k * clamp(0.3 + fres, 0.0, 1.0) * (1.0 - foam);
	// Brillo suave del sol y destellos sueltos (más en los lagos, que están quietos).
	float sd = max(dot(r, normalize(sun_dir)), 0.0);
	float sparkle = smoothstep(0.82, 0.98, fn2) * pow(sd, 60.0) * (1.4 - is_river * 0.8);
	vec3 glow = sky * refl + vec3(1.0, 0.97, 0.9) * (pow(sd, 18.0) * 0.12 * (1.0 - is_river * 0.5) + sparkle * 1.6);

	col = mix(col, foam_col, foam * 0.7);
	vec3 albedo = col * (1.0 - refl);
	float spec_k = 1.0;
	if (fog_on) {
		float f = texture(fog_tex, p / map_size).r * 255.0 / 2.0;
		float fl = f < 0.5 ? mix(0.04, 0.42, f * 2.0) : mix(0.42, 1.0, (f - 0.5) * 2.0);
		albedo *= fl;
		glow *= fl * fl;
		spec_k = fl;
	}
	ALBEDO = albedo;
	EMISSION = glow;
	ROUGHNESS = mix(0.08, 0.5, foam);
	SPECULAR = 0.35 * spec_k;
	METALLIC = 0.0;
	float a_min = mix(0.3, 0.62, turbidity);
	float a = mix(a_min, 0.94, smoothstep(0.0, 0.45, thick));
	a = mix(a, 0.4, ford * 0.85); // el vado deja ver el fondo
	a *= smoothstep(0.0, 0.025, thick); // borde sin línea dura
	ALPHA = clamp(a + foam * 0.5, 0.0, 1.0) * smoothstep(0.0, 0.012, thick);
}
