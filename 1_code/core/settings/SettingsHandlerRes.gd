extends Resource
class_name SettingsHandlerRes

signal custom_action_requested(key: String, value: Variant)

enum UiType {
	SLIDER,
	TOGGLE,
	SELECTOR,
	RADIO_GROUP,
	CUSTOM
}

enum ActionType {
	AUDIO_VOLUME,
	AUDIO_MUTE_ALL,
	WINDOW_MODE,
	WINDOW_RESOLUTION,
	LANGUAGE,
	CUSTOM
}

const META_TARGET_CONTROL = "target_control"

@export var category: String = ""
@export var setting_key: String = ""
@export var ui_type: UiType = UiType.SLIDER
@export var action_type: ActionType = ActionType.AUDIO_VOLUME
@export var control_node_path: NodePath
@export var default_value: Variant

var parent: Node
var control: Control
var target_control: Control
var is_loading: bool = false
var _adapter: UiAdapter

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(2560, 1440),
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 576)
]

const LANGUAGES: Array[String] = ["en", "ru"]

# ==============================================================================
# UI ADAPTERS (Subclasses for polymorphic UI handling)
# ==============================================================================

class UiAdapter extends RefCounted:
	var handler: SettingsHandlerRes

	func _init(p_handler: SettingsHandlerRes) -> void:
		handler = p_handler

	func get_type_name() -> String:
		return "Control"

	func is_matching(node: Control) -> bool:
		return node != null

	func resolve_target(root: Control) -> Control:
		if not root: return null
		if is_matching(root): return root
		if root.has_meta(META_TARGET_CONTROL):
			var meta_val = root.get_meta(META_TARGET_CONTROL)
			var resolved: Control = null
			if meta_val is NodePath:
				resolved = root.get_node_or_null(meta_val) as Control
			elif meta_val is String:
				resolved = root.get_node_or_null(NodePath(meta_val)) as Control
			elif meta_val is Control:
				resolved = meta_val
			if resolved and is_matching(resolved):
				return resolved
			elif resolved:
				return resolved
		return _auto_resolve_inner(root)

	func _auto_resolve_inner(root: Control) -> Control: return root
	func bind_events(_target: Control) -> void: pass
	func get_default_value(_target: Control) -> Variant: return null
	func set_ui_value(_target: Control, _value: Variant) -> void: pass


class SliderAdapter extends UiAdapter:
	func get_type_name() -> String:
		return "Slider (Range)"

	func is_matching(node: Control) -> bool:
		return node is Slider or (node != null and (node.has_node("HSlider") or node.has_node("Slider")))

	func _auto_resolve_inner(root: Control) -> Control:
		if root is Slider: return root
		if root.has_node("HSlider"): return root.get_node("HSlider") as Control
		if root.has_node("Slider"): return root.get_node("Slider") as Control
		return root

	func bind_events(target: Control) -> void:
		var slider = target as Slider
		if slider and not slider.value_changed.is_connected(handler._on_slider_value_changed):
			slider.value_changed.connect(handler._on_slider_value_changed)

	func get_default_value(target: Control) -> Variant:
		var slider = target as Slider
		return slider.value if slider else 50.0

	func set_ui_value(target: Control, value: Variant) -> void:
		var slider = target as Slider
		if slider:
			slider.value = float(value)


class ToggleAdapter extends UiAdapter:
	func get_type_name() -> String:
		return "BaseButton / CheckBox / HeartButton"

	func is_matching(node: Control) -> bool:
		if not node: return false
		if node is BaseButton: return true
		if "button" in node and node.button is BaseButton: return true
		if node.has_node("Button") and node.get_node("Button") is BaseButton: return true
		return false

	func _auto_resolve_inner(root: Control) -> Control:
		if root is BaseButton: return root
		if "button" in root and root.button is BaseButton: return root.button
		if root.has_node("Button") and root.get_node("Button") is BaseButton: return root.get_node("Button")
		return root

	func bind_events(target: Control) -> void:
		var btn = target as BaseButton
		if btn:
			btn.toggle_mode = true
			if not btn.toggled.is_connected(handler._on_toggle_value_changed):
				btn.toggled.connect(handler._on_toggle_value_changed)

	func get_default_value(target: Control) -> Variant:
		var btn = target as BaseButton
		return btn.button_pressed if btn else false

	func set_ui_value(target: Control, value: Variant) -> void:
		var btn = target as BaseButton
		if btn:
			btn.button_pressed = bool(value)


