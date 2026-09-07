## NotebookDialogueView
##
## Purpose:
##   A specialized DiaJoggerView styled as a realistic spiral notebook / journal.
##   Features metallic spiral rings on the left, horizontal ruled paper lines,
##   fountain pen ink typography, and notebook-style checklist choices.
##
## Role in Architecture:
##   Extends DiaJoggerView. Can be used as a drop-in replacement for standard VN dialogue boxes
##   whenever a game wants notes, diaries, investigation journals, or notebook conversations.

extends DiaJoggerView
class_name NotebookDialogueView

@export var paper: NotebookPaper
@export var speaker_label: Label
@export var message_label: RichTextLabel
@export var advance_indicator: Label
@export var choices_container: VBoxContainer
@export var root_container: Control
@export var typewriter_chars_per_sec: float = 40.0

var _is_typing: bool = false
var _skip_typing: bool = false

func _ready() -> void:
  layer = 100
  if root_container != null: root_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_text(text: String, state: DiaJoggerState, is_dirty: bool = false, write_wait: float = -1.0) -> void:
  _is_cancelled = false
  text_started.emit(text, state)
  if root_container != null: root_container.show()
  if choices_container != null: choices_container.hide()
  
  _update_speaker(state)
  
  if advance_indicator != null: advance_indicator.hide()
  
  var speed_mult: float = float(state.get_data("speed", 1.0)) if state != null else 1.0
  await _run_typewriter(text, is_dirty, speed_mult)
  if _is_cancelled: return
  
  if write_wait >= 0.0:
    if write_wait > 0.0: await get_tree().create_timer(write_wait).timeout
    text_finished.emit()
    return
  
  if advance_indicator != null: advance_indicator.show()
  
  _waiting_for_input = true
  await advance_requested
  _waiting_for_input = false
  
  if advance_indicator != null: advance_indicator.hide()
  text_finished.emit()

func show_choice(options: Array[String]) -> int:
  _is_cancelled = false
  choice_presented.emit(options)
  if choices_container == null: return 0
  
  for child in choices_container.get_children():
    choices_container.remove_child(child)
    child.queue_free()
  
  _active_choice_holder = [-1]
  for i in range(options.size()):
    var btn := Button.new()
    btn.text = "[  ] %d. %s" % [i + 1, options[i]]
    btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
    btn.custom_minimum_size = Vector2(0, 42)
    btn.pressed.connect(func(): _on_choice_clicked(i, _active_choice_holder))
    choices_container.add_child(btn)
  
  choices_container.show()
  
  for child in choices_container.get_children():
    if child is Button:
      child.grab_focus()
      break
  
  _waiting_for_choice = true
  while _active_choice_holder[0] == -1 and not _is_cancelled: await choice_selected
  _waiting_for_choice = false
  
  choices_container.hide()
  return _active_choice_holder[0]

func cancel() -> void:
  _is_cancelled = true
  _is_typing = false
  _skip_typing = true
  _waiting_for_input = false
  _waiting_for_choice = false
  advance_requested.emit()
  choice_selected.emit(-1)
  hide_dialogue()

func hide_dialogue() -> void:
  if root_container != null: root_container.hide()
  if choices_container != null: choices_container.hide()

func _update_speaker(state: DiaJoggerState) -> void:
  if speaker_label == null: return
  if state != null and state.has_speaker():
    speaker_label.text = "✎ " + state.speaker + ":"
    speaker_label.show()
  else: speaker_label.hide()

func _run_typewriter(text: String, is_dirty: bool, speed_mult: float) -> void:
  if message_label == null: return
  
  var start_char := 0
  if is_dirty and not message_label.text.is_empty():
    start_char = message_label.text.length()
    message_label.text += " " + text
    start_char += 1
  else: message_label.text = text
  
  var total_chars := message_label.text.length()
  if typewriter_chars_per_sec <= 0.0 or total_chars == 0:
    message_label.visible_characters = -1
    return
  
  message_label.visible_characters = start_char
  _is_typing = true
  _skip_typing = false
  var effective_speed := typewriter_chars_per_sec * maxf(speed_mult, 0.1)
  var char_delay := 1.0 / effective_speed
  
  while message_label.visible_characters < total_chars:
    if _skip_typing or _is_cancelled:
      message_label.visible_characters = -1
      break
    await get_tree().create_timer(char_delay).timeout
    if _skip_typing or _is_cancelled:
      message_label.visible_characters = -1
      break
    message_label.visible_characters += 1
  
  _is_typing = false

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
    if _is_typing:
      _skip_typing = true
      get_viewport().set_input_as_handled()
    elif _waiting_for_input:
      advance_requested.emit()
      get_viewport().set_input_as_handled()
