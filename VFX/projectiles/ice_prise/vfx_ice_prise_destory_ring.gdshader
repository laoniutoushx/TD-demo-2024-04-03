shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D ring_texture;
uniform float ring_width : hint_range(0.01, 0.5) = 0.1;
uniform float outer_fade : hint_range(0.0, 0.5) = 0.2;
uniform float inner_fade : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	// 计算从中心的距离
	vec2 center_uv = vec2(0.5, 0.5);
	float dist = distance(UV, center_uv);

	// 创建环形
	float ring_center = 0.4;
	float inner_edge = ring_center - ring_width/2.0;
	float outer_edge = ring_center + ring_width/2.0;

	// 内侧边缘渐变
	float inner_alpha = smoothstep(inner_edge - inner_fade, inner_edge, dist);
	// 外侧边缘渐变
	float outer_alpha = 1.0 - smoothstep(outer_edge, outer_edge + outer_fade, dist);

	// 合并内外渐变
	float ring_alpha = inner_alpha * outer_alpha;

	// 使用alpha通道和发光
	ALBEDO = vec3(1.0, 1.0, 1.0);
	ALPHA = ring_alpha;
	EMISSION = vec3(1.0, 1.0, 1.0) * ring_alpha * 2.0;
}