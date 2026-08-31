shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform int mode : hint_range(0, 2) = 0; // 0 = Blur, 1 = Color (Ambient edge glow), 2 = None (Black)
uniform float target_ratio = 1.7777778;
uniform float glow_size : hint_range(0.1, 2.0) = 0.85;
uniform float glow_intensity : hint_range(0.1, 3.0) = 1.3;

uniform float mip_level: hint_range(0.0, 5) = 2.0;
uniform int kawase_passes : hint_range(1, 8) = 4;
/** Offset create wider blur effect, may create artifacts on big values */
uniform float kawase_offset_scale : hint_range(0.0, 4.0, 0.25) = 1.5;
uniform float blur_radius : hint_range(1.0, 32.0) = 16.0;

vec4 kawase_blur(sampler2D tex, vec2 uv) {
    vec4 color = vec4(0.0);
    vec2 pixel_size = 1.0 / vec2(textureSize(tex, 0));
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

void fragment() {
    if (mode == 2) {
        // None / Off: pure black
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else if (mode == 0) {
        // Blur: full blurred background
        COLOR = kawase_blur(SCREEN_TEXTURE, SCREEN_UV);
    } else {
        // Mode 1: Color / Ambient edge backlight over black background
        vec2 vp_size = 1.0 / SCREEN_PIXEL_SIZE;
        float current_ratio = vp_size.x / vp_size.y;
        vec4 base_color = vec4(0.0, 0.0, 0.0, 1.0);
        float glow_factor = 0.0;
        vec2 sample_uv = SCREEN_UV;
        
        if (current_ratio > target_ratio) {
            // Wider screen: pillarbox (bars on left and right)
            float visible_width_ratio = target_ratio / current_ratio;
            float margin = (1.0 - visible_width_ratio) * 0.5;
            
            if (SCREEN_UV.x < margin) {
                // Left bar
                float dist = (margin - SCREEN_UV.x) / max(margin * glow_size, 0.001);
                glow_factor = clamp(1.0 - dist, 0.0, 1.0);
                glow_factor = pow(glow_factor, 1.5) * glow_intensity;
                sample_uv = vec2(margin + 0.02, SCREEN_UV.y);
            } else if (SCREEN_UV.x > (1.0 - margin)) {
                // Right bar
                float dist = (SCREEN_UV.x - (1.0 - margin)) / max(margin * glow_size, 0.001);
                glow_factor = clamp(1.0 - dist, 0.0, 1.0);
                glow_factor = pow(glow_factor, 1.5) * glow_intensity;
                sample_uv = vec2(1.0 - margin - 0.02, SCREEN_UV.y);
            }
        } else if (current_ratio < target_ratio) {
            // Taller screen: letterbox (bars on top and bottom)
            float visible_height_ratio = current_ratio / target_ratio;
            float margin = (1.0 - visible_height_ratio) * 0.5;
            
            if (SCREEN_UV.y < margin) {
                // Top bar
                float dist = (margin - SCREEN_UV.y) / max(margin * glow_size, 0.001);
                glow_factor = clamp(1.0 - dist, 0.0, 1.0);
                glow_factor = pow(glow_factor, 1.5) * glow_intensity;
                sample_uv = vec2(SCREEN_UV.x, margin + 0.02);
            } else if (SCREEN_UV.y > (1.0 - margin)) {
                // Bottom bar
                float dist = (SCREEN_UV.y - (1.0 - margin)) / max(margin * glow_size, 0.001);
                glow_factor = clamp(1.0 - dist, 0.0, 1.0);
                glow_factor = pow(glow_factor, 1.5) * glow_intensity;
                sample_uv = vec2(SCREEN_UV.x, 1.0 - margin - 0.02);
            }
        }
        
        vec4 edge_color = kawase_blur(SCREEN_TEXTURE, sample_uv);
        COLOR = mix(base_color, edge_color, clamp(glow_factor, 0.0, 1.0));
    }
}