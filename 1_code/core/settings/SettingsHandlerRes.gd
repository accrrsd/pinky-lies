extends Resource
## Resource for binding UI controls to SettingsManager and applying setting changes.
##
## Custom Control Integration (UiType.CUSTOM):
## To integrate a custom UI control node, your custom control should implement:
## - Signal: signal setting_value_changed(value: Variant)
## - Setter Method: func set_setting_value(value: Variant) -> void
## - Getter Method (optional): func get_setting_value() -> Variant
##
## Custom Action Handling (ActionType.CUSTOM):
## When using ActionType.CUSTOM, listen to custom_action_requested signal or implement:
## - Method: func _apply_custom_setting(key: String, value: Variant) -> void
##
class_name SettingsHandlerRes

## Emitted when ActionType.CUSTOM is used and a setting value changes
signal custom_action_requested(key: String, value: Variant)

enum UiType {
  SLIDER,
  CHECKBOX,
  TOGGLE_SWITCH,
  RADIO_GROUP,
  OPTION_BUTTON,
  CUSTOM
}

enum ActionType {
  AUDIO_VOLUME,
  AUDIO_MUTE_ALL,
  WINDOW_MODE,
  CUSTOM
}

## Category section in settings config file (e.g. "audio", "display", "gameplay")
@export var category: String = ""
## Unique setting key inside category (e.g. "master_volume", "window_mode", "language")
@export var setting_key: String = ""
## Type of UI control used to display and modify this setting
@export var ui_type: UiType = UiType.SLIDER
## Built-in system action to trigger when setting changes
@export var action_type: ActionType = ActionType.AUDIO_VOLUME
## Relative NodePath to target Control node from parent SettingsHandler node
@export var control_node_path: NodePath

var parent: Node
var control: Control
var is_loading: bool = false

# Internal delegate for UI handling
var _ui_handler: UIHandlerBase

func initialize(parent_node: Node) -> void:
  parent = parent_node
  control = parent.get_node_or_null(control_node_path)
  if not control:
    printerr("Control node not found for path: ", control_node_path)
    return
    
  is_loading = true
  
  match ui_type:
    UiType.SLIDER: _ui_handler = SliderHandler.new(self)
    UiType.CHECKBOX: _ui_handler = CheckboxHandler.new(self)
    UiType.TOGGLE_SWITCH: _ui_handler = ToggleSwitchHandler.new(self)
    UiType.RADIO_GROUP: _ui_handler = RadioHandler.new(self)
    UiType.OPTION_BUTTON: _ui_handler = OptionButtonHandler.new(self)
    UiType.CUSTOM: _ui_handler = CustomUIHandler.new(self)
      
  var current_value = SettingsManager.get_setting(category, setting_key, _ui_handler.get_default_value())
  _ui_handler.setup_ui(current_value)
  apply_setting(current_value)
  
  is_loading = false

func apply_setting(value: Variant) -> void:
  match action_type:
    ActionType.AUDIO_VOLUME:
      var bus_name = setting_key
      var bus_idx = AudioServer.get_bus_index(bus_name)
      if bus_idx != -1:
        AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
        # Play test sound when the player adjusts the slider
        if not is_loading and parent and parent.has_node("%AudioStreamPlayer"):
          var asp = parent.get_node("%AudioStreamPlayer") as AudioStreamPlayer
          if asp:
            asp.bus = bus_name
            asp.play()
            
    ActionType.AUDIO_MUTE_ALL:
      var is_muted = value as bool
      for i in range(AudioServer.bus_count):
        if is_muted:
          AudioServer.set_bus_mute(i, true)
        else:
          var tree = Engine.get_main_loop() as SceneTree
          if tree:
            var timer = tree.create_timer(0.5)
            var unmute_bus = func(idx: int): AudioServer.set_bus_mute(idx, false)
            timer.timeout.connect(unmute_bus.bind(i))
          else:
            AudioServer.set_bus_mute(i, false)
            
      # Visually disable audio sliders
      if parent and "handlers" in parent:
        var handlers_list = parent.handlers
        if handlers_list:
          for handler in handlers_list:
            if handler and handler.category == category and handler.ui_type == UiType.SLIDER:
              handler.visually_disable_slider(is_muted)
              
    ActionType.WINDOW_MODE:
      var mode = value as int
      DisplayServer.window_set_mode(mode)

    ActionType.CUSTOM:
      custom_action_requested.emit(setting_key, value)
      if parent and parent.has_method("_apply_custom_setting"):
        parent.call("_apply_custom_setting", setting_key, value)
      elif control and control.has_method("_apply_custom_setting"):
        control.call("_apply_custom_setting", setting_key, value)

