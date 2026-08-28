@tool
extends PanelContainer

@export var default_option_index: int = 0

## key is visible part, value is actual data (if needed) 
@export var options: Dictionary[String, Variant] = {}
@export var controlThemeHandler: ControlThemeHandlerRes

@export_group("DEV")
@export_tool_button("Apply normal theme", "Callable") var dev_apply_normal_theme = func():
  controlThemeHandler.apply_theme(self, theme_type_variation)

var prevButton: Button
var nextButton: Button
var label: Label

var current_index: int = 0:
  set(value):
    current_index = value
    _change_label_content(value)

func _ready() -> void:
  prevButton = %PrevButton
  nextButton = %NextButton
  label = %Label
  # _themes_setup()
  controlThemeHandler.apply_theme(self, theme_type_variation)
  # controlThemeHandler.
  if not Engine.is_editor_hint(): return
  prevButton.pressed.connect(_on_prev_button_pressed)
  nextButton.pressed.connect(_on_next_button_pressed)
  current_index = default_option_index
  
func _change_label_content(idx: int) -> void:
  if options.size() == 0: return
  label.text = options.keys()[idx]

func _on_prev_button_pressed() -> void:
  current_index = current_index - 1 if current_index - 1 > 0 else 0

func _on_next_button_pressed() -> void:
  var opt_size = options.size()
  current_index = current_index + 1 if current_index + 1 < opt_size - 1 else opt_size


# ## do not have tag, because it uses default styles system
# func _themes_setup() -> void:
#   var ttv: StringName = theme_type_variation
#   var _setup_text_style = func(elem: Control) -> void:
#     elem.add_theme_color_override("font_color", get_theme_color("font_color", ttv))
#     elem.add_theme_color_override("font_outline_color", get_theme_color("font_outline_color", ttv))
#     elem.add_theme_constant_override("outline_size", get_theme_constant("outline_size", ttv))
  
#   var _setup_button_style = func(elem: Button) -> void:
#     elem.add_theme_color_override("font_color", get_theme_color("_0_button_font_color", ttv))
#     elem.add_theme_color_override("font_focus_color", get_theme_color("font_focus_color", ttv))
#     elem.add_theme_color_override("font_hover_color", get_theme_color("font_hover_color", ttv))
    
  
#   _setup_text_style.call(label)
#   _setup_text_style.call(prevButton)
#   _setup_text_style.call(nextButton)
#   _setup_button_style.call(prevButton)
#   _setup_button_style.call(nextButton)
