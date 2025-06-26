shader_type canvas_item;

// 默认边框相关的uniform变量（新增）
uniform vec4 default_border_color : source_color = vec4(0.5, 0.5, 0.5, 1.0); // 默认边框颜色，默认为灰色
uniform float default_border_width : hint_range(0, 10) = 1.0;                  // 默认边框宽度，默认1像素
uniform int default_border_pattern : hint_range(0, 2) = 0;                     // 默认边框样式：0=菱形，1=圆形，2=方形
uniform bool default_inside = true;                                            // 默认边框位置：true=内边框，false=外边框
uniform bool show_default_border = true;                                       // 是否显示默认边框

// 第二边框相关的uniform变量（原有的border变量）
uniform vec4 border_color : source_color = vec4(1.0);         // 第二边框颜色，默认为白色
uniform float border_width : hint_range(0, 10) = 2.0;         // 第二边框宽度，范围0-10，默认2像素
uniform int border_pattern : hint_range(0, 2) = 0;            // 第二边框样式：0=菱形，1=圆形，2=方形
uniform bool inside = true;                                   // 第二边框位置：true=内边框，false=外边框
uniform bool add_margins = true;                             // 是否添加边距，用于外边框时扩展区域
uniform bool show_border = false;                            // 是否显示第二边框，默认关闭

// 圆角相关的uniform变量
uniform float corner_radius = 3.0;                           // 圆角半径

// 颜色相关的uniform变量
uniform vec4 modulate_color: source_color;                   // 纹理调制颜色

// 渐变相关的uniform变量
uniform bool enable_gradient = false;                        // 是否启用渐变效果
uniform vec4 gradient_color : source_color = vec4(0.0);      // 渐变目标颜色
uniform float gradient_power : hint_range(0.0, 1.0) = 0.5;   // 渐变整体强度
uniform float gradient_threshold : hint_range(0.0, 1.0) = 0.5; // 渐变突变阈值
uniform float gradient_smoothness : hint_range(0.0, 1.0) = 0.1; // 渐变过渡平滑度

// 计算矩形渐变因子
float calculate_gradient_factor(vec2 uv, vec2 size) {
    // 计算到中心的归一化距离
    vec2 center = size * 0.5;
    vec2 delta = abs(uv - center);
    // 使用max来创建矩形渐变效果
    float dist = max(delta.x / center.x, delta.y / center.y);

    // 应用阈值和平滑效果
    float smoothed_factor = smoothstep(
        gradient_threshold - gradient_smoothness,
        gradient_threshold + gradient_smoothness,
        dist
    );

    // 应用渐变强度
    return clamp(smoothed_factor * gradient_power, 0.0, 1.0);
}

// 检查点是否在矩形区域内
bool in_rect(vec2 uv, vec2 orign, vec2 end) {
    return all(lessThan(uv, end)) && all(greaterThan(uv, orign));
}

// 检查是否需要隐藏像素（用于实现圆角效果）
bool is_hid(vec2 uv, vec2 size, float radius) {
    vec2 center = vec2(size.x * 0.5, size.y * 0.5);
    vec2 a = vec2(radius, radius);
    vec2 b = vec2(size.x - radius, size.y - radius);
    vec2 c = vec2(size.x - radius, radius);
    vec2 d = vec2(radius, size.y - radius);

    vec2 rd_origin = vec2(size.x - radius, 0);
    vec2 rd_end = vec2(size.x, radius);
    vec2 lu_origin = vec2(0, size.y - radius);
    vec2 lu_end = vec2(radius, size.y);

    if (!in_rect(uv, a, b)) {
        float dis = radius - 1.0;
        if (in_rect(uv, vec2(0.0), a)) {
            dis = distance(a, uv);
        }
        if (in_rect(uv, b, size)) {
            dis = distance(b, uv);
        }
        if (in_rect(uv, rd_origin, rd_end)) {
            dis = distance(c, uv);
        }
        if (in_rect(uv, lu_origin, lu_end)) {
            dis = distance(d, uv);
        }
        return dis > radius;
    }
    return false;
}

// 检查像素是否应该被圆角隐藏（考虑圆角的边框检测）
bool should_hide_for_corner(vec2 uv, vec2 texture_pixel_size) {
    float pixel_size_x = 1.0 / texture_pixel_size.x;
    float pixel_size_y = 1.0 / texture_pixel_size.y;
    float max_r = min(pixel_size_x, pixel_size_y) / 2.0;
    
    return is_hid(vec2(uv.x * pixel_size_x, uv.y * pixel_size_y),
                  vec2(pixel_size_x, pixel_size_y),
                  min(corner_radius, max_r));
}

