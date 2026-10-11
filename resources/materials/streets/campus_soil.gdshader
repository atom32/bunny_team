shader_type spatial;
render_mode blend_mix, depth_draw_never;
uniform sampler2D ground_detail: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec2 center;
uniform vec2 radius;
varying vec2 world_xz;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
void fragment() {
	vec3 ground=texture(ground_detail,world_xz/2.4).rgb;
	float edge=length((world_xz-center)/radius)+(noise(world_xz*2.8)-.5)*.17;
	ALBEDO=ground*(.72+noise(world_xz*6.0)*.16);
	ALPHA=(1.0-smoothstep(.66,1.03,edge))*.85;
	ROUGHNESS=1.0;
}
