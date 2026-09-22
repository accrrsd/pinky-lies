@tool
extends PanelContainer

enum IconSide { LEFT, RIGHT }

@export var icon_side: IconSide = IconSide.LEFT:
  set(value):
    icon_side = value
    _update_icon_side()

@export_multiline var text: String = "":
  set(value):
    text = value
    var label = get_node_or_null("%Label")
    if label: label.text = value

@export var icon: Texture2D = null:
  set(value):
    icon = value
    var icon_rect = get_node_or_null("%Icon")
    if not icon_rect: icon_rect = find_child("Icon", true, false) as TextureRect
    if icon_rect:
      icon_rect.texture = value
      icon_rect.visible = (value != null)

@export var icon_modulate: Color = Color.WHITE:
  set(value):
    icon_modulate = value
    var icon_rect = get_node_or_null("%Icon")
    if not icon_rect: icon_rect = find_child("Icon", true, false) as TextureRect
    if icon_rect: icon_rect.modulate = value

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
  if not text.is_empty():
    var label = get_node_or_null("%Label")
    if not label: label = find_child("Label", true, false)
    if label: label.text = text

  if icon:
    var icon_rect = get_node_or_null("%Icon")
    if not icon_rect: icon_rect = find_child("Icon", true, false) as TextureRect
    if icon_rect:
      icon_rect.texture = icon
      icon_rect.modulate = icon_modulate
      icon_rect.visible = true

  _update_icon_side()

  button = %ButtonHandler
  if not button: button = find_child("ButtonHandler", true, false) as SoundButton
  if not button: return

  if pressed_sound and not button.pressed_sound: button.pressed_sound = pressed_sound
  if hover_sound and not button.hover_sound: button.hover_sound = hover_sound
  if Engine.is_editor_hint(): return
  button.hover_changed.connect(_on_button_hover_changed)
  button.focus_changed.connect(_on_button_focus_changed)
  button.button_down.connect(_on_button_down)
  button.button_up.connect(_on_button_up)

func _update_icon_side() -> void:
  var icon_rect = get_node_or_null("%Icon")
  if not icon_rect: icon_rect = find_child("Icon", true, false) as TextureRect
  if icon_rect and icon_rect.get_parent():
    var parent_container = icon_rect.get_parent()
    if icon_side == IconSide.LEFT: parent_container.move_child(icon_rect, 0)
    else: parent_container.move_child(icon_rect, parent_container.get_child_count() - 1)

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
  if _is_pressed: _apply_theme_state("pressed")
  elif _is_hovered: _apply_theme_state("hovered")
  else: _apply_theme_state("normal")