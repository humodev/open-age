shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;

// Caras de las piezas por casillas (proceso/64; src/game/piezas.gd): muros, puertas, torres,
// andenes, cimientos y palos. El dibujo sale del UV (x: a lo largo del muro, y: alto en el
// mundo), así sigue de una casilla a la otra; el grano de la piedra, de la textura de roca en
// triplanar. COLOR multiplica (oscurece al pie). patron: 0 sillar, 1 pirca, 2 ladrillo,
// 3 revoque, 4 tierra, 5 madera, 6 liso (paños del color del jugador).
uniform int patron = 0;
uniform vec3 color : source_color = vec3(0.64, 0.61, 0.56);
uniform vec3 junta : source_color = vec3(0.49, 0.47, 0.42);
uniform sampler2D t_rock : source_color, filter_linear_mipmap, repeat_enable;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 h22(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

// Piedras de campo: distancia al borde de la celda de Voronoi (F2 - F1) y el valor de la celda.
vec2 piedras(vec2 p) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	float f1 = 8.0;
	float f2 = 8.0;
	vec2 cell = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = h22(ip + g) * 0.8 + 0.1;
			float d = length(g + o - fp);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				cell = ip + g;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return vec2(f2 - f1, h21(cell));
}

// Hiladas de bloques: (junta 0..1, valor del bloque).
vec2 hiladas(vec2 uv, float alto, float largo, float ancho_junta) {
	float row = floor(uv.y / alto);
	float x = uv.x / largo + row * 0.5;
	vec2 f = vec2(fract(x) * largo, fract(uv.y / alto) * alto);
	float e = min(min(f.x, largo - f.x), min(f.y, alto - f.y));
	return vec2(1.0 - smoothstep(ancho_junta * 0.4, ancho_junta, e), h21(vec2(floor(x), row)));
}

void fragment() {
	// Las normales de la malla valen para las dos caras (Godot las da vuelta en la de atrás).
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec3 w = pow(abs(wnorm), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 grit = texture(t_rock, wpos.zy * 0.5).rgb * w.x + texture(t_rock, wpos.xz * 0.5).rgb * w.y + texture(t_rock, wpos.xy * 0.5).rgb * w.z;
	float g = dot(grit, vec3(0.3, 0.55, 0.15));
	vec2 uv = UV;
	vec3 col = color;
	float j = 0.0;
	float rough = 0.92;
	if (patron == 0) {
		vec2 b = hiladas(uv, 0.2, 0.42, 0.022);
		j = b.x;
		col *= 0.84 + 0.3 * b.y;
	} else if (patron == 1) {
		vec2 s = piedras(uv * vec2(5.5, 7.0));
		j = 1.0 - smoothstep(0.05, 0.16, s.x);
		col *= 0.74 + 0.42 * s.y;
		col *= mix(vec3(1.0), vec3(1.06, 1.0, 0.92), step(0.7, s.y));
	} else if (patron == 2) {
		vec2 b = hiladas(uv, 0.075, 0.2, 0.012);
		j = b.x;
		col *= 0.86 + 0.24 * b.y;
	} else if (patron == 3) {
		float n = texture(t_rock, uv * vec2(0.6, 0.9)).r;
		col *= 0.9 + 0.22 * n;
		rough = 0.96;
	} else if (patron == 4) {
		float n = texture(t_rock, uv * vec2(0.9, 1.6)).r;
		col *= 0.78 + 0.4 * n;
		rough = 0.98;
	} else if (patron == 5) {
		float n = texture(t_rock, vec2(uv.x * 3.0, uv.y * 0.25)).r;
		float veta = sin(uv.x * 90.0 + n * 6.0) * 0.5 + 0.5;
		col *= 0.78 + 0.18 * veta + 0.18 * n;
	}
	if (patron < 5) {
		col *= 0.86 + 0.45 * g;
		col = mix(col, junta, j * 0.85);
	}
	ALBEDO = col * COLOR.rgb;
	ROUGHNESS = rough;
	SPECULAR = 0.3;
}
