extends CanvasLayer
class_name NovelMenuLayer

signal jump_to_history(snapshot: Dictionary)
signal save_requested
signal load_requested
signal exit_requested

@export var menu_modal: Control
@export var log_modal: Control
@export var log_list: VBoxContainer
@export var toast_label: Label
@export var resume_btn: BaseButton
@export var menu_log_btn: BaseButton
@export var save_btn: BaseButton
@export var load_btn: BaseButton
@export var exit_btn: BaseButton
@export var close_log_btn: BaseButton

var history_records: Array[Dictionary] = []

func _ready() -> void:
  layer = 120
  hide()
  if menu_modal: menu_modal.hide()
  if log_modal: log_modal.hide()
  if toast_label: toast_label.modulate.a = 0.0

  _connect_btn(resume_btn, close_all)
  _connect_btn(menu_log_btn, func(): close_menu(); open_log())
  _connect_btn(save_btn, func(): save_requested.emit())
  _connect_btn(load_btn, func(): load_requested.emit())
  _connect_btn(exit_btn, func(): exit_requested.emit())
  _connect_btn(close_log_btn, close_log)

func _connect_btn(node: Node, callable: Callable) -> void:
  if not node: return
  var btn: Button = node as Button
  if not btn and "button" in node and node.button is Button: btn = node.button
  elif not btn: btn = node.get_node_or_null("Button") as Button
  if btn and not btn.pressed.is_connected(callable): btn.pressed.connect(callable)
  elif node.has_signal("pressed") and not node.pressed.is_connected(callable): node.pressed.connect(callable)

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

  if is_dirty and not history_records.is_empty() and history_records[-1].get("speaker", "") == spk:
    history_records[-1]["text"] += " " + text
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
    row.add_theme_constant_override("separation", 16)

    var spk_label := Label.new()
    var spk: String = entry.get("speaker", "")
    spk_label.text = spk if not spk.is_empty() else "—"
    spk_label.custom_minimum_size = Vector2(120, 0)
    spk_label.theme_type_variation = &"ColoredLabel"
    row.add_child(spk_label)

    var txt_label := Label.new()
    txt_label.text = entry.get("text", "")
    txt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    txt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    row.add_child(txt_label)

    var jump_btn := Button.new()
    jump_btn.text = " ⤴ Перейти "
    jump_btn.pressed.connect(_on_jump_clicked.bind(entry, i))
    row.add_child(jump_btn)

    log_list.add_child(row)

func _on_jump_clicked(entry: Dictionary, index: int) -> void:
  close_all()
  truncate_history_to(index)
  jump_to_history.emit(entry)

func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.is_pressed() and not event.is_echo():
    if event.keycode == KEY_ESCAPE:
      toggle_menu()
      get_viewport().set_input_as_handled()
    elif event.keycode == KEY_H:
      toggle_log()
      get_viewport().set_input_as_handled()
