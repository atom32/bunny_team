shader_type spatial;
uniform bool exterior=false;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_pos.xz;
	float scale=exterior?.72:.56;
	vec2 tile=floor(p/scale); vec2 cell=fract(p/scale);
	float joint=1.0-smoothstep(.013,.033,min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y)));
	float mottling=noise(p*3.2)*.55+noise(p*.7)*.45;
	float stain=smoothstep(.52,.8,noise(p*1.4));
	vec3 base=exterior?vec3(.40,.40,.35):vec3(.57,.54,.43);
	base*=.85+hash(tile)*.23;
	base*=.84+mottling*.24-stain*.16;
	base=mix(base,base*.46,joint*.75);
	if(exterior) {
		// Feather the visual paving into the existing forecourt, without moving its mesh.
		vec2 edge=abs(p-vec2(23,-6));
		float border=smoothstep(3.0,4.7,max(edge.x*.72,edge.y)+noise(p*2.1)*.6);
		base=mix(base,vec3(.29,.31,.24)*(.85+mottling*.2),border);
	}
	ALBEDO=base;
	ROUGHNESS=.96;
}
