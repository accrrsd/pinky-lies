extends CanvasLayer
class_name DemoMenuLayer

signal jump_to_history(entry: Dictionary)
signal save_requested
signal load_requested
signal exit_requested
signal sfx_replay_requested(sfx_key: String)

@export var menu_modal: Control
@export var log_modal: Control
@export var log_list: VBoxContainer
@export var toast_label: Label
@export var resume_btn: Button
@export var menu_log_btn: Button
@export var save_btn: Button
@export var load_btn: Button
@export var exit_btn: Button
@export var close_log_btn: Button

var history_records: Array[Dictionary] = []

func _ready() -> void:
  layer = 120
  hide()
  if menu_modal: menu_modal.hide()
  if log_modal: log_modal.hide()
  if toast_label: toast_label.modulate.a = 0.0

  if resume_btn: resume_btn.pressed.connect(close_all)
  if menu_log_btn: menu_log_btn.pressed.connect(func(): close_menu(); open_log())
  if save_btn: save_btn.pressed.connect(func(): save_requested.emit())
  if load_btn: load_btn.pressed.connect(func(): load_requested.emit())
  if exit_btn: exit_btn.pressed.connect(func(): exit_requested.emit())
  if close_log_btn: close_log_btn.pressed.connect(close_log)

func open_menu() -> void:
  show()
  if log_modal: log_modal.hide()
  if menu_modal: menu_modal.show()

func close_menu() -> void:
  if menu_modal: menu_modal.hide()
  if not log_modal or not log_modal.visible: hide()

func open_log() -> void:
  show()
  if menu_modal: menu_modal.hide()
  _rebuild_log_ui()
  if log_modal: log_modal.show()

func close_log() -> void:
  if log_modal: log_modal.hide()
  if not menu_modal or not menu_modal.visible: hide()

func close_all() -> void:
  if menu_modal: menu_modal.hide()
  if log_modal: log_modal.hide()
  hide()

func toggle_menu() -> void:
  if menu_modal and menu_modal.visible: close_menu()
  else: open_menu()

func toggle_log() -> void:
  if log_modal and log_modal.visible: close_log()
  else: open_log()

func add_history_entry(entry: Dictionary) -> void:
  var spk: String = entry.get("speaker", "")
  var text: String = entry.get("text", "")
  var is_dirty: bool = entry.get("is_dirty", false)
  var sfx: String = entry.get("sfx", "")

  if is_dirty and not history_records.is_empty() and history_records[-1].get("speaker", "") == spk:
    history_records[-1]["text"] += " " + text
    if not sfx.is_empty(): history_records[-1]["sfx"] = sfx
    history_records[-1]["diajogger_state"] = entry.get("diajogger_state", {})
  else:
    history_records.append(entry.duplicate(true))

func truncate_history_to(entry_index: int) -> void:
  if entry_index >= 0 and entry_index < history_records.size():
    history_records = history_records.slice(0, entry_index + 1)

func show_toast(message: String) -> void:
  if not toast_label: return
  toast_label.text = message
  var tw := create_tween()
  tw.tween_property(toast_label, "modulate:a", 1.0, 0.2)
  tw.tween_interval(1.5)
  tw.tween_property(toast_label, "modulate:a", 0.0, 0.4)

func _rebuild_log_ui() -> void:
  if not log_list: return
  for child in log_list.get_children():
    log_list.remove_child(child)
    child.queue_free()

  for i in range(history_records.size()):
    var entry := history_records[i]
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)

    var spk_label := Label.new()
    var spk: String = entry.get("speaker", "")
    spk_label.text = spk if not spk.is_empty() else "—"
    spk_label.custom_minimum_size = Vector2(110, 0)
    match spk.to_lower():
      "emily": spk_label.modulate = Color(1.0, 0.88, 0.45)
      "deva": spk_label.modulate = Color(0.45, 0.92, 0.85)
      "ren", "pinky": spk_label.modulate = Color(0.9, 0.9, 0.9)
      _: spk_label.modulate = Color(0.7, 0.7, 0.75)
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
      sfx_btn.pressed.connect(func(): sfx_replay_requested.emit(sfx))
      row.add_child(sfx_btn)

    var jump_btn := Button.new()
    jump_btn.text = "⤴ Загрузить"
    jump_btn.pressed.connect(_on_jump_clicked.bind(entry, i))
    row.add_child(jump_btn)

    log_list.add_child(row)

func _on_jump_clicked(entry: Dictionary, index: int) -> void:
  close_all()
  truncate_history_to(index)
  jump_to_history.emit(entry)
