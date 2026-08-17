extends Node
class_name StateManager

# use that names in state as main process and physics process functions
const UPDATE_STR := StringName("s_process")
const PHYSICS_UPDATE_STR := StringName("s_physics_process")

@export var initial_state: State

var current_state: State
var states: Dictionary[String, State] = {}

var _is_transitioning: bool = false

func _ready() -> void:
  for state in get_children():
    if state is State:
      states[state.name.to_lower()] = state
  
  if initial_state: change_state(initial_state.name.to_lower())

func _process(delta: float) -> void: if current_state: current_state.call(UPDATE_STR, delta)
func _physics_process(delta: float) -> void: if current_state: current_state.call(PHYSICS_UPDATE_STR, delta)

func _change_state_body(new_state_name: String) -> void:
  new_state_name = new_state_name.to_lower()
  if new_state_name == "":
    if current_state: await current_state.end()
    set_process(false)
    set_physics_process(false)
    current_state = null
    return

  var new_state: State = states.get(new_state_name.to_lower(), null)
  if not new_state:
    printerr('State "%s" not found, in %s' % [new_state_name, get_parent()])
    return
  if new_state == current_state: return
  if current_state: await current_state.end()
  set_process(new_state.has_method(UPDATE_STR))
  set_physics_process(new_state.has_method(PHYSICS_UPDATE_STR))
  await new_state.start()
  current_state = new_state

func change_state(new_state_name: String) -> void:
  if _is_transitioning: return
  _is_transitioning = true;
  await _change_state_body(new_state_name)
  _is_transitioning = false;