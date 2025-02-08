shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform sampler2D texture_albedo : source_color;
uniform vec4 modulate : source_color = vec4(1.0);
uniform float rotation_speed : hint_range(-5.0, 5.0) = 1.0;

void vertex() {
    // 计算自动旋转
    float rotation = TIME * rotation_speed;

    // 创建旋转矩阵
    mat3 rotation_matrix = mat3(
        vec3(cos(rotation), 0.0, -sin(rotation)),
        vec3(0.0, 1.0, 0.0),
        vec3(sin(rotation), 0.0, cos(rotation))
    );

    // 应用旋转
    VERTEX = rotation_matrix * VERTEX;
}

void fragment() {
    // 获取纹理颜色
    vec4 albedo_tex = texture(texture_albedo, UV);

    // 应用颜色调制
    ALBEDO = albedo_tex.rgb * modulate.rgb;

    // 设置透明度
    ALPHA = albedo_tex.a * modulate.a;
}