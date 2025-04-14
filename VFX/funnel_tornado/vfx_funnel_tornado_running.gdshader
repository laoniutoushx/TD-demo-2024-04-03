shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx, unshaded;

// Port of tornado example from this http://www.html5rocks.com/en/tutorials/casestudies/oz/ topic with some optimizations.
// Original Shader by Dmytry Lavrov, Copyright 2012 (http://dmytry.com/) with permission from Moritz Helmsteadter at
// The Max Plank Institute is licensed under a Creative Commons attribution license http://creativecommons.org/licenses/by/3.0/
// free to share and remix for any purpose as long as it includes this note.
// Uses 'Computed noise' by Flavien Brebion.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Ported to Godot 4.4 3D shader

// Tornado parameters
uniform float spin_speed = 1.0;
uniform vec3 background_color: source_color = vec3(0.4, 0.4, 0.7);
uniform sampler2D noise_texture: source_color, filter_linear_mipmap, repeat_enable;

// Raytracing parameters
const int number_of_steps = 160; // number of isosurface raytracing steps
const float base_step_scaling = 0.6; // Larger values allow for faster rendering but cause rendering artifacts
const float min_step_size = 0.4; // Minimal step size
const float tornado_bounding_radius = 35.0;


// Rotation function (returns the rotated vector directly)
vec2 rotate2d(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(
        v.x * c - v.y * s,
        v.x * s + v.y * c
    );
}

// Noise function adapted for Godot
float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    vec2 rg = texture(noise_texture, (uv + 0.5) / 256.0).yx;
    return -1.0 + 2.4 * mix(rg.x, rg.y, f.z);
}

float ridged(float f) {
    return 1.0 - 2.0 * abs(f);
}

// The isosurface shape function, the surface is at o(q)=0
float shape(vec3 q) {
    q.y += 45.0;
    float h = 90.0;
    float t = spin_speed * TIME;

    // Use rotate2d function directly on vectors
    vec2 rotated_xz = rotate2d(q.xz, t - sqrt(q.y));
    vec3 spin_pos = vec3(rotated_xz, q.y - t * 5.0);

    float zcurve = pow(q.y, 1.5) * 0.03;
    float v = abs(length(q.xz) - zcurve) - 5.5 - clamp(zcurve * 0.2, 0.1, 1.0) * noise(spin_pos * vec3(0.1, 0.1, 0.1)) * 5.0;

    vec2 rotated_xz2 = rotate2d(q.xz, t * 1.5 + 0.1 * q.y);
    v = v - ridged(noise(vec3(rotated_xz2, q.y - t * 4.0) * 0.3)) * 1.2;

    v = max(v, q.y - h);
    return min(max(v, -q.y), 0.0) + max(v, -q.y);
}

// Calculates fog colour, and the multiplier for the colour of item behind the fog
void fog_step(float dist, vec3 fog_absorb, vec3 fog_reemit, inout vec3 colour, inout vec3 multiplier) {
    vec3 fog = exp(-dist * fog_absorb);
    colour += multiplier * (vec3(1.0) - fog) * fog_reemit;
    multiplier *= fog;
}

void raytrace_foggy(vec3 org, vec3 dir, float min_dist, float max_dist, inout vec3 colour, inout vec3 multiplier) {
    vec3 q = vec3(0.0);
    float d = 0.0;
    float dist = min_dist;
    float step_scaling = base_step_scaling;
    const float extra_step = min_step_size;

    for(int i = 0; i < number_of_steps; i++) {
        q = org + dist * dir;
        float shape_value = shape(q);
        float density = -shape_value;
        d = max(shape_value * step_scaling, 0.0);
        float step_dist = d + extra_step;

        if(density > 0.0) {
            float brightness = exp(-0.6 * density);
            fog_step(step_dist * 0.2, clamp(density, 0.0, 1.0) * vec3(1,1,1), vec3(1) * brightness, colour, multiplier);
        }

        if(dist > max_dist || multiplier.x < 0.01) {
            return;
        }

        dist += step_dist;
    }
}

// Bounding cylinder from Dmytry Lavrov
bool ray_cylinder_intersect(vec3 org, vec3 dir, out float min_dist, out float max_dist) {
    vec2 p = org.xz;
    vec2 d = dir.xz;
    float r = tornado_bounding_radius;
    float a = dot(d, d) + 1.0E-10; // Small constant to avoid division by zero
    float det, b;
    b = -dot(p, d); // -B/2 in quadratic formula
    det = (b * b) - dot(p, p) * a + r * r * a; // B^2/4 - AC = determinant / 4

    if (det < 0.0) {
        return false;
    }

    det = sqrt(det); // already divided by 2 here
    min_dist = (b - det) / a; // still needs to be divided by A
    max_dist = (b + det) / a;

    if(max_dist > 0.0) {
        return true;
    } else {
        return false;
    }
}

void fragment() {
    // Get direction and origin in model space
    vec3 dir = normalize(VIEW);
    vec3 org = CAMERA_POSITION_WORLD - MODEL_MATRIX[3].xyz;

    // Transform to the local space of the object
    dir = (inverse(MODEL_MATRIX) * vec4(dir, 0.0)).xyz;
    org = (inverse(MODEL_MATRIX) * vec4(org, 1.0)).xyz;

    // Raymarching the isosurface
    float min_dist = 0.0;
    float max_dist = 200.0;
    vec3 multiplier = vec3(1.0);
    vec3 color = vec3(0.0);

    if(ray_cylinder_intersect(org, dir, min_dist, max_dist)) {
        min_dist = max(min_dist, 0.0);
        raytrace_foggy(org, dir, min_dist, max_dist, color, multiplier);
        vec3 col = color * 0.5 + multiplier * background_color;
        ALBEDO = col;
        ALPHA = length(col) > 0.05 ? 1.0 : 0.0; // Only show non-black pixels
    } else {
        // Outside the effect boundaries
        ALPHA = 0.0;
    }
}