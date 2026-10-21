extends Node

@export var is_save_mode: bool = false:
  set(value):
    is_save_mode = value
    refresh()

@export var confirmation_popup_node: NodePath

const SLOTS_PER_PAGE: int = 4
const MAX_PAGES: int = 100

var current_page: int = 1
var max_page: int = 1

var header_label: Label
var grid_container: Container
var confirmation_popup: CanvasLayer
var prev_button: Button
var next_button: Button
var page_input: LineEdit
var max_page_label: Label

func _ready() -> void:
  _ensure_references()
  _connect_save_manager()
  _setup_slots()
  _setup_pagination_events()
  refresh()

func _ensure_references() -> void:
  var search_root: Node = get_parent() if get_parent() else self
  if not header_label: header_label = search_root.find_child("HeaderLabel", true, false) as Label
  if not grid_container: grid_container = search_root.find_child("GridContainer", true, false) as Container
  if not prev_button: prev_button = search_root.find_child("PrevPageButton", true, false) as Button
  if not next_button: next_button = search_root.find_child("NextPageButton", true, false) as Button
  if not page_input: page_input = search_root.find_child("PageInput", true, false) as LineEdit
  if not max_page_label: max_page_label = search_root.find_child("MaxPageLabel", true, false) as Label
  if not confirmation_popup and not confirmation_popup_node.is_empty(): confirmation_popup = get_node_or_null(confirmation_popup_node) as CanvasLayer
  if not confirmation_popup:
    var main_loop = Engine.get_main_loop()
    if main_loop and main_loop is SceneTree and main_loop.root: confirmation_popup = main_loop.root.find_child("ConfirmationPopup", true, false) as CanvasLayer

func _connect_save_manager() -> void:
  var save_mgr = _get_save_manager()
  if not save_mgr: return
  if not save_mgr.save_created.is_connected(_on_save_manager_event): save_mgr.save_created.connect(_on_save_manager_event)
  if not save_mgr.save_deleted.is_connected(_on_save_manager_event): save_mgr.save_deleted.connect(_on_save_manager_event)

func _on_save_manager_event(_slot_id: int) -> void: refresh()

func _get_save_manager() -> Node:
  var main_loop = Engine.get_main_loop()
  if main_loop and main_loop is SceneTree and main_loop.root and main_loop.root.has_node("SaveManager"): return main_loop.root.get_node("SaveManager")
  if is_inside_tree() and get_tree().root and get_tree().root.has_node("SaveManager"): return get_tree().root.get_node("SaveManager")
  return null

func _setup_pagination_events() -> void:
  if prev_button and not prev_button.pressed.is_connected(_on_prev_pressed): prev_button.pressed.connect(_on_prev_pressed)
  if next_button and not next_button.pressed.is_connected(_on_next_pressed): next_button.pressed.connect(_on_next_pressed)
  if page_input and not page_input.text_submitted.is_connected(_on_page_submitted): page_input.text_submitted.connect(_on_page_submitted)
  if page_input and not page_input.focus_exited.is_connected(_on_page_focus_exited): page_input.focus_exited.connect(_on_page_focus_exited)

func _calculate_max_page() -> int:
  var save_mgr = _get_save_manager()
  var highest_slot = save_mgr.get_highest_slot_id() if (save_mgr and save_mgr.has_method("get_highest_slot_id")) else 0
  if highest_slot <= 0: return 1
  var highest_page: int = int(ceil(float(highest_slot) / float(SLOTS_PER_PAGE)))
  return clampi(highest_page + 1, 1, MAX_PAGES)

func _setup_slots() -> void:
  _ensure_references()
  if not grid_container: return
  var children = grid_container.get_children()
  for i in range(children.size()):
    var child = children[i]
    if child.has_signal("slot_pressed") and not child.slot_pressed.is_connected(_on_slot_icon_pressed): child.slot_pressed.connect(_on_slot_icon_pressed)
    if child.has_signal("trash_pressed") and not child.trash_pressed.is_connected(_on_trash_pressed): child.trash_pressed.connect(_on_trash_pressed)
    var main_btn = child.find_child("Button", true, false) as Button
    if main_btn and not child.has_signal("slot_pressed") and not main_btn.pressed.is_connected(_on_legacy_slot_pressed.bind(i)): main_btn.pressed.connect(_on_legacy_slot_pressed.bind(i))
    var trash_btn = child.find_child("TrashButton", true, false) as Button
    if trash_btn and not child.has_signal("trash_pressed") and not trash_btn.pressed.is_connected(_on_legacy_trash_pressed.bind(i)): trash_btn.pressed.connect(_on_legacy_trash_pressed.bind(i))

