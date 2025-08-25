shader_type canvas_item;
render_mode unshaded;

// 渐变参数
uniform vec4 start_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // 渐变起始颜色
uniform vec4 end_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);   // 渐变结束颜色
uniform float gradient_direction : hint_range(0.0, 360.0) = 0.0;    // 渐变方向（角度，0-360）
uniform float intensity : hint_range(0.0, 2.0) = 1.0;                // 渐变强度

// 边框参数
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 边框颜色
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.0;        // 边框厚度

// 阴影参数
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5); // 阴影颜色
uniform float shadow_offset_x : hint_range(-10.0, 10.0) = 2.0;       // 阴影 X 偏移
uniform float shadow_offset_y : hint_range(-10.0, 10.0) = 2.0;       // 阴影 Y 偏移

void fragment() {
    // 获取原始纹理颜色和透明度
    vec4 tex_color = texture(TEXTURE, UV);
    float texture_alpha = tex_color.a;

    // 计算渐变方向
    float rad = radians(gradient_direction);
    vec2 dir = vec2(cos(rad), sin(rad));

    // 计算渐变因子（基于 UV 和方向）
    float gradient_factor = dot(UV, dir);
    gradient_factor = clamp(gradient_factor, 0.0, 1.0);

    // 混合渐变颜色
    vec4 gradient_color = mix(start_color, end_color, gradient_factor) * intensity;

    // 应用渐变到文本（保留原始透明度）
    vec4 final_color = vec4(gradient_color.rgb, texture_alpha);

    // 边框效果
    if (outline_thickness > 0.0) {
        float outline = 0.0;
        for (float x = -outline_thickness; x <= outline_thickness; x += 0.001) {
            for (float y = -outline_thickness; y <= outline_thickness; y += 0.001) {
                outline += texture(TEXTURE, UV + vec2(x, y)).a;
            }
        }
        if (outline > texture_alpha) {
            final_color = mix(outline_color, final_color, texture_alpha);
        }
    }

    // 阴影效果
    vec4 shadow = texture(TEXTURE, UV + vec2(shadow_offset_x, shadow_offset_y) * 0.01);
    if (shadow.a > 0.0 && texture_alpha == 0.0) {
        final_color = shadow_color * shadow.a;
    }

    // 最终颜色输出
    COLOR = final_color;
}