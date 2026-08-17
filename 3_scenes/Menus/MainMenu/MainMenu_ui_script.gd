extends Node

const bigColoredButtonFile = preload("res://3_scenes/UiKit/BigColoredButton/big_colored_button_script.gd")
var parent: Node

func _ready() -> void:
  if not owner.is_node_ready(): await owner.ready
  parent = owner

  # Main menu action buttons
  _setup_button("%StartGame", _on_start_game_pressed)
  _setup_button("%LoadGame", _on_load_game_pressed)
  _setup_button("%Gallery", _on_gallery_pressed)
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

func _setup_button(node_name: String, callable: Callable) -> void:
  var node = parent.get_node_or_null(node_name)
  if node and node is bigColoredButtonFile:
    node.button.pressed.connect(callable)

func _setup_raw_button(node_name: String, callable: Callable) -> void:
  var button = parent.get_node_or_null(node_name) as Button
  if button:
    button.pressed.connect(callable)

func _setup_footer_return(layer_node_name: String) -> void:
  var layer = parent.get_node_or_null(layer_node_name)
  if layer:
    var panel_handler = layer.get_node_or_null("UiPanelHandler")
    if not panel_handler:
      printerr("No panel handler for layer " + layer_node_name)
      return
    var return_btn: Button = panel_handler.get_node_or_null("%ReturnButton") as Button
    if return_btn and not return_btn.pressed.is_connected(_on_return_to_main_menu):
      return_btn.pressed.connect(_on_return_to_main_menu)

func _on_start_game_pressed() -> void:
  print("Start game pressed")

func _on_load_game_pressed() -> void:
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