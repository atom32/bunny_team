shader_type spatial;
render_mode cull_disabled;

uniform sampler2D palette : source_color, filter_nearest;
uniform vec4 accent : source_color = vec4(0.13, 0.40, 0.43, 1.0);
uniform float brightness = 1.0;

void fragment() {
	vec3 source = texture(palette, UV).rgb;
	float high = max(source.r, max(source.g, source.b));
	float low = min(source.r, min(source.g, source.b));
	float saturation = (high - low) / max(high, 0.001);
	vec3 neutral = mix(source, vec3(dot(source, vec3(0.3, 0.59, 0.11))), 0.55);
	ALBEDO = mix(neutral, accent.rgb * (0.6 + high * 0.65), smoothstep(0.22, 0.5, saturation)) * brightness;
	ROUGHNESS = 0.74;
	METALLIC = 0.12;
}
