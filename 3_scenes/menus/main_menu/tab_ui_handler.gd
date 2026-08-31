extends Node
@export var state_manager: StateManager
@export var tabs: Dictionary

var _resolved_tabs: Dictionary = {}

func _ready() -> void:
	_resolve_tabs()
	if state_manager:
		state_manager.state_changed.connect(_on_state_changed)
		if state_manager.initial_state and state_manager.initial_state in _resolved_tabs:
			_set_button_pressed(_resolved_tabs[state_manager.initial_state], true)

func _resolve_tabs() -> void:
	_resolved_tabs.clear()
	for k in tabs.keys():
		var state_node: State = null
		if k is State:
			state_node = k
		elif k is NodePath and has_node(k):
			state_node = get_node(k) as State
		elif k is String and has_node(NodePath(k)):
			state_node = get_node(NodePath(k)) as State
			
		var btn_node = tabs[k]
		if btn_node is NodePath and has_node(btn_node):
			btn_node = get_node(btn_node)
		elif btn_node is String and has_node(NodePath(btn_node)):
			btn_node = get_node(NodePath(btn_node))
			
		if state_node and btn_node:
			_resolved_tabs[state_node] = btn_node

func _on_state_changed(prev_state: State, current_state: State) -> void:
	if _resolved_tabs.is_empty():
		_resolve_tabs()
	if prev_state and prev_state in _resolved_tabs:
		_set_button_pressed(_resolved_tabs[prev_state], false)
	if current_state and current_state in _resolved_tabs:
		_set_button_pressed(_resolved_tabs[current_state], true)

func _set_button_pressed(node: Node, pressed: bool) -> void:
	if not node: return
	var btn: Button = node as Button
	if not btn and "button" in node and node.button is Button:
		btn = node.button
	elif not btn:
		btn = node.get_node_or_null("Button") as Button
	if btn:
		btn.toggle_mode = true
		btn.button_pressed = pressed
