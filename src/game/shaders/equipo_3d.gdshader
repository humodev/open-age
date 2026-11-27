// Color del equipo sobre un modelo 3D texturizado (proceso/56-rig-y-color).
// La máscara (tools/mascara_equipo_3d.py) está en el mismo atlas UV que la textura.
// Lo enmascarado toma el color del jugador con la luz de la tela original:
// equipo × (luminancia / luz_ref), así los pliegues, guardas y sombras pintadas se conservan.
// Todavía no lo usa el juego.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D mascara : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform vec3 equipo : source_color = vec3(0.2, 0.42, 0.8);
uniform float luz_ref = 0.08; // la imprime tools/mascara_equipo_3d.py
uniform float fuerza : hint_range(0.0, 1.0) = 1.0;
uniform float brillo_max = 1.8;
uniform vec3 tinte : source_color = vec3(1.18, 1.15, 1.1); // como WorldView._matte
uniform bool ver_mascara = false;

void fragment() {
	vec3 c = texture(textura, UV).rgb;
	float m = texture(mascara, UV).r * fuerza;
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 t = equipo * clamp(l / max(luz_ref, 0.001), 0.15, brillo_max);
	vec3 o = mix(c, t, m) * tinte;
	if (ver_mascara) {
		o = mix(c * 0.6, vec3(1.0, 0.0, 1.0), m);
	}
	ALBEDO = o;
	ROUGHNESS = 0.92;
	METALLIC = 0.0;
	SPECULAR = 0.2;
}
