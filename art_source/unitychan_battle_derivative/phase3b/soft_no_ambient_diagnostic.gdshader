shader_type spatial;
render_mode cull_disabled, specular_disabled, ambient_light_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, hint_default_white, filter_linear_mipmap;
void fragment() {
 ALBEDO = base_color.rgb * texture(base_texture, UV).rgb;
 ROUGHNESS = 0.8;
 METALLIC = 0.0;
}
void light() {
 // Bounded diffuse response for pale painted/anime surfaces. No emission,
 // camera term, new lights, texture recoloring or per-scene parameter changes.
 vec3 irradiance = LIGHT_COLOR / 3.14159265;
 float peak = max(irradiance.r, max(irradiance.g, irradiance.b));
 vec3 response = 0.45 * irradiance / (1.0 + peak);
 float diffuse = mix(0.25, 1.0, smoothstep(-0.2, 0.6, dot(NORMAL, LIGHT)));
 DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, response * diffuse * ATTENUATION);
}
