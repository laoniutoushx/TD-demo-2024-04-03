shader_type spatial;

uniform sampler2D ice_normal;
uniform sampler2D ice_roughness;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform vec4 ice_color : source_color = vec4(0.8, 0.9, 1.0, 0.7);
uniform float refraction_strength = 0.05;
uniform float frost_mix = 0.5;
uniform float frost_scale = 10.0;
uniform float ice_depth = 0.2;

void fragment() {
    // 基础冰的颜色和透明度
    vec4 base_color = ice_color;
    
    // 获取法线贴图
    vec3 normal_map = texture(ice_normal, UV).rgb * 2.0 - 1.0;
    
    // 使用分形噪声创建结霜效果
    vec2 frost_uv = UV * frost_scale;
    float noise1 = fract(sin(dot(frost_uv, vec2(12.9898, 78.233))) * 43758.5453);
    float noise2 = fract(sin(dot(frost_uv * 2.0, vec2(12.9898, 78.233))) * 43758.5453);
    float frost_pattern = mix(noise1, noise2, 0.5);
    
    // 结合噪声创建结晶结构
    vec2 distortion = normal_map.xy * refraction_strength;
    vec4 frost_color = vec4(0.95, 0.98, 1.0, 1.0);
    vec4 crystal_color = mix(base_color, frost_color, frost_pattern * frost_mix);
    
    // 冰面深度效果
    float depth_factor = (1.0 - texture(DEPTH_TEXTURE, SCREEN_UV + distortion).r) * ice_depth;
    vec4 deep_ice_color = vec4(ice_color.rgb * 0.7, ice_color.a);
    vec4 final_color = mix(crystal_color, deep_ice_color, clamp(depth_factor, 0.0, 1.0));
    
    // 粗糙度贴图
    float roughness = texture(ice_roughness, UV).r;
    
    // 输出到渲染器
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
    ROUGHNESS = roughness;
    SPECULAR = 0.8;
    NORMAL_MAP = normal_map;
    METALLIC = 0.0;
    
    // 使用法线贴图和折射强度创建折射效果
    vec3 refraction_normal = normalize(mix(vec3(0.0, 0.0, 1.0), normal_map, refraction_strength));
    EMISSION = vec3(0.1) * frost_pattern * base_color.rgb; // 添加一点发光效果模拟冰的反射
}