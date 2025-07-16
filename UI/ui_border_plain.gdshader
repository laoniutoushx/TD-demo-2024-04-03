shader_type canvas_item;

uniform float border_width_px : hint_range(0.0, 10.0) = 2.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.2, 0.4, 0.8, 1.0);
uniform float corner_radius_px : hint_range(0.0, 50.0) = 0.0;
uniform float smoothness_px : hint_range(0.1, 5.0) = 1.0;

float rect_sdf(vec2 p, vec2 size, float radius) {
    vec2 d = abs(p) - size + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

void fragment() {
    // 计算纹理的像素尺寸
    vec2 texture_size = 1.0 / fwidth(UV);

    // 使用较小的尺寸作为基准，确保圆角在所有方向上都是圆形
    float min_size = min(texture_size.x, texture_size.y);

    // 将像素值转换为UV空间，使用统一的缩放比例
    float corner_radius_uv = corner_radius_px / min_size;
    float border_width_uv = border_width_px / min_size;
    float smoothness_uv = smoothness_px / min_size;

    // 计算UV坐标，但需要按纹理比例调整
    vec2 aspect_ratio = texture_size / min_size;
    vec2 uv_centered = (UV - vec2(0.5)) * aspect_ratio;

    // UV空间中的半尺寸（已按比例调整）
    vec2 half_size = aspect_ratio * 0.5;
    vec2 rect_size = half_size - vec2(border_width_uv);

    // 计算SDF距离
    float outer_dist = rect_sdf(uv_centered, half_size, corner_radius_uv);
    float inner_dist = rect_sdf(uv_centered, rect_size, max(0.0, corner_radius_uv - border_width_uv));

    // 创建平滑边缘
    float outer_alpha = 1.0 - smoothstep(-smoothness_uv, smoothness_uv, outer_dist);
    float inner_alpha = 1.0 - smoothstep(-smoothness_uv, smoothness_uv, inner_dist);

    float border_alpha = outer_alpha - inner_alpha;

    vec3 final_color = mix(border_color.rgb, fill_color.rgb, inner_alpha);
    float final_alpha = max(border_alpha * border_color.a, inner_alpha * fill_color.a);

    COLOR = vec4(final_color, final_alpha);
}