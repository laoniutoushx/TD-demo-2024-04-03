shader_type canvas_item;

// 边框参数
uniform float border_width : hint_range(0.0, 50.0) = 5.0;

// 边框渐变色参数
uniform vec4 border_start_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // 边框左侧颜色
uniform vec4 border_end_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);   // 边框右侧颜色

// 可选：边框平滑度
uniform float border_smoothness : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
    
    // 计算像素级别的边框宽度（确保在不同长宽比下一致）
    float border_pixels = border_width / size.x;
    
    // 计算到各边缘的距离
    float left_dist = uv.x;
    float right_dist = 1.0 - uv.x;
    float top_dist = uv.y;
    float bottom_dist = 1.0 - uv.y;
    
    // 判断是否在边框区域
    bool in_left_border = left_dist < border_pixels;
    bool in_right_border = right_dist < border_pixels;
    bool in_top_border = top_dist < border_pixels;
    bool in_bottom_border = bottom_dist < border_pixels;
    
    // 检查是否在边框内（任意一条边）
    bool in_border = in_left_border || in_right_border || in_top_border || in_bottom_border;
    
    if (in_border) {
        // 在边框区域内，根据水平位置计算渐变色
        vec4 gradient_color = mix(border_start_color, border_end_color, uv.x);
        
        // 计算边框的平滑过渡
        float min_dist_to_edge = min(min(left_dist, right_dist), min(top_dist, bottom_dist));
        float border_alpha = 1.0;
        
        // 如果需要平滑边缘
        if (border_smoothness > 0.0) {
            border_alpha = smoothstep(0.0, border_smoothness / size.x, min_dist_to_edge);
        }
        
        COLOR = vec4(gradient_color.rgb, gradient_color.a * border_alpha);
    } else {
        // 不在边框区域，完全透明
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}