class SelectorAdapter extends UiAdapter:
	func get_type_name() -> String:
		return "OptionButton / ArrowSelector"

	func is_matching(node: Control) -> bool:
		if not node: return false
		if node is OptionButton: return true
		if node.has_signal("item_selected") or node.has_signal("value_changed"): return true
		if node.has_method("select") or "selected" in node or "selected_index" in node: return true
		if node.has_node("OptionButton"): return true
		return false

	func _auto_resolve_inner(root: Control) -> Control:
		if is_matching(root): return root
		if root.has_node("OptionButton"): return root.get_node("OptionButton")
		return root

	func bind_events(target: Control) -> void:
		if target is OptionButton:
			var opt = target as OptionButton
			SettingsHandlerRes.setup_option_button_popup_cursor(opt)
			if not opt.item_selected.is_connected(handler._on_selector_index_changed):
				opt.item_selected.connect(handler._on_selector_index_changed)
		elif target.has_signal("item_selected"):
			if not target.is_connected("item_selected", handler._on_selector_index_changed):
				target.connect("item_selected", handler._on_selector_index_changed)
		elif target.has_signal("value_changed"):
			if not target.is_connected("value_changed", handler._on_generic_value_changed):
				target.connect("value_changed", handler._on_generic_value_changed)

	func get_default_value(target: Control) -> Variant:
		if target is OptionButton:
			return (target as OptionButton).selected
		if "selected_index" in target:
			return target.selected_index
		if "selected" in target:
			return target.selected
		return 0

	func set_ui_value(target: Control, value: Variant) -> void:
		if target is OptionButton:
			var opt = target as OptionButton
			var idx = int(value)
			if idx >= 0 and idx < opt.item_count:
				opt.selected = idx
		elif "selected_index" in target:
			target.selected_index = int(value)
		elif "selected" in target:
			target.selected = int(value)


class RadioGroupAdapter extends UiAdapter:
	func get_type_name() -> String:
		return "Control with 'button_group' metadata"

	func is_matching(node: Control) -> bool:
		return node != null and node.has_meta("button_group")

	func bind_events(target: Control) -> void:
		if target.has_meta("button_group"):
			var bg: ButtonGroup = target.get_meta("button_group")
			if not bg.pressed.is_connected(handler._on_radio_pressed):
				bg.pressed.connect(handler._on_radio_pressed)

	func get_default_value(target: Control) -> Variant:
		if target.has_meta("button_group"):
			var bg: ButtonGroup = target.get_meta("button_group")
			var pressed_btn = bg.get_pressed_button()
			if pressed_btn:
				var data = pressed_btn.get_meta("button_data", {})
				return data.get(handler.setting_key, pressed_btn.name)
		return null

	func set_ui_value(target: Control, value: Variant) -> void:
		if target.has_meta("button_group"):
			var bg: ButtonGroup = target.get_meta("button_group")
			for btn in bg.get_buttons():
				var data = btn.get_meta("button_data", {})
				if data.get(handler.setting_key) == value or btn.name == str(value) or btn.text == str(value):
					btn.button_pressed = true
					break


class CustomAdapter extends UiAdapter:
	func get_type_name() -> String:
		return "Custom Control / PanelButton"

	func is_matching(node: Control) -> bool:
		return node != null

	func bind_events(target: Control) -> void:
		if target.has_signal("setting_value_changed"):
			if not target.is_connected("setting_value_changed", handler._on_generic_value_changed):
				target.connect("setting_value_changed", handler._on_generic_value_changed)
		elif target.has_signal("value_changed"):
			if not target.is_connected("value_changed", handler._on_generic_value_changed):
				target.connect("value_changed", handler._on_generic_value_changed)
		elif target.has_signal("toggled"):
			if not target.is_connected("toggled", handler._on_toggle_value_changed):
				target.connect("toggled", handler._on_toggle_value_changed)
		elif "button" in target and target.button is BaseButton:
			var btn = target.button as BaseButton
			btn.toggle_mode = true
			if not btn.toggled.is_connected(handler._on_toggle_value_changed):
				btn.toggled.connect(handler._on_toggle_value_changed)
		elif target.has_node("Button"):
			var btn = target.get_node("Button") as BaseButton
			if btn:
				btn.toggle_mode = true
				if not btn.toggled.is_connected(handler._on_toggle_value_changed):
					btn.toggled.connect(handler._on_toggle_value_changed)
		elif target.has_signal("text_submitted"):
			if not target.is_connected("text_submitted", handler._on_generic_value_changed):
				target.connect("text_submitted", handler._on_generic_value_changed)

	func get_default_value(target: Control) -> Variant:
		if target.has_method("get_setting_value"):
			return target.call("get_setting_value")
		if "button" in target and target.button is BaseButton:
			return (target.button as BaseButton).button_pressed
		if "button_pressed" in target:
			return target.button_pressed
		if "value" in target:
			return target.value
		return null

	func set_ui_value(target: Control, value: Variant) -> void:
		if target.has_method("set_setting_value"):
			target.call("set_setting_value", value)
		elif "button" in target and target.button is BaseButton:
			(target.button as BaseButton).button_pressed = bool(value)
		elif "button_pressed" in target:
			target.button_pressed = bool(value)
		elif "value" in target:
			target.value = value

