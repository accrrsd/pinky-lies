extends Node

const bigColoredButtonFile = preload("res://3_scenes/UiKit/BigColoredButton/big_colored_button_script.gd")
var parent: Node

func _ready() -> void:
  if not owner.is_node_ready(): await owner.ready
  parent = owner
  var startGameButton = (parent.get_node("%StartGame") as bigColoredButtonFile).button
  startGameButton.pressed.connect(_on_start_game_button_pressed)

func _on_start_game_button_pressed() -> void:
  var node = (parent.get_node("%MenuStateManager") as StateManager)
  node.change_state("ShowSettings")