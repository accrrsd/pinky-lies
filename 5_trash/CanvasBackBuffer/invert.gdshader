shader_type canvas_item;

uniform sampler2D screen_buffer: hint_screen_texture, filter_linear, repeat_disable;

void fragment() {
	vec4 col = texture(screen_buffer, SCREEN_UV);
	col.rgb = 1.0 - col.rgb;
	col.a = 1.0;

	COLOR = col;
}
