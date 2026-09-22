extends CanvasLayer
class_name NovelMessageBox

signal advance_requested
signal auto_toggled(is_auto: bool)
signal skip_toggled(is_skip: bool)
signal log_requested
signal menu_requested

@export var message_box: GeneralMessageBox
@export var advance_button: BaseButton
@export var typewriter_chars_per_sec: float = 45.0
@export var auto_advance_delay: float = 1.5
@export var skip_delay: float = 0.04

var is_auto: bool = false:
  set(value):
    is_auto = value
    _update_button_visuals()
    auto_toggled.emit(value)
    if is_auto and _waiting_for_input: advance_requested.emit()

var is_skip: bool = false:
  set(value):
    is_skip = value
    _update_button_visuals()
    skip_toggled.emit(value)
    if is_skip and _waiting_for_input: advance_requested.emit()

var _waiting_for_input: bool = false
var _is_typing: bool = false
var _skip_typing: bool = false

func _ready() -> void:
  layer = 100
  if not message_box: message_box = find_child("GeneralMessageBox", true, false) as GeneralMessageBox
  if not advance_button: advance_button = find_child("AdvanceButton", true, false) as BaseButton
  if advance_button: advance_button.pressed.connect(_on_advance_pressed)
  _setup_hud_buttons()

func _setup_hud_buttons() -> void:
  if not message_box: return
  var auto_btn = message_box.find_child("AutoButton", true, false) as Button
  var skip_btn = message_box.find_child("SkipButton", true, false) as Button
  var log_btn = message_box.find_child("LogButton", true, false) as Button
  var menu_btn = message_box.find_child("MenuButton", true, false) as Button

  if auto_btn and not auto_btn.pressed.is_connected(_toggle_auto): auto_btn.pressed.connect(_toggle_auto)
  if skip_btn and not skip_btn.pressed.is_connected(_toggle_skip): skip_btn.pressed.connect(_toggle_skip)
  if log_btn and not log_btn.pressed.is_connected(func(): log_requested.emit()): log_btn.pressed.connect(func(): log_requested.emit())
  if menu_btn and not menu_btn.pressed.is_connected(func(): menu_requested.emit()): menu_btn.pressed.connect(func(): menu_requested.emit())

func display_text(text: String, state: DiaJoggerState, is_dirty: bool = false, write_wait: float = -1.0) -> void:
  show_box()
  if message_box:
    message_box.speaker_name = state.speaker if state and state.has_speaker() else ""
    await _apply_message_text(text, is_dirty, float(state.get_data("speed", 1.0)) if state else 1.0)

  if write_wait >= 0.0:
    if is_skip: await get_tree().create_timer(skip_delay).timeout
    elif write_wait > 0.0: await get_tree().create_timer(write_wait).timeout
    return

  if is_skip:
    await get_tree().create_timer(skip_delay).timeout
    return

  _waiting_for_input = true
  if is_auto:
    var timer = get_tree().create_timer(auto_advance_delay)
    await _await_advance_or_timer(timer)
  else:
    await advance_requested
  _waiting_for_input = false

func _apply_message_text(text: String, is_dirty: bool, speed_mult: float) -> void:
  var label: RichTextLabel = message_box.find_child("MessageLabel", true, false) as RichTextLabel if message_box else null
  if not label:
    if is_dirty and not message_box.message_text.is_empty(): message_box.message_text += " " + text
    else: message_box.message_text = text
    return

  var start_char := 0
  if is_dirty and not message_box.message_text.is_empty():
    start_char = message_box.message_text.length()
    message_box.message_text += " " + text
    start_char += 1
  else:
    message_box.message_text = text

  var total_chars := message_box.message_text.length()
  if is_skip or typewriter_chars_per_sec <= 0.0 or total_chars == 0:
    label.visible_characters = -1
    return

  label.visible_characters = start_char
  _is_typing = true
  _skip_typing = false
  var char_delay: float = (1.0 / typewriter_chars_per_sec) / maxf(speed_mult, 0.1)

  for i in range(start_char, total_chars):
    if _skip_typing or is_skip:
      label.visible_characters = -1
      break
    label.visible_characters = i + 1
    await get_tree().create_timer(char_delay).timeout

  _is_typing = false
  _skip_typing = false

func _on_advance_pressed() -> void:
  if _is_typing:
    _skip_typing = true
    return
  if _waiting_for_input: advance_requested.emit()

func _await_advance_or_timer(timer: SceneTreeTimer) -> void:
  var advanced: Array[bool] = [false]
  var on_adv = func(): advanced[0] = true
  advance_requested.connect(on_adv, CONNECT_ONE_SHOT)
  while not advanced[0] and timer.time_left > 0.0 and is_inside_tree(): await get_tree().process_frame
  if advance_requested.is_connected(on_adv): advance_requested.disconnect(on_adv)

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_accept"):
    _on_advance_pressed()
    get_viewport().set_input_as_handled()
  elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
    _on_advance_pressed()
    get_viewport().set_input_as_handled()
  elif event is InputEventKey and event.is_pressed() and not event.is_echo():
    if event.keycode == KEY_A: _toggle_auto()
    elif event.keycode == KEY_TAB: _toggle_skip()
    elif event.keycode == KEY_H: log_requested.emit()
    elif event.keycode == KEY_ESCAPE: menu_requested.emit()

func _toggle_auto() -> void:
  is_auto = not is_auto
  if is_auto and is_skip: is_skip = false

func _toggle_skip() -> void:
  is_skip = not is_skip
  if is_skip and is_auto: is_auto = false

func _update_button_visuals() -> void:
  if not message_box: return
  var auto_btn = message_box.find_child("AutoButton", true, false) as Button
  var skip_btn = message_box.find_child("SkipButton", true, false) as Button
  if auto_btn: auto_btn.button_pressed = is_auto
  if skip_btn: skip_btn.button_pressed = is_skip

func show_box() -> void: show()
func hide_box() -> void: hide()
