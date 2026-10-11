shader_type spatial;
render_mode blend_mix, depth_draw_never;
uniform vec4 paint_color: source_color=vec4(.62,.63,.52,.62);
varying vec2 world_xz;
void vertex() { world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	float chip=hash(floor(world_xz*52.0));
	float wear=noise(world_xz*1.2);
	ALBEDO=paint_color.rgb*(.88+chip*.15);
	ALPHA=paint_color.a*smoothstep(.02,.13,chip)*smoothstep(.24,.44,wear);
	ROUGHNESS=1.0;
}
