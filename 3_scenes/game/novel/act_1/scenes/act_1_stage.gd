extends Node
class_name Act1Stage

@export var scenario_path: String = "res://3_scenes/game/novel/act_1/scenario/act_1_intro.md"
@export var initial_target: String = "Act1/Start"

@onready var background: Control = $Background
@onready var music_player: AudioStreamPlayer = $MusicPlayer

@onready var character_stage: NovelCharacterStage = $NovelCharacterStage
@onready var message_box: NovelMessageBox = $NovelMessageBox
@onready var choices: NovelChoices = $NovelChoices
@onready var menu_layer: NovelMenuLayer = $NovelMenuLayer

var _current_music: String = ""

func _ready() -> void:
  DiaJogger.set_text_handler(_on_display_text)
  DiaJogger.set_choice_handler(choices.display_choices)
  DiaJogger.state_changed.connect(_on_state_changed)

  if message_box:
    message_box.log_requested.connect(menu_layer.open_log)
    message_box.menu_requested.connect(menu_layer.open_menu)

  if menu_layer:
    menu_layer.jump_to_history.connect(_on_jump_to_history)
    menu_layer.exit_requested.connect(_on_exit_to_menu)

  DiaJogger.load_file(scenario_path)
  await DiaJogger.play(initial_target)

  var choice_idx := await DiaJogger.choice([
    "Продолжить исследование станции",
    "Открыть журнал записей (Backlog)",
    "Перейти в хаб локаций"
  ])

  match choice_idx:
    0:
      menu_layer.show_toast("Выбрано: Продолжить")
    1:
      menu_layer.open_log()
    2:
      menu_layer.show_toast("Переход в хаб...")

func _on_display_text(text: String, state: DiaJoggerState, is_dirty: bool = false, write_wait: float = -1.0) -> void:
  if menu_layer:
    var snapshot := {
      "speaker": state.speaker if state else "",
      "text": text,
      "is_dirty": is_dirty,
      "music": state.music if state else "",
      "diajogger_state": DiaJogger.serialize_state()
    }
    menu_layer.add_history_entry(snapshot)

  await message_box.display_text(text, state, is_dirty, write_wait)

func _on_state_changed(state: DiaJoggerState) -> void:
  if not state: return
  if character_stage: character_stage.apply_state(state)
  if not state.music.is_empty(): play_music(state.music)

func play_music(music_key: String) -> void:
  if music_key.is_empty() or music_key == "none":
    music_player.stop()
    _current_music = ""
    return
  if _current_music == music_key and music_player.playing: return
  _current_music = music_key
  # If music resource exists, load and play, otherwise track state
  music_player.play()

func _on_jump_to_history(snapshot: Dictionary) -> void:
  DiaJogger.stop()
  var dj_state: Dictionary = snapshot.get("diajogger_state", {})
  DiaJogger.restore_state(dj_state)

  var target_music: String = snapshot.get("music", "")
  if not target_music.is_empty(): play_music(target_music)

  menu_layer.show_toast("⤴ Загружено к выбранной реплике!")
  await DiaJogger.resume()

func _on_exit_to_menu() -> void:
  DiaJogger.stop()
  get_tree().change_scene_to_file("res://3_scenes/menus/main_menu/MainMenu.tscn")
