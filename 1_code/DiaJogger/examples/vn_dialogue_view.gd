## VNDialogueView
##
## Purpose:
##   A multi-character visual novel dialogue view demonstrating how DiaJogger
##   controls speaker highlights, emotions, typewriter text, and character staging.
##
## Role in Architecture:
##   Extends DiaJoggerView. Coordinates presentation across multiple actors:
##   - Emily & Deva sprite illumination and emotion animations.
##   - Dynamic speaker badge accent colors per character.
##   - Typewriter text display with instant skip on click / space.
##   - Supports @dirty (non-clearing buffer) and @write_wait (timed auto-advance).
##   - Handles arbitrary @d metadata (e.g. @d sfx train, @d speed 0.8).
##   - Timed choices with countdown progress bar and fallback selection.
##   - Auto-Forward, Skip, and Dialogue History Backlog with audio replay.

extends DiaJoggerView
class_name VNDialogueView

const SFX_TRAIN = preload("res://1_code/DiaJogger/examples/train.mp3")

@export var emily_sprite: TextureRect
@export var deva_sprite: TextureRect
@export var background_rect: TextureRect
@export var dialogue_box: PanelContainer
@export var speaker_badge: PanelContainer
@export var speaker_name_label: Label
@export var message_label: RichTextLabel
@export var advance_glyph: Label
@export var choices_box: VBoxContainer
@export var choice_timer_bar: ProgressBar
@export var choice_timer_label: Label
@export var sfx_player: AudioStreamPlayer
@export var log_modal: Control
@export var log_list: VBoxContainer
@export var auto_button: Button
@export var skip_button: Button
@export var typewriter_chars_per_sec: float = 40.0

var is_auto: bool = false
var is_skipping: bool = false
var dialogue_history: Array[Dictionary] = []

var _is_typing: bool = false
var _skip_typing: bool = false
var _emily_base_y: float = 0.0
var _deva_base_y: float = 0.0

func _ready() -> void:
  layer = 100
  if emily_sprite != null: _emily_base_y = emily_sprite.position.y
  if deva_sprite != null: _deva_base_y = deva_sprite.position.y
  _setup_ui_bindings()

func show_text(text: String, state: DiaJoggerState, is_dirty: bool = false, write_wait: float = -1.0) -> void:
  _is_cancelled = false
  text_started.emit(text, state)
  if dialogue_box != null: dialogue_box.show()
  if choices_box != null: choices_box.hide()
  
  _update_speaker(state)
  _update_character_staging(state)
  _record_history(state, text, is_dirty)
  _handle_metadata(state)
  
  if advance_glyph != null: advance_glyph.hide()
  
  var speed_mult: float = float(state.get_data("speed", 1.0)) if state != null else 1.0
  await _run_typewriter_step(text, is_dirty, speed_mult)
  if _is_cancelled: return
  
  if write_wait >= 0.0:
    if is_skipping: await get_tree().create_timer(0.04).timeout
    elif write_wait > 0.0: await get_tree().create_timer(write_wait).timeout
    text_finished.emit()
    return
  
  if advance_glyph != null: advance_glyph.show()
  
  if is_skipping: await get_tree().create_timer(0.04).timeout
  elif is_auto:
    _waiting_for_input = true
    var auto_timer := get_tree().create_timer(1.6)
    auto_timer.timeout.connect(func(): if _waiting_for_input and is_auto: advance_requested.emit())
    await advance_requested
    _waiting_for_input = false
  else:
    _waiting_for_input = true
    await advance_requested
    _waiting_for_input = false
  
  if advance_glyph != null: advance_glyph.hide()
  text_finished.emit()

func show_choice(options: Array[String]) -> int:
  _is_cancelled = false
  choice_presented.emit(options)
  if choices_box == null: return 0
  
  if choice_timer_bar != null: choice_timer_bar.hide()
  if choice_timer_label != null: choice_timer_label.hide()
  
  var was_auto := is_auto
  if is_skipping: toggle_skip()
  
  for child in choices_box.get_children():
    if child == choice_timer_bar or child == choice_timer_label: continue
    choices_box.remove_child(child)
    child.queue_free()
  
  _active_choice_holder = [-1]
  for i in range(options.size()):
    var btn := Button.new()
    btn.text = options[i]
    btn.custom_minimum_size = Vector2(480, 54)
    btn.pressed.connect(func(): _on_choice_clicked(i, _active_choice_holder))
    choices_box.add_child(btn)
  
  choices_box.show()
  
  for child in choices_box.get_children():
    if child is Button:
      child.grab_focus()
      break
  
  _waiting_for_choice = true
  while _active_choice_holder[0] == -1 and not _is_cancelled: await choice_selected
  _waiting_for_choice = false
  
  choices_box.hide()
  if choice_timer_bar != null: choice_timer_bar.hide()
  if choice_timer_label != null: choice_timer_label.hide()
  if was_auto and not is_auto: toggle_auto()
  return _active_choice_holder[0]