// 通用边框检测函数
bool detectBorder(vec2 uv, vec2 texture_pixel_size, sampler2D texture, 
                  float border_w, int border_p, bool is_inside) {
    // 首先检查当前像素是否应该因为圆角而被隐藏
    bool current_hidden = should_hide_for_corner(uv, texture_pixel_size);
    
    // 获取当前像素的alpha值
    float current_alpha = texture(texture, uv).a;
    bool current_transparent = current_alpha <= 0.0 || current_hidden;

    for (float i = -ceil(border_w); i <= ceil(border_w); i++) {
        float x = abs(i) > border_w ? border_w * sign(i) : i;
        float offset;

        if (border_p == 0) {                           // 菱形边框
            offset = border_w - abs(x);
        } else if (border_p == 1) {                    // 圆形边框
            offset = floor(sqrt(pow(border_w + 0.5, 2) - x * x));
        } else if (border_p == 2) {                    // 方形边框
            offset = border_w;
        }

        for (float j = -ceil(offset); j <= ceil(offset); j++) {
            float y = abs(j) > offset ? offset * sign(j) : j;
            vec2 xy = uv + texture_pixel_size * vec2(x, y);

            // 检查采样点是否在纹理范围内
            bool in_bounds = (xy == clamp(xy, vec2(0.0), vec2(1.0)));
            
            // 检查采样点是否应该因为圆角而被隐藏
            bool neighbor_hidden = should_hide_for_corner(xy, texture_pixel_size);
            
            // 检查采样点的alpha值
            float neighbor_alpha = in_bounds ? texture(texture, xy).a : 0.0;
            bool neighbor_transparent = !in_bounds || neighbor_alpha <= 0.0 || neighbor_hidden;

            // 边框检测逻辑：如果当前像素和邻居像素的透明状态不同，则认为是边框
            if (is_inside) {
                // 内边框：当前像素不透明，邻居像素透明
                if (!current_transparent && neighbor_transparent) {
                    return true;
                }
            } else {
                // 外边框：当前像素透明，邻居像素不透明
                if (current_transparent && !neighbor_transparent) {
                    return true;
                }
            }
        }
    }
    return false;
}

// 默认边框检测函数
bool hasDefaultBorder(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
    if (!show_default_border) return false;
    return detectBorder(uv, texture_pixel_size, texture, 
                       default_border_width, default_border_pattern, default_inside);
}

// 第二边框检测函数
bool hasSecondBorder(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
    if (!show_border) return false;
    return detectBorder(uv, texture_pixel_size, texture, 
                       border_width, border_pattern, inside);
}

// 顶点着色器
void vertex() {
    // 计算需要的最大边框宽度来扩展顶点
    float max_border_width = 0.0;
    
    if (add_margins) {
        if (show_default_border && !default_inside) {
            max_border_width = max(max_border_width, default_border_width);
        }
        if (show_border && !inside) {
            max_border_width = max(max_border_width, border_width);
        }
    }
    
    if (max_border_width > 0.0) {
        VERTEX += (UV * 2.0 - 1.0) * max_border_width;
    }
}

// 片段着色器
void fragment() {
    vec2 uv = UV;
    vec4 texture_color;
    bool is_default_border = false;
    bool is_second_border = false;

    // 处理内边框模式
    if ((default_inside && show_default_border) || (inside && show_border)) {
        // 直接使用原始UV坐标采样纹理，不进行缩放
        texture_color = texture(TEXTURE, uv);
        
        // 检查是否是默认边框位置
        if (hasDefaultBorder(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
            is_default_border = true;
        }
        
        // 检查是否是第二边框位置
        if (hasSecondBorder(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
            is_second_border = true;
        }
    }
    // 处理外边框模式或无边框模式
    else {
        // 计算需要调整的最大边框宽度
        float max_border_width = 0.0;
        
        if (add_margins) {
            if (show_default_border && !default_inside) {
                max_border_width = max(max_border_width, default_border_width);
            }
            if (show_border && !inside) {
                max_border_width = max(max_border_width, border_width);
            }
        }
        
        if (add_margins && max_border_width > 0.0) {
            vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(max_border_width * 2.0));
            uv = (uv - texture_pixel_size * max_border_width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
        }

        if (uv == clamp(uv, vec2(0.0), vec2(1.0))) {
            texture_color = texture(TEXTURE, uv);

            if (hasDefaultBorder(UV, TEXTURE_PIXEL_SIZE, TEXTURE)) {
                is_default_border = true;
            }
            
            if (hasSecondBorder(UV, TEXTURE_PIXEL_SIZE, TEXTURE)) {
                is_second_border = true;
            }
        } else {
            texture_color = vec4(0.0);
        }
    }

    // 应用圆角效果
    float pixel_size_x = 1.0 / TEXTURE_PIXEL_SIZE.x;
    float pixel_size_y = 1.0 / TEXTURE_PIXEL_SIZE.y;
    float max_r = min(pixel_size_x, pixel_size_y) / 2.0;

    if (is_hid(vec2(UV.x * pixel_size_x, UV.y * pixel_size_y),
               vec2(pixel_size_x, pixel_size_y),
               min(corner_radius, max_r))) {
        COLOR = vec4(0.0);
    }
    // 应用最终颜色
    else {
        // 边框优先级：第二边框 > 默认边框 > 纹理内容
        if (is_second_border && show_border) {
            COLOR = border_color;
        } else if (is_default_border && show_default_border) {
            COLOR = default_border_color;
        } else {
            vec4 final_color = texture_color * modulate_color;

            // 应用渐变效果（只对非边框区域）
            if (enable_gradient) {
                float gradient_factor = calculate_gradient_factor(
                    vec2(UV.x * pixel_size_x, UV.y * pixel_size_y),
                    vec2(pixel_size_x, pixel_size_y)
                );
                final_color = mix(final_color, gradient_color, gradient_factor);
            }

            COLOR = final_color;
        }
    }
}