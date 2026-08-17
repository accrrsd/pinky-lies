extends HoverDetectButton
class_name SoundButton

@export var pressed_sound: SoundsPropsRes = null
@export var hover_sound: SoundsPropsRes = null
@export var scale_prop_res: ScaleHoverPropRes

var original_scale: Vector2
var active_tween: Tween

func _ready() -> void:
  super()
  original_scale = scale
  pressed.connect(_pressed)

func _pressed() -> void:
  if pressed_sound: Sounds.play(self, pressed_sound)

func _on_hovered(value: bool) -> void:
  if value:
    if hover_sound: Sounds.play(self, hover_sound)
    _change_scale_on_hover(true)
  else:
    _change_scale_on_hover(false)

func _on_focused(value: bool) -> void: _change_scale_on_focus(value)

func _change_scale_on_hover(value: bool) -> void:
  if not scale_prop_res: return
  pivot_offset = size * 0.5
  if scale_prop_res.scale_when_hovered == original_scale: return
  if active_tween: active_tween.kill()
  active_tween = create_tween()
  if value: active_tween.tween_property(self, "offset_transform_scale", scale_prop_res.scale_when_hovered, scale_prop_res.duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
  else: active_tween.tween_property(self, "offset_transform_scale", original_scale, scale_prop_res.duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func _change_scale_on_focus(focused: bool) -> void:
  if not scale_prop_res: return
  pivot_offset = size * 0.5
  if scale_prop_res.scale_when_focused == original_scale: return
  if active_tween: active_tween.kill()
  active_tween = create_tween()
  if focused: active_tween.tween_property(self, "offset_transform_scale", scale_prop_res.scale_when_focused, scale_prop_res.duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
  else: active_tween.tween_property(self, "offset_transform_scale", original_scale, scale_prop_res.duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
