shader_type canvas_item;
render_mode blend_mix;

uniform vec4 outline_color : source_color = vec4(0.482, 0.086, 0.118, 1.0);
uniform float outline_width : hint_range(0.0, 30.0, 0.5) = 4.0;
uniform int pattern : hint_range(0, 2) = 0; // 0 = Circle (smooth candy), 1 = Diamond, 2 = Box
uniform bool only_outline = false;

const float TAU = 6.28318530718;

void fragment() {
  vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
  vec4 tex_color = texture(TEXTURE, UV);
  vec4 node_color = COLOR; // Contains node modulate and self_modulate
  vec4 original_color = tex_color * node_color;
  
  float max_alpha = 0.0;
  
  if (outline_width > 0.0) {
    if (pattern == 0) {
      // 16-point circle sampling for smooth candy outline
      for (int i = 0; i < 16; i++) {
        float angle = float(i) * (TAU / 16.0);
        vec2 offset = vec2(cos(angle), sin(angle)) * size;
        max_alpha = max(max_alpha, texture(TEXTURE, UV + offset).a);
      }
    } else if (pattern == 1) {
      // Diamond sampling (4 points)
      max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
      max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
      max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
      max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
    } else {
      // Box sampling (8 points)
      for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
          if (x != 0.0 || y != 0.0) {
            vec2 offset = vec2(x, y) * size;
            max_alpha = max(max_alpha, texture(TEXTURE, UV + offset).a);
          }
        }
      }
    }
  }
  
  float outline_alpha = clamp(max_alpha - tex_color.a, 0.0, 1.0) * outline_color.a * node_color.a;
  vec4 final_outline = vec4(outline_color.rgb, outline_alpha);
  
  if (only_outline) {
    COLOR = final_outline;
  } else {
    COLOR = mix(final_outline, original_color, original_color.a);
  }
}
