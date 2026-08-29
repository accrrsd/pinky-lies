@tool
extends CheckBox

@export var sound_button_comp: SoundButtonComp
@export var hover_button_comp: HoverButtonComp

@export var disable_mark_normal: bool = true

@export_group("Theme Handlers")
@export var normal_theme: ControlThemeHandlerRes
@export var toggled_theme: ControlThemeHandlerRes

@export_group("DEV")
@export_tool_button("Apply normal theme", "Callable") var dev_apply_normal_theme = func():
  if normal_theme: normal_theme.apply_theme(self, theme_type_variation)
@export_tool_button("Apply toggled theme", "Callable") var dev_apply_toggled_theme = func():
  if toggled_theme: toggled_theme.apply_theme(self, theme_type_variation)

@export_group("State Test")
@export var toggled_test: bool = false:
  set(value):
    if not is_node_ready(): await ready
    toggled_test = value
    _apply_theme_state("toggled" if value else "normal")

func _apply_theme_state(state: String = "normal") -> void:
  match state:
    "normal": if normal_theme: normal_theme.apply_theme(self, theme_type_variation)
    "toggled": if toggled_theme: toggled_theme.apply_theme(self, theme_type_variation)

func _ready() -> void:
  _apply_theme_state("toggled" if button_pressed else "normal")
  if Engine.is_editor_hint(): return
  if disable_mark_normal: %CheckMark.visible = button_pressed
  button_down.connect(_on_button_down)
  button_up.connect(_on_button_release)
  toggled.connect(_on_button_toggled)

func _on_button_toggled(value: bool) -> void:
  if disable_mark_normal: %CheckMark.visible = value
  _apply_theme_state("toggled" if value else "normal")

func _on_button_down() -> void:
  var anim = get_node_or_null("%AnimationPlayer") as AnimationPlayer
  if anim: anim.play("press")

func _on_button_release() -> void:
  var anim = get_node_or_null("%AnimationPlayer") as AnimationPlayer
  if anim: anim.play_backwards("press")
