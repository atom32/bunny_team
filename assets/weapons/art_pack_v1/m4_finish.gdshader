shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D source_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D source_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D source_ao : filter_linear_mipmap, repeat_enable;
uniform sampler2D source_specular : filter_linear_mipmap, repeat_enable;
uniform bool replace_factory_optic = false;
varying vec3 asset_position;
void vertex() { asset_position = VERTEX; }
void fragment() {
    if (replace_factory_optic && asset_position.y > 0.108 && asset_position.z > -0.02 && asset_position.z < 0.22) { discard; }
    vec3 original = texture(source_albedo, UV).rgb;
    float detail = clamp(dot(original, vec3(0.2126,0.7152,0.0722))*2.1+0.58,0.55,1.10);
    float stock = 1.0-smoothstep(-0.035,-0.018,asset_position.z);
    float handguard = smoothstep(0.23,0.25,asset_position.z)*(1.0-smoothstep(0.44,0.46,asset_position.z));
    float grip = (1.0-smoothstep(0.005,0.02,asset_position.y))*(1.0-smoothstep(0.02,0.035,asset_position.z));
    float polymer = max(stock,max(handguard,grip));
    float magazine = (1.0-smoothstep(0.0,0.018,asset_position.y))*smoothstep(0.03,0.05,asset_position.z)*(1.0-smoothstep(0.20,0.22,asset_position.z));
    vec3 finish = mix(vec3(0.12,0.155,0.18),vec3(0.24,0.26,0.20),polymer);
    finish = mix(finish,vec3(0.29,0.31,0.30),magazine);
    float spec = texture(source_specular,UV).r;
    ALBEDO = finish*detail;
    METALLIC = mix(0.48,0.02,polymer);
    METALLIC = mix(METALLIC,0.67,magazine);
    ROUGHNESS = clamp(mix(0.52,0.76,polymer)-spec*0.12,0.38,0.80);
    NORMAL_MAP = texture(source_normal,UV).rgb;
    NORMAL_MAP_DEPTH = 0.65;
    AO = mix(1.0,texture(source_ao,UV).r,0.65);
    AO_LIGHT_AFFECT = 0.3;
}
