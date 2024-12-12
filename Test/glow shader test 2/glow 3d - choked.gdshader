shader_type spatial;

uniform vec4 emission_color: source_color;
uniform float emission_amount: hint_range(0.0, 16.0) = 5.0;
uniform float rim_sharpness: hint_range(0.0, 16.0) = 3.0;



void fragment() {
	ALPHA = pow(1.0 - dot(NORMAL, VIEW), rim_sharpness);
}


