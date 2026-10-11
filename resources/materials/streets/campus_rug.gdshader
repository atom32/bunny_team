shader_type spatial;
render_mode diffuse_burley;
uniform vec2 rug_origin = vec2(24.0,17.0);
uniform vec2 rug_half_size = vec2(1.15,3.8);
uniform vec3 fabric_color : source_color = vec3(0.41,0.46,0.35);
varying vec2 floor_position;
float grain(vec2 p) {
 return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
void vertex() { floor_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz-rug_origin; }
void fragment() {
 vec2 p=floor_position;
 // Broad faded fibres survive minification; thin warp/weft fade at distance.
 float wear=sin(p.x*1.3+sin(p.y*.8))*.04+sin(p.y*2.1+p.x*.9)*.035;
 float fibres=grain(floor(p*75.0));
 float filter_width=max(fwidth(p.x),fwidth(p.y));
 float weave=mix(0.0,(fibres-.5)*.11,1.0-smoothstep(.025,.07,filter_width));
 vec3 color=fabric_color*(.9+wear+weave);
 float border=smoothstep(rug_half_size.x-.22,rug_half_size.x-.13,abs(p.x))+smoothstep(rug_half_size.y-.26,rug_half_size.y-.17,abs(p.y));
 color=mix(color,vec3(.47,.43,.32),clamp(border,0.0,1.0)*.55);
 // Soft, walked strip; no hard rectangle of artificial brightness.
 float walked=(1.0-smoothstep(.4,1.45,abs(p.x)))*smoothstep(-3.8,-2.0,p.y);
 ALBEDO=color*(1.0+walked*.08);
 ROUGHNESS=.98;
}
