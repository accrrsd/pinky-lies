## DemoDialogueScene
##
## Purpose:
##   Techno-demo showcasing the strengths of DiaJogger:
##   1. GDScript-controlled dialogue loops (no @jump in Markdown).
##   2. Multi-actor staging (Emily & Deva lighting and animations).
##   3. Timed choices with countdown timers and fallback options.
##   4. Time flow controls (Auto-Forward, Skip, History Log).
##   5. Live Quick Save / Quick Load (F5 / F9, S / L, or HUD buttons).

extends Control
class_name DemoDialogueScene

const SAVE_PATH = "user://diajogger_demo_save.json"

@onready var vn_view: VNDialogueView = $VNDialogueView
@onready var background: TextureRect = $Background
@onready var emily: TextureRect = $CharacterLayer/EmilySprite
@onready var deva: TextureRect = $CharacterLayer/DevaSprite
@onready var save_btn: Button = %SaveButton
@onready var load_btn: Button = %LoadButton
@onready var auto_btn: Button = %AutoButton
@onready var skip_btn: Button = %SkipButton
@onready var log_btn: Button = %LogButton
@onready var close_log_btn: Button = $VNDialogueView/UIRoot/LogModal/Margin/VBox/Header/CloseButton
@onready var toast_label: Label = %ToastLabel

var _current_step: String = "act1"
var _story_generation: int = 0
var _saved_data: Dictionary = {}

func _ready() -> void:
  DiaJogger.set_view(vn_view)
  DiaJogger.load_file("res://1_code/DiaJogger/examples/station.md")
  _setup_hud()
  _run_story("act1")

func _setup_hud() -> void:
  if save_btn != null: save_btn.pressed.connect(quick_save)
  if load_btn != null: load_btn.pressed.connect(quick_load)
  if auto_btn != null: auto_btn.pressed.connect(vn_view.toggle_auto)
  if skip_btn != null: skip_btn.pressed.connect(vn_view.toggle_skip)
  if log_btn != null: log_btn.pressed.connect(vn_view.toggle_log)
  if close_log_btn != null: close_log_btn.pressed.connect(vn_view.close_log)
  if toast_label != null: toast_label.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.is_pressed() and not event.is_echo():
    if event.keycode == KEY_F5 or event.keycode == KEY_S:
      quick_save()
      get_viewport().set_input_as_handled()
    elif event.keycode == KEY_F9 or event.keycode == KEY_L:
      quick_load()
      get_viewport().set_input_as_handled()

func _run_story(start_step: String, is_resumed: bool = false) -> void:
  _story_generation += 1
  var gen := _story_generation
  _current_step = start_step
  
  if _current_step == "act1":
    if is_resumed: await DiaJogger.resume()
    else: await DiaJogger.play("Station/Act 1")
    if gen != _story_generation: return
    _current_step = "loop"
  
  if _current_step == "train":
    if is_resumed: await DiaJogger.resume()
    else: await DiaJogger.play("Station/AskTrain")
    if gen != _story_generation: return
    var timed_choice := await _timed_choice([
      "Быстро бежать на третий путь! [По умолчанию / 6с]",
      "Остаться и ещё раз проверить билеты"
    ], 6.0, 0)
    if gen != _story_generation: return
    if timed_choice == 0: _current_step = "leave"
    else: _current_step = "loop"
  elif _current_step == "letter":
    if is_resumed: await DiaJogger.resume()
    else: await DiaJogger.play("Station/AskLetter")
    if gen != _story_generation: return
    _current_step = "loop"
  elif _current_step == "deva":
    if is_resumed: await DiaJogger.resume()
    else: await DiaJogger.play("Station/AskDeva")
    if gen != _story_generation: return
    _current_step = "loop"
  
  if _current_step == "loop":
    var exploring := true
    while exploring and gen == _story_generation:
      var choice := await DiaJogger.choice([
        "Спросить про поезд (со звуком гудка @d sfx train)",
        "Спросить про странное письмо (с инлайн склейкой @dirty)",
        "Спросить у Девы про поездку",
        "Закончить разговор и идти на посадку"
      ])
      if gen != _story_generation or choice < 0: return
      
      match choice:
        0:
          _current_step = "train"
          await DiaJogger.play("Station/AskTrain")
          if gen != _story_generation: return
          var timed_choice := await _timed_choice([
            "Быстро бежать на третий путь! [По умолчанию / 6с]",
            "Остаться и ещё раз проверить билеты"
          ], 6.0, 0)
          if gen != _story_generation: return
          if timed_choice == 0:
            exploring = false
            break
          else: _current_step = "loop"
        1:
          _current_step = "letter"
          await DiaJogger.play("Station/AskLetter")
          if gen != _story_generation: return
          _current_step = "loop"
        2:
          _current_step = "deva"
          await DiaJogger.play("Station/AskDeva")
          if gen != _story_generation: return
          _current_step = "loop"
        3:
          exploring = false
        _: return
    
    if gen != _story_generation: return
    _current_step = "leave"
  
  if _current_step == "leave":
    if is_resumed: await DiaJogger.resume()
    else: await DiaJogger.play("Station/Leave")

func quick_save() -> void:
  var save_dict := {
    "step": _current_step,
    "diajogger": DiaJogger.serialize_state(),
    "history": vn_view.dialogue_history.duplicate(true) if vn_view != null else [],
    "bg_modulate": [background.modulate.r, background.modulate.g, background.modulate.b, background.modulate.a]
  }
  _saved_data = save_dict
  var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  if file:
    file.store_string(JSON.stringify(save_dict, "  "))
    file.close()
  _show_toast("💾 Сохранено! [F5 / S]")

func quick_load() -> void:
  if _saved_data.is_empty() and FileAccess.file_exists(SAVE_PATH):
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
      var json := JSON.new()
      if json.parse(file.get_as_text()) == OK and json.data is Dictionary: _saved_data = json.data
      file.close()
  
  if _saved_data.is_empty():
    _show_toast("⚠️ Нет сохранений!")
    return
  
  DiaJogger.stop()
  DiaJogger.restore_state(_saved_data.get("diajogger", {}))
  if vn_view != null: vn_view.dialogue_history = _saved_data.get("history", []).duplicate(true)
  
  var bg_arr: Array = _saved_data.get("bg_modulate", [1.0, 1.0, 1.0, 1.0])
  if bg_arr.size() == 4: background.modulate = Color(bg_arr[0], bg_arr[1], bg_arr[2], bg_arr[3])
  
  _show_toast("📂 Загружено! [F9 / L]")
  
  var target_step: String = _saved_data.get("step", "loop")
  _run_story(target_step, target_step != "loop")

func _show_toast(message: String) -> void:
  if toast_label == null: return
  toast_label.text = message
  var tween := create_tween()
  tween.tween_property(toast_label, "modulate:a", 1.0, 0.2)
  tween.tween_interval(1.5)
  tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)

func _timed_choice(options: Array[String], timeout: float, default_index: int = 0) -> int:
  var time_left := timeout
  var active := [true]
  var ticker := func():
    while active[0] and time_left > 0.0:
      if vn_view != null: vn_view.set_choice_timer_visual(time_left, timeout)
      await get_tree().create_timer(0.05).timeout
      time_left -= 0.05
    if active[0] and DiaJogger.is_waiting_choice(): DiaJogger.select_choice(default_index)
    if vn_view != null: vn_view.set_choice_timer_visual(0.0, 0.0)
  ticker.call()
  var result := await DiaJogger.choice(options)
  active[0] = false
  if vn_view != null: vn_view.set_choice_timer_visual(0.0, 0.0)
  return result
