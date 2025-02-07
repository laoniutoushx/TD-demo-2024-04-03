shader_type spatial;

uniform vec4 edge_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float edge_thickness : hint_range(0, 10) = 2.0;

render_mode blend_mix, depth_draw_always, cull_back;

void fragment() {
    float width = edge_thickness / 100.0;
    vec2 uv = UV;
    
    // 检测边缘
    float edge = 0.0;
    if(uv.x < width || uv.x > (1.0 - width) || 
       uv.y < width || uv.y > (1.0 - width)) {
        ALBEDO = edge_color.rgb;
        ALPHA = edge_color.a;
    } else {
        ALBEDO = fill_color.rgb;
        ALPHA = fill_color.a;
    }
}