shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx, unshaded;

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

// Tornado effect parameters
uniform float twist_strength : hint_range(0.0, 5.0);
uniform float speed : hint_range(0.1, 10.0);
uniform float height_warp : hint_range(0.0, 2.0);
uniform float noise_strength : hint_range(0.0, 1.0);

void vertex() {
    float time_offset = TIME * speed;
    float twist = (VERTEX.y + time_offset) * twist_strength; // One-directional twist
    float height_displacement = sin(VERTEX.y * 3.0 + time_offset) * height_warp;

    // Rotation matrix for twisting effect
    vec2 xz = VERTEX.xz;
    vec2 rotated_xz = vec2(
        cos(twist) * xz.x - sin(twist) * xz.y,
        sin(twist) * xz.x + cos(twist) * xz.y
    );

    VERTEX.xz = rotated_xz;
    VERTEX.y += height_displacement;

    UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
    vec2 base_uv = UV;
    //base_uv.x += sin(base_uv.y * 10.0 + TIME * speed) * noise_strength;
	base_uv.x += base_uv.y * 10.0 + TIME * speed * noise_strength;

    vec4 albedo_tex = texture(texture_albedo, base_uv);

    // Vertex Color Use as Albedo: Enabled
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