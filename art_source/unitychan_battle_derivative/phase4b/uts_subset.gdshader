shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;
// Battle Costume's active UTS subset: opaque UV0 base/shade/grade only.
// No vertex function, generated detail, normal map, emission or PBR specular.
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 shade1_color : source_color = vec4(1.0);
uniform vec4 shade2_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform sampler2D shade1_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform sampler2D shade2_texture : source_color, hint_default_white, filter_linear_mipmap;
// Source Unity import metadata explicitly enables sRGB for this grade texture too.
uniform sampler2D grade_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform float shade1_step = 0.5;
uniform float shade2_step = 0.0;
uniform float shade1_feather = 0.0001;
uniform float shade2_feather = 0.0001;
uniform bool first_shade_only = false;
uniform bool bound_game_lights = false;
varying vec3 paint_base;
varying vec3 paint_shade1;
varying vec3 paint_shade2;
varying float grade;
vec3 paint_to_light_space(vec3 value) {
 // Compatibility fragment inputs are sRGB, but DIFFUSE_LIGHT is linear.
 // Verified with a .5 swatch: direct light output becomes .7373 unless converted.
 // Forward+/Mobile source_color inputs are already linear.
 if (OUTPUT_IS_SRGB) {
  return mix(value / 12.92, pow((value + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), value));
 }
 return value;
}
void fragment() {
 paint_base = paint_to_light_space(texture(base_texture, UV).rgb * base_color.rgb);
 paint_shade1 = paint_to_light_space(texture(shade1_texture, UV).rgb * shade1_color.rgb);
 paint_shade2 = paint_to_light_space(texture(shade2_texture, UV).rgb * shade2_color.rgb);
 grade = texture(grade_texture, UV).r;
 ALBEDO = vec3(1.0);
 ROUGHNESS = 1.0;
 METALLIC = 0.0;
}
void light() {
 float half_lambert = 0.5 * dot(NORMAL, LIGHT) + 0.5;
 float g = grade * half_lambert * clamp(ATTENUATION * 0.5 + 0.5, 0.0, 1.0);
 float first = clamp((shade1_step - g) / max(shade1_feather, 0.0001), 0.0, 1.0);
 float second = clamp((shade2_step - g) / max(shade2_feather, 0.0001), 0.0, 1.0);
 vec3 base_first = mix(paint_base, paint_shade1, first);
 vec3 painted = mix(base_first, mix(paint_shade1, paint_shade2, second), first);
 painted = first_shade_only ? base_first : painted;
 vec3 irradiance = LIGHT_COLOR / PI;
 if (bound_game_lights) {
  // Explicit game-light adaptation, NOT full UTS ForwardAdd parity.
  // Compatibility adds separately tone-mapped shadow-light passes. A per-light
  // max cannot cap that sum. Use the existing directional key for the character;
  // local accent lights still illuminate the scene/equipment, not these paints.
  // Hanger and Field Office both provide this key. No custom lights are added.
  irradiance /= max(1.0, max(irradiance.r, max(irradiance.g, irradiance.b)));
  if (LIGHT_IS_DIRECTIONAL) {
   DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, painted * irradiance);
  }
 } else {
  DIFFUSE_LIGHT += clamp(painted * irradiance, vec3(0.0), vec3(1.0));
 }
}
