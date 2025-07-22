shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

void fragment() {
    // 半径渐变
    float radius = length(UV - vec2(0.5));
    float radial_fade = smoothstep(0.4, 0.0, radius);

    // 高度渐变（UV.y）
    float height_fade = smoothstep(1.0, 0.0, UV.y);

    // 最终 alpha = 中心亮 + 顶部亮
    float alpha = radial_fade * height_fade;

    ALBEDO = vec3(1.0, 1.0, 0.8); // 偏金色或白色
    ALPHA = alpha * 0.3; // 可调节亮度
}
