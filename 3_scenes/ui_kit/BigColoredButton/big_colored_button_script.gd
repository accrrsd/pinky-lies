@tool
extends PanelContainer

@export_multiline var text: String = "":
    set(value):
        text = value
        var label = get_node_or_null("%Label")
        if label: label.text = value

@export_group("Sounds")
@export var pressed_sound: SoundsPropsRes = null
@export var hover_sound: SoundsPropsRes = null

@export_group("State Test")
@export_tool_button("Remove overrides", "Callable") var remove_overrides = _themes_clear
@export var hovered_test: bool = false:
  set(value):
    if not is_node_ready(): await ready
    hovered_test = value
    _themes_setup("hovered" if value else "")

var button: SoundButton
var _elems_arr: Array[Control]

func _fill_elems_arr() -> void:
  if _elems_arr.is_empty():
    _elems_arr = [$Background, $Background/InnerBorder, $Background/InnerBorder/Decoration, $Background/InnerBorder/Decoration/GradientBackground, %Label]

func _themes_setup(tag: String = "") -> void:
  _elems_arr[0].add_theme_stylebox_override("panel", get_theme_stylebox("_0_background_" + tag, theme_type_variation))
  _elems_arr[1].add_theme_stylebox_override("panel", get_theme_stylebox("_1_inner_border_" + tag, theme_type_variation))
  _elems_arr[2].add_theme_stylebox_override("panel", get_theme_stylebox("_2_decoration_" + tag, theme_type_variation))
  _elems_arr[3].add_theme_stylebox_override("panel", get_theme_stylebox("_3_gradient_bg_" + tag, theme_type_variation))
  _elems_arr[4].add_theme_color_override("font_outline_color", get_theme_color("label_font_outline_color_" + tag, theme_type_variation))
  _elems_arr[4].add_theme_constant_override("outline_size", get_theme_constant("label_font_outline_size_", theme_type_variation))

# helper for editior and tests
func _themes_clear() -> void:
  _elems_arr[0].remove_theme_stylebox_override("panel")
  _elems_arr[1].remove_theme_stylebox_override("panel")
  _elems_arr[2].remove_theme_stylebox_override("panel")
  _elems_arr[3].remove_theme_stylebox_override("panel")
  _elems_arr[4].remove_theme_color_override("font_outline_color")
  _elems_arr[4].remove_theme_constant_override("outline_size")

func _ready() -> void:
  _fill_elems_arr()
  _themes_setup()
  if Engine.is_editor_hint(): return
  button = %ButtonHandler
  button.pressed_sound = pressed_sound
  button.hover_sound = hover_sound
  button.hover_changed.connect(_on_button_hover_changed)
  button.focus_changed.connect(_on_button_focus_changed)

func _on_button_hover_changed(value: bool) -> void:
  _themes_setup("hovered" if value else "")

func _on_button_focus_changed(value: bool) -> void:
  _themes_setup("hovered" if value else "")