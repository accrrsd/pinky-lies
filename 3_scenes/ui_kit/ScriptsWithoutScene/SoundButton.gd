extends HoverDetectButton
class_name SoundButton

@export var pressed_sound: SoundsPropsRes = null
@export var hover_sound: SoundsPropsRes = null


func _ready() -> void:
  super()
  if pressed_sound and not pressed.is_connected(_pressed):
    pressed.connect(_pressed)
  if hover_sound and not hover_changed.is_connected(_on_hovered):
    hover_changed.connect(_on_hovered)

func _pressed() -> void:
  var sounds = _get_sounds()
  if sounds and pressed_sound: sounds.play(self, pressed_sound)

func _on_hovered(value: bool) -> void:
  if value and hover_sound:
    var sounds = _get_sounds()
    if sounds: sounds.play(self, hover_sound)

func _get_sounds() -> Node:
  if is_inside_tree() and get_tree().root and get_tree().root.has_node("Sounds"):
    return get_tree().root.get_node("Sounds")
  return null