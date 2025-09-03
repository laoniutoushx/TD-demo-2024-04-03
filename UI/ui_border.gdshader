shader_type canvas_item;

// 边框宽度控制
uniform float border_width_px : hint_range(0.0, 10.0) = 2.0;

// 四个边框的颜色
uniform vec4 top_border_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 right_border_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 bottom_border_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 left_border_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);

// 四个边框的渐变程度（0.0 = 硬边缘，1.0 = 最大渐变）
uniform float top_gradient : hint_range(0.0, 1.0) = 0.0;
uniform float right_gradient : hint_range(0.0, 1.0) = 0.0;
uniform float bottom_gradient : hint_range(0.0, 1.0) = 0.0;
uniform float left_gradient : hint_range(0.0, 1.0) = 0.0;

// 填充色
uniform vec4 fill_color : source_color = vec4(0.2, 0.4, 0.8, 1.0);

// 圆角和平滑度
uniform float corner_radius_px : hint_range(0.0, 50.0) = 0.0;
uniform float smoothness_px : hint_range(0.1, 5.0) = 1.0;

float rect_sdf(vec2 p, vec2 size, float radius) {
    vec2 d = abs(p) - size + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

// 计算到各边的权重，基于到边的距离
vec4 get_border_weights(vec2 uv_centered, vec2 half_size, float border_width_uv, float corner_radius_uv) {
    vec4 weights = vec4(0.0);

    // 计算到各边的距离（不考虑圆角）
    float top_dist = half_size.y + uv_centered.y;
    float right_dist = half_size.x - uv_centered.x;
    float bottom_dist = half_size.y - uv_centered.y;
    float left_dist = half_size.x + uv_centered.x;

    // 在圆角区域，我们需要特殊处理
    vec2 abs_uv = abs(uv_centered);
    vec2 corner_center = half_size - vec2(corner_radius_uv);

    // 检查是否在圆角区域
    bool in_corner = abs_uv.x > corner_center.x && abs_uv.y > corner_center.y;

    if (in_corner && corner_radius_uv > 0.0) {
        // 在圆角区域，基于相对位置来分配权重
        vec2 corner_pos = abs_uv - corner_center;

        // 使用归一化的坐标来计算权重，避免角度计算的复杂性
        float total_dist = corner_pos.x + corner_pos.y;
        if (total_dist > 0.0) {
            float x_factor = corner_pos.x / total_dist;
            float y_factor = corner_pos.y / total_dist;

            // 确定在哪个象限并分配权重
            if (uv_centered.x > 0.0 && uv_centered.y < 0.0) {
                // 右上角：x增加时偏向右边框，y增加时偏向上边框
                weights.y = x_factor; // 右边框
                weights.x = y_factor; // 上边框
            } else if (uv_centered.x > 0.0 && uv_centered.y > 0.0) {
                // 右下角：x增加时偏向右边框，y增加时偏向下边框
                weights.y = x_factor; // 右边框
                weights.z = y_factor; // 下边框
            } else if (uv_centered.x < 0.0 && uv_centered.y > 0.0) {
                // 左下角：x增加时偏向左边框，y增加时偏向下边框
                weights.w = x_factor; // 左边框
                weights.z = y_factor; // 下边框
            } else {
                // 左上角：x增加时偏向左边框，y增加时偏向上边框
                weights.w = x_factor; // 左边框
                weights.x = y_factor; // 上边框
            }
        }
    } else {
        // 不在圆角区域，使用基于距离的权重
        if (top_dist < border_width_uv) {
            weights.x = 1.0;
        }
        if (right_dist < border_width_uv) {
            weights.y = 1.0;
        }
        if (bottom_dist < border_width_uv) {
            weights.z = 1.0;
        }
        if (left_dist < border_width_uv) {
            weights.w = 1.0;
        }

        // 在边缘交接处，需要混合权重
        float total = weights.x + weights.y + weights.z + weights.w;
        if (total > 1.0) {
            weights /= total;
        }
    }

    return weights;
}

void fragment() {
    // 计算纹理的像素尺寸
    vec2 texture_size = 1.0 / fwidth(UV);

    // 使用较小的尺寸作为基准
    float min_size = min(texture_size.x, texture_size.y);

    // 将像素值转换为UV空间
    float corner_radius_uv = corner_radius_px / min_size;
    float border_width_uv = border_width_px / min_size;
    float smoothness_uv = smoothness_px / min_size;

    // 计算UV坐标，按纹理比例调整
    vec2 aspect_ratio = texture_size / min_size;
    vec2 uv_centered = (UV - vec2(0.5)) * aspect_ratio;

    // UV空间中的半尺寸
    vec2 half_size = aspect_ratio * 0.5;
    vec2 rect_size = half_size - vec2(border_width_uv);

    // 计算SDF距离
    float outer_dist = rect_sdf(uv_centered, half_size, corner_radius_uv);
    float inner_dist = rect_sdf(uv_centered, rect_size, max(0.0, corner_radius_uv - border_width_uv));

    // 创建基本的形状遮罩
    float outer_alpha = 1.0 - smoothstep(-smoothness_uv, smoothness_uv, outer_dist);
    float inner_alpha = 1.0 - smoothstep(-smoothness_uv, smoothness_uv, inner_dist);

    vec3 final_color = vec3(0.0);
    float final_alpha = 0.0;

    // 如果在填充区域内，使用填充色
    if (inner_alpha > 0.5) {
        final_color = fill_color.rgb;
        final_alpha = fill_color.a;
    }
    // 如果完全在形状外，使用透明
    else if (outer_alpha < 0.01) {
        final_color = vec3(0.0);
        final_alpha = 0.0;
    }
    // 在边框区域内，计算边框颜色
    else {
        // 获取边框权重
        vec4 border_weights = get_border_weights(uv_centered, half_size, border_width_uv, corner_radius_uv);

        // 应用渐变效果
        float distance_to_outer = max(0.0, -outer_dist);
        float distance_to_inner = max(0.0, inner_dist);
        float border_progress = distance_to_inner / (distance_to_inner + distance_to_outer);

        // 对每个边框应用渐变
        vec4 gradient_factors = vec4(
            mix(1.0, border_progress, top_gradient),
            mix(1.0, border_progress, right_gradient),
            mix(1.0, border_progress, bottom_gradient),
            mix(1.0, border_progress, left_gradient)
        );

        border_weights *= gradient_factors;

        // 归一化权重
        float total_weight = border_weights.x + border_weights.y + border_weights.z + border_weights.w;
        if (total_weight > 0.0) {
            border_weights /= total_weight;
        }

        // 混合边框颜色
        final_color += top_border_color.rgb * border_weights.x;
        final_color += right_border_color.rgb * border_weights.y;
        final_color += bottom_border_color.rgb * border_weights.z;
        final_color += left_border_color.rgb * border_weights.w;

        final_alpha += top_border_color.a * border_weights.x;
        final_alpha += right_border_color.a * border_weights.y;
        final_alpha += bottom_border_color.a * border_weights.z;
        final_alpha += left_border_color.a * border_weights.w;

        // 应用外部形状遮罩
        final_alpha *= outer_alpha;
    }

    COLOR = vec4(final_color, final_alpha);
}