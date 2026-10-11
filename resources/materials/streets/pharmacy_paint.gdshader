shader_type spatial;
render_mode diffuse_burley;
uniform vec4 paint_color : source_color = vec4(.34,.44,.38,1.0);
uniform float wear_amount : hint_range(0.0,1.0) = 1.0;
varying vec3 world;
varying vec3 normal_world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;normal_world=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);}
void fragment(){
 vec2 p=abs(normal_world.y)>.7?world.xz:vec2(world.x+world.z,world.y);
 float coarse=noise(p*1.3),fine=noise(p*18.0);
 float chips=smoothstep(.63,.74,coarse+fine*.16)*wear_amount;
 float streak=noise(vec2(p.x*8.0,p.y*.12));
 vec3 worn=vec3(.44,.39,.28)*(.84+fine*.2);
 ALBEDO=mix(paint_color.rgb*(.83+.15*streak+.08*fine),worn,chips);
 ROUGHNESS=mix(.69,.94,chips);
}
