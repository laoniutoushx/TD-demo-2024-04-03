shader_type canvas_item;

// 背景颜色设置
uniform vec4 bg_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform bool use_gradient = false;
uniform vec4 gradient_color_2 : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform int gradient_direction : hint_range(0, 3, 1) = 0; // 0:水平, 1:垂直, 2:对角线, 3:径向

// 图案设置
uniform bool use_pattern = false;
uniform int pattern_type : hint_range(0, 3, 1) = 0; // 0:网格, 1:圆点, 2:条纹, 3:棋盘
uniform float pattern_scale : hint_range(0.1, 20.0, 0.1) = 5.0;
uniform vec4 pattern_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);

// 边框设置
uniform float border_width : hint_range(0.0, 20.0, 0.1) = 2.0;
uniform vec4 border_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform bool border_gradient = false;
uniform vec4 border_gradient_color_2 : source_color = vec4(1.0, 0.5, 0.2, 1.0);

// 圆角设置 - 精确控制四个角
uniform float corner_radius_tl : hint_range(0.0, 50.0, 0.1) = 5.0; // 左上
uniform float corner_radius_tr : hint_range(0.0, 50.0, 0.1) = 5.0; // 右上
uniform float corner_radius_bl : hint_range(0.0, 50.0, 0.1) = 5.0; // 左下
uniform float corner_radius_br : hint_range(0.0, 50.0, 0.1) = 5.0; // 右下
uniform float smoothness : hint_range(0.1, 5.0, 0.1) = 1.0; // 平滑度

// 鼠标悬浮效果
uniform bool mouse_hover = false;
uniform float hover_intensity : hint_range(0.0, 2.0, 0.1) = 1.2;
uniform vec4 hover_color : source_color = vec4(1.0, 1.0, 1.0, 0.2);
uniform bool use_hover_slide = false;
uniform float slide_position : hint_range(-1.0, 2.0, 0.01) = 0.0;
uniform float slide_width : hint_range(0.1, 2.0, 0.1) = 0.3;
uniform vec4 slide_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);

// 时间变量用于动画
uniform float time : hint_range(0.0, 100.0) = 0.0;

