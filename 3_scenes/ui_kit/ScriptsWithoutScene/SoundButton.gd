extends HoverDetectButton
class_name SoundButton

@export var pressed_sound: SoundsPropsRes = null
@export var hover_sound: SoundsPropsRes = null


func _ready() -> void:
  super()
  if pressed_sound: pressed.connect(_pressed)
  if hover_sound: hover_changed.connect(_on_hovered)

func _pressed() -> void: Sounds.play(self, pressed_sound)
func _on_hovered(value: bool) -> void: if value: Sounds.play(self, hover_sound)