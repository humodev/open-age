shader_type spatial;
// Silueta de la gente tapada (proceso/24-tras-la-segunda-ronda/4p-escala.md): con los árboles
// y los edificios más altos, una unidad detrás de un bosque o de una casa se dibuja como una
// sombra del color del equipo, como en AoE4. Va como material_overlay del cuerpo: se pinta solo
// donde lo opaco de la escena está más cerca que la unidad, y deja la unidad visible como está.
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, blend_mix, shadows_disabled;

uniform vec4 color : source_color = vec4(0.2, 0.4, 1.0, 0.55);
uniform float margen = 0.35; // casillas: lo que está más cerca que esto no cuenta (la propia mano, el escudo)
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

void fragment() {
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	float scene = -v.z / v.w;
	if (-VERTEX.z < scene + margen) {
		discard;
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
