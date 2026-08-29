@tool
extends PanelContainer

signal item_selected(index: int)
signal value_changed(value: Variant)

@export var options: Array[String] = []:
  set(value):
    options = value
    _update_state()

@export var selected_index: int = 0:
  set(value):
    selected_index = value
    _update_state()

@export var wrap_around: bool = true:
  set(value):
    wrap_around = value
    _update_buttons_enabled()

@export var localize_options: bool = true:
  set(value):
    localize_options = value
    _update_label()

@export var controlThemeHandler: ControlThemeHandlerRes

@export_group("DEV")
@export_tool_button("Apply normal theme", "Callable") var dev_apply_normal_theme = func():
  if controlThemeHandler: controlThemeHandler.apply_theme(self, theme_type_variation)

var prevButton: Button
var nextButton: Button
var label: Label

# Compatibility getter/setter with OptionButton API
var selected: int:
  get:
    return selected_index
  set(value):
    select(value)

func _notification(what: int) -> void:
  if what == NOTIFICATION_TRANSLATION_CHANGED:
    _update_label()

func _ready() -> void:
  _cache_nodes()
  if controlThemeHandler:
    controlThemeHandler.apply_theme(self, theme_type_variation)
    
  if not Engine.is_editor_hint():
    if prevButton and not prevButton.pressed.is_connected(_on_prev_button_pressed):
      prevButton.pressed.connect(_on_prev_button_pressed)
    if nextButton and not nextButton.pressed.is_connected(_on_next_button_pressed):
      nextButton.pressed.connect(_on_next_button_pressed)
      
  _update_state()

func _cache_nodes() -> void:
  if not prevButton:
    prevButton = get_node_or_null("%PrevButton")
  if not nextButton:
    nextButton = get_node_or_null("%NextButton")
  if not label:
    label = get_node_or_null("%Label")

func _update_state() -> void:
  _cache_nodes()
  if options.is_empty():
    if label: label.text = ""
    _update_buttons_enabled()
    return
  
  if selected_index < 0:
    selected_index = 0
  elif selected_index >= options.size():
    selected_index = options.size() - 1

  _update_label()
  _update_buttons_enabled()

func _update_label() -> void:
  _cache_nodes()
  if not label or options.is_empty(): return
  if selected_index >= 0 and selected_index < options.size():
    var raw_opt = options[selected_index]
    label.text = tr(raw_opt) if localize_options else raw_opt

func _update_buttons_enabled() -> void:
  _cache_nodes()
  if not prevButton or not nextButton: return
  if wrap_around or options.size() <= 1:
    prevButton.disabled = options.is_empty()
    nextButton.disabled = options.is_empty()
  else:
    prevButton.disabled = (selected_index <= 0)
    nextButton.disabled = (selected_index >= options.size() - 1)

func select(idx: int) -> void:
  if options.is_empty(): return
  selected_index = clampi(idx, 0, options.size() - 1)
  _update_state()

func get_selected() -> int:
  return selected_index

func get_selected_text() -> String:
  if options.is_empty() or selected_index < 0 or selected_index >= options.size():
    return ""
  var raw = options[selected_index]
  return tr(raw) if localize_options else raw

func get_selected_raw_text() -> String:
  if options.is_empty() or selected_index < 0 or selected_index >= options.size():
    return ""
  return options[selected_index]

func set_options(new_options: Array[String]) -> void:
  options = new_options

func add_item(item: String) -> void:
  options.append(item)
  _update_state()

func clear() -> void:
  options.clear()
  selected_index = 0
  _update_state()

func _on_prev_button_pressed() -> void:
  if options.is_empty(): return
  if wrap_around:
    selected_index = (selected_index - 1 + options.size()) % options.size()
  else:
    selected_index = max(0, selected_index - 1)
  _update_state()
  item_selected.emit(selected_index)
  value_changed.emit(get_selected_raw_text())

func _on_next_button_pressed() -> void:
  if options.is_empty(): return
  if wrap_around:
    selected_index = (selected_index + 1) % options.size()
  else:
    selected_index = min(options.size() - 1, selected_index + 1)
  _update_state()
  item_selected.emit(selected_index)
  value_changed.emit(get_selected_raw_text())
