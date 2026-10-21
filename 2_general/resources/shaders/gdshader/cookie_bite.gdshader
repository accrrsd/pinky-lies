shader_type canvas_item;

uniform float bite_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 bite_center_px = vec2(0.0, 0.0);
uniform vec2 bite_dir = vec2(-0.7071, 0.7071);
uniform float bite_radius_px = 65.0;

varying vec2 global_coord;

void vertex() {
  global_coord = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
  if (bite_progress > 0.001) {
    vec2 p = global_coord;
    float r = bite_radius_px * bite_progress;
    vec2 perp = vec2(-bite_dir.y, bite_dir.x);
    
    // Teeth impression circle centers along bite arc
    float d_corner = distance(p, bite_center_px);
    float d_main = distance(p, bite_center_px + bite_dir * (r * 0.28));
    
    float d_t1 = distance(p, bite_center_px + bite_dir * (r * 0.65) + perp * (r * 0.38));
    float d_t2 = distance(p, bite_center_px + bite_dir * (r * 0.75));
    float d_t3 = distance(p, bite_center_px + bite_dir * (r * 0.65) - perp * (r * 0.38));
    
    float d_t4 = distance(p, bite_center_px + bite_dir * (r * 0.32) + perp * (r * 0.68));
    float d_t5 = distance(p, bite_center_px + bite_dir * (r * 0.32) - perp * (r * 0.68));
    
    float min_d = min(d_corner, min(d_main, min(min(d_t1, d_t2), min(d_t3, min(d_t4, d_t5)))));
    
    float tooth_radius = r * 0.42;
    float bite_mask = smoothstep(tooth_radius - 1.5, tooth_radius + 0.5, min_d);
    
    COLOR.a *= bite_mask;
  }
}
