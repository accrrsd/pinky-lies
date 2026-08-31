extends Node

@export var is_save_mode: bool = false:
	set(value):
		is_save_mode = value
		refresh()

@export var confirmation_popup_node: NodePath

var header_label: Label
var grid_container: GridContainer
var confirmation_popup: CanvasLayer

func _ready() -> void:
	_ensure_references()
	_connect_save_manager()
	_setup_slots()
	refresh()

func _ensure_references() -> void:
	if not header_label:
		if get_parent():
			header_label = get_parent().find_child("HeaderLabel", true, false) as Label
		if not header_label:
			header_label = find_child("HeaderLabel", true, false) as Label
			
	if not grid_container:
		if get_parent():
			grid_container = get_parent().find_child("GridContainer", true, false) as GridContainer
		if not grid_container:
			grid_container = find_child("GridContainer", true, false) as GridContainer
			
	if not confirmation_popup and not confirmation_popup_node.is_empty():
		confirmation_popup = get_node_or_null(confirmation_popup_node) as CanvasLayer
	if not confirmation_popup:
		var main_loop = Engine.get_main_loop()
		if main_loop and main_loop is SceneTree and main_loop.root:
			confirmation_popup = main_loop.root.find_child("ConfirmationPopup", true, false) as CanvasLayer

func _connect_save_manager() -> void:
	var save_mgr = _get_save_manager()
	if save_mgr:
		if not save_mgr.save_created.is_connected(_on_save_manager_event):
			save_mgr.save_created.connect(_on_save_manager_event)
		if not save_mgr.save_deleted.is_connected(_on_save_manager_event):
			save_mgr.save_deleted.connect(_on_save_manager_event)

func _on_save_manager_event(_slot_id: int) -> void:
	refresh()

func _get_save_manager() -> Node:
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root and main_loop.root.has_node("SaveManager"):
		return main_loop.root.get_node("SaveManager")
	if is_inside_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
		return get_tree().root.get_node("SaveManager")
	return null

func _setup_slots() -> void:
	_ensure_references()
	if not grid_container: return
	
	var slot_index = 1
	for child in grid_container.get_children():
		if child is Control:
			var slot_id = slot_index
			var main_btn = child.find_child("Button", true, false) as Button
			if main_btn and not main_btn.pressed.is_connected(_on_slot_pressed.bind(slot_id)):
				main_btn.pressed.connect(_on_slot_pressed.bind(slot_id))
			
			var trash_btn = child.find_child("TrashButton", true, false) as Button
			if trash_btn and not trash_btn.pressed.is_connected(_on_trash_pressed.bind(slot_id)):
				trash_btn.pressed.connect(_on_trash_pressed.bind(slot_id))
				
			slot_index += 1

func refresh() -> void:
	_ensure_references()
	_connect_save_manager()
	
	if header_label:
		header_label.text = tr("SAVE GAME ♥︎") if is_save_mode else tr("LOAD GAME ♥︎")
		
	if not grid_container: return
	
	var save_mgr = _get_save_manager()
	var slot_index = 1
	
	for child in grid_container.get_children():
		if child is Control:
			var slot_id = slot_index
			var title_lbl = child.find_child("SlotTitle", true, false) as Label
			if title_lbl:
				title_lbl.text = tr("SLOT %02d" % slot_id)
				
			var info_lbl = child.find_child("SlotInfo", true, false) as Label
			var trash_btn = child.find_child("TrashButton", true, false) as Control
			
			var has_save = false
			var info: Dictionary = {}
			if save_mgr:
				has_save = save_mgr.has_save(slot_id)
				if has_save:
					info = save_mgr.get_slot_info(slot_id)
					
			if info_lbl:
				if has_save:
					var title = info.get("title", "Save %d" % slot_id)
					var timestamp = info.get("timestamp", "")
					info_lbl.text = "%s\n%s" % [title, timestamp]
				else:
					info_lbl.text = tr("Empty_Slot")
					
			if trash_btn:
				trash_btn.visible = has_save
				
			slot_index += 1

func _on_slot_pressed(slot_id: int) -> void:
	var save_mgr = _get_save_manager()
	if not save_mgr: return
	_ensure_references()
	
	var has_save = save_mgr.has_save(slot_id)
	
	if is_save_mode:
		var msg = tr("Are you sure you want to overwrite this save?") if has_save else tr("Save game to this slot?")
		if confirmation_popup:
			confirmation_popup.open("SAVE GAME ♥︎", msg, func(): _do_save(slot_id))
		else:
			_do_save(slot_id)
	else:
		if has_save:
			if confirmation_popup:
				confirmation_popup.open("LOAD GAME ♥︎", tr("Are you sure you want to load this save?"), func(): _do_load(slot_id))
			else:
				_do_load(slot_id)

func _on_trash_pressed(slot_id: int) -> void:
	_ensure_references()
	if confirmation_popup:
		confirmation_popup.open("CONFIRMATION ♥︎", tr("Are you sure you want to delete this save?"), func(): _do_delete(slot_id))
	else:
		_do_delete(slot_id)

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
	if save_mgr:
		save_mgr.delete_save(slot_id)
	refresh()
