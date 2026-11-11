shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// Anillo (shape 0) o marco rectangular (shape 1) sobre un plano, en unidades de mundo.
uniform vec4 color : source_color = vec4(1.0);
uniform int shape = 0;
uniform vec2 size = vec2(1.0);
uniform float thickness = 0.06;
uniform float fill = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float a;
	if (shape == 0) {
		float r = size.x * 0.5;
		float d = length(p);
		float aa = fwidth(d);
		a = smoothstep(r, r - aa, d) * smoothstep(r - thickness - aa, r - thickness, d);
		a += fill * smoothstep(r - thickness, r - thickness - aa, d);
	} else {
		vec2 h = size * 0.5;
		vec2 q = abs(p);
		float outer = max(q.x - h.x, q.y - h.y);
		float inner = max(q.x - (h.x - thickness), q.y - (h.y - thickness));
		float aa = fwidth(outer);
		a = smoothstep(aa, -aa, outer) * smoothstep(-aa, aa, inner);
		a += fill * smoothstep(aa, -aa, inner);
	}
	ALBEDO = color.rgb;
	ALPHA = clamp(a, 0.0, 1.0) * color.a;
}
