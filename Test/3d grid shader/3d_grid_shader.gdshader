shader_type spatial;
render_mode unshaded;

uniform float grid_size = 512.0;
uniform float cell_size = 1.0;
uniform float gutter_size = 0.04;
uniform vec4 cell_color : source_color = vec4(0.078, 0.024, 0.0, 1.0);
uniform vec4 gutter_color : source_color = vec4(0.922, 0.376, 0.0, 1.0);
uniform float cell_roundedness : hint_range(0.0, 0.9999) = 0.0;

group_uniforms CellManipulator;
uniform float cell_manipulator_radius = 0.0; // Radius of the effect
uniform vec2 cell_manipulator_uv_pos = vec2(0.5, 0.5); // The UV coordinate to affect
uniform float manipulated_cell_size = 0.5; // Minimum cell size
uniform vec4 manipulator_gutter_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float cell_manipulation_anim_speed = 1.0;

group_uniforms GutterNoise;
uniform vec3 gutter_noise_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D gutter_noise: source_color;
uniform float gutter_noise_speed = 0.1;

group_uniforms Fresnel;
uniform vec3 fresnel_color : source_color = vec3(0.675, 0.192, 0.0);
uniform float fresnel_intensity = 0.2;
uniform float fresnel_amount = 15.0;

vec4 square_rounded(vec2 uv, float width, float radius) {
    uv = uv * 2.0 - 1.0;
    radius *= width; // make radius go from 0-1 instead of 0-width
    vec2 abs_uv = abs(uv.xy) - radius;
    vec2 dist = max(abs_uv, 0.0);
    float square = step(width - radius, length(dist));
    return vec4(vec3(square), square); // Return with alpha value as the last component
}

vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
    return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * intensity;
}

void fragment() {
    float _min_cell_size = manipulated_cell_size / grid_size;
    float _max_cell_size = cell_size / grid_size;
    float _target_radius = cell_manipulator_radius / grid_size;
    // Calculate the center of the current cell based on the max cell size
    vec2 cell_coord = floor(UV / _max_cell_size);
    vec2 cell_center = cell_coord * _max_cell_size + _max_cell_size * 0.5;

    // Animate the cell size using a sine wave function
    float animated_cell_size = mix(_min_cell_size, _max_cell_size * 0.75, (sin(TIME * cell_manipulation_anim_speed * 2.0 * PI) * 0.5) + 0.5);

    // Calculate the distance from the cell center to the target UV
    float cell_dist = distance(cell_center, cell_manipulator_uv_pos);
    float cell_dist_t = clamp(cell_dist / _target_radius, 0.0, 1.0);

    float px_dist = distance(UV, cell_manipulator_uv_pos);
    float px_dist_t = clamp(px_dist / _target_radius, 0.0, 1.0);

    // Determine the cell size based on the distance
    float _cell_size = mix(animated_cell_size, _max_cell_size, cell_dist_t);
    float size_t = _cell_size / _max_cell_size;

    // Calculate the scaled UV coordinates based on the max cell size for alignment
    vec2 aligned_uv = UV / _max_cell_size;
    vec2 grid_uv = fract(aligned_uv);

    // Adjust the grid UV based on the calculated cell size to maintain uniform scaling
    vec2 adjusted_uv = (grid_uv - 0.5) * (_max_cell_size / _cell_size) + 0.5;

    // Define the gutter size relative to the cell size
    float _gutter_size = gutter_size * _max_cell_size / _cell_size;
    float gutter_half = _gutter_size * 0.5;

    vec4 _gutter_color = mix(manipulator_gutter_color, gutter_color, px_dist_t);
    vec4 noise = texture(gutter_noise, UV + (vec2(0, 1) * gutter_noise_speed * TIME));
    vec4 color_noise = vec4(noise.rgb * gutter_noise_color, 1.0);
    vec3 mixed_gutter_color = (_gutter_color + color_noise).rgb;
    mixed_gutter_color = mix(mixed_gutter_color, _gutter_color.rgb, px_dist_t);

    // Determine the color based on the position within the cell
    if (adjusted_uv.x < gutter_half || adjusted_uv.x > 1.0 - gutter_half || adjusted_uv.y < gutter_half || adjusted_uv.y > 1.0 - gutter_half) {
        ALBEDO = mixed_gutter_color;
    } else {
        vec4 square_result = square_rounded(adjusted_uv, 1.0 - _gutter_size, 0.9999 - cell_roundedness);
        if (square_result.a <= 0.0) {
            ALBEDO = cell_color.rgb;
        } else {
            ALBEDO = mixed_gutter_color;
        }
    }
    ALBEDO = ALBEDO + fresnel_glow(fresnel_amount, fresnel_intensity, fresnel_color, NORMAL, VIEW);
}
