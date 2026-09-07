shader_type canvas_item;
render_mode blend_mix;

// =============================================================================
// Notebook Holes Shader (Шейдер вырезания отверстий)
// =============================================================================
// Создает прозрачные отверстия внутри текстуры, через которые виден фон.
//
// Настройки (Uniforms):
// - start_offset: Офсет первого отверстия в пикселях.
//     При вертикальном расположении: X = отступ от края, Y = начало ряда.
//     При горизонтальном расположении: X = начало ряда, Y = отступ от края.
// - hole_size: Размер отверстия (радиусы X и Y в пикселях). Если X == Y — ровный круг.
// - hole_spacing: Шаг/расстояние между центрами соседних отверстий (в пикселях).
// - hole_count: Количество отверстий.
//     -1 = автоматический подсчет (сколько влезет до конца текстуры);
//     >= 0 = фиксированное заданное число отверстий.
// - direction: Направление ряда отверстий (0 = Вертикально, 1 = Горизонтально).
// - hole_shape: Форма отверстий (0 = Круг/Эллипс, 1 = Прямоугольник/Слот).
// - corner_radius: Скругление углов для прямоугольной формы.
// - end_offset: Отступ от противоположного края текстуры, где отверстия прекращаются.
// - edge_softness: Сглаживание краев отверстий (антиалиасинг в пикселях).
// - hole_border_color: Опциональный цвет контура/обводки вокруг отверстий.
// - hole_border_width: Толщина контура отверстий в пикселях.
// - invert: Инверсия маски (true = показывать только отверстия).
// - custom_size: Ручной размер текстуры (если 0, определяется автоматически).
// =============================================================================

uniform vec2 start_offset = vec2(32.0, 36.0);
uniform vec2 hole_size = vec2(8.0, 8.0);
uniform float hole_spacing = 44.0;
uniform int hole_count = -1;
uniform int direction : hint_range(0, 1) = 0;
uniform int hole_shape : hint_range(0, 1) = 0;
uniform float corner_radius : hint_range(0.0, 50.0, 0.5) = 0.0;
uniform float end_offset = 0.0;
uniform float edge_softness : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform vec4 hole_border_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float hole_border_width : hint_range(0.0, 20.0, 0.5) = 0.0;
uniform bool invert = false;
uniform vec2 custom_size = vec2(0.0, 0.0);

varying vec2 v_local_pos;

void vertex() {
  v_local_pos = VERTEX;
}

float get_hole_dist(vec2 p, vec2 center) {
  vec2 d_pos = p - center;
  if (hole_shape == 0) {
    if (abs(hole_size.x - hole_size.y) < 0.001) return length(d_pos) - hole_size.x;
    vec2 safe_size = max(hole_size, vec2(0.001));
    return (length(d_pos / safe_size) - 1.0) * min(safe_size.x, safe_size.y);
  }
  vec2 d_rect = abs(d_pos) - max(hole_size - vec2(corner_radius), vec2(0.0));
  return length(max(d_rect, vec2(0.0))) + min(max(d_rect.x, d_rect.y), 0.0) - corner_radius;
}

void fragment() {
  vec4 tex_color = texture(TEXTURE, UV) * COLOR;

  vec2 tex_size = vec2(1.0, 1.0);
  if (custom_size.x > 0.0 && custom_size.y > 0.0) tex_size = custom_size;
  else if (TEXTURE_PIXEL_SIZE.x > 0.0 && TEXTURE_PIXEL_SIZE.x < 0.999) tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
  else {
    float deriv_x = abs(dFdx(UV.x)) + abs(dFdy(UV.x));
    float deriv_y = abs(dFdx(UV.y)) + abs(dFdy(UV.y));
    if (deriv_x > 0.000001 && deriv_y > 0.000001) {
      float local_scale_x = abs(dFdx(v_local_pos.x)) + abs(dFdy(v_local_pos.x));
      float local_scale_y = abs(dFdx(v_local_pos.y)) + abs(dFdy(v_local_pos.y));
      if (local_scale_x > 0.001 && local_scale_y > 0.001) tex_size = vec2(local_scale_x / deriv_x, local_scale_y / deriv_y);
    }
  }

  vec2 pixel_pos = UV * tex_size;

  float spacing = max(hole_spacing, 0.001);
  float start_along = (direction == 0) ? start_offset.y : start_offset.x;
  float start_across = (direction == 0) ? start_offset.x : start_offset.y;
  float dim_along = (direction == 0) ? tex_size.y : tex_size.x;
  float hole_extent = (direction == 0) ? hole_size.y : hole_size.x;
  float effective_end = (end_offset > 0.0) ? (dim_along - end_offset) : (dim_along - hole_extent);

  int total_holes = hole_count;
  if (total_holes < 0) {
    total_holes = (start_along + hole_extent > effective_end) ? 0 : (int(floor((effective_end - start_along) / spacing)) + 1);
  }
  if (total_holes < 0) total_holes = 0;

  float min_dist = 100000.0;

  if (total_holes > 0) {
    float coord_along = (direction == 0) ? pixel_pos.y : pixel_pos.x;
    float coord_across = (direction == 0) ? pixel_pos.x : pixel_pos.y;
    float max_cross = max(hole_size.x, hole_size.y) + edge_softness + hole_border_width;

    if (abs(coord_across - start_across) <= max_cross) {
      float rel = (coord_along - start_along) / spacing;
      int nearest_idx = int(round(rel));

      for (int k = -2; k <= 2; k++) {
        int idx = nearest_idx + k;
        if (idx >= 0 && idx < total_holes) {
          float pos_along = start_along + float(idx) * spacing;
          vec2 center = (direction == 0) ? vec2(start_across, pos_along) : vec2(pos_along, start_across);
          float d = get_hole_dist(pixel_pos, center);
          min_dist = min(min_dist, d);
        }
      }
    }
  }

  float half_soft = max(edge_softness * 0.5, 0.0001);
  float hole_alpha = (edge_softness <= 0.001) ? ((min_dist < 0.0) ? 0.0 : 1.0) : smoothstep(-half_soft, half_soft, min_dist);
  float alpha_mask = invert ? (1.0 - hole_alpha) : hole_alpha;

  vec4 final_color = tex_color;
  if (hole_border_width > 0.0 && hole_border_color.a > 0.0) {
    float b_end = hole_border_width;
    float border_val = (1.0 - smoothstep(b_end - half_soft, b_end + half_soft, min_dist)) * hole_alpha;
    final_color = mix(tex_color, vec4(hole_border_color.rgb, tex_color.a), border_val * hole_border_color.a);
  }

  final_color.a *= alpha_mask;
  COLOR = final_color;
}