// 改进的圆角矩形SDF
float rounded_rect_sdf(vec2 p, vec2 size, vec4 radius) {
    // 选择当前象限的圆角半径
    float r;
    if (p.x > 0.0 && p.y < 0.0) {
        r = radius.y; // 右上 
    } else if (p.x <= 0.0 && p.y < 0.0) {
        r = radius.x; // 左上
    } else if (p.x <= 0.0 && p.y >= 0.0) {
        r = radius.z; // 左下
    } else {
        r = radius.w; // 右下
    }
    
    vec2 d = abs(p) - size + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

// 生成渐变
vec4 get_gradient(vec2 uv, vec4 color1, vec4 color2, int direction) {
    float t = 0.0;
    switch(direction) {
        case 0: // 水平
            t = uv.x;
            break;
        case 1: // 垂直
            t = uv.y;
            break;
        case 2: // 对角线
            t = (uv.x + uv.y) * 0.5;
            break;
        case 3: // 径向
            t = distance(uv, vec2(0.5));
            break;
    }
    return mix(color1, color2, t);
}

// 生成图案
float get_pattern(vec2 uv, int type, float scale) {
    vec2 p = uv * scale;
    float pattern = 0.0;
    
    switch(type) {
        case 0: // 网格
            pattern = max(
                step(0.9, fract(p.x)),
                step(0.9, fract(p.y))
            );
            break;
        case 1: // 圆点
            vec2 grid = fract(p) - 0.5;
            pattern = 1.0 - smoothstep(0.1, 0.2, length(grid));
            break;
        case 2: // 条纹
            pattern = step(0.5, fract(p.x));
            break;
        case 3: // 棋盘
            pattern = step(0.5, fract(p.x)) * step(0.5, fract(p.y)) + 
                     (1.0 - step(0.5, fract(p.x))) * (1.0 - step(0.5, fract(p.y)));
            break;
    }
    
    return pattern;
}

void fragment() {
    vec2 uv = UV;
    
    // 计算纹理的像素尺寸 - 参考方法
    vec2 texture_size = 1.0 / fwidth(uv);
    float min_size = min(texture_size.x, texture_size.y);
    
    // 将像素值转换为UV空间
    float corner_radius_tl_uv = corner_radius_tl / min_size;
    float corner_radius_tr_uv = corner_radius_tr / min_size;
    float corner_radius_bl_uv = corner_radius_bl / min_size;
    float corner_radius_br_uv = corner_radius_br / min_size;
    float border_width_uv = border_width / min_size;
    float smoothness_uv = smoothness / min_size;
    
    // 计算UV坐标，按纹理比例调整
    vec2 aspect_ratio = texture_size / min_size;
    vec2 uv_centered = (uv - vec2(0.5)) * aspect_ratio;
    
    // UV空间中的半尺寸
    vec2 half_size = aspect_ratio * 0.5;
    vec2 inner_size = half_size - vec2(border_width_uv);
    
    // 圆角半径
    vec4 radius = vec4(corner_radius_tl_uv, corner_radius_tr_uv, corner_radius_bl_uv, corner_radius_br_uv);
    vec4 inner_radius = max(vec4(0.0), radius - vec4(border_width_uv));
    
    // 计算SDF距离
    float outer_dist = rounded_rect_sdf(uv_centered, half_size, radius);
    float inner_dist = rounded_rect_sdf(uv_centered, inner_size, inner_radius);
    
    // 创建基本的形状遮罩
    float outer_alpha = 1.0 - smoothstep(-smoothness_uv, smoothness_uv, outer_dist);
    float inner_alpha = 1.0 - smoothstep(-smoothness_uv, smoothness_uv, inner_dist);
    
    // 基础背景颜色
    vec4 bg = bg_color;
    
    // 应用渐变背景
    if (use_gradient) {
        bg = get_gradient(uv, bg_color, gradient_color_2, gradient_direction);
    }
    
    // 应用图案
    if (use_pattern) {
        float pattern = get_pattern(uv, pattern_type, pattern_scale);
        bg = mix(bg, pattern_color, pattern * pattern_color.a);
    }
    
    // 边框颜色
    vec4 border_col = border_color;
    if (border_gradient) {
        border_col = get_gradient(uv, border_color, border_gradient_color_2, gradient_direction);
    }
    
    // 最终颜色计算
    vec4 final_color = vec4(0.0);
    
    // 如果在填充区域内，使用背景色
    if (inner_alpha > 0.01) {
        final_color = bg;
        final_color.a *= inner_alpha;
    }
    
    // 如果在边框区域内，使用边框色
    float border_alpha = outer_alpha - inner_alpha;
    if (border_alpha > 0.01) {
        final_color = mix(final_color, border_col, border_alpha / max(outer_alpha, 0.001));
        final_color.a = max(final_color.a, border_alpha * border_col.a);
    }
    
    // 应用整体透明度
    final_color.a *= outer_alpha;
    
    // 鼠标悬浮效果
    if (mouse_hover && outer_alpha > 0.01) {
        // 高亮效果
        final_color.rgb *= hover_intensity;
        final_color = mix(final_color, hover_color, hover_color.a * outer_alpha);
        
        // 滑动光效
        if (use_hover_slide) {
            vec2 slide_uv = uv - vec2(slide_position - 0.5, 0.0);
            float slide_strength = 1.0 - smoothstep(0.0, slide_width, abs(slide_uv.x));
            slide_strength *= smoothstep(-0.1, 0.1, slide_uv.x) * smoothstep(0.6, -0.1, slide_uv.x);
            final_color = mix(final_color, slide_color, slide_strength * slide_color.a * outer_alpha);
        }
    }
    
    COLOR = final_color;
}