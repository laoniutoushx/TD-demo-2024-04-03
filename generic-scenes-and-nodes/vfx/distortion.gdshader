shader_type spatial;
render_mode world_vertex_coords, unshaded, cull_disabled ; // 关键：启用世界坐标计算

uniform vec3 center;    // 冲击波中心（世界坐标）
uniform float radius;   // 当前半径
uniform float strength; // 扭曲强度

void vertex() {
    // 正确获取世界坐标的两种方式：
    // 方式1：使用内置转换 (需启用render_mode world_vertex_coords)
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // 方式2：手动计算
    // vec3 world_pos = (CAMERA_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    float dist = length(world_pos - center);
    
    if (dist < radius) {
        float falloff = 1.0 - smoothstep(0.0, radius, dist);
        vec3 dir = normalize(world_pos - center);
        
        // 沿法线方向偏移顶点
        VERTEX += NORMAL * strength * falloff;
    }
}