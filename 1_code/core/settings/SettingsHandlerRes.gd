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

const RESOLUTIONS: Array[Vector2i] = [
  Vector2i(1920, 1080),
  Vector2i(1600, 900),
  Vector2i(1280, 720)
]

const LANGUAGES: Array[String] = ["en", "ru"]

func initialize(parent_node: Node) -> void:
  parent = parent_node
  control = parent.get_node_or_null(control_node_path)
  if not control:
    printerr("SettingsHandlerRes: Control node not found for path '", control_node_path, "' in parent '", parent.name, "'")
    return
    
  target_control = _resolve_target_control(control)
  if not target_control:
    return
    
  is_loading = true
  
  var fallback_default = _get_control_default_value()
  var init_val = default_value if default_value != null else fallback_default
  var current_value = SettingsManager.get_setting(category, setting_key, init_val)
  
  _bind_control_events()
  _set_control_ui_value(current_value)
  apply_setting(current_value)
  
  is_loading = false

func _resolve_target_control(root: Control) -> Control:
  if not root: return null
  
  if _is_expected_type(root):
    return root
    
  if root.has_meta(META_TARGET_CONTROL):
    var meta_val = root.get_meta(META_TARGET_CONTROL)
    var resolved: Control = null
    if meta_val is NodePath:
      resolved = root.get_node_or_null(meta_val) as Control
    elif meta_val is String:
      resolved = root.get_node_or_null(NodePath(meta_val)) as Control
    elif meta_val is Control:
      resolved = meta_val
      
    if resolved and _is_expected_type(resolved):
      return resolved
    elif resolved:
      printerr("SettingsHandlerRes: Target node '", resolved.get_path(), "' found via '", META_TARGET_CONTROL, "' metadata in '", root.get_path(), "', but it is not a '", _get_expected_type_name(), "'.")
      return resolved
      
  printerr("SettingsHandlerRes: Node '", root.get_path(), "' is a '", root.get_class(), "', not a '", _get_expected_type_name(), "'. Please specify '", META_TARGET_CONTROL, "' (NodePath) in its metadata pointing to the inner control.")
  return root

func _is_expected_type(node: Control) -> bool:
  if not node: return false
  match ui_type:
    UiType.SLIDER:
      return node is Slider
    UiType.TOGGLE:
      return node is BaseButton
    UiType.SELECTOR:
      return node is OptionButton or node.has_signal("item_selected") or node.has_method("select")
    UiType.RADIO_GROUP:
      return node.has_meta("button_group")
    UiType.CUSTOM:
      return true
  return false

func _get_expected_type_name() -> String:
  match ui_type:
    UiType.SLIDER: return "Slider (Range)"
    UiType.TOGGLE: return "BaseButton / CheckBox / HeartButton"
    UiType.SELECTOR: return "OptionButton / ArrowSelector"
    UiType.RADIO_GROUP: return "Control with 'button_group' metadata"
    UiType.CUSTOM: return "Custom Control"
  return "Control"

func _bind_control_events() -> void:
  var target = target_control if target_control else control
  if not target: return
  
  match ui_type:
    UiType.SLIDER:
      var slider = target as Slider
      if slider and not slider.value_changed.is_connected(_on_slider_value_changed):
        slider.value_changed.connect(_on_slider_value_changed)
        
    UiType.TOGGLE:
      var btn = target as BaseButton
      if btn:
        btn.toggle_mode = true
        if not btn.toggled.is_connected(_on_toggle_value_changed):
          btn.toggled.connect(_on_toggle_value_changed)
          
    UiType.SELECTOR:
      if target is OptionButton:
        var opt = target as OptionButton
        if not opt.item_selected.is_connected(_on_selector_index_changed):
          opt.item_selected.connect(_on_selector_index_changed)
      elif target.has_signal("item_selected"):
        if not target.is_connected("item_selected", _on_selector_index_changed):
          target.connect("item_selected", _on_selector_index_changed)
      elif target.has_signal("value_changed"):
        if not target.is_connected("value_changed", _on_generic_value_changed):
          target.connect("value_changed", _on_generic_value_changed)

    UiType.RADIO_GROUP:
      if target.has_meta("button_group"):
        var bg: ButtonGroup = target.get_meta("button_group")
        if not bg.pressed.is_connected(_on_radio_pressed):
          bg.pressed.connect(_on_radio_pressed)

    UiType.CUSTOM:
      if target.has_signal("setting_value_changed"):
        if not target.is_connected("setting_value_changed", _on_generic_value_changed):
          target.connect("setting_value_changed", _on_generic_value_changed)
      elif target.has_signal("value_changed"):
        if not target.is_connected("value_changed", _on_generic_value_changed):
          target.connect("value_changed", _on_generic_value_changed)
      elif target.has_signal("text_submitted"):
        if not target.is_connected("text_submitted", _on_generic_value_changed):
          target.connect("text_submitted", _on_generic_value_changed)

func _get_control_default_value() -> Variant:
  var target = target_control if target_control else control
  if not target: return null
  match ui_type:
    UiType.SLIDER:
      var slider = target as Slider
      return slider.value if slider else 50.0
    UiType.TOGGLE:
      var btn = target as BaseButton
      return btn.button_pressed if btn else false
    UiType.SELECTOR:
      if target is OptionButton:
        return (target as OptionButton).selected
      if "selected_index" in target:
        return target.selected_index
      if "selected" in target:
        return target.selected
      return 0
    UiType.CUSTOM:
      if target.has_method("get_setting_value"):
        return target.call("get_setting_value")
      if "value" in target:
        return target.value
      return null
  return null

func _set_control_ui_value(value: Variant) -> void:
  var target = target_control if target_control else control
  if not target or value == null: return
  match ui_type:
    UiType.SLIDER:
      var slider = target as Slider
      if slider:
        slider.value = float(value)
    UiType.TOGGLE:
      var btn = target as BaseButton
      if btn:
        btn.button_pressed = bool(value)
    UiType.SELECTOR:
      if target is OptionButton:
        var opt = target as OptionButton
        var idx = int(value)
        if idx >= 0 and idx < opt.item_count:
          opt.selected = idx
      elif target.has_method("select"):
        target.call("select", int(value))
      elif "selected_index" in target:
        target.selected_index = int(value)
      elif "selected" in target:
        target.selected = int(value)
    UiType.RADIO_GROUP:
      if target.has_meta("button_group"):
        var bg: ButtonGroup = target.get_meta("button_group")
        for btn in bg.get_buttons():
          var btn_data = btn.get_meta("button_data", {})
          if btn_data.get(setting_key) == value:
            btn.button_pressed = true
            break
    UiType.CUSTOM:
      if target.has_method("set_setting_value"):
        target.call("set_setting_value", value)
      elif "value" in target:
        target.value = value

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

    ActionType.WINDOW_RESOLUTION:
      var res_idx = int(value)
      if res_idx >= 0 and res_idx < RESOLUTIONS.size():
        var target_res = RESOLUTIONS[res_idx]
        DisplayServer.window_set_size(target_res)
        var screen_size = DisplayServer.screen_get_size()
        var new_pos = (screen_size - target_res) / 2
        DisplayServer.window_set_position(new_pos)

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
  SettingsManager.set_setting(category, setting_key, value)
  if parent and parent.has_method("start_debounce"):
    parent.start_debounce()

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
          sl.editable = !muted
          sl.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if muted else Control.CURSOR_POINTING_HAND

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
