shader_type spatial;
uniform vec4 tile_color : source_color=vec4(0.50,0.54,0.48,1.0);
uniform vec2 floor_size=vec2(32.0,24.0);
void fragment(){
	vec2 p=UV*floor_size/0.8;
	vec2 edge=min(fract(p),1.0-fract(p));
	float grout=1.0-smoothstep(0.008,0.027,min(edge.x,edge.y));
	float alternate=mod(floor(p.x)+floor(p.y),2.0)*0.025;
	ALBEDO=mix(tile_color.rgb-vec3(alternate),tile_color.rgb*0.64,grout);
	ROUGHNESS=0.83;
}