func set_choice_timer_visual(time_left: float, max_time: float) -> void:
  if choice_timer_bar != null:
    choice_timer_bar.max_value = max_time
    choice_timer_bar.value = maxf(time_left, 0.0)
    choice_timer_bar.visible = time_left > 0.0
  if choice_timer_label != null:
    choice_timer_label.text = "⏱️ Время на выбор: %.1fс" % maxf(time_left, 0.0)
    choice_timer_label.visible = time_left > 0.0

func toggle_auto() -> void:
  is_auto = not is_auto
  if is_auto and is_skipping: toggle_skip()
  if auto_button != null:
    auto_button.text = "▶ Auto [ON]" if is_auto else "▶ Auto"
    auto_button.modulate = Color(0.4, 1.0, 0.6) if is_auto else Color.WHITE
  if is_auto and _waiting_for_input: advance_requested.emit()

func toggle_skip() -> void:
  is_skipping = not is_skipping
  if is_skipping and is_auto: toggle_auto()
  if skip_button != null:
    skip_button.text = "⏩ Skip [ON]" if is_skipping else "⏩ Skip"
    skip_button.modulate = Color(1.0, 0.7, 0.3) if is_skipping else Color.WHITE
  if is_skipping:
    _skip_typing = true
    if _waiting_for_input: advance_requested.emit()

func open_log() -> void:
  if log_modal == null: return
  _rebuild_log_ui()
  log_modal.show()

func close_log() -> void: if log_modal != null: log_modal.hide()

func toggle_log() -> void:
  if log_modal == null: return
  if log_modal.visible: close_log()
  else: open_log()

func play_sfx(sfx_key: String) -> void:
  if sfx_player == null: return
  match sfx_key:
    "train":
      sfx_player.stream = SFX_TRAIN
      sfx_player.play()

func cancel() -> void:
  _is_cancelled = true
  _is_typing = false
  _skip_typing = true
  _waiting_for_input = false
  advance_requested.emit()
  choice_selected.emit(-1)
  hide_dialogue()

func hide_dialogue() -> void:
  if dialogue_box != null: dialogue_box.hide()
  if choices_box != null: choices_box.hide()
  if log_modal != null: log_modal.hide()

func _handle_metadata(state: DiaJoggerState) -> void:
  if state == null: return
  var sfx := str(state.get_data("sfx", "")).strip_edges()
  if not sfx.is_empty():
    play_sfx(sfx)
    state.data.erase("sfx")

func _record_history(state: DiaJoggerState, text: String, is_dirty: bool) -> void:
  var spk := state.speaker if state != null else ""
  var sfx := str(state.get_data("sfx", "")) if state != null else ""
  if is_dirty and not dialogue_history.is_empty() and dialogue_history[-1].get("speaker", "") == spk:
    dialogue_history[-1]["text"] += " " + text
    if not sfx.is_empty(): dialogue_history[-1]["sfx"] = sfx
  else: dialogue_history.append({"speaker": spk, "text": text, "sfx": sfx})

func _rebuild_log_ui() -> void:
  if log_list == null: return
  for child in log_list.get_children():
    log_list.remove_child(child)
    child.queue_free()
  
  for entry in dialogue_history:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    
    var spk_label := Label.new()
    var spk: String = entry.get("speaker", "")
    spk_label.text = spk if not spk.is_empty() else "—"
    spk_label.custom_minimum_size = Vector2(100, 0)
    match spk:
      "Emily": spk_label.modulate = Color(1.0, 0.88, 0.45)
      "Deva": spk_label.modulate = Color(0.45, 0.92, 0.85)
      "Ren": spk_label.modulate = Color(0.9, 0.9, 0.9)
      _: spk_label.modulate = Color(0.65, 0.65, 0.7)
    row.add_child(spk_label)
    
    var txt_label := Label.new()
    txt_label.text = entry.get("text", "")
    txt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    txt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    row.add_child(txt_label)
    
    var sfx: String = entry.get("sfx", "")
    if not sfx.is_empty():
      var sfx_btn := Button.new()
      sfx_btn.text = "🔊 " + sfx.capitalize()
      sfx_btn.pressed.connect(func(): play_sfx(sfx))
      row.add_child(sfx_btn)
    
    log_list.add_child(row)

