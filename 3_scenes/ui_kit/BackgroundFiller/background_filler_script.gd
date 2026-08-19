@tool
extends Control
@export var backgroundImage:Texture:
  set(new_texture):
    if new_texture == backgroundImage:return
    backgroundImage = new_texture
    _update_texture()
    
func _ready() -> void:
  _update_texture()

func _update_texture()->void:
  if not is_inside_tree(): await ready
  %Background.texture = backgroundImage
  %BlurBackground.texture = backgroundImage
