@tool
extends PanelContainer

@export var default_option_index: int = 0

## key is visible part, value is actual data (if needed) 
@export var options: Dictionary[String, Variant] = {}:
  set(value):
    options = value
    _change_label_content(current_index)

@export var controlThemeHandler: ControlThemeHandlerRes

@export_group("DEV")
@export_tool_button("Apply normal theme", "Callable") var dev_apply_normal_theme = func():
  if controlThemeHandler: controlThemeHandler.apply_theme(self, theme_type_variation)

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
  if controlThemeHandler:
    controlThemeHandler.apply_theme(self, theme_type_variation)
  if not Engine.is_editor_hint():
    prevButton.pressed.connect(_on_prev_button_pressed)
    nextButton.pressed.connect(_on_next_button_pressed)
    current_index = default_option_index

func _change_label_content(idx: int) -> void:
  if options.is_empty(): return
  var keys = options.keys()
  if idx >= 0 and idx < keys.size():
    label.text = str(keys[idx])

func _on_prev_button_pressed() -> void:
  if options.is_empty(): return
  current_index = max(0, current_index - 1)

func _on_next_button_pressed() -> void:
  if options.is_empty(): return
  current_index = min(options.size() - 1, current_index + 1)
