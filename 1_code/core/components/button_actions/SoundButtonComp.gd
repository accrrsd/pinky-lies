extends HoverButtonComp
class_name SoundButtonComp

@export var pressed_sound: SoundsPropsRes = null
@export var hover_sound: SoundsPropsRes = null

func _ready() -> void:
  super()
  if pressed_sound: button.pressed.connect(_on_pressed)
  if hover_sound: hover_changed.connect(_on_hover_changed)
  
func _on_pressed() -> void: Sounds.play(self, pressed_sound)
func _on_hover_changed(_is_hovered: bool) -> void: Sounds.play(self, hover_sound)
