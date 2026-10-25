shader_type spatial;
render_mode blend_mix, depth_draw_never;
uniform sampler2D soil_detail : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_vertex;
void vertex() {world_vertex=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment() {
	vec2 p=world_vertex.xz;
	float noise=sin(p.x*5.7+p.y*2.3)*sin(p.y*4.1-p.x*1.9);
	float radius=length((UV-0.5)*2.0)+noise*0.055;
	vec3 detail=texture(soil_detail,p/2.7).rgb;
	ALBEDO=mix(detail,vec3(dot(detail,vec3(0.333))),0.45)*vec3(0.63,0.68,0.52);
	ALPHA=(1.0-smoothstep(0.48,1.0,radius))*0.78;
	ROUGHNESS=1.0;
}
