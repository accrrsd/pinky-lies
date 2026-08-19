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

func start_debounce() -> void: debounceTimer.start()

func _on_debounceTimer_timeout() -> void: SettingsManager.save_settings()
