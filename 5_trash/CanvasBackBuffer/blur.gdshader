shader_type canvas_item;

uniform sampler2D screen_buffer: hint_screen_texture, filter_linear, repeat_disable;

uniform float blur_strength = 0.0;
uniform float blur_resolution = 32.0;

const float GOLDEN_ANGLE = 2.399963;

vec2 fibonacci_circle(in float p_index, in float p_count) {
	return cos(p_index * GOLDEN_ANGLE + vec2(0.0, PI * 0.5)) * sqrt(p_index / p_count);
}

float hash14(vec4 p4) {
	p4 = fract(p4 * vec4(.1031, .1030, .0973, .1099));
	p4 += dot(p4, p4.wzxy+33.33);
	return fract((p4.x + p4.y) * (p4.z + p4.w));
}

void fragment() {
	vec2 view_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 pos = SCREEN_UV * view_size;

	vec4 pix = vec4(0.0);

	for (float i = 0.0; i < blur_resolution; i += 1.0) {
		vec2 off = fibonacci_circle(i + hash14(vec4(FRAGCOORD.xy, i, TIME)), blur_resolution);

		float w = clamp(1.0 - length(off), 0.0, 1.0);
		pix.rgb += texture(screen_buffer, (pos + off * blur_strength) / view_size).rgb * w;
		pix.a += w;
	}

	pix /= pix.a;

	COLOR.rgb = pix.rgb;
}
