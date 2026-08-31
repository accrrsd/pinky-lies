extends Node

signal save_created(slot_id: int)
signal save_deleted(slot_id: int)
signal save_loaded(slot_id: int)

const SAVES_DIR = "user://saves/"
const MAX_SLOTS = 6

func _ready() -> void:
	_ensure_saves_dir()

func _ensure_saves_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVES_DIR):
		DirAccess.make_dir_recursive_absolute(SAVES_DIR)

func get_save_path(slot_id: int) -> String:
	return SAVES_DIR + "save_slot_%d.json" % slot_id

func has_save(slot_id: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot_id))

func get_slot_info(slot_id: int) -> Dictionary:
	var path = get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
		
	var text = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK or not json.data is Dictionary:
		return {}
		
	return json.data as Dictionary

func save_game(slot_id: int, save_data: Dictionary = {}) -> bool:
	_ensure_saves_dir()
	var path = get_save_path(slot_id)
	
	var now = Time.get_datetime_dict_from_system()
	var timestamp_str = "%04d-%02d-%02d %02d:%02d" % [now.year, now.month, now.day, now.hour, now.minute]
	
	var full_payload: Dictionary = {
		"slot_id": slot_id,
		"timestamp": timestamp_str,
		"title": save_data.get("title", "Chapter 1"),
		"playtime": save_data.get("playtime", "00:00"),
		"data": save_data.get("data", {})
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		printerr("SaveManager: Failed to open file for write: ", path)
		return false
		
	file.store_string(JSON.stringify(full_payload, "\t"))
	file.close()
	save_created.emit(slot_id)
	return true

func load_game(slot_id: int) -> Dictionary:
	var info = get_slot_info(slot_id)
	if info.is_empty():
		printerr("SaveManager: No save found in slot ", slot_id)
		return {}
	save_loaded.emit(slot_id)
	return info

func delete_save(slot_id: int) -> bool:
	var path = get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return false
	var err = DirAccess.remove_absolute(path)
	if err == OK:
		save_deleted.emit(slot_id)
		return true
	printerr("SaveManager: Failed to delete save at: ", path, " error: ", err)
	return false
