shader_type spatial;
render_mode diffuse_burley, cull_disabled, specular_disabled;

// Detalle del suelo que se mueve con el viento (matas, pasto alto, flores,
// juncos y totora; etapa 16). El color viene en el vértice; el balanceo crece
// con el cuadrado de la altura de la hoja y tiene ráfagas que recorren el mapa.
// Lo sin explorar no se dibuja y lo explorado fuera de la vista se oscurece.
uniform sampler2D fog_tex : filter_linear;
uniform bool fog_on = false;
uniform float map_size = 128.0;
uniform float wind = 1.0;
uniform vec2 wind_dir = vec2(0.8, 0.6);
varying float fogl;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 o = MODEL_MATRIX[3].xyz;
	fogl = 1.0;
	if (fog_on) {
		float f = textureLod(fog_tex, o.xz / map_size, 0.0).r * 255.0 / 2.0;
		fogl = f < 0.5 ? mix(0.04, 0.42, f * 2.0) : mix(0.42, 1.0, (f - 0.5) * 2.0);
		if (f < 0.25) {
			VERTEX = vec3(0.0); // sin explorar: no se ve
		}
	}
	// Alfa del vértice: 1 hoja (se mece y toma la luz del suelo), 0 piedra.
	float leaf = step(0.5, COLOR.a);
	float h = max(VERTEX.y, 0.0) * leaf;
	float k = h * h * 2.2 * wind;
	float gust = sin(dot(o.xz, wind_dir) * 0.11 - TIME * 1.3) * 0.5 + 0.5;
	float sway = sin(TIME * 2.3 + o.x * 0.9 + o.z * 0.7) * 0.35 + gust * 0.9;
	vec3 off = vec3(wind_dir.x, 0.0, wind_dir.y) * sway * k * 0.25;
	// Del mundo al espacio del modelo (giro en Y y escala pareja).
	float s2 = dot(MODEL_MATRIX[0].xyz, MODEL_MATRIX[0].xyz);
	VERTEX += (vec4(off, 0.0) * MODEL_MATRIX).xyz / max(s2, 0.0001);
	NORMAL = mix(NORMAL, vec3(0.0, 1.0, 0.0), leaf); // luz pareja con el suelo, sin caras negras
}

void fragment() {
	ALBEDO = COLOR.rgb * fogl;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.18, 0.2, 0.1) * fogl * step(0.5, COLOR.a);
}