func save_setting(value: Variant) -> void:
  SettingsManager.set_setting(category, setting_key, value)
  if parent and parent.has_method("start_debounce"):
    parent.start_debounce()

func visually_disable_slider(mute: bool) -> void:
  if _ui_handler is SliderHandler:
    _ui_handler.visually_disable(mute)

# --- INTERNAL UI CLASSES ---

class UIHandlerBase:
  var owner: SettingsHandlerRes
  
  func _init(_owner: SettingsHandlerRes) -> void:
    owner = _owner
    
  func setup_ui(_current_value: Variant) -> void:
    pass
    
  func get_default_value() -> Variant:
    return null

class SliderHandler extends UIHandlerBase:
  var previous_value: float = 0.0
  var previous_cursor_shape: Control.CursorShape = Control.CURSOR_ARROW
  
  func setup_ui(current_value: Variant) -> void:
    var slider = owner.control as Slider
    if slider:
      if not slider.value_changed.is_connected(_on_value_changed):
        slider.value_changed.connect(_on_value_changed)
      slider.value = current_value
      previous_value = slider.value
      previous_cursor_shape = slider.mouse_default_cursor_shape
      
  func get_default_value() -> Variant:
    var slider = owner.control as Slider
    return slider.value if slider else 0.0
    
  func _on_value_changed(value: float) -> void:
    if owner.is_loading: return
    owner.apply_setting(value)
    owner.save_setting(value)
    
  func visually_disable(mute: bool) -> void:
    var slider = owner.control as Slider
    if not slider: return
    slider.set_block_signals(true)
    slider.editable = !mute
    if mute:
      previous_value = slider.value
      slider.value = 0
      slider.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
    else:
      slider.value = previous_value
      slider.mouse_default_cursor_shape = previous_cursor_shape
    slider.set_block_signals(false)

class CheckboxHandler extends UIHandlerBase:
  func setup_ui(current_value: Variant) -> void:
    var button = owner.control as Button
    if button:
      if not button.toggled.is_connected(_on_toggled):
        button.toggled.connect(_on_toggled)
      button.button_pressed = bool(current_value)
      
  func get_default_value() -> Variant:
    var button = owner.control as Button
    return button.button_pressed if button else false
    
  func _on_toggled(button_pressed: bool) -> void:
    if owner.is_loading: return
    owner.apply_setting(button_pressed)
    owner.save_setting(button_pressed)

class ToggleSwitchHandler extends UIHandlerBase:
  func setup_ui(current_value: Variant) -> void:
    if not owner.control: return
    
    if owner.control.has_signal("toggled"):
      if not owner.control.is_connected("toggled", _on_toggled):
        owner.control.connect("toggled", _on_toggled)
      if "button_pressed" in owner.control:
        owner.control.button_pressed = bool(current_value)
    elif owner.control.has_signal("switched"):
      if not owner.control.is_connected("switched", _on_toggled):
        owner.control.connect("switched", _on_toggled)
      if "is_on" in owner.control:
        owner.control.is_on = bool(current_value)
    elif owner.control.has_signal("value_changed"):
      if not owner.control.is_connected("value_changed", _on_toggled):
        owner.control.connect("value_changed", _on_toggled)
      if "value" in owner.control:
        owner.control.value = current_value

  func get_default_value() -> Variant:
    if not owner.control: return false
    if "button_pressed" in owner.control: return owner.control.button_pressed
    if "is_on" in owner.control: return owner.control.is_on
    if "value" in owner.control: return owner.control.value
    return false

  func _on_toggled(value: Variant) -> void:
    if owner.is_loading: return
    owner.apply_setting(value)
    owner.save_setting(value)