# ==============================================================================
# INITIALIZATION & LOGIC
# ==============================================================================

func initialize(parent_node: Node) -> void:
	parent = parent_node
	control = parent.get_node_or_null(control_node_path)
	if not control:
		printerr("SettingsHandlerRes: Control node not found for path '", control_node_path, "' in parent '", parent.name, "'")
		return
		
	_adapter = _create_adapter()
	target_control = _adapter.resolve_target(control)
	if not target_control:
		target_control = control
		
	is_loading = true
	
	var fallback_default = _adapter.get_default_value(target_control)
	var init_val = default_value if default_value != null else fallback_default
	var current_value = init_val
	var sm = _get_settings_manager()
	if sm:
		current_value = sm.get_setting(category, setting_key, init_val)
	
	_adapter.bind_events(target_control)
	_adapter.set_ui_value(target_control, current_value)
	apply_setting(current_value)
	
	is_loading = false

func _create_adapter() -> UiAdapter:
	match ui_type:
		UiType.SLIDER: return SliderAdapter.new(self)
		UiType.TOGGLE: return ToggleAdapter.new(self)
		UiType.SELECTOR: return SelectorAdapter.new(self)
		UiType.RADIO_GROUP: return RadioGroupAdapter.new(self)
		UiType.CUSTOM: return CustomAdapter.new(self)
	return CustomAdapter.new(self)

func apply_setting(value: Variant) -> void:
	var target = target_control if target_control else control
	match action_type:
		ActionType.AUDIO_VOLUME:
			var bus_idx = _find_audio_bus(setting_key)
			if bus_idx != -1:
				var slider = target as Slider
				var max_val = slider.max_value if slider and slider.max_value > 0.0 else 100.0
				var linear_ratio = clampf(float(value) / max_val, 0.0, 1.0)
				if linear_ratio <= 0.0001:
					AudioServer.set_bus_volume_db(bus_idx, -80.0)
				else:
					AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_ratio))
					
				if not is_loading and parent and parent.has_node("%AudioStreamPlayer"):
					var asp = parent.get_node("%AudioStreamPlayer") as AudioStreamPlayer
					if asp:
						asp.bus = AudioServer.get_bus_name(bus_idx)
						asp.play()

		ActionType.AUDIO_MUTE_ALL:
			var is_muted = bool(value)
			AudioServer.set_bus_mute(0, is_muted)
			for i in range(AudioServer.bus_count):
				AudioServer.set_bus_mute(i, is_muted)
			_visually_update_mute(is_muted)

		ActionType.WINDOW_MODE:
			var mode_idx = int(value)
			if mode_idx == 1:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				var sm = _get_settings_manager()
				var res_idx = 1
				if sm:
					res_idx = sm.get_setting("display", "resolution", 1)
				if res_idx >= 0 and res_idx < RESOLUTIONS.size():
					var target_res = RESOLUTIONS[res_idx]
					DisplayServer.window_set_size(target_res)
					var screen_size = DisplayServer.screen_get_size()
					var new_pos = (screen_size - target_res) / 2.0
					DisplayServer.window_set_position(new_pos)
			_update_resolution_ui_visibility(mode_idx == 0)

		ActionType.WINDOW_RESOLUTION:
			var res_idx = int(value)
			var cur_mode = DisplayServer.window_get_mode()
			if cur_mode == DisplayServer.WINDOW_MODE_WINDOWED or cur_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
				if res_idx >= 0 and res_idx < RESOLUTIONS.size():
					var target_res = RESOLUTIONS[res_idx]
					DisplayServer.window_set_size(target_res)
					var screen_size = DisplayServer.screen_get_size()
					var new_pos = (screen_size - target_res) / 2.0
					DisplayServer.window_set_position(new_pos)
			var sm = _get_settings_manager()
			var win_mode = 0
			if sm:
				win_mode = sm.get_setting("display", "window_mode", 0)
			_update_resolution_ui_visibility(win_mode == 0)

		ActionType.LANGUAGE:
			var lang_code = ""
			if value is int:
				var idx = int(value)
				if idx >= 0 and idx < LANGUAGES.size():
					lang_code = LANGUAGES[idx]
			elif value is String:
				lang_code = value
				
			if not lang_code.is_empty():
				TranslationServer.set_locale(lang_code)

		ActionType.CUSTOM:
			custom_action_requested.emit(setting_key, value)
			if parent and parent.has_method("_apply_custom_setting"):
				parent.call("_apply_custom_setting", setting_key, value)
			elif target and target.has_method("_apply_custom_setting"):
				target.call("_apply_custom_setting", setting_key, value)

