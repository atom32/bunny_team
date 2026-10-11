shader_type spatial;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_pos.xz;
	float seam=1.0-smoothstep(.015,.04,abs(fract(p.x/.42)-.5));
	float weather=noise(p*.9)*.65+noise(p*3.8)*.35;
	float rust=smoothstep(.58,.79,weather);
	ALBEDO=mix(vec3(.25,.29,.25),vec3(.35,.21,.12),rust);
	ALBEDO*=.82+weather*.3-seam*.22;
	ROUGHNESS=mix(.72,.97,rust);
	METALLIC=.35*(1.0-rust);
}