func _run_typewriter_step(text: String, is_dirty: bool, speed_mult: float) -> void:
  if message_label == null: return
  
  var start_char := 0
  if is_dirty and not message_label.text.is_empty():
    start_char = message_label.text.length()
    message_label.text += " " + text
    start_char += 1
  else: message_label.text = text
  
  var total_chars := message_label.text.length()
  if is_skipping or typewriter_chars_per_sec <= 0.0 or total_chars == 0:
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

func _update_speaker(state: DiaJoggerState) -> void:
  if speaker_name_label == null: return
  if state != null and state.has_speaker():
    speaker_name_label.text = state.speaker
    if speaker_badge != null: speaker_badge.show()
    match state.speaker:
      "Emily": speaker_name_label.modulate = Color(1.0, 0.88, 0.45)
      "Deva": speaker_name_label.modulate = Color(0.45, 0.92, 0.85)
      _: speaker_name_label.modulate = Color(0.9, 0.9, 0.9)
  else: if speaker_badge != null: speaker_badge.hide()

func _update_character_staging(state: DiaJoggerState) -> void:
  if state == null: return
  var tween := create_tween()
  tween.set_parallel(true)
  
  match state.speaker:
    "Emily":
      if emily_sprite != null:
        tween.tween_property(emily_sprite, "modulate", Color.WHITE, 0.2)
        _animate_actor(emily_sprite, _emily_base_y, state.emotion)
      if deva_sprite != null: tween.tween_property(deva_sprite, "modulate", Color(0.55, 0.55, 0.65), 0.2)
    "Deva":
      if deva_sprite != null:
        tween.tween_property(deva_sprite, "modulate", Color.WHITE, 0.2)
        _animate_actor(deva_sprite, _deva_base_y, state.emotion)
      if emily_sprite != null: tween.tween_property(emily_sprite, "modulate", Color(0.55, 0.55, 0.65), 0.2)
    "Ren":
      if emily_sprite != null: tween.tween_property(emily_sprite, "modulate", Color(0.68, 0.68, 0.75), 0.2)
      if deva_sprite != null: tween.tween_property(deva_sprite, "modulate", Color(0.68, 0.68, 0.75), 0.2)
    _:
      if emily_sprite != null: tween.tween_property(emily_sprite, "modulate", Color(0.48, 0.48, 0.55), 0.2)
      if deva_sprite != null: tween.tween_property(deva_sprite, "modulate", Color(0.48, 0.48, 0.55), 0.2)

func _animate_actor(sprite: TextureRect, base_y: float, emotion: String) -> void:
  var y_pos := base_y if base_y != 0.0 else sprite.position.y
  match emotion:
    "happy":
      var t := create_tween()
      t.tween_property(sprite, "position:y", y_pos - 18.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
      t.tween_property(sprite, "position:y", y_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    "surprised":
      var t := create_tween()
      t.tween_property(sprite, "position:y", y_pos - 28.0, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
      t.tween_property(sprite, "position:y", y_pos, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
    "sad", "worried":
      var t := create_tween()
      t.tween_property(sprite, "position:y", y_pos + 12.0, 0.2).set_trans(Tween.TRANS_SINE)
      t.tween_property(sprite, "position:y", y_pos, 0.25).set_trans(Tween.TRANS_SINE)

func _setup_ui_bindings() -> void:
  if dialogue_box != null: dialogue_box.gui_input.connect(_on_box_gui_input)

func _on_box_gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
    if _is_typing: _skip_typing = true
    elif _waiting_for_input: advance_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
  if log_modal != null and log_modal.visible:
    if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.is_pressed() and event.keycode == KEY_H):
      close_log()
      get_viewport().set_input_as_handled()
      return
  
  if event is InputEventKey and event.is_pressed() and not event.is_echo():
    if event.keycode == KEY_A:
      toggle_auto()
      get_viewport().set_input_as_handled()
      return
    elif event.keycode == KEY_TAB:
      toggle_skip()
      get_viewport().set_input_as_handled()
      return
    elif event.keycode == KEY_H:
      toggle_log()
      get_viewport().set_input_as_handled()
      return
  
  if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
    if _is_typing:
      _skip_typing = true
      get_viewport().set_input_as_handled()
    elif _waiting_for_input:
      advance_requested.emit()
      get_viewport().set_input_as_handled()
