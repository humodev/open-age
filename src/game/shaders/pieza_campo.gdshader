shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;

// Suelo de los campos (proceso/64; src/game/piezas.gd): tierra arada con surcos, el borde más
// oscuro y, en el arrozal, agua entre los bordos. La malla sigue el terreno. UV: posición en
// el campo (x a lo largo de los surcos, y a través), UV2: tamaño del campo en casillas.
// surcos: distancia entre surcos (0 = tierra lisa, el terraplén de las empalizadas).
uniform vec3 suelo_a : source_color = vec3(0.48, 0.38, 0.27);
uniform vec3 suelo_b : source_color = vec3(0.35, 0.27, 0.2);
uniform float surcos = 0.22;
uniform bool agua = false;
uniform vec3 agua_color : source_color = vec3(0.31, 0.44, 0.42);
uniform float bordo = 0.12;
uniform sampler2D t_dirt : source_color, filter_linear_mipmap, repeat_enable;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Las normales de la malla valen para las dos caras (Godot las da vuelta en la de atrás).
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec2 uv = UV;
	vec2 tam = UV2;
	vec3 tex = texture(t_dirt, wpos.xz * 0.35).rgb;
	float n = dot(tex, vec3(0.3, 0.55, 0.15));
	vec3 col = mix(suelo_b, suelo_a, 0.5) * (0.7 + 0.7 * n);
	float rough = 0.97;
	float spec = 0.25;
	if (surcos > 0.0) {
		float s = fract(uv.y / surcos);
		float lomo = smoothstep(0.0, 0.5, s) * smoothstep(1.0, 0.5, s);
		col = mix(suelo_b, suelo_a, lomo) * (0.72 + 0.6 * n);
	}
	// Borde del campo: tierra pisada, más clara y sin surcos.
	float e = min(min(uv.x, tam.x - uv.x), min(uv.y, tam.y - uv.y));
	float borde = 1.0 - smoothstep(0.04, 0.1, e);
	if (agua) {
		// Bordos en el borde y en cruz al medio: cuatro paños de agua por campo de 2×2.
		vec2 m = abs(uv - tam * 0.5);
		float b = min(e, min(m.x, m.y));
		float dentro = smoothstep(bordo * 0.5, bordo, b);
		vec3 ag = agua_color * (0.8 + 0.4 * n);
		col = mix(col, ag, dentro * 0.85);
		rough = mix(rough, 0.35, dentro);
		spec = mix(spec, 0.45, dentro);
		borde = 1.0 - smoothstep(0.0, bordo * 0.5, b);
	}
	col = mix(col, suelo_a * 1.08 * (0.8 + 0.4 * n), borde * 0.7);
	ALBEDO = col * COLOR.rgb;
	ROUGHNESS = rough;
	SPECULAR = spec;
}
