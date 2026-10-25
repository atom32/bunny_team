shader_type spatial;
// Metre UVs match the physical 3.4 m window bays and 3.3 m storeys.
// Windows remain legible beyond the geometry LOD, not a blue checkerboard.
uniform vec4 wall_color : source_color = vec4(0.72,0.69,0.58,1.0);
uniform sampler2D wall_detail : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float brick_amount = 0.0;
void fragment() {
	vec2 p=UV;
	vec3 detail=texture(wall_detail,p/2.5).rgb;
	float value=dot(detail,vec3(0.2126,0.7152,0.0722));
	vec3 plaster=wall_color.rgb*(0.83+value*0.38);
	float row=floor(p.y/0.19);
	vec2 brick=fract(vec2(p.x/0.46+mod(row,2.0)*0.5,p.y/0.19));
	float joint=1.0-smoothstep(0.018,0.065,min(min(brick.x,1.0-brick.x),min(brick.y,1.0-brick.y)));
	plaster=mix(plaster,plaster*0.72,joint*brick_amount*0.65);
	float weather=sin(p.x*0.73+sin(p.y*0.13))*sin(p.y*0.21)*0.025;
	vec2 cell=fract(vec2(p.x/3.4,p.y/3.3));
	float window=step(0.272,cell.x)*step(cell.x,0.728)*step(0.303,cell.y)*step(cell.y,0.833)*step(0.01,p.y);
	float frame=(1.0-step(0.017,abs(cell.x-0.5)))*window;
	vec3 glass=mix(vec3(0.075,0.12,0.115),vec3(0.15,0.22,0.205),cell.y);
	ALBEDO=mix(plaster+weather,glass,window);
	ALBEDO=mix(ALBEDO,vec3(0.46,0.49,0.43),frame);
	ROUGHNESS=mix(0.94,0.36,window);
	METALLIC=window*0.12;
}
