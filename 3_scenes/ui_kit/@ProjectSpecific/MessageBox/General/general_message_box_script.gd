@tool
extends AspectRatioContainer
class_name GeneralMessageBox

@export var speaker_name: String = "":
  set(value):
    speaker_name = value
    var label = get_node_or_null("%SpeakerLabel")
    if label: label.text = value
    var speaker_box = get_node_or_null("%Speaker")
    if speaker_box: speaker_box.visible = not value.is_empty()

@export_multiline var message_text: String = "":
  set(value):
    message_text = value
    var label = get_node_or_null("%MessageLabel")
    if label: label.text = value

@export_group("Theme Handlers")
@export var theme_handler: ControlThemeHandlerRes

@export_group("DEV")
@export_tool_button("Apply theme", "Callable") var dev_apply_theme = func(): apply_theme()

func apply_theme(override_ttv: StringName = &"") -> void:
  var ttv: StringName = override_ttv if not override_ttv.is_empty() else theme_type_variation
  if theme_handler: theme_handler.apply_theme(self, ttv)

func _ready() -> void:
  apply_theme()
  if not speaker_name.is_empty():
    var label = get_node_or_null("%SpeakerLabel")
    if label: label.text = speaker_name
  if not message_text.is_empty():
    var label = get_node_or_null("%MessageLabel")
    if label: label.text = message_text

func _notification(what: int) -> void:
  if what == NOTIFICATION_THEME_CHANGED: apply_theme()
