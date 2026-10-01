shader_type spatial;
render_mode blend_mix,depth_draw_never,cull_disabled;
uniform vec4 tint : source_color = vec4(.12,.13,.11,1.0);
uniform float wetness = 0.0;
uniform float seed = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float detail=noise(UV*19.0+seed);
 float edge=noise(UV*6.0+seed)*.28;
 float mask=1.0-smoothstep(.65+edge,.95+edge,length(p));
 ALBEDO=tint.rgb*(.8+detail*.25);
 ALPHA=mask*(.22+detail*.42);
 ROUGHNESS=mix(.96,.25,wetness);
 SPECULAR=mix(.08,.5,wetness);
}
