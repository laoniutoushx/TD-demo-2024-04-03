shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_mix, depth_test_disabled;

uniform float arrow_width : hint_range(0.1, 1.0) = 0.4;
uniform float arrow_height : hint_range(0.1, 1.0) = 0.6;
uniform float animation_speed : hint_range(0.1, 5.0) = 1.0;
uniform vec4 arrow_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);
uniform float fade_height : hint_range(0.1, 2.0) = 1.0;
uniform bool loop = true;
uniform float direction_angle = 0.0; // 弧度，控制箭头方向

vec2 rotate(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);
}

void vertex() {
    VERTEX = VERTEX;
}

void fragment() {
    vec2 uv = UV * 2.0 - vec2(1.0);
    uv = rotate(uv, direction_angle);

    float t = TIME * animation_speed;
    float offset_y = loop ? fract(t) * 2.0 - 1.0 : min(t, 1.0) * 2.0 - 1.0;
    uv.y += offset_y;

    float body = step(abs(uv.x), arrow_width * 0.5) * step(abs(uv.y), arrow_height * 0.5);
    float tip = step(abs(uv.x / uv.y), arrow_width / arrow_height);
    float shape = max(body, tip * step(uv.y, 0.0));

    float alpha_fade = smoothstep(1.0, 0.0, uv.y + 1.0);

    ALBEDO = arrow_color.rgb;
    ALPHA = shape * arrow_color.a * alpha_fade;
}
