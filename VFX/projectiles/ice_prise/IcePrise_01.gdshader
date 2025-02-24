shader_type spatial;

uniform sampler2D over_texture : hint_default_white, filter_linear_mipmap;
uniform sampler2D under_texture : hint_default_white, filter_linear_mipmap;
uniform sampler2D surface_normalmap : hint_normal, filter_linear_mipmap;

// CC0 ice textures from AmbientCG
// over_texture = https://ambientcg.com/view?id=Ice003
// surface_normalmap = https://ambientcg.com/view?id=Ice002
// under_texture can be the displacement map from Ice002

uniform vec4 top_color : source_color = vec4(0.6764, 0.980092, 1.0, 1.0);
uniform float depth = 0.1;
uniform float normal_depth = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.7;
uniform float refractive_index = 0.1;
uniform float transparency : hint_range(0.0, 1.0) = 0.5; // Transparency control

// Blend function from u/lexpartizan the GOAT
float blendOverlay_f(float base, float blend) {
    float branchless = step(base, 0.5);
    return (2.0 * base * blend) * branchless + (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)) * (1.0 - branchless);
}

vec3 blendOverlay(vec3 base, vec3 blend) {
    return vec3(blendOverlay_f(base.r, blend.r), blendOverlay_f(base.g, blend.g), blendOverlay_f(base.b, blend.b));
}

// Vertex shader: Get camera position and world space coordinates
varying vec3 ro;
varying vec3 p;
varying vec3 vertex_normal_ws;

void vertex() {
    ro = (VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz; // Camera position in world space
    p = ((MODEL_MATRIX) * vec4(VERTEX, 1.0)).xyz; // Fragment position in world space
    vertex_normal_ws = ((MODEL_MATRIX) * vec4(NORMAL, 1.0)).xyz; // Vertex normal in world space
}

void fragment() {
    vec3 normal = texture(surface_normalmap, UV).xyz * 2.0 - 1.0;
    NORMAL_MAP = texture(surface_normalmap, UV).xyz;
    NORMAL_MAP_DEPTH = normal_depth;

    vec3 refraction;
    vec3 rd = normalize(p - ro - normal * refractive_index) * depth;

    vec3 over_color = texture(over_texture, UV).rgb;
    vec3 color = blendOverlay(over_color, top_color.rgb);

    vec2 offset = rd.xz;
    vec3 under_color = texture(under_texture, UV + offset + (normal.xy)).rgb;

    ALBEDO = blendOverlay(color, under_color);
    ROUGHNESS = roughness;
    METALLIC = metallic;

    // Set transparency (use transparency uniform to control alpha)
    ALPHA = transparency;
    // You can use depth or other factors to blend transparency based on the refraction/normal values
    // For example, making the transparency dependent on normal or depth could create a more realistic effect:
    // ALPHA = transparency * max(0.0, dot(normal, view_direction));
}
