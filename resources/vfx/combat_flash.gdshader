shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.72, 0.3, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform int shape = 0; // 0: forward jet, 1: impact star, 2: movement streak

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float mask;
	if (shape == 1) {
		float star = max(pow(max(0.0, 1.0 - abs(p.x)), 16.0) * (1.0 - abs(p.y)),
			pow(max(0.0, 1.0 - abs(p.y)), 16.0) * (1.0 - abs(p.x)));
		mask = max(star, pow(max(0.0, 1.0 - length(p) * 2.8), 2.0));
	} else {
		float along = UV.y;
		float width = shape == 2 ? 0.11 : mix(0.5, 0.02, along);
		float edge = 1.0 - smoothstep(width * 0.45, width, abs(p.x));
		mask = edge * smoothstep(0.0, 0.12, along) * (1.0 - along);
	}
	ALBEDO = mix(tint.rgb, vec3(1.0, 0.95, 0.82), mask * 0.65);
	ALPHA = mask * opacity * tint.a;
}