func refresh() -> void:
  _ensure_references()
  _connect_save_manager()
  _setup_slots()
  _setup_pagination_events()
  max_page = _calculate_max_page()
  current_page = clampi(current_page, 1, max_page)
  if header_label: header_label.text = tr("SAVE GAME ♥︎") if is_save_mode else tr("LOAD GAME ♥︎")
  _update_pagination_ui()
  _update_slots_ui()

func _update_pagination_ui() -> void:
  if prev_button: prev_button.disabled = (current_page <= 1)
  if next_button: next_button.disabled = (current_page >= max_page)
  if page_input and not page_input.has_focus(): page_input.text = str(current_page)
  if max_page_label: max_page_label.text = "/ %d" % max_page

func _update_slots_ui() -> void:
  if not grid_container: return
  var save_mgr = _get_save_manager()
  var children = grid_container.get_children()
  for i in range(children.size()):
    var child = children[i]
    var slot_id = (current_page - 1) * SLOTS_PER_PAGE + (i + 1)
    var has_save = save_mgr.has_save(slot_id) if save_mgr else false
    var info = save_mgr.get_slot_info(slot_id) if (save_mgr and has_save) else {}
    if child.has_method("set_slot_data"):
      child.set_slot_data(slot_id, has_save, info)
      child.reset_bite()
    else:
      var title_lbl = child.find_child("SlotTitle", true, false) as Label
      if title_lbl: title_lbl.text = tr("SLOT %02d" % slot_id)
      var info_lbl = child.find_child("SlotInfo", true, false) as Label
      var trash_btn = child.find_child("TrashButton", true, false) as Control
      if info_lbl:
        if has_save:
          var title = info.get("title", "Save %d" % slot_id)
          var timestamp = info.get("timestamp", "")
          info_lbl.text = "%s\n%s" % [title, timestamp]
        else:
          info_lbl.text = tr("Empty_Slot")
      if trash_btn: trash_btn.visible = has_save

func change_page(target_page: int) -> void:
  max_page = _calculate_max_page()
  var clamped_page = clampi(target_page, 1, max_page)
  current_page = clamped_page
  refresh()

func _on_prev_pressed() -> void: change_page(current_page - 1)

func _on_next_pressed() -> void: change_page(current_page + 1)

func _on_page_submitted(new_text: String) -> void:
  if new_text.is_valid_int(): change_page(new_text.to_int())
  elif page_input: page_input.text = str(current_page)
  if page_input: page_input.release_focus()

func _on_page_focus_exited() -> void:
  if page_input and page_input.text.is_valid_int(): change_page(page_input.text.to_int())
  elif page_input: page_input.text = str(current_page)

func _on_slot_icon_pressed(slot_id: int) -> void: _handle_slot_activation(slot_id)

func _on_legacy_slot_pressed(index: int) -> void:
  var slot_id = (current_page - 1) * SLOTS_PER_PAGE + (index + 1)
  _handle_slot_activation(slot_id)

func _on_legacy_trash_pressed(index: int) -> void:
  var slot_id = (current_page - 1) * SLOTS_PER_PAGE + (index + 1)
  _on_trash_pressed(slot_id)

func _handle_slot_activation(slot_id: int) -> void:
  var save_mgr = _get_save_manager()
  if not save_mgr: return
  _ensure_references()
  var has_save = save_mgr.has_save(slot_id)
  if is_save_mode:
    var msg = tr("Are you sure you want to overwrite this save?") if has_save else tr("Save game to this slot?")
    if confirmation_popup: confirmation_popup.open(tr("SAVE GAME ♥︎"), msg, func(): _do_save(slot_id))
    else: _do_save(slot_id)
  else:
    if has_save:
      if confirmation_popup: confirmation_popup.open(tr("LOAD GAME ♥︎"), tr("Are you sure you want to load this save?"), func(): _do_load(slot_id))
      else: _do_load(slot_id)

func _on_trash_pressed(slot_id: int) -> void:
  _ensure_references()
  if confirmation_popup: confirmation_popup.open(tr("CONFIRMATION ♥︎"), tr("Are you sure you want to delete this save?"), func(): _do_delete(slot_id))
  else: _do_delete(slot_id)

func _do_save(slot_id: int) -> void:
  var save_mgr = _get_save_manager()
  if save_mgr:
    save_mgr.save_game(slot_id, {
      "title": "Chapter 1",
      "playtime": "00:15"
    })
  refresh()

func _do_load(slot_id: int) -> void:
  var save_mgr = _get_save_manager()
  if save_mgr:
    var loaded_data = save_mgr.load_game(slot_id)
    print("Successfully loaded save slot ", slot_id, ": ", loaded_data)

func _do_delete(slot_id: int) -> void:
  var save_mgr = _get_save_manager()
  if save_mgr: save_mgr.delete_save(slot_id)
  refresh()
