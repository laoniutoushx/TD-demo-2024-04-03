shader_type canvas_item;

// 边框相关的uniform变量
uniform vec4 border_color : source_color = vec4(1.0);         // 边框颜色，默认为白色
uniform float border_width : hint_range(0, 10) = 2.0;         // 边框宽度，范围0-10，默认2像素
uniform int border_pattern : hint_range(0, 2) = 0;            // 边框样式：0=菱形，1=圆形，2=方形
uniform bool inside = true;                                   // 边框位置：true=内边框，false=外边框
uniform bool add_margins = true;                             // 是否添加边距，用于外边框时扩展区域
uniform bool show_border = true;                             // 是否显示边框

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

// 边框检测函数
bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
    if (!show_border) return false;                          // 如果不显示边框，直接返回false

    for (float i = -ceil(border_width); i <= ceil(border_width); i++) {
        float x = abs(i) > border_width ? border_width * sign(i) : i;
        float offset;

        if (border_pattern == 0) {                           // 菱形边框
            offset = border_width - abs(x);
        } else if (border_pattern == 1) {                    // 圆形边框
            offset = floor(sqrt(pow(border_width + 0.5, 2) - x * x));
        } else if (border_pattern == 2) {                    // 方形边框
            offset = border_width;
        }

        for (float j = -ceil(offset); j <= ceil(offset); j++) {
            float y = abs(j) > offset ? offset * sign(j) : j;
            vec2 xy = uv + texture_pixel_size * vec2(x, y);

            if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == inside) {
                return true;
            }
        }
    }
    return false;
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

// 顶点着色器
void vertex() {
    if (add_margins && !inside && show_border) {
        VERTEX += (UV * 2.0 - 1.0) * border_width;
    }
}

// 片段着色器
void fragment() {
    vec2 uv = UV;
    vec4 texture_color;
    bool is_border = false;

    // 处理内边框模式
    if (inside && show_border) {
        vec2 border_uv = uv;
        vec2 texture_uv = uv;

        if (hasContraryNeighbour(border_uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
            is_border = true;
        }

        float scale = max(0.0001, 1.0 - (2.0 * border_width * TEXTURE_PIXEL_SIZE.x));
        texture_uv = (texture_uv - 0.5) / scale + 0.5;

        if (texture_uv == clamp(texture_uv, vec2(0.0), vec2(1.0))) {
            texture_color = texture(TEXTURE, texture_uv);
        } else {
            texture_color = vec4(0.0);
        }
    }
    // 处理外边框模式或无边框模式
    else {
        if (add_margins && show_border && !inside) {
            vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(border_width * 2.0));
            uv = (uv - texture_pixel_size * border_width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
        }

        if (uv == clamp(uv, vec2(0.0), vec2(1.0))) {
            texture_color = texture(TEXTURE, uv);

            if (show_border && hasContraryNeighbour(UV, TEXTURE_PIXEL_SIZE, TEXTURE)) {
                is_border = true;
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
        if (is_border && show_border) {
            COLOR = border_color;
        } else {
            vec4 final_color = texture_color * modulate_color;

            // 应用渐变效果
            if (enable_gradient && !is_border) {
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