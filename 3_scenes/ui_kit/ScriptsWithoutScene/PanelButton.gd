@tool
extends PanelContainer
class_name PanelButton

@export_group("Sounds")
@export var pressed_sound: SoundsPropsRes = null
@export var hover_sound: SoundsPropsRes = null

var button: SoundButton
var button_toggled: bool = false

func _find_sound_button(node: Node) -> SoundButton:
  for child in node.get_children():
    if child is SoundButton:
      return child
    var btn = _find_sound_button(child)
    if btn:
      return btn
  return null

func _ready() -> void:
  _themes_setup()
  if Engine.is_editor_hint(): return

  if not button:
    button = _find_sound_button(self)

  if button:
    button.pressed_sound = pressed_sound
    button.hover_sound = hover_sound
    button.hover_changed.connect(_on_button_hover_changed)
    button.focus_changed.connect(_on_button_focus_changed)
    button.button_down.connect(_on_button_down)
    button.button_up.connect(_on_button_up)
    button.toggled.connect(_on_button_toggled)

func _themes_setup(tag: String = "") -> void:
  var style_name = "_0_background_" + tag
  if has_theme_stylebox(style_name, theme_type_variation):
    add_theme_stylebox_override("panel", get_theme_stylebox(style_name, theme_type_variation))
  elif has_theme_stylebox("panel", theme_type_variation):
    add_theme_stylebox_override("panel", get_theme_stylebox("panel", theme_type_variation))

func _on_button_hover_changed(value: bool) -> void:
  _themes_setup("hovered" if value else _return_toggled_or_default_style())

func _on_button_focus_changed(value: bool) -> void:
  _themes_setup("hovered" if value else _return_toggled_or_default_style())

func _on_button_down() -> void:
  _themes_setup("pressed")

func _on_button_up() -> void:
  if button and button.is_hovered_var: _themes_setup("hovered")
  else: _themes_setup("")

func _on_button_toggled(toggled_on: bool) -> void:
  button_toggled = toggled_on
  if toggled_on: _on_button_down()
  else: _on_button_up()

func _return_toggled_or_default_style() -> String: return "pressed" if button_toggled else ""