func save_setting(value: Variant) -> void:
	var sm = _get_settings_manager()
	if sm:
		sm.set_setting(category, setting_key, value)
	if parent and parent.has_method("start_debounce"):
		parent.start_debounce()

static func _get_settings_manager() -> Node:
	if Engine.has_singleton("SettingsManager"):
		return Engine.get_singleton("SettingsManager")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root and main_loop.root.has_node("SettingsManager"):
		return main_loop.root.get_node("SettingsManager")
	return null

func _find_audio_bus(name_key: String) -> int:
	var idx = AudioServer.get_bus_index(name_key)
	if idx != -1: return idx
	idx = AudioServer.get_bus_index(name_key.capitalize())
	if idx != -1: return idx
	if name_key.to_lower() == "effects" or name_key.to_lower() == "sound":
		idx = AudioServer.get_bus_index("Sound")
		if idx != -1: return idx
		idx = AudioServer.get_bus_index("Effects")
		if idx != -1: return idx
	return -1

func _visually_update_mute(muted: bool) -> void:
	if parent and "handlers" in parent:
		for handler in parent.handlers:
			if handler and handler.ui_type == UiType.SLIDER:
				var sl = handler.target_control as Slider if handler.target_control else handler.control as Slider
				if sl:
					var prev_step = sl.step  
					sl.editable = !muted
					sl.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if muted else Control.CURSOR_POINTING_HAND
					# send "changed" signal to inner functions
					sl.step = prev_step * 2.0
					sl.step = prev_step

func _update_resolution_ui_visibility(is_windowed: bool) -> void:
	if parent:
		var res_node = parent.get_node_or_null("HboxContainerResolution")
		if not res_node:
			res_node = parent.find_child("HboxContainerResolution", true, false)
		if res_node:
			res_node.visible = is_windowed

func _on_slider_value_changed(val: float) -> void:
	if is_loading: return
	apply_setting(val)
	save_setting(val)

func _on_toggle_value_changed(toggled_on: bool) -> void:
	if is_loading: return
	apply_setting(toggled_on)
	save_setting(toggled_on)

func _on_selector_index_changed(index: int) -> void:
	if is_loading: return
	apply_setting(index)
	save_setting(index)

func _on_radio_pressed(button: Button) -> void:
	if is_loading: return
	var btn_data = button.get_meta("button_data", {})
	var val = btn_data.get(setting_key)
	if val != null:
		apply_setting(val)
		save_setting(val)

func _on_generic_value_changed(val: Variant) -> void:
	if is_loading: return
	apply_setting(val)
	save_setting(val)

static func setup_option_button_popup_cursor(opt: OptionButton) -> void:
	if not opt: return
	opt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var popup = opt.get_popup()
	if not popup: return
	if popup.has_meta("__cursor_hooked"): return
	popup.set_meta("__cursor_hooked", true)
	
	popup.window_input.connect(func(event: InputEvent):
		if event is InputEventMouseMotion:
			var hovered = popup.gui_get_hovered_control()
			if hovered is LineEdit:
				DisplayServer.cursor_set_shape(DisplayServer.CURSOR_IBEAM)
			else:
				DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)
	)
	popup.mouse_exited.connect(func():
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
	)
	popup.popup_hide.connect(func():
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
	)
