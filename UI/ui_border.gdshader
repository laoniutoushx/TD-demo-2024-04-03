shader_type canvas_item;

// 边框参数
uniform float border_width : hint_range(0.0, 0.1) = 0.02;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.2, 0.4, 0.8, 1.0);

// 圆角参数（可选）
uniform float corner_radius : hint_range(0.0, 0.5) = 0.0;

// 抗锯齿参数
uniform float smoothness : hint_range(0.001, 0.1) = 0.01;

// 计算到矩形边缘的距离
float rect_sdf(vec2 p, vec2 size, float radius) {
    vec2 d = abs(p) - size + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

void fragment() {
    // 将UV坐标转换为以中心为原点的坐标系
    vec2 uv = UV - 0.5;
    
    // 矩形大小（从中心到边缘的距离）
    vec2 rect_size = vec2(0.5 - border_width);
    
    // 计算到矩形的距离
    float outer_dist = rect_sdf(uv, vec2(0.5), corner_radius);
    float inner_dist = rect_sdf(uv, rect_size, max(0.0, corner_radius - border_width));
    
    // 外边缘的alpha（整个形状）
    float outer_alpha = 1.0 - smoothstep(-smoothness, smoothness, outer_dist);
    
    // 内边缘的alpha（填充区域）
    float inner_alpha = 1.0 - smoothstep(-smoothness, smoothness, inner_dist);
    
    // 边框区域 = 外形状 - 内形状
    float border_alpha = outer_alpha - inner_alpha;
    
    // 混合颜色
    vec3 final_color = mix(border_color.rgb, fill_color.rgb, inner_alpha);
    float final_alpha = max(border_alpha * border_color.a, inner_alpha * fill_color.a);
    
    COLOR = vec4(final_color, final_alpha);
}