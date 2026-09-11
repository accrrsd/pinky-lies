shader_type canvas_item;

uniform sampler2D screen_buffer: hint_screen_texture, filter_linear, repeat_disable;

void fragment() {
	vec4 col = texture(screen_buffer, SCREEN_UV);
	float lum = dot(vec3(0.2125, 0.7154, 0.0721), col.rgb);
	col.rgb = vec3(lum);
	col.a = 1.0;

	COLOR = col;
}
