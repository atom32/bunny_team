shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.44,0.58,0.35,1.0);
uniform sampler2D detail_texture : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_vertex;
void vertex() {world_vertex=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment() {
	vec3 detail=texture(detail_texture,world_vertex.xz/3.0).rgb;
	float grain=dot(detail,vec3(0.333));
	float mottling=(texture(detail_texture,world_vertex.zx/21.7).r-0.25)*0.12;
	ALBEDO=base_color.rgb*(0.72+grain*0.8+mottling);
	ROUGHNESS=0.95;
}
