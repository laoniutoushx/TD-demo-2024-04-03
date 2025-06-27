shader_type canvas_item;

// 边框参数（单位：像素）
uniform float border_pixels : hint_range(0.0, 50.0, 1.0) = 5.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.2, 0.4, 0.8, 1.0);

// 圆角参数（单位：像素）
uniform float corner_radius_pixels : hint_range(0.0, 100.0, 1.0) = 10.0;

// 抗锯齿（平滑过渡的像素宽度）
uniform float anti_aliasing : hint_range(0.5, 5.0) = 1.0;

// 计算到矩形边缘的距离（SDF - Signed Distance Function）
// 此函数现在处理的是像素坐标
float rect_sdf(vec2 p, vec2 size, float radius) {
    vec2 d = abs(p) - size + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

void fragment() {
    // 获取纹理的总像素尺寸
    vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;

    // 将片元坐标转换为以矩形中心为原点(0,0)的像素坐标系
    vec2 p = FRAGCOORD.xy - texture_size * 0.5;

    // 外部矩形的大小（从中心到边缘的距离，单位：像素）
    vec2 outer_rect_size = texture_size * 0.5;
    
    // 内部矩形的大小（外部尺寸减去边框像素宽度）
    vec2 inner_rect_size = outer_rect_size - vec2(border_pixels);

    // 计算到外部矩形和内部矩形的距离
    float outer_dist = rect_sdf(p, outer_rect_size, corner_radius_pixels);
    float inner_dist = rect_sdf(p, inner_rect_size, max(0.0, corner_radius_pixels - border_pixels));

    // 使用 smoothstep 进行抗锯齿处理
    // smoothstep 的平滑区域宽度为 2.0 * anti_aliasing
    // 当距离 dist 在 [-anti_aliasing, anti_aliasing] 范围时，alpha会平滑过渡
    float outer_alpha = 1.0 - smoothstep(-anti_aliasing, anti_aliasing, outer_dist);
    float inner_alpha = 1.0 - smoothstep(-anti_aliasing, anti_aliasing, inner_dist);

    // 边框区域的 alpha = 外部形状 alpha - 内部形状 alpha
    float border_alpha = outer_alpha - inner_alpha;

    // 混合填充颜色和边框颜色
    vec3 final_color = mix(border_color.rgb, fill_color.rgb, inner_alpha);
    
    // 计算最终的 alpha
    // 使用 max 来确保重叠部分的 alpha 不会错误地减少
    float final_alpha = max(border_alpha * border_color.a, inner_alpha * fill_color.a);

    COLOR = vec4(final_color, final_alpha);
}