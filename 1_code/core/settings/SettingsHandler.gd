extends Node

@export var handlers: Array[SettingsHandlerRes] = []
@export var debounce_timeout: float = 0.2

var debounceTimer: Timer

func _ready() -> void:
  debounceTimer = Timer.new()
  add_child(debounceTimer)
  debounceTimer.wait_time = debounce_timeout
  debounceTimer.one_shot = true
  debounceTimer.timeout.connect(_on_debounceTimer_timeout)
  
  for handler in handlers:
    if handler:
      handler.initialize(self)

func start_debounce() -> void:
  debounceTimer.start()

func _on_debounceTimer_timeout() -> void:
  SettingsManager.save_settings()

func reset_to_defaults() -> void:
  for handler in handlers:
    if handler:
      var def = handler.default_value if handler.default_value != null else handler._get_control_default_value()
      handler._set_control_ui_value(def)
      handler.apply_setting(def)
      handler.save_setting(def)
  SettingsManager.save_settings()
