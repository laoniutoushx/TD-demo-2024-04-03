shader_type canvas_item;

void fragment() {
    vec2 uv = UV - vec2(0.5); // 以中心为原点
    float dist = length(uv);  // 距离中心的距离
    if (dist > 0.5) {
        discard; // 超出圆形范围的不显示
    }
    COLOR = texture(TEXTURE, UV);
}
