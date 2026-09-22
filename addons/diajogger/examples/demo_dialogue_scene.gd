extends Control
class_name DemoDialogueScene

const SAVE_PATH = "user://diajogger_demo_save.json"
const SFX_TRAIN = preload("res://addons/diajogger/examples/train.mp3")

@onready var background: TextureRect = $Background
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

@onready var character_layer: DemoCharacterLayer = $DemoCharacterLayer
@onready var message_box: DemoMessageBox = $DemoMessageBox
@onready var choices_layer: DemoChoicesLayer = $DemoChoicesLayer
@onready var menu_layer: DemoMenuLayer = $DemoMenuLayer

var _current_step: String = "act1"
var _story_generation: int = 0
var _saved_data: Dictionary = {}
var _current_music: String = ""

func _ready() -> void:
  DiaJogger.set_text_handler(_on_display_text)
  DiaJogger.set_choice_handler(choices_layer.display_choices)
  DiaJogger.state_changed.connect(_on_state_changed)

  if message_box:
    message_box.log_requested.connect(menu_layer.open_log)
    message_box.menu_requested.connect(menu_layer.open_menu)

  if menu_layer:
    menu_layer.jump_to_history.connect(_on_jump_to_history)
    menu_layer.save_requested.connect(quick_save)
    menu_layer.load_requested.connect(quick_load)
    menu_layer.sfx_replay_requested.connect(play_sfx)

  DiaJogger.load_file("res://addons/diajogger/examples/station.md")
  _run_story("act1")

func _on_display_text(text: String, state: DiaJoggerState, is_dirty: bool = false, write_wait: float = -1.0) -> void:
  if menu_layer:
    var snapshot := {
      "speaker": state.speaker if state else "",
      "text": text,
      "sfx": str(state.get_data("sfx", "")) if state else "",
      "music": state.music if state else "",
      "is_dirty": is_dirty,
      "diajogger_state": DiaJogger.serialize_state(),
      "step": _current_step
    }
    menu_layer.add_history_entry(snapshot)

  await message_box.display_text(text, state, is_dirty, write_wait)

func _on_state_changed(state: DiaJoggerState) -> void:
  if not state: return
  if character_layer: character_layer.apply_state(state)
  if not state.music.is_empty(): play_music(state.music)

  var sfx := str(state.get_data("sfx", "")).strip_edges()
  if not sfx.is_empty():
    play_sfx(sfx)
    state.data.erase("sfx")

func play_music(music_key: String) -> void:
  if music_key.is_empty() or music_key == "none":
    music_player.stop()
    _current_music = ""
    return
  if _current_music == music_key and music_player.playing: return
  _current_music = music_key
  music_player.stream = SFX_TRAIN
  music_player.play()

func play_sfx(sfx_key: String) -> void:
  if sfx_key == "train":
    sfx_player.stream = SFX_TRAIN
    sfx_player.play()

func _on_jump_to_history(entry: Dictionary) -> void:
  DiaJogger.stop()
  var dj_state: Dictionary = entry.get("diajogger_state", {})
  DiaJogger.restore_state(dj_state)

  var target_music: String = entry.get("music", "")
  if not target_music.is_empty(): play_music(target_music)

  var target_step: String = entry.get("step", "loop")
  _current_step = target_step
  menu_layer.show_toast("⤴ Загружено к выбранной реплике!")
  await DiaJogger.resume()

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.is_pressed() and not event.is_echo():
    if event.keycode == KEY_F5:
      quick_save()
      get_viewport().set_input_as_handled()
    elif event.keycode == KEY_F9:
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
    "music": _current_music,
    "diajogger": DiaJogger.serialize_state(),
    "history": menu_layer.history_records.duplicate(true) if menu_layer else [],
    "bg_modulate": [background.modulate.r, background.modulate.g, background.modulate.b, background.modulate.a]
  }
  _saved_data = save_dict
  var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  if file:
    file.store_string(JSON.stringify(save_dict, "  "))
    file.close()
  if menu_layer: menu_layer.show_toast("💾 Сохранено! [F5]")

func quick_load() -> void:
  if _saved_data.is_empty() and FileAccess.file_exists(SAVE_PATH):
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
      var json := JSON.new()
      if json.parse(file.get_as_text()) == OK and json.data is Dictionary: _saved_data = json.data
      file.close()

  if _saved_data.is_empty():
    if menu_layer: menu_layer.show_toast("⚠️ Нет сохранений!")
    return

  DiaJogger.stop()
  DiaJogger.restore_state(_saved_data.get("diajogger", {}))
  if menu_layer: menu_layer.history_records = _saved_data.get("history", []).duplicate(true)

  var bg_arr: Array = _saved_data.get("bg_modulate", [1.0, 1.0, 1.0, 1.0])
  if bg_arr.size() == 4: background.modulate = Color(bg_arr[0], bg_arr[1], bg_arr[2], bg_arr[3])

  var saved_music: String = _saved_data.get("music", "")
  if not saved_music.is_empty(): play_music(saved_music)

  if menu_layer: menu_layer.show_toast("📂 Загружено! [F9]")

  var target_step: String = _saved_data.get("step", "loop")
  _run_story(target_step, target_step != "loop")

func _timed_choice(options: Array[String], timeout: float, default_index: int = 0) -> int:
  var time_left := timeout
  var active := [true]
  var ticker := func():
    while active[0] and time_left > 0.0:
      if choices_layer: choices_layer.set_timer_visual(time_left, timeout)
      await get_tree().create_timer(0.05).timeout
      time_left -= 0.05
    if active[0] and DiaJogger.is_waiting_choice(): DiaJogger.select_choice(default_index)
    if choices_layer: choices_layer.set_timer_visual(0.0, 0.0)
  ticker.call()
  var result := await DiaJogger.choice(options)
  active[0] = false
  if choices_layer: choices_layer.set_timer_visual(0.0, 0.0)
  return result
