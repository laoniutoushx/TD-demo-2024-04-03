shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_lambert, specular_schlick_ggx;
render_mode unshaded; // 使材质不受光照影响，保持原色

uniform vec4 ring_color_1 : source_color = vec4(0.8, 0.2, 0.3, 1.0);
uniform vec4 ring_color_2 : source_color = vec4(0.2, 0.3, 0.8, 1.0);
uniform float inner_radius_min = 0.2;
uniform float inner_radius_max = 0.25;
uniform float outer_radius_min = 0.4;
uniform float outer_radius_max = 0.45;
uniform float distortion_amount = 0.1;
uniform float distortion_scale = 5.0;
uniform float rotation_speed = 0.2;
uniform float edge_softness : hint_range(0.001, 0.1) = 0.03; // 边缘柔和度
uniform float alpha_variation : hint_range(0.0, 1.0) = 0.3; // 透明度随机变化强度
uniform float alpha_noise_scale = 4.0; // 透明度噪声的细节程度

// 噪声函数，用于创建不规则形状
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    // 四个角的伪随机值
    float a = fract(sin(dot(i, vec2(12.9898, 78.233))) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    
    // 平滑插值
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// FBM (分形布朗运动) - 用于创建更自然的噪声
float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // 叠加几层噪声以获得更自然的效果
    for (int i = 0; i < 1; i++) {
        value += amplitude * noise(uv * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void fragment() {
    // 使用UV坐标而不是Canvas坐标
    vec2 uv = UV - vec2(0.5, 0.5); // 中心化UV坐标
    
    // 应用旋转
    float time = TIME * rotation_speed;
    float cos_rot = cos(time);
    float sin_rot = sin(time);
    vec2 rotated_uv = vec2(
        uv.x * cos_rot - uv.y * sin_rot,
        uv.x * sin_rot + uv.y * cos_rot
    );
    
    // 计算角度和距离
    float angle = atan(rotated_uv.y, rotated_uv.x);
    float dist = length(rotated_uv);
    
    // 使用FBM噪声创建更自然的扭曲
    float noise_val = fbm(vec2(angle * distortion_scale, time * 0.5));
    float distortion = distortion_amount * noise_val;
    
    // 内圆环 - 使用更柔和的边缘
    float inner_var = fbm(vec2(angle * 3.0, time * 0.5));
    float inner_radius = mix(inner_radius_min, inner_radius_max, inner_var);
    float inner_edge_inner = inner_radius - edge_softness * (1.0 + inner_var * 0.5);
    float inner_edge_outer = inner_radius + edge_softness * (1.0 + inner_var * 0.5) + distortion;
    
    float inner_ring = smoothstep(inner_edge_inner, inner_radius, dist) - 
                       smoothstep(inner_radius, inner_edge_outer, dist);
    
    // 外圆环 - 使用更柔和的边缘
    float outer_var = fbm(vec2(angle * 2.0, time * 0.3));
    float outer_radius = mix(outer_radius_min, outer_radius_max, outer_var);
    float outer_edge_inner = outer_radius - edge_softness * (1.0 + outer_var * 0.5);
    float outer_edge_outer = outer_radius + edge_softness * (1.0 + outer_var * 0.5) + distortion;
    
    float outer_ring = smoothstep(outer_edge_inner, outer_radius, dist) - 
                       smoothstep(outer_radius, outer_edge_outer, dist);
    
    // 合并两个圆环
    float ring_mask = inner_ring + outer_ring;
    
    // 为两个圆环应用不同的颜色
    vec4 final_color = mix(ring_color_1, ring_color_2, fbm(rotated_uv * 5.0 + time));
    
    // 为透明度添加噪声变化
    float alpha_noise = fbm(vec2(angle * alpha_noise_scale, dist * 10.0 + time * 0.2));
    float alpha_mod = 1.0 - alpha_variation * alpha_noise;
    
    // 使用遮罩应用颜色和透明度
    ALBEDO = final_color.rgb;
    
    // 设置带随机变化的透明度
    ALPHA = ring_mask * alpha_mod;
    
    // 丢弃非常低透明度的像素 (可选)
    if (ALPHA < 0.05) {
        discard;
    }
    
    // 添加发光效果，强度也受透明度影响
    EMISSION = final_color.rgb * ring_mask * 0.8 * alpha_mod;
}