shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded, ambient_light_disabled, fog_disabled;

uniform vec3 light_pos; // 光源位置（世界空间）
uniform vec4 light_color = vec4(1.0, 1.0, 1.0, 1.0); // 光颜色和强度
uniform float density = 0.1; // 体积密度
uniform vec3 CAMERA_POSITION; // Declared globally in the shader

void fragment() {
    vec3 ray_origin = CAMERA_POSITION; // 相机位置
    vec3 ray_dir = normalize(VERTEX - CAMERA_POSITION); // 从相机到顶点的方向
    vec3 pos = VERTEX; // 当前片段的世界位置

    float total_light = 0.0;
    float step_size = 0.1;
    int steps = 50;

    // 简单光线步进
    for (int i = 0; i < steps; i++) {
        vec3 to_light = light_pos - pos;
        float dist = length(to_light);
        float light_intensity = 1.0 / (dist * dist); // 光强随距离平方衰减
        total_light += light_intensity * density * step_size;
        pos += ray_dir * step_size;
        // 检查是否超出网格边界（简化处理）
        if (dist < step_size || total_light > 1.0) break;
    }

    ALBEDO = light_color.rgb * total_light;
    ALPHA = total_light * light_color.a;
}