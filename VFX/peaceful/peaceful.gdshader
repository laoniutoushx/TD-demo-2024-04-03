// 诊断版本：先搞清楚到底发生了什么
shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded, ambient_light_disabled, fog_disabled;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);
uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// === 收缩控制参数 ===
uniform float shrink_start_time : hint_range(0.0, 1.0) = 0.0;
uniform float y_shrink_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float x_shrink_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float quad_half_height : hint_range(0.1, 2.0) = 0.5;
uniform bool smooth_shrink = true;
uniform bool debug_mode = true;  // 默认开启调试

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	
	// 先保存原始的VERTEX坐标用于调试
	vec3 original_vertex = VERTEX;
	
	// 计算收缩参数
	float lifetime_progress = 1.0 - COLOR.a;
	float shrink_progress = 0.0;
	if (lifetime_progress > shrink_start_time) {
		shrink_progress = (lifetime_progress - shrink_start_time) / (1.0 - shrink_start_time);
		if (smooth_shrink) {
			shrink_progress = shrink_progress * shrink_progress * (3.0 - 2.0 * shrink_progress);
		}
		shrink_progress = clamp(shrink_progress, 0.0, 1.0);
	}
	
	float scale_y = 1.0 - (shrink_progress * y_shrink_intensity);
	scale_y = max(scale_y, 0.0);
	
	// === 关键：在Billboard变换之前进行收缩变换 ===
	// 方法：直接操作本地坐标的VERTEX
	
	// 找到最高点（假设QuadMesh中心在原点）
	float max_y = quad_half_height;  // 顶端
	float min_y = -quad_half_height; // 底端
	
	// 以顶端为锚点进行缩放
	// 核心思想：保持顶端不动，底部向顶端收缩
	if (VERTEX.y < max_y) {  // 只对非顶端顶点进行变换
		float distance_from_top = max_y - VERTEX.y;
		VERTEX.y = max_y - (distance_from_top * scale_y);
	}
	
	// X轴照常缩放
	VERTEX.x *= (1.0 - (shrink_progress * x_shrink_intensity));
	
	// 调试信息传递给fragment shader
	if (debug_mode) {
		COLOR.r = (original_vertex.y + 0.5);  // 原始Y坐标 (-0.5~0.5 映射到 0~1)
		COLOR.g = shrink_progress;  // 收缩进度
		COLOR.b = (VERTEX.y + 0.5);  // 变换后Y坐标
		COLOR.a = 1.0;  // 确保可见
	}
	
	// Billboard变换（在收缩之后进行）
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	
	if (debug_mode) {
		// 调试显示：
		// 红色 = 原始Y位置
		// 绿色 = 收缩进度  
		// 蓝色 = 变换后Y位置
		ALBEDO = COLOR.rgb;
		ALPHA = 1.0;
	} else {
		albedo_tex *= COLOR;
		ALBEDO = albedo.rgb * albedo_tex.rgb;
		
		float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
		METALLIC = metallic_tex * metallic;
		SPECULAR = specular;
		
		vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
		float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
		ROUGHNESS = roughness_tex * roughness;
		
		ALPHA *= albedo.a * albedo_tex.a;
	}
}