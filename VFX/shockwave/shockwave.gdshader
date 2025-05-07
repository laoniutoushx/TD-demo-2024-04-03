shader_type spatial;

uniform float wave_width = 0.1; // 波浪宽度
uniform float distortion_strength = 0.2; // 失真强度
uniform float wave_speed = 2.0; // 波浪速度
uniform float wave_amplitude = 0.5; // 波浪振幅
uniform vec4 wave_color  = vec4(1.0, 1.0, 1.0, 1.0); // 波浪颜色

// Noise 函数，用于创建扭曲效果
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // 计算到中心的距离
    vec2 center_uv = UV - vec2(0.5, 0.5);
    float distance_from_center = length(center_uv);

    // 创建波浪效果
    float wave = sin(distance_from_center * 10.0 - TIME * wave_speed) * wave_amplitude;

    // 添加噪声失真
    float noise_value = noise(UV * 10.0 + TIME) * distortion_strength;

    // 计算波浪遮罩
    float wave_mask = 1.0 - smoothstep(
        wave_width,
        wave_width + 0.1,
        abs(distance_from_center - (wave + noise_value))
    );

    // 应用波浪颜色和透明度
    vec4 final_color = wave_color * wave_mask;

    // 设置片段颜色和透明度
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
}