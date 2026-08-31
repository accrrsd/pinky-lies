extends Node

# load gd script as a type without class
const bigColoredButtonFile = preload("uid://bmf4x3kgfv1yn")
var parent: Node

func _ready() -> void:
  if not owner.is_node_ready(): await owner.ready
  parent = owner

  # Main menu action buttons
  _setup_button("%StartGame", _on_start_game_pressed)
  _setup_button("%LoadGame", _on_load_game_pressed)
  _setup_button("%Gallery", _on_gallery_pressed)
  _setup_button("%Memories", _on_gallery_pressed)
  _setup_button("%Settings", _on_settings_pressed)
  _setup_button("%Exit", _on_exit_pressed)

  # Settings tabs
  _setup_raw_button("%AudioTabButton", func(): _change_settings_tab("ShowAudio"))
  _setup_raw_button("%TextTabButton", func(): _change_settings_tab("ShowText"))
  _setup_raw_button("%AdditionTabButton", func(): _change_settings_tab("ShowAddition"))
  _setup_raw_button("%HotKeysTabButton", func(): _change_settings_tab("ShowHotKeys"))

  # Footer Return buttons for all screens
  _setup_footer_return("Settings")
  _setup_footer_return("LoadGame")
  _setup_footer_return("Memories")
  
  # Settings Reset button
  _setup_settings_reset()

  # Ensure all option buttons have styled popup cursor
  _setup_all_option_buttons(parent)

func _setup_button(node_name: String, callable: Callable) -> void:
  var node = parent.get_node_or_null(node_name)
  if node and node is bigColoredButtonFile:
    node.button.pressed.connect(callable)

func _setup_raw_button(node_name: String, callable: Callable) -> void:
  var clean_name = node_name.trim_prefix("%")
  var node = parent.get_node_or_null(node_name)
  if not node:
    node = parent.find_child(clean_name, true, false)
  if not node and clean_name.ends_with("TabButton"):
    node = parent.find_child(clean_name.trim_suffix("TabButton"), true, false)
  if node:
    var btn: Button = node as Button
    if not btn and "button" in node and node.button is Button:
      btn = node.button
    elif not btn:
      btn = node.get_node_or_null("Button") as Button
    if btn and not btn.pressed.is_connected(callable):
      btn.pressed.connect(callable)
    elif node.has_signal("pressed") and not node.pressed.is_connected(callable):
      node.pressed.connect(callable)

func _setup_footer_return(layer_node_name: String) -> void:
  var layer = parent.get_node_or_null(layer_node_name)
  if layer:
    var panel_handler = layer.get_node_or_null("UiPanelHandler")
    if not panel_handler:
      printerr("No panel handler for layer " + layer_node_name)
      return
    var return_node = panel_handler.get_node_or_null("%ReturnButton")
    if not return_node:
      return_node = panel_handler.find_child("Return", true, false)
    if return_node:
      var btn: Button = return_node as Button
      if not btn and "button" in return_node and return_node.button is Button:
        btn = return_node.button
      elif not btn:
        btn = return_node.get_node_or_null("Button") as Button
      if btn and not btn.pressed.is_connected(_on_return_to_main_menu):
        btn.pressed.connect(_on_return_to_main_menu)

func _on_start_game_pressed() -> void:
  print("Start game pressed")

func _on_load_game_pressed() -> void:
  var save_load_handler = parent.get_node_or_null("LoadGame/SaveLoadHandler")
  if save_load_handler and save_load_handler.has_method("refresh"):
    save_load_handler.is_save_mode = false
    save_load_handler.refresh()
  var state_mgr = parent.get_node_or_null("%MenuStateManager") as StateManager
  if state_mgr: state_mgr.change_state("ShowLoadGame")

func _on_gallery_pressed() -> void:
  var state_mgr = parent.get_node_or_null("%MenuStateManager") as StateManager
  if state_mgr: state_mgr.change_state("ShowMemories")

func _on_settings_pressed() -> void:
  var state_mgr = parent.get_node_or_null("%MenuStateManager") as StateManager
  if state_mgr: state_mgr.change_state("ShowSettings")

func _on_exit_pressed() -> void:
  get_tree().quit()

func _on_return_to_main_menu() -> void:
  var state_mgr = parent.get_node_or_null("%MenuStateManager") as StateManager
  if state_mgr: state_mgr.change_state("ShowButtons")

func _change_settings_tab(tab_state_name: String) -> void:
  var settings_mgr = parent.get_node_or_null("%SettingsStateManager") as StateManager
  if settings_mgr: settings_mgr.change_state(tab_state_name)

func _setup_settings_reset() -> void:
  var settings_layer = parent.get_node_or_null("Settings")
  if settings_layer:
    var panel_handler = settings_layer.get_node_or_null("UiPanelHandler")
    if panel_handler:
      var reset_node = panel_handler.get_node_or_null("%ResetButton")
      if not reset_node:
        reset_node = panel_handler.find_child("Reset", true, false)
      if reset_node:
        var btn: Button = reset_node as Button
        if not btn and "button" in reset_node and reset_node.button is Button:
          btn = reset_node.button
        elif not btn:
          btn = reset_node.get_node_or_null("Button") as Button
        if btn and not btn.pressed.is_connected(_on_settings_reset_pressed):
          btn.pressed.connect(_on_settings_reset_pressed)

func _on_settings_reset_pressed() -> void:
  var audio_content = parent.get_node_or_null("Settings/UiPanelHandler/MarginContainer/PanelContainer/MarginContainer/MainVBox/ContentContainer/AudioContent")
  var text_content = parent.get_node_or_null("Settings/UiPanelHandler/MarginContainer/PanelContainer/MarginContainer/MainVBox/ContentContainer/TextContent")
  var addition_content = parent.get_node_or_null("Settings/UiPanelHandler/MarginContainer/PanelContainer/MarginContainer/MainVBox/ContentContainer/AdditionContent")
  for content in [audio_content, text_content, addition_content]:
    if content and content.has_method("reset_to_defaults"):
      content.reset_to_defaults()

func _setup_all_option_buttons(node: Node) -> void:
  if not node: return
  if node is OptionButton:
    SettingsHandlerRes.setup_option_button_popup_cursor(node as OptionButton)
  for child in node.get_children():
    _setup_all_option_buttons(child)
