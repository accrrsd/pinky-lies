extends CanvasLayer

signal confirmed
signal cancelled

@export var default_title: String = "CONFIRMATION ♥︎"
@export var default_message: String = "Are you sure?"

var _confirm_callback: Callable = Callable()
var _cancel_callback: Callable = Callable()
var _tween: Tween

var backdrop: ColorRect
var panel_container: PanelContainer
var title_label: Label
var message_label: Label
var confirm_button: Button
var cancel_button: Button
var confirm_label: Label
var cancel_label: Label
var confirm_icon: TextureRect
var cancel_icon: TextureRect

const PILL_ICON_PATH = "res://2_general/assets/ui/icons/Pill-White.svg"

func _ensure_nodes() -> void:
	if not backdrop: backdrop = get_node_or_null("%Backdrop")
	if not panel_container: panel_container = get_node_or_null("%PanelContainer")
	if not title_label: title_label = get_node_or_null("%TitleLabel")
	if not message_label: message_label = get_node_or_null("%MessageLabel")
	
	var confirm_panel = get_node_or_null("%Confirm")
	if not confirm_panel: confirm_panel = find_child("Confirm", true, false)
	if confirm_panel:
		if "button" in confirm_panel and confirm_panel.button is Button:
			confirm_button = confirm_panel.button
		else:
			confirm_button = confirm_panel.get_node_or_null("Button") as Button
			if not confirm_button: confirm_button = confirm_panel.find_child("Button", true, false) as Button
		confirm_label = confirm_panel.find_child("Label", true, false) as Label
		confirm_icon = confirm_panel.find_child("Icon", true, false) as TextureRect
		
	var cancel_panel = get_node_or_null("%Cancel")
	if not cancel_panel: cancel_panel = find_child("Cancel", true, false)
	if cancel_panel:
		if "button" in cancel_panel and cancel_panel.button is Button:
			cancel_button = cancel_panel.button
		else:
			cancel_button = cancel_panel.get_node_or_null("Button") as Button
			if not cancel_button: cancel_button = cancel_panel.find_child("Button", true, false) as Button
		cancel_label = cancel_panel.find_child("Label", true, false) as Label
		cancel_icon = cancel_panel.find_child("Icon", true, false) as TextureRect

func _ready() -> void:
	_ensure_nodes()
	visible = false
	if confirm_button and not confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.connect(_on_confirm_pressed)
	if cancel_button and not cancel_button.pressed.is_connected(_on_cancel_pressed):
		cancel_button.pressed.connect(_on_cancel_pressed)
	if backdrop and not backdrop.gui_input.is_connected(_on_backdrop_gui_input):
		backdrop.gui_input.connect(_on_backdrop_gui_input)

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel_pressed()

func open(title: String = "", message: String = "", on_confirm: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	open_custom(title, message, "CONFIRM", "CANCEL", null, null, Color.WHITE, Color.WHITE, on_confirm, on_cancel)

func open_custom(
	title: String = "",
	message: String = "",
	confirm_text: String = "CONFIRM",
	cancel_text: String = "CANCEL",
	c_icon: Texture2D = null,
	k_icon: Texture2D = null,
	c_icon_modulate: Color = Color.WHITE,
	k_icon_modulate: Color = Color.WHITE,
	on_confirm: Callable = Callable(),
	on_cancel: Callable = Callable(),
	c_icon_rot: float = 0.52359877,
	k_icon_rot: float = -0.52359877
) -> void:
	_ensure_nodes()
	_confirm_callback = on_confirm
	_cancel_callback = on_cancel
	
	if title_label:
		title_label.text = tr(title) if not title.is_empty() else tr(default_title)
	if message_label:
		message_label.text = tr(message) if not message.is_empty() else tr(default_message)
		
	if confirm_label:
		confirm_label.text = tr(confirm_text)
	if cancel_label:
		cancel_label.text = tr(cancel_text)
		
	if confirm_icon:
		if c_icon:
			confirm_icon.texture = c_icon
			confirm_icon.modulate = c_icon_modulate
			confirm_icon.offset_transform_enabled = true
			confirm_icon.offset_transform_rotation = c_icon_rot
			confirm_icon.visible = true
		else:
			confirm_icon.visible = false
			
	if cancel_icon:
		if k_icon:
			cancel_icon.texture = k_icon
			cancel_icon.modulate = k_icon_modulate
			cancel_icon.offset_transform_enabled = true
			cancel_icon.offset_transform_rotation = k_icon_rot
			cancel_icon.visible = true
		else:
			cancel_icon.visible = false
	
	visible = true
	
	if not is_inside_tree():
		return
		
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if backdrop:
		backdrop.modulate.a = 0.0
		_tween.tween_property(backdrop, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
	if panel_container:
		panel_container.modulate.a = 0.0
		panel_container.scale = Vector2(0.85, 0.85)
		panel_container.pivot_offset = panel_container.size * 0.5
		_tween.tween_property(panel_container, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD)
		_tween.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.25)

func open_matrix_pill_prompt(
	title: String = "ERASE MEMORIES?",
	message: String = "If you take the blue pill, all your unlocked memories, gallery arts, and achievements will dissolve like morning mist. Are you ready to let everything go?",
	on_confirm: Callable = Callable(),
	on_cancel: Callable = Callable(),
	confirm_text: String = "Forget",
	cancel_text: String = "Remember"
) -> void:
	var pill_tex = null
	if ResourceLoader.exists(PILL_ICON_PATH):
		pill_tex = load(PILL_ICON_PATH)
		
	open_custom(
		title,
		message,
		confirm_text,
		cancel_text,
		pill_tex,
		pill_tex,
		Color(0.3, 0.65, 1.0, 1.0),
		Color(1.0, 0.3, 0.45, 1.0),
		on_confirm,
		on_cancel,
		0.52359877,
		-0.52359877
	)

func async_prompt(title: String = "", message: String = "") -> bool:
	open(title, message)
	var result = await self._wait_for_choice()
	close()
	return result

func _wait_for_choice() -> bool:
	var state = {"resolved": false, "result": false}
	
	var on_conf = func():
		if not state.resolved:
			state.resolved = true
			state.result = true
	var on_canc = func():
		if not state.resolved:
			state.resolved = true
			state.result = false
			
	confirmed.connect(on_conf, CONNECT_ONE_SHOT)
	cancelled.connect(on_canc, CONNECT_ONE_SHOT)
	
	while not state.resolved:
		await get_tree().process_frame
		
	return state.result

func close() -> void:
	if not visible: return
	if not is_inside_tree():
		visible = false
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if backdrop:
		_tween.tween_property(backdrop, "modulate:a", 0.0, 0.15)
	if panel_container:
		_tween.tween_property(panel_container, "modulate:a", 0.0, 0.15)
		_tween.tween_property(panel_container, "scale", Vector2(0.9, 0.9), 0.15)
	_tween.chain().tween_callback(func(): visible = false)

func _on_confirm_pressed() -> void:
	var cb = _confirm_callback
	_confirm_callback = Callable()
	_cancel_callback = Callable()
	confirmed.emit()
	if cb.is_valid():
		cb.call()
	close()

func _on_cancel_pressed() -> void:
	var cb = _cancel_callback
	_confirm_callback = Callable()
	_cancel_callback = Callable()
	cancelled.emit()
	if cb.is_valid():
		cb.call()
	close()
