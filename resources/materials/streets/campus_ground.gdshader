shader_type spatial;
uniform sampler2D grass_albedo: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil_albedo: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec4 ground_color: source_color=vec4(.33,.40,.26,1.0);
uniform vec2 lake_points[24];
uniform int lake_counts[3];
uniform vec2 tree_points[32];
uniform int tree_count=0;
varying vec3 world_pos;
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_pos.xz;
	vec3 detail=texture(grass_albedo,p/4.0).rgb;
	float value=dot(detail,vec3(.2126,.7152,.0722));
	float broad=sin(p.x*.17+p.y*.09)*sin(p.y*.21-p.x*.04)*.10;
	ALBEDO=ground_color.rgb*(.65+value*1.15+broad);
	float bank=100.0;
	for(int lake=0;lake<3;lake++) {
		int count=lake_counts[lake];
		for(int i=0;i<8;i++) {
			if(i>=count) break;
			vec2 a=lake_points[lake*8+i];vec2 b=lake_points[lake*8+(i+1)%count];vec2 d=b-a;
			bank=min(bank,length(p-a-d*clamp(dot(p-a,d)/max(dot(d,d),.001),0.0,1.0)));
		}
	}
	float damp=1.0-smoothstep(1.5,5.0,bank);
	ALBEDO=mix(ALBEDO,ALBEDO*vec3(.74,.86,.72),damp*.50);
	float litter=0.0;
	for(int i=0;i<32;i++) {
		if(i>=tree_count) break;
		litter=max(litter,1.0-smoothstep(.5,3.8,length(p-tree_points[i])));
	}
	vec3 soil=texture(soil_albedo,p/3.2).rgb;
	ALBEDO=mix(ALBEDO,soil*.78,litter*.65);
	float verge=min(abs(p.y-4.0)-4.1,abs(p.y-47.0)-3.6);
	verge=min(verge,min(abs(p.x+10.0)-2.5,abs(p.x+50.0)-3.1));
	float worn=1.0-smoothstep(.3,1.5,verge);
	ALBEDO=mix(ALBEDO,vec3(.13,.125,.086),worn*.22);
	ROUGHNESS=mix(1.0,.88,damp);

}
