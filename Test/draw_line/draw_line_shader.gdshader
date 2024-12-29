shader_type spatial;

render_mode blend_add, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx, unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

// 用户传入的颜色参数
uniform vec4 ColorParameter : source_color;
// 纹理
uniform sampler2D tex_frg_2;

//
//void vertex() {
    //// 使用内置的 VIEW_MATRIX 和 MODEL_MATRIX 获取矩阵
    //mat4 view_matrix = VIEW_MATRIX;    // 获取摄像机视图矩阵
    //mat4 model_matrix = MODEL_MATRIX;  // 获取模型的世界空间矩阵
//
    //// 计算模型的位置
    //vec3 model_position = (model_matrix * vec4(VERTEX, 1.0)).xyz;
//
    //// 计算摄像机的位置
    //vec3 camera_position = (view_matrix * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
//
    //// 计算从物体到摄像机的方向
    //vec3 to_camera = normalize(camera_position - model_position);
//
    //// 创建一个面向摄像机的旋转矩阵
    //mat4 billboard_matrix = mat4(1.0);
    //billboard_matrix[0] = vec4(to_camera.x, 0.0, 0.0, 0.0);  // X轴方向
    //billboard_matrix[1] = vec4(0.0, 1.0, 0.0, 0.0);          // Y轴方向
    //billboard_matrix[2] = vec4(to_camera.z, 0.0, 0.0, 0.0);  // Z轴方向
//
    //// 通过矩阵变换更新顶点
    //vec4 camera_offset = billboard_matrix * vec4(VERTEX, 1.0);
    //VERTEX = camera_offset.xyz;  // 更新顶点
//}




void fragment() {
    // 颜色参数（原始）
    vec4 n_out8p0 = ColorParameter;

    // 获取时间
    float n_out6p0 = TIME;

    // 设置纹理坐标的变换（按时间动态变化）
    vec2 n_in5p1 = vec2(0.00000, 0.500000);
    vec2 n_out5p0 = vec2(n_out6p0) * n_in5p1;

    // 调整纹理坐标
    vec2 n_in4p1 = vec2(0.00000, 1.00000);
    vec2 n_out4p0 = n_out5p0 * n_in4p1 + UV;

    // 采样纹理
    vec4 n_out2p0 = texture(tex_frg_2, n_out4p0);

    // 颜色计算：将颜色参数与纹理颜色进行混合
    vec3 n_out7p0 = vec3(1.0) - (vec3(1.0) - vec3(n_out8p0.xyz)) * (vec3(1.0) - vec3(n_out2p0.xyz));

    // 提取纹理颜色的透明度
    float n_out3p3 = n_out2p0.w;

    // 输出颜色和透明度
    ALBEDO = n_out7p0;
    ALPHA = n_out3p3;
}
