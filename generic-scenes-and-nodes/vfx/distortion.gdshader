shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float x_offset : hint_range(-50.0, 50.0) = 10.0; // 可调节的像素偏移量

void fragment() {
    // 获取当前像素的屏幕坐标
    vec2 screen_uv = SCREEN_UV;
    
    // 计算偏移后的像素坐标
    // 将偏移转换为 UV 空间的偏移量
    vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 offset_uv = screen_uv + vec2(x_offset * pixel_size.x, 0.0);
    
    // 完全忽略物体本身的纹理，只输出屏幕空间纹理
    // 可以选择原始位置或偏移位置的采样
    COLOR = texture(SCREEN_TEXTURE, offset_uv);
    
    // 如果需要混合效果，可以取消注释下面这行
    // COLOR = mix(texture(SCREEN_TEXTURE, screen_uv), texture(SCREEN_TEXTURE, offset_uv), 0.5);
}