shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.4,0.37,0.33,1.0);
uniform bool brick = false;
uniform int floor_finish = 0;
varying vec3 world;
varying vec3 surface_normal;
float hash(vec2 p) { vec3 p3=fract(vec3(p.xyx)*.1031);p3+=dot(p3,p3.yzx+33.33);return fract((p3.x+p3.y)*p3.z); }
float noise(vec2 p) {vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;surface_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);}
void fragment(){
 vec2 p=abs(surface_normal.y)>.7?world.xz:vec2(world.x+world.z,world.y);
 float grain=noise(p*13.0)*.08+noise(p*1.7)*.12+noise(p*.13)*.12;
 vec3 tint=base_color.rgb*(.76+grain);
 if(abs(surface_normal.y)>.7 && floor_finish>0){
  vec2 tile=fract(p/(floor_finish==1?vec2(.16,.8):vec2(.45)));
  float joint=1.0-smoothstep(.012,.04,min(min(tile.x,1.0-tile.x),min(tile.y,1.0-tile.y)));
  if(floor_finish==1){
   float plank=hash(floor(p/vec2(.16,.8)));
   tint*=.8+plank*.35+noise(vec2(p.x*60.0,p.y*3.0))*.08;
  }
  if(floor_finish==3){
   float checker=mod(floor(p.x/.45)+floor(p.y/.45),2.0);
   tint=mix(tint*.48,tint,checker);
  }
  if(floor_finish<4) tint=mix(tint,vec3(.16,.16,.14),joint*.65);
  if(floor_finish==4) tint*=mix(.38,1.0,smoothstep(.32,.56,noise(p*.65)));
 }
 if(brick && abs(surface_normal.y)<.7){
  float row=floor(p.y/.18);
  vec2 cell=fract(vec2(p.x/.42+mod(row,2.0)*.5,p.y/.18));
  float mortar=1.0-smoothstep(.025,.07,min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y)));
  tint=mix(tint,vec3(.26,.25,.23),mortar*.6);
 }
 float stains=noise(vec2(p.x*2.5,p.y*.18));
 tint*=.83+.17*stains;
 ALBEDO=tint;ROUGHNESS=.93;
}
