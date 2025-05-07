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
uniform float edge_softness : hint_range(0.001, 0.1) = 0.03;
uniform float alpha_variation : hint_range(0.0, 1.0) = 0.3;
uniform float alpha_noise_scale = 4.0;

// 光点相关参数
uniform vec4 light_point_color : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform float light_point_size : hint_range(0.001, 0.05) = 0.01;
uniform int light_point_count = 20;
uniform float light_point_brightness = 2.0;
uniform float light_point_flicker_speed = 0.5;
uniform float light_point_orbit_speed = 0.1;

// 噪声函数
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = fract(sin(dot(i, vec2(12.9898, 78.233))) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// FBM噪声
float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < 1; i++) {
        value += amplitude * noise(uv * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// 计算光点
float calculate_light_point(vec2 uv, float time, float index) {
    // 使用不同的种子获得稳定的随机位置
    float angle_seed = fract(sin(index * 43.21) * 4321.54321);
    float radius_seed = fract(sin(index * 12.34) * 1234.56789);
    float size_seed = fract(sin(index * 56.78) * 5678.9012);

    // 光点位置基于随机值和时间
    float angle = angle_seed * 6.28 + time * light_point_orbit_speed * (0.5 + angle_seed);
    float radius_factor = mix(0.9, 1.1, radius_seed);
    float radius_base = mix(inner_radius_max, outer_radius_min, radius_seed) * radius_factor;

    // 光点大小变化
    float size = light_point_size * (0.5 + size_seed);

    // 光点的闪烁效果
    float flicker = sin(time * light_point_flicker_speed * (1.0 + 2.0 * radius_seed)) * 0.5 + 0.5;

    // 计算光点的位置
    vec2 point_pos = vec2(cos(angle), sin(angle)) * radius_base;

    // 计算光点的强度
    float dist_to_point = length(uv - point_pos);
    return smoothstep(size, 0.0, dist_to_point) * flicker;
}

void fragment() {
    vec2 uv = UV - vec2(0.5, 0.5);
    float time = TIME * rotation_speed;
    float cos_rot = cos(time);
    float sin_rot = sin(time);
    vec2 rotated_uv = vec2(uv.x * cos_rot - uv.y * sin_rot, uv.x * sin_rot + uv.y * cos_rot);

    float angle = atan(rotated_uv.y, rotated_uv.x);
    float dist = length(rotated_uv);
    float noise_val = fbm(vec2(angle * distortion_scale, time * 0.5));
    float distortion = distortion_amount * noise_val;
    float inner_var = fbm(vec2(angle * 3.0, time * 0.5));
    float inner_radius = mix(inner_radius_min, inner_radius_max, inner_var);
    float inner_edge_inner = inner_radius - edge_softness * (1.0 + inner_var * 0.5);
    float inner_edge_outer = inner_radius + edge_softness * (1.0 + inner_var * 0.5) + distortion;

    float inner_ring = smoothstep(inner_edge_inner, inner_radius, dist) -
                       smoothstep(inner_radius, inner_edge_outer, dist);
    float outer_var = fbm(vec2(angle * 2.0, time * 0.3));
    float outer_radius = mix(outer_radius_min, outer_radius_max, outer_var);
    float outer_edge_inner = outer_radius - edge_softness * (1.0 + outer_var * 0.5);
    float outer_edge_outer = outer_radius + edge_softness * (1.0 + outer_var * 0.5) + distortion;

    float outer_ring = smoothstep(outer_edge_inner, outer_radius, dist) -
                       smoothstep(outer_radius, outer_edge_outer, dist);
    float ring_mask = inner_ring + outer_ring;
    vec4 final_color = mix(ring_color_1, ring_color_2, fbm(rotated_uv * 5.0 + time));

    // 计算所有光点的贡献
    float light_points = 0.0;
    for (int i = 0; i < light_point_count; i++) {
        light_points += calculate_light_point(rotated_uv, TIME, float(i));
    }

    // 将光点混合到最终颜色中
    final_color = mix(final_color, light_point_color, light_points * light_point_color.a);

    // 读取 Godot 4 里的粒子颜色
    //vec4 particle_color = vec4(INSTANCE_CUSTOM.rgb, INSTANCE_CUSTOM.a);

    // 让粒子颜色影响最终颜色
    //final_color *= particle_color;
    float alpha_noise = fbm(vec2(angle * alpha_noise_scale, dist * 10.0 + time * 0.2));
    float alpha_mod = 1.0 - alpha_variation * alpha_noise;

    ALBEDO = final_color.rgb;
    ALPHA = (ring_mask + light_points) * alpha_mod * COLOR.a; // 乘以粒子的 alpha
    if (ALPHA < 0.05) {
        discard;
    }
    EMISSION = final_color.rgb * (ring_mask * 5.0 + light_points * light_point_brightness) * alpha_mod;
}