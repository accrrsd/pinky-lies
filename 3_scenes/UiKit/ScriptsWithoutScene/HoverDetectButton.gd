extends Button
class_name HoverDetectButton

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
  mouse_entered.connect(_on_mouse_entered)
  mouse_exited.connect(_on_mouse_exited)
  focus_entered.connect(_on_focus_entered)
  focus_exited.connect(_on_focus_exited)
  
  hover_changed.connect(_on_hovered)
  focus_changed.connect(_on_focused)
  
func _on_mouse_entered() -> void: is_hovered_var = true
func _on_mouse_exited() -> void: is_hovered_var = false

func _on_focus_entered() -> void: is_focused = true
func _on_focus_exited() -> void: is_focused = false

func _on_hovered(_value: bool) -> void: pass
func _on_focused(_value: bool) -> void: pass
