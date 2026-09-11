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

@export_group("Theme Handlers")
@export var normal_theme: ControlThemeHandlerRes
@export var hovered_theme: ControlThemeHandlerRes
@export var pressed_theme: ControlThemeHandlerRes

@export_group("DEV")
@export_tool_button("Apply normal theme", "Callable") var dev_apply_normal_theme = func():
  if normal_theme: normal_theme.apply_theme(self, theme_type_variation)
@export_tool_button("Apply hovered theme", "Callable") var dev_apply_hovered_theme = func():
  if hovered_theme: hovered_theme.apply_theme(self, theme_type_variation)
@export_tool_button("Apply pressed theme", "Callable") var dev_apply_pressed_theme = func():
  if pressed_theme: pressed_theme.apply_theme(self, theme_type_variation)

var button: SoundButton
var _is_hovered: bool = false
var _is_pressed: bool = false

func _apply_theme_state(state: String = "normal") -> void:
  match state:
    "normal": if normal_theme: normal_theme.apply_theme(self, theme_type_variation)
    "hovered": if hovered_theme: hovered_theme.apply_theme(self, theme_type_variation)
    "pressed": if pressed_theme: pressed_theme.apply_theme(self, theme_type_variation)

func _ready() -> void:
  _apply_theme_state("normal")
  if Engine.is_editor_hint(): return
  button = %ButtonHandler
  button.pressed_sound = pressed_sound
  button.hover_sound = hover_sound
  button.hover_changed.connect(_on_button_hover_changed)
  button.focus_changed.connect(_on_button_focus_changed)
  button.button_down.connect(_on_button_down)
  button.button_up.connect(_on_button_up)

func _on_button_hover_changed(value: bool) -> void:
  _is_hovered = value
  _update_state()

func _on_button_focus_changed(value: bool) -> void:
  _is_hovered = value
  _update_state()

func _on_button_down() -> void:
  _is_pressed = true
  _update_state()

func _on_button_up() -> void:
  _is_pressed = false
  _update_state()

func _update_state() -> void:
  if _is_pressed:
    _apply_theme_state("pressed")
  elif _is_hovered:
    _apply_theme_state("hovered")
  else:
    _apply_theme_state("normal")