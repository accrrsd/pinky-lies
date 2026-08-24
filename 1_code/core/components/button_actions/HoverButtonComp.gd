extends Node
class_name HoverButtonComp

@export var button: Button

var is_hovered_var: bool = false:
  set(value):
    if is_hovered_var == value: return
    is_hovered_var = value
    hover_changed.emit(is_hovered_var)

signal hover_changed(is_hovered: bool)

var is_focused: bool = false:
  set(value):
    if is_focused == value: return
    is_focused = value
    focus_changed.emit(is_focused)

signal focus_changed(is_focused: bool)

func _ready() -> void:
  button.mouse_entered.connect(_on_mouse_entered)
  button.mouse_exited.connect(_on_mouse_exited)
  button.focus_entered.connect(_on_focus_entered)
  button.focus_exited.connect(_on_focus_exited)
  
func _on_mouse_entered() -> void: is_hovered_var = true
func _on_mouse_exited() -> void: is_hovered_var = false

func _on_focus_entered() -> void: is_focused = true
func _on_focus_exited() -> void: is_focused = false