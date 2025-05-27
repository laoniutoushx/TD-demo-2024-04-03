shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque,  blend_mix;

// 圆环控制参数
uniform int ring_count : hint_range(1, 20) = 5;
uniform float ring_radius : hint_range(0.1, 1.0) = 0.5;
uniform float ring_width : hint_range(0.01, 0.3) = 0.05;
uniform float ring_spacing : hint_range(0.01, 1.0) = 0.1; // 圆环之间的时间偏移

uniform vec4 ring_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// 动画参数
uniform float shrink_speed : hint_range(0.1, 5.0) = 1.0;
uniform bool auto_restart = true;
uniform float animation_offset : hint_range(0.0, 10.0) = 0.0;
uniform bool expand_mode = false; // false: 向内收缩，true: 向外扩散

// 视觉效果参数
uniform bool enable_gradient = false;
uniform vec4 gradient_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;

// 透明度控制
uniform float base_alpha : hint_range(0.0, 1.0) = 1.0;
uniform bool fade_on_shrink = true;

void vertex() {
    VERTEX = VERTEX;
}

void fragment() {
    vec2 center_uv = UV - vec2(0.5);
    float distance_from_center = length(center_uv);
    float final_alpha = 0.0;
    vec3 final_rgb = vec3(0.0);

    for (int i = 0; i < ring_count; i++) {
        float offset = float(i) * ring_spacing + animation_offset;
        float t = TIME * shrink_speed + offset;

        // 动画进度控制：收缩（1->0）或扩散（0->1）
        float progress = auto_restart ? fract(t) : clamp(t, 0.0, 1.0);
        float shrink_t = expand_mode ? progress : (1.0 - progress);

        float current_radius = ring_radius * shrink_t;

        float outer_radius = current_radius + ring_width * 0.5;
        float inner_radius = max(0.0, current_radius - ring_width * 0.5);

        float outer_mask = 1.0 - smoothstep(outer_radius - edge_softness, outer_radius + edge_softness, distance_from_center);
        float inner_mask = smoothstep(inner_radius - edge_softness, inner_radius + edge_softness, distance_from_center);
        float ring_mask = outer_mask * inner_mask;

        float alpha_multiplier = base_alpha;
        if (fade_on_shrink) {
            alpha_multiplier *= shrink_t;
        }

        vec4 this_color = ring_color;

        if (enable_gradient && ring_width > 0.0) {
            float gradient_factor = (distance_from_center - inner_radius) / ring_width;
            gradient_factor = clamp(gradient_factor, 0.0, 1.0);
            this_color = mix(gradient_color, ring_color, gradient_factor);
        }

        this_color.a *= ring_mask * alpha_multiplier;

        // 累加颜色和 alpha（透明通道混合）
        final_rgb += this_color.rgb * this_color.a;
        final_alpha += this_color.a;
    }

    ALBEDO = final_rgb;
    ALPHA = clamp(final_alpha, 0.0, 1.0);
}
