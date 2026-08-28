@tool
extends CheckBox

@export var sound_button_comp: SoundButtonComp
@export var hover_button_comp: HoverButtonComp

@export var disable_mark_normal: bool = true

@export_group("State Test")
@export_tool_button("Remove overrides", "Callable") var remove_overrides = _themes_clear
@export var hovered_test: bool = false:
  set(value):
    if not is_node_ready(): await ready
    hovered_test = value
    _themes_setup("hovered" if value else "")

var _elems_arr: Array[Control]

func _fill_elems_arr() -> void: if _elems_arr.is_empty(): _elems_arr = [%MainTexture, %Shadow, %Outline, %Underbody, %CheckMark]

func _set_texture(tag: String = "") -> void:
  for i in range(4):
    var target_elem = _elems_arr[i].get_node("TextureHandler") if i > 0 else _elems_arr[i]
    target_elem.add_theme_stylebox_override("panel", get_theme_stylebox("heart_texture_" + tag, theme_type_variation))

func _themes_setup(tag: String = "") -> void:
  _elems_arr[0].self_modulate = get_theme_color("_0_main_tex_" + tag, theme_type_variation)
  _elems_arr[1].modulate = get_theme_color("_1_shadow_" + tag, theme_type_variation)
  _elems_arr[2].modulate = get_theme_color("_2_outline_" + tag, theme_type_variation)
  _elems_arr[3].modulate = get_theme_color("_3_underbody_" + tag, theme_type_variation)
  _elems_arr[4].modulate = get_theme_color("_4_mark_" + tag, theme_type_variation)

# helper for editior and tests
func _themes_clear() -> void:
  for elem in _elems_arr:
    elem.modulate = Color.WHITE
    elem.self_modulate = Color.WHITE

func _ready() -> void:
  _fill_elems_arr()
  _set_texture()
  _themes_setup()
  if Engine.is_editor_hint(): return
  if disable_mark_normal: %CheckMark.visible = !toggled
  # hover_button_comp.hover_changed.connect(_on_button_hover_changed)
  # hover_button_comp.focus_changed.connect(_on_button_focus_changed)
  button_down.connect(_on_button_down)
  button_up.connect(_on_button_release)
  toggled.connect(_on_button_toggled)

# func _on_button_hover_changed(value: bool) -> void: _themes_setup("hovered" if value else "")
# func _on_button_focus_changed(value: bool) -> void: _themes_setup("hovered" if value else "")
func _on_button_toggled(value: bool) -> void:
  if disable_mark_normal: %CheckMark.visible = value
  _themes_setup("toggled" if value else "")

func _on_button_down() -> void: (%AnimationPlayer as AnimationPlayer).play("press")
func _on_button_release() -> void: (%AnimationPlayer as AnimationPlayer).play_backwards("press")
