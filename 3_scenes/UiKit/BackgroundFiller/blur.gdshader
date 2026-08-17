shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float mip_level: hint_range(0.0, 5) = 0.0;
uniform int kawase_passes : hint_range(1, 8) = 4;
/** Offset create wider blur effect, may create artifacts on big values */
uniform float kawase_offset_scale : hint_range(0.0, 4.0, 0.25) = 1.5;
uniform float blur_radius : hint_range(1.0, 32.0) = 16.0;

vec4 kawase_blur(sampler2D tex, vec2 uv) {
    vec4 color = vec4(0.0);
    vec2 pixel_size = 1.0/vec2(textureSize(tex, 0));
     const vec2 ANGLE = vec2(0.7071, 0.7071);
    for(int i = 0; i < kawase_passes; i++) {
        float offset = (float(i) + 0.5) * kawase_offset_scale;
        vec2 offset_vec = ANGLE * offset * pixel_size * blur_radius;

        color += textureLod(tex, uv + offset_vec, mip_level);
        color += textureLod(tex, uv - offset_vec, mip_level);
        color += textureLod(tex, uv + vec2(offset_vec.x, -offset_vec.y), mip_level);
        color += textureLod(tex, uv + vec2(-offset_vec.x, offset_vec.y), mip_level);
    }
    return color / (float(kawase_passes) * 4.0);
}

void fragment(){
	//vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, mip_level);
  vec4 bg_color = kawase_blur(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = bg_color;
}