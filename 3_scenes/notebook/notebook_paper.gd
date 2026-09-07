## NotebookPaper
##
## Purpose:
##   Custom Control that renders an authentic spiral notebook page with:
##   - Metallic spiral binding rings and punch holes on the left.
##   - Vertical red/coral school margin rule.
##   - Horizontal blue notebook ruled lines aligned with text rows.

@tool
extends Control
class_name NotebookPaper

@export var paper_color: Color = Color(0.97, 0.96, 0.92)
@export var line_color: Color = Color(0.72, 0.80, 0.90, 0.65)
@export var margin_line_color: Color = Color(0.92, 0.44, 0.44, 0.75)
@export var ring_color: Color = Color(0.78, 0.82, 0.86)
@export var hole_color: Color = Color(0.18, 0.16, 0.14, 0.85)
@export var line_spacing: float = 38.0
@export var top_line_offset: float = 64.0
@export var margin_x: float = 88.0
@export var ring_spacing: float = 44.0

func _draw() -> void:
  var s := size
  if s.x <= 0.0 or s.y <= 0.0: return
  
  # 1. Paper background and border
  draw_rect(Rect2(Vector2.ZERO, s), paper_color, true, -1.0)
  draw_rect(Rect2(Vector2.ZERO, s), Color(0.82, 0.80, 0.74, 0.7), false, 1.5)
  
  # 2. Horizontal ruled lines
  var cur_y := top_line_offset
  while cur_y < s.y - 20.0:
    draw_line(Vector2(margin_x - 12.0, cur_y), Vector2(s.x - 24.0, cur_y), line_color, 1.2)
    cur_y += line_spacing
  
  # 3. Vertical red margin line
  draw_line(Vector2(margin_x, 16.0), Vector2(margin_x, s.y - 16.0), margin_line_color, 1.5)
  
  # 4. Spiral punch holes and metallic rings
  var ring_y := 36.0
  while ring_y < s.y - 24.0:
    draw_circle(Vector2(32.0, ring_y), 5.5, hole_color)
    draw_circle(Vector2(32.0, ring_y), 4.5, Color(0.10, 0.09, 0.08, 0.95))
    
    var center := Vector2(18.0, ring_y)
    draw_arc(center, 18.0, -PI * 0.45, PI * 0.45, 14, Color(0.0, 0.0, 0.0, 0.25), 4.5)
    draw_arc(center, 17.0, -PI * 0.45, PI * 0.45, 14, ring_color, 3.2)
    draw_arc(center, 17.0, -PI * 0.25, PI * 0.1, 8, Color(1.0, 1.0, 1.0, 0.9), 1.6)
    
    draw_line(Vector2(18.0 + 17.0 * cos(PI * 0.42), ring_y + 17.0 * sin(PI * 0.42)), Vector2(32.0, ring_y), ring_color * 0.85, 3.0)
    draw_line(Vector2(18.0 + 17.0 * cos(-PI * 0.42), ring_y + 17.0 * sin(-PI * 0.42)), Vector2(32.0, ring_y), ring_color * 0.85, 3.0)
    
    ring_y += ring_spacing
