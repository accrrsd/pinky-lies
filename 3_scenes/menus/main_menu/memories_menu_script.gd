extends Node

signal memories_cleared

@export var confirmation_popup_node: NodePath

var confirmation_popup: CanvasLayer
var current_tab_index: int = 0

var tab_buttons: Array[Button] = []
var tab_contents: Array[Control] = []

func _ready() -> void:
	_ensure_references()
	_setup_tabs()
	_setup_forget_button()
	switch_tab(0)

func _ensure_references() -> void:
	if not confirmation_popup and not confirmation_popup_node.is_empty():
		confirmation_popup = get_node_or_null(confirmation_popup_node) as CanvasLayer
	if not confirmation_popup:
		var main_loop = Engine.get_main_loop()
		if main_loop and main_loop is SceneTree and main_loop.root:
			confirmation_popup = main_loop.root.find_child("ConfirmationPopup", true, false) as CanvasLayer

func _resolve_button(node: Node) -> Button:
	if not node: return null
	if node is Button: return node
	if "button" in node and node.button is Button: return node.button
	return node.get_node_or_null("Button") as Button

func _setup_tabs() -> void:
	tab_buttons.clear()
	tab_contents.clear()
	
	var parent_node = get_parent()
	if not parent_node: parent_node = self
	
	var adv_node = parent_node.find_child("Adventures", true, false)
	var gal_node = parent_node.find_child("Gallery", true, false)
	var enc_node = parent_node.find_child("Encyclopedia", true, false)
	var end_node = parent_node.find_child("Endings", true, false)
	
	var adv_content = parent_node.find_child("AdventuresContent", true, false) as Control
	var gal_content = parent_node.find_child("GalleryContent", true, false) as Control
	var enc_content = parent_node.find_child("EncyclopediaContent", true, false) as Control
	var end_content = parent_node.find_child("EndingsContent", true, false) as Control
	
	var node_list = [adv_node, gal_node, enc_node, end_node]
	var content_list = [adv_content, gal_content, enc_content, end_content]
	
	for i in range(node_list.size()):
		var n = node_list[i]
		var content = content_list[i]
		if n:
			var btn = _resolve_button(n)
			if btn:
				tab_buttons.append(btn)
				btn.toggle_mode = true
				if not btn.pressed.is_connected(switch_tab.bind(i)):
					btn.pressed.connect(switch_tab.bind(i))
		if content:
			tab_contents.append(content)

func _setup_forget_button() -> void:
	var parent_node = get_parent()
	if not parent_node: parent_node = self
	
	var forget_node = parent_node.find_child("Forget", true, false)
	if not forget_node: forget_node = parent_node.find_child("ForgetButton", true, false)
	if forget_node:
		var btn = _resolve_button(forget_node)
		if btn and not btn.pressed.is_connected(_on_forget_pressed):
			btn.pressed.connect(_on_forget_pressed)

func switch_tab(tab_idx: int) -> void:
	current_tab_index = tab_idx
	
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		if btn:
			btn.toggle_mode = true
			btn.button_pressed = (i == tab_idx)
			
	for i in range(tab_contents.size()):
		var content = tab_contents[i]
		if content:
			content.visible = (i == tab_idx)

func _on_forget_pressed() -> void:
	_ensure_references()
	if confirmation_popup and confirmation_popup.has_method("open_matrix_pill_prompt"):
		confirmation_popup.open_matrix_pill_prompt(
			"ERASE MEMORIES?",
			"If you take the blue pill, all your unlocked memories, gallery arts, and achievements will dissolve like morning mist. Are you ready to let everything go?",
			_do_forget,
			Callable(),
			"Forget",
			"Remember"
		)
	else:
		_do_forget()

func _do_forget() -> void:
	print("Memories reset: All memories and unlockables have been forgotten.")
	memories_cleared.emit()
	switch_tab(current_tab_index)
