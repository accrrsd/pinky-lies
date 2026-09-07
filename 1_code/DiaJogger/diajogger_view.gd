## DiaJoggerView
##
## Purpose:
##   The presentation and input boundary for dialogue. Displays text, speaker names,
##   choices, and awaits player advance input.
##
## Role in Architecture:
##   Strictly separated from gameplay logic. It receives text and presentation state
##   from DiaJoggerRuntime, renders it to the screen, and returns user choice indices.
##   Includes a built-in default UI out-of-the-box, or can be inherited/replaced
##   with a custom visual novel interface.
##
## Usage:
##   # In custom UI script:
##   extends DiaJoggerView
##   func show_text(text: String, state: DiaJoggerState) -> void: ...
##   func show_choice(options: Array[String]) -> int: ...
##
##   # Registering with facade:
##   DiaJogger.set_view($MyCustomDialogueUI)

extends CanvasLayer
class_name DiaJoggerView

signal text_started(text: String, state: DiaJoggerState)
signal text_finished
signal advance_requested
signal choice_presented(options: Array[String])
signal choice_selected(index: int)

@export var typing_speed: float = 0.0 # 0.0 means instant display
@export var default_box_visible: bool = true

var panel: PanelContainer
var speaker_label: Label
var dialogue_label: RichTextLabel
var advance_indicator: Label
var choices_container: VBoxContainer
var _waiting_for_input: bool = false
var _waiting_for_choice: bool = false
var _is_cancelled: bool = false
var _active_choice_holder: Array[int] = [-1]

func _ready() -> void:
  layer = 100
  _build_default_ui_if_needed()

func show_text(text: String, state: DiaJoggerState, is_dirty: bool = false, write_wait: float = -1.0) -> void:
  _is_cancelled = false
  _ensure_ui()
  text_started.emit(text, state)
  panel.show()
  choices_container.hide()
  
  if state != null and state.has_speaker():
    speaker_label.text = state.speaker
    speaker_label.show()
  else: speaker_label.hide()
  
  if is_dirty and not dialogue_label.text.is_empty(): dialogue_label.text += " " + text
  else: dialogue_label.text = text
  
  if write_wait >= 0.0:
    if write_wait > 0.0: await get_tree().create_timer(write_wait).timeout
    text_finished.emit()
    return
  
  advance_indicator.show()
  _waiting_for_input = true
  await advance_requested
  _waiting_for_input = false
  advance_indicator.hide()
  text_finished.emit()

func show_choice(options: Array[String]) -> int:
  _is_cancelled = false
  _ensure_ui()
  choice_presented.emit(options)
  
  for child in choices_container.get_children():
    choices_container.remove_child(child)
    child.queue_free()
  
  _active_choice_holder = [-1]
  for i in range(options.size()):
    var btn := Button.new()
    btn.text = options[i]
    btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
    btn.pressed.connect(func(): _on_choice_clicked(i, _active_choice_holder))
    choices_container.add_child(btn)
  
  choices_container.show()
  
  if choices_container.get_child_count() > 0:
    var first_btn := choices_container.get_child(0) as Button
    if first_btn != null: first_btn.grab_focus()
  
  _waiting_for_choice = true
  while _active_choice_holder[0] == -1 and not _is_cancelled: await choice_selected
  _waiting_for_choice = false
  
  choices_container.hide()
  return _active_choice_holder[0]

func select_choice(index: int) -> void:
  if not _waiting_for_choice: return
  _active_choice_holder[0] = index
  choice_selected.emit(index)

func is_waiting_choice() -> bool: return _waiting_for_choice

func cancel() -> void:
  _is_cancelled = true
  _waiting_for_input = false
  _waiting_for_choice = false
  advance_requested.emit()
  choice_selected.emit(-1)
  hide_dialogue()

func hide_dialogue() -> void:
  if panel != null: panel.hide()
  if choices_container != null: choices_container.hide()

func _on_choice_clicked(index: int, target_holder: Array[int]) -> void:
  target_holder[0] = index
  choice_selected.emit(index)

func _unhandled_input(event: InputEvent) -> void:
  if not _waiting_for_input: return
  if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
    advance_requested.emit()
    get_viewport().set_input_as_handled()

func _ensure_ui() -> void: if panel == null: _build_default_ui_if_needed()

func _build_default_ui_if_needed() -> void:
  if panel != null: return
  
  var root_control := Control.new()
  root_control.name = "DialogueRoot"
  root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
  root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(root_control)
  
  panel = PanelContainer.new()
  panel.name = "DialogueBox"
  panel.anchor_left = 0.1
  panel.anchor_right = 0.9
  panel.anchor_top = 0.72
  panel.anchor_bottom = 0.95
  panel.mouse_filter = Control.MOUSE_FILTER_STOP
  root_control.add_child(panel)
  
  var margin := MarginContainer.new()
  margin.add_theme_constant_override("margin_left", 20)
  margin.add_theme_constant_override("margin_top", 16)
  margin.add_theme_constant_override("margin_right", 20)
  margin.add_theme_constant_override("margin_bottom", 16)
  panel.add_child(margin)
  
  var vbox := VBoxContainer.new()
  vbox.add_theme_constant_override("separation", 8)
  margin.add_child(vbox)
  
  speaker_label = Label.new()
  speaker_label.name = "SpeakerLabel"
  speaker_label.add_theme_font_size_override("font_size", 22)
  speaker_label.modulate = Color(1.0, 0.85, 0.4)
  vbox.add_child(speaker_label)
  
  dialogue_label = RichTextLabel.new()
  dialogue_label.name = "DialogueLabel"
  dialogue_label.bbcode_enabled = true
  dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
  dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  dialogue_label.add_theme_font_size_override("normal_font_size", 20)
  vbox.add_child(dialogue_label)
  
  advance_indicator = Label.new()
  advance_indicator.name = "AdvanceIndicator"
  advance_indicator.text = "▼"
  advance_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  advance_indicator.modulate = Color(0.8, 0.8, 0.8, 0.7)
  advance_indicator.hide()
  vbox.add_child(advance_indicator)
  
  choices_container = VBoxContainer.new()
  choices_container.name = "ChoicesContainer"
  choices_container.anchor_left = 0.3
  choices_container.anchor_right = 0.7
  choices_container.anchor_top = 0.35
  choices_container.anchor_bottom = 0.65
  choices_container.add_theme_constant_override("separation", 10)
  choices_container.hide()
  root_control.add_child(choices_container)
  
  panel.gui_input.connect(_on_panel_gui_input)

func _on_panel_gui_input(event: InputEvent) -> void:
  if not _waiting_for_input: return
  if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT: advance_requested.emit()
