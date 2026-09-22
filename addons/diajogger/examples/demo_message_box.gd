extends CanvasLayer
class_name DemoMessageBox

signal advance_requested
signal auto_toggled(is_auto: bool)
signal skip_toggled(is_skip: bool)
signal log_requested
signal menu_requested

@export var dialogue_box: PanelContainer
@export var speaker_badge: PanelContainer
@export var speaker_name_label: Label
@export var message_label: RichTextLabel
@export var advance_glyph: Label
@export var advance_button: BaseButton
@export var auto_button: Button
@export var skip_button: Button
@export var log_button: Button
@export var menu_button: Button
@export var typewriter_chars_per_sec: float = 45.0
@export var auto_delay: float = 1.6

var is_auto: bool = false:
  set(value):
    is_auto = value
    _update_auto_button_visual()
    auto_toggled.emit(value)
    if is_auto and _waiting_for_input: advance_requested.emit()

var is_skip: bool = false:
  set(value):
    is_skip = value
    _update_skip_button_visual()
    skip_toggled.emit(value)
    if is_skip and _waiting_for_input: advance_requested.emit()

var _waiting_for_input: bool = false
var _is_typing: bool = false
var _skip_typing: bool = false

func _ready() -> void:
  layer = 100
  if advance_button: advance_button.pressed.connect(_on_advance_clicked)
  if auto_button: auto_button.pressed.connect(toggle_auto)
  if skip_button: skip_button.pressed.connect(toggle_skip)
  if log_button: log_button.pressed.connect(func(): log_requested.emit())
  if menu_button: menu_button.pressed.connect(func(): menu_requested.emit())

func display_text(text: String, state: DiaJoggerState, is_dirty: bool = false, write_wait: float = -1.0) -> void:
  show()
  if dialogue_box: dialogue_box.show()
  if advance_glyph: advance_glyph.hide()

  _update_speaker(state)

  var speed_mult: float = float(state.get_data("speed", 1.0)) if state != null else 1.0
  await _run_typewriter_step(text, is_dirty, speed_mult)

  if write_wait >= 0.0:
    if is_skip: await get_tree().create_timer(0.04).timeout
    elif write_wait > 0.0: await get_tree().create_timer(write_wait).timeout
    return

  if advance_glyph: advance_glyph.show()

  if is_skip:
    await get_tree().create_timer(0.04).timeout
  elif is_auto:
    _waiting_for_input = true
    var timer := get_tree().create_timer(auto_delay)
    await _await_advance_or_timer(timer)
    _waiting_for_input = false
  else:
    _waiting_for_input = true
    await advance_requested
    _waiting_for_input = false

  if advance_glyph: advance_glyph.hide()

func _update_speaker(state: DiaJoggerState) -> void:
  if not speaker_badge or not speaker_name_label: return
  if state != null and state.has_speaker():
    speaker_name_label.text = state.speaker
    speaker_badge.show()
    match state.speaker.to_lower():
      "emily": speaker_name_label.modulate = Color(1.0, 0.9, 0.5)
      "deva": speaker_name_label.modulate = Color(0.4, 0.95, 0.85)
      _: speaker_name_label.modulate = Color.WHITE
  else:
    speaker_badge.hide()

func _run_typewriter_step(text: String, is_dirty: bool, speed_mult: float) -> void:
  if not message_label: return
  var start_char := 0
  if is_dirty and not message_label.text.is_empty():
    start_char = message_label.text.length()
    message_label.text += " " + text
    start_char += 1
  else: message_label.text = text

  var total_chars := message_label.text.length()
  if is_skip or typewriter_chars_per_sec <= 0.0 or total_chars == 0:
    message_label.visible_characters = -1
    return

  message_label.visible_characters = start_char
  _is_typing = true
  _skip_typing = false
  var char_delay: float = (1.0 / typewriter_chars_per_sec) / maxf(speed_mult, 0.1)

  for i in range(start_char, total_chars):
    if _skip_typing or is_skip:
      message_label.visible_characters = -1
      break
    message_label.visible_characters = i + 1
    await get_tree().create_timer(char_delay).timeout

  _is_typing = false
  _skip_typing = false

func _on_advance_clicked() -> void:
  if _is_typing:
    _skip_typing = true
    return
  if _waiting_for_input: advance_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_accept"):
    _on_advance_clicked()
    get_viewport().set_input_as_handled()
  elif event is InputEventKey and event.is_pressed() and not event.is_echo():
    if event.keycode == KEY_A: toggle_auto()
    elif event.keycode == KEY_TAB: toggle_skip()
    elif event.keycode == KEY_H: log_requested.emit()
    elif event.keycode == KEY_ESCAPE: menu_requested.emit()

func _await_advance_or_timer(timer: SceneTreeTimer) -> void:
  var advanced: Array[bool] = [false]
  var on_adv = func(): advanced[0] = true
  advance_requested.connect(on_adv, CONNECT_ONE_SHOT)
  while not advanced[0] and timer.time_left > 0.0 and is_inside_tree(): await get_tree().process_frame
  if advance_requested.is_connected(on_adv): advance_requested.disconnect(on_adv)

func toggle_auto() -> void:
  is_auto = not is_auto
  if is_auto and is_skip: is_skip = false

func toggle_skip() -> void:
  is_skip = not is_skip
  if is_skip and is_auto: is_auto = false

func _update_auto_button_visual() -> void:
  if not auto_button: return
  auto_button.text = "▶ Auto [ON]" if is_auto else "▶ Auto [A]"
  auto_button.modulate = Color(0.4, 1.0, 0.6) if is_auto else Color.WHITE

func _update_skip_button_visual() -> void:
  if not skip_button: return
  skip_button.text = "⏩ Skip [ON]" if is_skip else "⏩ Skip [Tab]"
  skip_button.modulate = Color(1.0, 0.7, 0.3) if is_skip else Color.WHITE
