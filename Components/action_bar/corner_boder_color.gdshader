shader_type canvas_item;

// Border uniforms
uniform vec4 border_color : source_color = vec4(1.0);
uniform float border_width : hint_range(0, 10) = 2.0;
uniform int border_pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool inside = true;
uniform bool add_margins = true;
uniform bool show_border = true; // 新增：控制边框显示

// Corner and color uniforms
uniform float corner_radius = 3.0;
uniform vec4 modulate_color: source_color;

// Border functions
bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
    if (!show_border) return false; // 如果不显示边框，直接返回false

    for (float i = -ceil(border_width); i <= ceil(border_width); i++) {
        float x = abs(i) > border_width ? border_width * sign(i) : i;
        float offset;

        if (border_pattern == 0) {
            offset = border_width - abs(x);
        } else if (border_pattern == 1) {
            offset = floor(sqrt(pow(border_width + 0.5, 2) - x * x));
        } else if (border_pattern == 2) {
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

// Corner functions
bool in_rect(vec2 uv, vec2 orign, vec2 end) {
    return all(lessThan(uv, end)) && all(greaterThan(uv, orign));
}

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

void vertex() {
    // 只在显示外边框时调整顶点位置
    if (add_margins && !inside && show_border) {
        VERTEX += (UV * 2.0 - 1.0) * border_width;
    }
}

void fragment() {
    vec2 uv = UV;
    vec4 texture_color;
    bool is_border = false;

    // 处理纹理UV映射
    if (inside && show_border) {
        // 内边框模式
        vec2 border_uv = uv;
        vec2 texture_uv = uv;

        // 检查是否在边框区域
        if (hasContraryNeighbour(border_uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
            is_border = true;
        }

        // 缩放纹理UV以适应内边框
        float scale = max(0.0001, 1.0 - (2.0 * border_width * TEXTURE_PIXEL_SIZE.x));
        texture_uv = (texture_uv - 0.5) / scale + 0.5;

        if (texture_uv == clamp(texture_uv, vec2(0.0), vec2(1.0))) {
            texture_color = texture(TEXTURE, texture_uv);
        } else {
            texture_color = vec4(0.0);
        }
    } else {
        // 外边框模式或无边框模式
        if (add_margins && show_border && !inside) {
            vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(border_width * 2.0));
            uv = (uv - texture_pixel_size * border_width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
        }

        if (uv == clamp(uv, vec2(0.0), vec2(1.0))) {
            texture_color = texture(TEXTURE, uv);

            // 只在显示边框时检查边框区域
            if (show_border && hasContraryNeighbour(UV, TEXTURE_PIXEL_SIZE, TEXTURE)) {
                is_border = true;
            }
        } else {
            texture_color = vec4(0.0);
        }
    }

    // 应用圆角
    float pixel_size_x = 1.0 / TEXTURE_PIXEL_SIZE.x;
    float pixel_size_y = 1.0 / TEXTURE_PIXEL_SIZE.y;
    float max_r = min(pixel_size_x, pixel_size_y) / 2.0;

    if (is_hid(vec2(UV.x * pixel_size_x, UV.y * pixel_size_y),
               vec2(pixel_size_x, pixel_size_y),
               min(corner_radius, max_r))) {
        COLOR = vec4(0.0);
    } else {
        // 分别处理边框和纹理的颜色
        if (is_border && show_border) {
            // 边框使用border_color
            COLOR = border_color;
        } else {
            // 纹理使用modulate_color
            COLOR = texture_color * modulate_color;
        }
    }
}