class RadioHandler extends UIHandlerBase:
  func setup_ui(current_value: Variant) -> void:
    if owner.control.has_meta("button_group"):
      var bg: ButtonGroup = owner.control.get_meta("button_group")
      if not bg.pressed.is_connected(_on_radio_pressed):
        bg.pressed.connect(_on_radio_pressed)
      
      var found := false
      for btn in bg.get_buttons():
        var btn_data = btn.get_meta("button_data", {})
        if btn_data.get(owner.setting_key) == current_value:
          btn.button_pressed = true
          found = true
          break
          
      if not found:
        var pressed_btn = bg.get_pressed_button()
        if pressed_btn:
          var btn_data = pressed_btn.get_meta("button_data", {})
          var val = btn_data.get(owner.setting_key)
          if val != null:
            SettingsManager.set_setting(owner.category, owner.setting_key, val)
            owner.apply_setting(val)
            
  func get_default_value() -> Variant:
    if owner.control and owner.control.has_meta("button_group"):
      var bg: ButtonGroup = owner.control.get_meta("button_group")
      var pressed = bg.get_pressed_button()
      if pressed:
        return pressed.get_meta("button_data", {}).get(owner.setting_key)
    return null
    
  func _on_radio_pressed(button: Button) -> void:
    if owner.is_loading: return
    var btn_data = button.get_meta("button_data", {})
    var value = btn_data.get(owner.setting_key)
    if value != null:
      owner.apply_setting(value)
      owner.save_setting(value)

class OptionButtonHandler extends UIHandlerBase:
  func setup_ui(current_value: Variant) -> void:
    var option_btn = owner.control as OptionButton
    if option_btn:
      if not option_btn.item_selected.is_connected(_on_item_selected):
        option_btn.item_selected.connect(_on_item_selected)
      
      var idx = int(current_value)
      if idx >= 0 and idx < option_btn.item_count:
        option_btn.selected = idx

  func get_default_value() -> Variant:
    var option_btn = owner.control as OptionButton
    return option_btn.selected if option_btn else 0

  func _on_item_selected(index: int) -> void:
    if owner.is_loading: return
    owner.apply_setting(index)
    owner.save_setting(index)

class CustomUIHandler extends UIHandlerBase:
  func setup_ui(current_value: Variant) -> void:
    if not owner.control: return

    # Priority 1: Custom interface method and signal
    if owner.control.has_signal("setting_value_changed"):
      if not owner.control.is_connected("setting_value_changed", _on_custom_value_changed):
        owner.control.connect("setting_value_changed", _on_custom_value_changed)
      if owner.control.has_method("set_setting_value"):
        owner.control.call("set_setting_value", current_value)
      return

    # Priority 2: LineEdit / TextEdit
    if owner.control.has_signal("text_submitted"):
      if not owner.control.is_connected("text_submitted", _on_custom_value_changed):
        owner.control.connect("text_submitted", _on_custom_value_changed)
      if "text" in owner.control:
        owner.control.text = str(current_value)
    elif owner.control.has_signal("text_changed"):
      if not owner.control.is_connected("text_changed", _on_custom_value_changed):
        owner.control.connect("text_changed", _on_custom_value_changed)
      if "text" in owner.control:
        owner.control.text = str(current_value)
    # Priority 3: Custom Sliders / SpinBox
    elif owner.control.has_signal("value_changed"):
      if not owner.control.is_connected("value_changed", _on_custom_value_changed):
        owner.control.connect("value_changed", _on_custom_value_changed)
      if "value" in owner.control:
        owner.control.value = current_value

  func get_default_value() -> Variant:
    if not owner.control: return null
    if owner.control.has_method("get_setting_value"):
      return owner.control.call("get_setting_value")
    if "text" in owner.control:
      return owner.control.text
    if "value" in owner.control:
      return owner.control.value
    if "button_pressed" in owner.control:
      return owner.control.button_pressed
    return null

  func _on_custom_value_changed(value: Variant) -> void:
    if owner.is_loading: return
    owner.apply_setting(value)
    owner.save_setting(value)
