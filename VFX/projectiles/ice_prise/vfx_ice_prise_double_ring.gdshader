shader_type spatial;
render_mode unshaded, blend_add,  cull_disabled;

uniform vec4 inner_ring_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 outer_ring_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform float inner_radius = 0.4;
uniform float inner_thickness = 0.05;
uniform float outer_radius = 0.7;
uniform float outer_thickness = 0.03;
uniform float edge_softness = 0.01;


 
void fragment() {
    // 将UV坐标从[0,1]范围转换为[-1,1]范围，使中心位于(0,0)
    vec2 uv = UV * 2.0 - 1.0;
    
    // 计算点到圆心的距离
    float dist = length(uv);
    
    // 计算内圆环和外圆环的边界
    float inner_min = inner_radius - inner_thickness / 2.0;
    float inner_max = inner_radius + inner_thickness / 2.0;
    float outer_min = outer_radius - outer_thickness / 2.0;
    float outer_max = outer_radius + outer_thickness / 2.0;
    
    // 初始化颜色为完全透明
    vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0);
    
    // 为内圆环计算平滑的透明度过渡
    if (dist > inner_min && dist < inner_max) {
        float inner_alpha = 1.0 - smoothstep(inner_min, inner_min + edge_softness, dist) 
                           - smoothstep(inner_max - edge_softness, inner_max, dist);
        inner_alpha *= inner_ring_color.a;
        final_color = vec4(inner_ring_color.rgb * inner_alpha, inner_alpha);
    }
    
    // 为外圆环计算平滑的透明度过渡
    if (dist > outer_min && dist < outer_max) {
        float outer_alpha = 1.0 - smoothstep(outer_min, outer_min + edge_softness, dist) 
                           - smoothstep(outer_max - edge_softness, outer_max, dist);
        outer_alpha *= outer_ring_color.a;
        
        if (final_color.a > 0.0) {
            // 如果已经有内圆环，则使用适当的混合
            final_color = vec4(
                mix(final_color.rgb, outer_ring_color.rgb, outer_alpha / (final_color.a + outer_alpha)),
                max(final_color.a, outer_alpha)
            );
        } else {
            final_color = vec4(outer_ring_color.rgb * outer_alpha, outer_alpha);
        }
    }
    
    // 如果最终颜色完全透明，则丢弃片段（这是关键修复点！）
    if (final_color.a < 0.001) {
        discard;
    }
    
    // 设置最终颜色输出
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a * COLOR.a;
    EMISSION = final_color.rgb;
}