shader_type spatial;
render_mode cull_disabled;
varying vec3 world_vertex;
// Integer lattice hashing keeps shared cell corners identical. The large
// sin()*multiplier hash amplified GPU rounding into visible cell boundaries.
float hash(vec2 p) {
	uvec2 q=uvec2(ivec2(p));
	uint h=(q.x*1597334677u)^(q.y*3812015801u);
	h=(h^(h>>16u))*2246822519u;
	h=h^(h>>13u);
	return float(h&16777215u)/16777215.0;
}
float noise(vec2 p) {
	vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex() { world_vertex=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_vertex.xz;
	// Source-ring distance is baked per grid vertex; stable across material
	// chunks and renderers, with no dynamic uniform-array shore loop.
	float bank=COLOR.r*8.0;
	float ripple_lod=1.0-smoothstep(0.12,1.5,length(fwidth(p)));
	vec3 deep=vec3(0.029,0.093,0.081)+(noise(p*0.028)-0.5)*0.008;
	vec3 shallow=vec3(0.067,0.16,0.13);
	ALBEDO=mix(shallow,deep,smoothstep(0.3,5.5,bank));
	float dx=(noise(p*0.32+vec2(TIME*0.05,0.0))-noise(p*0.32+vec2(0.18,TIME*0.05)))*0.022;
	float dz=(noise(p*0.29+vec2(-TIME*0.03,1.8))-noise(p*0.29+vec2(2.1,-TIME*0.03)))*0.018;
	// A world-space normal avoids tangent-basis seams across an arbitrary
	// unsimplified lake triangulation. Nonperiodic ripples do not form a grid.
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(vec3(dx*ripple_lod,1.0,dz*ripple_lod)),0.0)).xyz);
	ROUGHNESS=0.34;
	SPECULAR=0.4;
	METALLIC=0.06;
}
