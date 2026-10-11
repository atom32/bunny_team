shader_type spatial;
uniform sampler2D tile_albedo: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D tile_normal: hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec4 roof_color: source_color=vec4(.4,.45,.42,1.0);
uniform float desaturate=.8;
void fragment() {
	vec3 tile=texture(tile_albedo,UV).rgb;
	float luminance=dot(tile,vec3(.2126,.7152,.0722));
	ALBEDO=mix(tile,vec3(luminance),desaturate)*roof_color.rgb*1.6;
	NORMAL_MAP=texture(tile_normal,UV).rgb;
	NORMAL_MAP_DEPTH=.65;
	ROUGHNESS=.89;
}
