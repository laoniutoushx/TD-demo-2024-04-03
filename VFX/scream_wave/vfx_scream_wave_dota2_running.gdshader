shader_type spatial;

// 形变控制参数
uniform float deform_strength : hint_range(0.0, 2.0) = 0.5; // 形变强度
uniform float deform_scale : hint_range(0.1, 10.0) = 3.0;   // 噪声缩放
uniform float time_speed : hint_range(0.0, 5.0) = 1.0;      // 时间速度
uniform vec3 deform_direction = vec3(1.0, 1.0, 0.5); // 形变方向

// 颜色控制参数
uniform float base_hue : hint_range(0.0, 1.0) = 0.1;           // 基础色相
uniform float hue_variation : hint_range(0.0, 1.0) = 0.2;      // 色相变化范围
uniform float base_saturation : hint_range(0.0, 1.0) = 0.8;    // 基础饱和度
uniform float saturation_variation : hint_range(0.0, 1.0) = 0.3; // 饱和度变化范围
uniform float base_brightness : hint_range(0.0, 2.0) = 1.0;    // 基础亮度
uniform float brightness_variation : hint_range(0.0, 1.0) = 0.4; // 亮度变化范围
uniform float color_noise_scale : hint_range(0.1, 20.0) = 5.0; // 颜色噪声缩放

// 简单噪声函数
float noise(vec3 pos) {
    return fract(sin(dot(pos, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

// 3D噪声函数
float noise3d(vec3 pos) {
    vec3 i = floor(pos);
    vec3 f = fract(pos);
    f = f * f * (3.0 - 2.0 * f);

    float n000 = noise(i);
    float n100 = noise(i + vec3(1.0, 0.0, 0.0));
    float n010 = noise(i + vec3(0.0, 1.0, 0.0));
    float n110 = noise(i + vec3(1.0, 1.0, 0.0));
    float n001 = noise(i + vec3(0.0, 0.0, 1.0));
    float n101 = noise(i + vec3(1.0, 0.0, 1.0));
    float n011 = noise(i + vec3(0.0, 1.0, 1.0));
    float n111 = noise(i + vec3(1.0, 1.0, 1.0));

    float n00 = mix(n000, n100, f.x);
    float n10 = mix(n010, n110, f.x);
    float n01 = mix(n001, n101, f.x);
    float n11 = mix(n011, n111, f.x);

    float n0 = mix(n00, n10, f.y);
    float n1 = mix(n01, n11, f.y);

    return mix(n0, n1, f.z);
}

// HSV到RGB转换函数
vec3 hsv_to_rgb(vec3 hsv) {
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;

    float c = v * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = v - c;

    vec3 rgb;
    if (h < 1.0/6.0) {
        rgb = vec3(c, x, 0.0);
    } else if (h < 2.0/6.0) {
        rgb = vec3(x, c, 0.0);
    } else if (h < 3.0/6.0) {
        rgb = vec3(0.0, c, x);
    } else if (h < 4.0/6.0) {
        rgb = vec3(0.0, x, c);
    } else if (h < 5.0/6.0) {
        rgb = vec3(x, 0.0, c);
    } else {
        rgb = vec3(c, 0.0, x);
    }

    return rgb + m;
}

// 分形噪声
float fractal_noise(vec3 pos) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;

    for (int i = 0; i < 4; i++) {
        value += amplitude * noise3d(pos * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

// 全局变量存储顶点位置（用于fragment着色器）
varying vec3 world_position;

void vertex() {
    // 获取原始顶点位置
    vec3 world_pos = VERTEX;

    // 添加时间变化
    vec3 noise_pos = world_pos * deform_scale + vec3(TIME * time_speed);

    // 生成噪声值
    float noise_value = fractal_noise(noise_pos);

    // 将噪声值从[0,1]映射到[-1,1]
    noise_value = noise_value * 2.0 - 1.0;

    // 应用形变
    vec3 deformation = deform_direction * noise_value * deform_strength;

    // 对于圆环，我们可以根据位置应用不同的形变
    // 获取顶点到中心的距离（用于圆环特殊处理）
    float distance_from_center = length(world_pos.xz);

    // 径向形变（影响圆环的圆度）
    vec3 radial_dir = normalize(vec3(world_pos.x, 0.0, world_pos.z));
    float radial_noise = fractal_noise(noise_pos + vec3(100.0));
    radial_noise = radial_noise * 2.0 - 1.0;

    // 垂直形变（影响圆环的高度）
    float vertical_noise = fractal_noise(noise_pos + vec3(200.0));
    vertical_noise = vertical_noise * 2.0 - 1.0;

    // 综合形变
    vec3 final_deformation = vec3(0.0);

    // 径向形变
    final_deformation += radial_dir * radial_noise * deform_strength * 0.3;

    // 垂直形变
    final_deformation.y += vertical_noise * deform_strength * 0.2;

    // 整体形变
    final_deformation += deformation * 0.5;

    // 应用形变到顶点
    VERTEX += final_deformation;

    // 传递世界位置到fragment着色器
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // 重新计算法线（简单方法）
    // 在实际应用中，你可能需要更精确的法线计算
    NORMAL = normalize(NORMAL + final_deformation * 0.1);
}

void fragment() {
    // 使用世界位置生成颜色噪声
    vec3 color_noise_pos = world_position * color_noise_scale;

    // 生成三个不同的噪声值用于HSV
    float hue_noise = fractal_noise(color_noise_pos);
    float saturation_noise = fractal_noise(color_noise_pos + vec3(100.0));
    float brightness_noise = fractal_noise(color_noise_pos + vec3(200.0));

    // 将噪声值从[0,1]映射到[-1,1]然后再调整
    hue_noise = (hue_noise - 0.5) * 2.0;
    saturation_noise = (saturation_noise - 0.5) * 2.0;
    brightness_noise = (brightness_noise - 0.5) * 2.0;

    // 计算最终的HSV值
    float final_hue = base_hue + hue_noise * hue_variation;
    float final_saturation = clamp(base_saturation + saturation_noise * saturation_variation, 0.0, 1.0);
    float final_brightness = clamp(base_brightness + brightness_noise * brightness_variation, 0.0, 2.0);

    // 确保色相在0-1范围内循环
    final_hue = fract(final_hue);

    // 转换HSV到RGB
    vec3 hsv_color = vec3(final_hue, final_saturation, final_brightness);
    vec3 rgb_color = hsv_to_rgb(hsv_color);

    // 设置材质属性
    ALBEDO = rgb_color;
    METALLIC = 0.1;
    ROUGHNESS = 0.3;

    // 可选：添加发光效果
    if (final_brightness > 1.0) {
        EMISSION = rgb_color * (final_brightness - 1.0) * 0.5;
    }
}