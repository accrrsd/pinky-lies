@tool
extends Control

enum FillMode {
  BLUR = 0,
  COLOR = 1,
  NONE = 2
}

@export var backgroundImage: Texture:
  set(new_texture):
    if new_texture == backgroundImage: return
    backgroundImage = new_texture
    _update_texture()

@export var fill_mode: FillMode = FillMode.BLUR:
  set(value):
    fill_mode = value
    _update_fill_mode()

func _ready() -> void:
  _update_texture()
  if not Engine.is_editor_hint():
    var settings_mgr = _get_settings_manager()
    if settings_mgr:
      if not settings_mgr.setting_changed.is_connected(_on_setting_changed):
        settings_mgr.setting_changed.connect(_on_setting_changed)
      var saved_mode = settings_mgr.get_setting("display", "fill_mode", int(FillMode.BLUR))
      fill_mode = int(saved_mode) as FillMode
  _update_fill_mode()

func _get_settings_manager() -> Node:
  if not is_inside_tree(): return null
  var root = get_tree().root
  if root and root.has_node("SettingsManager"):
    return root.get_node("SettingsManager")
  return null

func _on_setting_changed(category: String, key: String, value: Variant) -> void:
  if category == "display" and key == "fill_mode":
    fill_mode = int(value) as FillMode

func _update_texture() -> void:
  if not is_inside_tree(): await ready
  var bg = get_node_or_null("%Background") as TextureRect
  if bg: bg.texture = backgroundImage
  var blur_bg = get_node_or_null("%BlurBackground") as TextureRect
  if blur_bg: blur_bg.texture = backgroundImage

func _update_fill_mode() -> void:
  if not is_inside_tree(): await ready
  var blur_bg = get_node_or_null("%BlurBackground")
  if not blur_bg: return
  var color_rect: ColorRect = blur_bg.get_node_or_null("ColorRect") as ColorRect
  if not color_rect and blur_bg.get_child_count() > 0:
    color_rect = blur_bg.get_child(0) as ColorRect
  if color_rect and color_rect.material is ShaderMaterial:
    var sm = color_rect.material as ShaderMaterial
    sm.set_shader_parameter("mode", int(fill_mode))
