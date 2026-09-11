shader_type canvas_item;

uniform sampler2D screen_buffer: hint_screen_texture, filter_linear, repeat_disable;

uniform float frequency = 8.0;
uniform float speed = 1.0;
uniform float magnitude = 0.0;

void fragment() {
	vec2 view_size = 1.0 / SCREEN_PIXEL_SIZE;

	vec2 pos = SCREEN_UV * view_size;
	vec2 off = UV * 2.0 - 1.0;
	float dst = length(off);
	vec2 dir = dst > 0.0 ? off / dst : vec2(1.0, 0.0);

	vec2 displace = dir * magnitude;
	displace *= sin(dst * TAU * frequency - TIME * speed * TAU) * 0.5 + 0.5;
	displace *= clamp(1.0 - dst, 0.0, 1.0);

	vec4 col = texture(screen_buffer, (pos + displace) / view_size);
	col.a = 1.0;

	COLOR = col;
}
