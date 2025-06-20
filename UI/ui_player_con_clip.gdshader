shader_type canvas_item;

// 边框控制参数
uniform float border_width : hint_range(0.0, 0.1, 0.001) = 0.02;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// 内部渐变参数
uniform vec4 inner_color_start : source_color = vec4(0.2, 0.4, 1.0, 1.0);
uniform vec4 inner_color_end : source_color = vec4(1.0, 0.2, 0.4, 1.0);
uniform float gradient_angle : hint_range(0.0, 360.0, 1.0) = 45.0;

// 旋转动画参数
uniform float rotation_speed : hint_range(-10.0, 10.0, 0.1) = 1.0;
uniform bool animate_border = true;
uniform bool animate_gradient = false;

// 边框样式参数
uniform float border_softness : hint_range(0.0, 0.05, 0.001) = 0.005;
uniform bool use_rainbow_border = false;
uniform bool circular_border = false;

varying vec2 world_position;

vec2 rotate_point(vec2 point, vec2 center, float angle) {
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    vec2 relative = point - center;
    return vec2(
        relative.x * cos_angle - relative.y * sin_angle,
        relative.x * sin_angle + relative.y * cos_angle
    ) + center;
}

vec3 hsv_to_rgb(vec3 hsv) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

void vertex() {
    world_position = VERTEX;
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    
    float min_edge_dist;
    bool is_outside_circle = false;
    
    if (circular_border) {
        // 圆形边框 - 基于到中心的距离
        float dist_to_center = distance(uv, center);
        float max_radius = 0.5;
        min_edge_dist = max_radius - dist_to_center;
        
        // 检查是否超出圆形范围
        is_outside_circle = dist_to_center > max_radius;
    } else {
        // 矩形边框 - 基于到边缘的距离
        vec2 edge_dist = vec2(
            min(uv.x, 1.0 - uv.x),
            min(uv.y, 1.0 - uv.y)
        );
        min_edge_dist = min(edge_dist.x, edge_dist.y);
    }
    
    if (is_outside_circle) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        // 边框遮罩
        float border_mask = 1.0 - smoothstep(border_width - border_softness, border_width + border_softness, min_edge_dist);
        
        // 内部区域遮罩
        float inner_mask = 1.0 - border_mask;
        
        // 计算旋转后的UV坐标
        vec2 rotated_uv = uv;
        if (animate_border || animate_gradient) {
            float time_angle = TIME * rotation_speed;
            if (animate_border) {
                // 用于边框动画的旋转UV
            }
            if (animate_gradient) {
                rotated_uv = rotate_point(uv, center, time_angle);
            }
        }
        
        // 计算边框颜色
        vec4 final_border_color = border_color;
        if (use_rainbow_border) {
            float angle = atan(uv.y - center.y, uv.x - center.x);
            if (animate_border) {
                angle += TIME * rotation_speed;
            }
            float hue = (angle + PI) / (2.0 * PI);
            final_border_color.rgb = hsv_to_rgb(vec3(hue, 1.0, 1.0));
            final_border_color.a = border_color.a;
        }
        
        // 计算内部渐变
        float gradient_rad = radians(gradient_angle);
        vec2 gradient_uv = rotated_uv;
        float gradient_factor = dot(gradient_uv - center, vec2(cos(gradient_rad), sin(gradient_rad))) + 0.5;
        gradient_factor = clamp(gradient_factor, 0.0, 1.0);
        
        vec4 inner_color = mix(inner_color_start, inner_color_end, gradient_factor);
        
        // 混合最终颜色
        COLOR = mix(inner_color, final_border_color, border_mask);
    }
}