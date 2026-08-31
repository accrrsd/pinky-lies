extends HoverButtonComp
class_name SoundButtonComp

@export var pressed_sound: SoundsPropsRes = null
@export var hover_sound: SoundsPropsRes = null

func _ready() -> void:
  super()
  if pressed_sound: button.pressed.connect(_on_pressed)
  if hover_sound: hover_changed.connect(_on_hover_changed)
  
func _on_pressed() -> void:
  var sounds = _get_sounds()
  if sounds and pressed_sound: sounds.play(self, pressed_sound)

func _on_hover_changed(_is_hovered: bool) -> void:
  if _is_hovered and hover_sound:
    var sounds = _get_sounds()
    if sounds: sounds.play(self, hover_sound)

func _get_sounds() -> Node:
  if is_inside_tree() and get_tree().root and get_tree().root.has_node("Sounds"):
    return get_tree().root.get_node("Sounds")
  return null
