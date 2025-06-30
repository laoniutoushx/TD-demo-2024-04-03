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
    // 直接使用UV坐标，避免复杂的像素转换
    vec2 uv_centered = UV - vec2(0.5);
    
    // 更准确的纹理尺寸计算
    vec2 texture_size = 1.0 / fwidth(UV);
    
    // 分别计算X和Y方向的边框宽度，保持像素精度
    vec2 border_width_uv = vec2(border_width_px) / texture_size;
    vec2 corner_radius_uv = vec2(corner_radius_px) / texture_size;
    vec2 smoothness_uv = vec2(smoothness_px) / texture_size;
    
    // UV空间中的半尺寸
    vec2 half_size = vec2(0.5);
    vec2 rect_size = half_size - border_width_uv;
    
    // 使用平均半径和平滑度来避免变形
    float avg_corner_radius = (corner_radius_uv.x + corner_radius_uv.y) * 0.5;
    float avg_smoothness = (smoothness_uv.x + smoothness_uv.y) * 0.5;
    
    // 计算SDF距离
    float outer_dist = rect_sdf(uv_centered, half_size, avg_corner_radius);
    float inner_dist = rect_sdf(uv_centered, rect_size, max(0.0, avg_corner_radius - max(border_width_uv.x, border_width_uv.y)));
    
    // 创建平滑边缘
    float outer_alpha = 1.0 - smoothstep(-avg_smoothness, avg_smoothness, outer_dist);
    float inner_alpha = 1.0 - smoothstep(-avg_smoothness, avg_smoothness, inner_dist);
    
    float border_alpha = outer_alpha - inner_alpha;
    
    vec3 final_color = mix(border_color.rgb, fill_color.rgb, inner_alpha);
    float final_alpha = max(border_alpha * border_color.a, inner_alpha * fill_color.a);
    
    COLOR = vec4(final_color, final_alpha);
}