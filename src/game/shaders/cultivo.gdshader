shader_type spatial;
render_mode diffuse_burley, cull_disabled;

// Cultivo de un campo (proceso/64; src/game/piezas.gd): las matas se apoyan en el suelo de cada
// una (la malla ya sigue el terreno) y crecen con `alto` (0 a 1) sin mover la base: UV2.x es el
// alto de cada vértice sobre su suelo, maduro. El color de la etapa (data/arte_base.json →
// granjas) va en `tinte`; las espigas y flores (COLOR.a = 1) toman su color con `flor`.
instance uniform float alto = 1.0;
instance uniform vec3 tinte : source_color = vec3(0.37, 0.6, 0.23);
instance uniform float flor = 0.0;

void vertex() {
	float h = UV2.x;
	VERTEX.y += h * (alto - 1.0);
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float viento = sin(TIME * 1.7 + wp.x * 0.9 + wp.z * 0.6) * 0.5 + 0.5;
	VERTEX.x += h * alto * 0.08 * viento;
}

void fragment() {
	// Las normales de la malla valen para las dos caras (Godot las da vuelta en la de atrás).
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec3 hoja = tinte * COLOR.rgb;
	ALBEDO = COLOR.a > 0.5 ? mix(tinte, COLOR.rgb, flor) : hoja;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
}
