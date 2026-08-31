extends Node

signal setting_changed(category: String, key: String, value: Variant)

const SAVE_PATH = "user://settings.cfg"
var _config := ConfigFile.new()
var _settings: Dictionary[String, Dictionary] = {}
@export var debug: bool = false

func _ready() -> void:
  load_settings()

func load_settings() -> void:
  var err = _config.load(SAVE_PATH)
  if err != OK:
    if debug: print("No settings file found, using defaults.")
    return
    
  for section in _config.get_sections():
    var section_dict: Dictionary = {}
    for key in _config.get_section_keys(section):
      section_dict[key] = _config.get_value(section, key)
    _settings[section] = section_dict

func save_settings() -> void:
  for section in _settings.keys():
    var section_dict = _settings[section]
    for key in section_dict.keys():
      _config.set_value(section, key, section_dict[key])
      
  var err = _config.save(SAVE_PATH)
  if debug: print("Failed to save settings: " + err if err != OK else "Settings saved.")

func get_settings() -> Dictionary[String, Dictionary]:
  return _settings

func get_setting(category: String, key: String, default: Variant = null) -> Variant:
  if not _settings.has(category):
    return default
  return _settings[category].get(key, default)

func set_setting(category: String, key: String, value: Variant) -> void:
  if not _settings.has(category):
    _settings[category] = {}
  _settings[category][key] = value
  setting_changed.emit(category, key, value)
