shader_type spatial;
uniform vec2 shore_points[8];
uniform int shore_count=4;
varying vec3 world_pos;
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz; }
void fragment() {
	vec2 p=world_pos.xz;
	float bank=100.0;
	for(int i=0;i<8;i++) {
		if(i>=shore_count) break;
		vec2 a=shore_points[i];vec2 b=shore_points[(i+1)%shore_count];
		vec2 d=b-a;
		bank=min(bank,length(p-a-d*clamp(dot(p-a,d)/max(dot(d,d),.001),0.0,1.0)));
	}
	float ripple=sin(p.x*5.7+p.y*2.4+TIME*.72)*.35+sin(p.y*7.9-p.x*1.8-TIME*.53)*.25;
	float broad=sin(p.x*.47+p.y*.39)*sin(p.y*.28-p.x*.19)*.5+.5;
	vec3 deep=mix(vec3(.025,.084,.078),vec3(.042,.115,.103),broad);
	vec3 shallow=vec3(.083,.151,.113);
	ALBEDO=mix(shallow,deep,smoothstep(.25,2.4,bank))*(.96+ripple*.07);
	ROUGHNESS=.22+smoothstep(0.0,1.3,bank)*.10;
	SPECULAR=.8;
	NORMAL_MAP=vec3(.5+cos(p.x*5.7+p.y*2.4+TIME*.72)*.065,.5+cos(p.y*7.9-p.x*1.8-TIME*.53)*.045,1.0);
}
