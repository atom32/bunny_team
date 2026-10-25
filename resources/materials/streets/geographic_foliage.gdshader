shader_type spatial;
render_mode cull_disabled;
void vertex() {
	vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float weight=smoothstep(1.3,4.0,VERTEX.y);
	VERTEX.x+=sin(p.x*0.21+p.z*0.13+TIME*1.1)*0.024*weight;
	VERTEX.z+=sin(p.z*0.31-p.x*0.17+TIME*0.83)*0.018*weight;
}
void fragment() {
	ALBEDO=COLOR.rgb;
	ROUGHNESS=0.96;
	BACKLIGHT=COLOR.rgb*0.15;
}
