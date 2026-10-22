shader_type spatial;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.47, 0.53, 0.51, 1.0);
uniform float panel_size = 4.0;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_position.xz * 0.22;
	float wear = dot(texture(albedo_map, uv).rgb, vec3(0.2126, 0.7152, 0.0722));
	vec2 cell = fract(world_position.xz / panel_size);
	float border = min(min(cell.x, 1.0 - cell.x), min(cell.y, 1.0 - cell.y));
	ALBEDO = (tint.rgb + vec3((wear - 0.4) * 0.08)) * mix(0.8, 1.0, smoothstep(0.002, 0.007, border));
	ROUGHNESS = mix(0.75, 0.95, texture(roughness_map, uv).r);
	NORMAL_MAP = texture(normal_map, uv).rgb;
	NORMAL_MAP_DEPTH = 0.18;
}
