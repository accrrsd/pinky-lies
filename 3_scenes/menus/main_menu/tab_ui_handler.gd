extends Node
@export var state_manager: StateManager
@export var tabs: Dictionary[State, Button]

# THIS CODE CAN BE DONE VIA SHOW_NODE_STATE with TWEEN CHAINS, but it required 2 additional resources, 
# so i made this code to make it faster and simplier

func _ready() -> void:
  state_manager.state_changed.connect(_on_state_changed)

func _on_state_changed(prev_state: State, current_state: State) -> void:
  if prev_state:
    var prev_button: Button = tabs[prev_state]
    prev_button.button_pressed = false
    prev_button.toggle_mode = false
  if current_state:
    var button: Button = tabs[current_state]
    button.toggle_mode = true
    button.button_pressed = true