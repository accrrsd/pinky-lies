extends Node
class_name TabUiHandler

@export var state_manager: StateManager
@export var tabs: Dictionary

var _resolved_tabs: Dictionary = {}
var _connected_buttons: Array[Button] = []
var _is_updating_visual: bool = false

func _ready() -> void:
  _resolve_tabs()
  if state_manager:
    if not state_manager.is_node_ready(): await state_manager.ready
    state_manager.state_changed.connect(_on_state_changed)
    var active: State = state_manager.current_state if state_manager.current_state else state_manager.initial_state
    _update_all_tabs_visual(active)

func _resolve_tabs() -> void:
  _resolved_tabs.clear()
  for k in tabs.keys():
    var state_node: State = null
    if k is State: state_node = k
    elif k is NodePath and has_node(k): state_node = get_node(k) as State
    elif k is String and has_node(NodePath(k)): state_node = get_node(NodePath(k)) as State

    var btn_node = tabs[k]
    if btn_node is NodePath and has_node(btn_node): btn_node = get_node(btn_node)
    elif btn_node is String and has_node(NodePath(btn_node)): btn_node = get_node(NodePath(btn_node))

    if state_node and btn_node:
      _resolved_tabs[state_node] = btn_node
      var btn: Button = _resolve_button(btn_node)
      if btn and not btn in _connected_buttons:
        _connected_buttons.append(btn)
        btn.pressed.connect(_on_tab_pressed.bind(state_node))
        btn.toggled.connect(_on_tab_toggled.bind(state_node))

func _on_tab_pressed(state: State) -> void:
  if not state_manager: return
  if state_manager.is_transitioning or state == state_manager.current_state:
    _update_all_tabs_visual(state_manager.current_state)
    return
  state_manager.change_state(state.name)

func _on_tab_toggled(toggled_on: bool, state: State) -> void:
  if not state_manager: return
  if (toggled_on and state != state_manager.current_state) or (not toggled_on and state == state_manager.current_state):
    _update_all_tabs_visual(state_manager.current_state)

func _on_state_changed(_prev_state: State, current_state: State) -> void:
  if _resolved_tabs.is_empty(): _resolve_tabs()
  _update_all_tabs_visual(current_state)

func _update_all_tabs_visual(active_state: State) -> void:
  if _is_updating_visual: return
  _is_updating_visual = true
  for state in _resolved_tabs:
    var node = _resolved_tabs[state]
    _set_tab_visual(node, state == active_state)
  _is_updating_visual = false

func _set_tab_visual(node: Node, is_active: bool) -> void:
  if not node: return
  var btn: Button = _resolve_button(node)
  if btn:
    if is_active:
      btn.toggle_mode = true
      btn.button_pressed = true
    else:
      btn.button_pressed = false
      btn.toggle_mode = false
  if node != btn:
    if "button_toggled" in node: node.button_toggled = is_active
    if node.has_method("_update_state"): node._update_state()

func _resolve_button(node: Node) -> Button:
  if not node: return null
  if node is Button: return node
  if "button" in node and node.button is Button: return node.button
  return node.get_node_or_null("Button") as Button
