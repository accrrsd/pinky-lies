extends CanvasLayer
class_name DemoCharacterLayer

@export var emily_sprite: TextureRect
@export var deva_sprite: TextureRect
@export var active_modulate: Color = Color.WHITE
@export var inactive_modulate: Color = Color(0.65, 0.65, 0.75, 1.0)
@export var tween_duration: float = 0.25

var _emily_base_y: float = 0.0
var _deva_base_y: float = 0.0

func _ready() -> void:
  layer = 10
  if not emily_sprite: emily_sprite = find_child("EmilySprite", true, false) as TextureRect
  if not deva_sprite: deva_sprite = find_child("DevaSprite", true, false) as TextureRect
  if emily_sprite: _emily_base_y = emily_sprite.position.y
  if deva_sprite: _deva_base_y = deva_sprite.position.y

func apply_state(state: DiaJoggerState) -> void:
  if state == null: return
  var spk := state.speaker.to_lower() if state.has_speaker() else ""

  if emily_sprite:
    var is_emily := (spk == "emily" or spk.is_empty())
    _animate_actor(emily_sprite, is_emily, _emily_base_y, state.emotion if spk == "emily" else "")

  if deva_sprite:
    var is_deva := (spk == "deva" or spk.is_empty())
    _animate_actor(deva_sprite, is_deva, _deva_base_y, state.emotion if spk == "deva" else "")

func _animate_actor(node: TextureRect, is_speaker: bool, base_y: float, emotion: String) -> void:
  var target_mod: Color = active_modulate if is_speaker else inactive_modulate
  var tw := create_tween().set_parallel(true)
  tw.tween_property(node, "modulate", target_mod, tween_duration)

  if is_speaker and not emotion.is_empty():
    var bounce_tw := create_tween()
    bounce_tw.tween_property(node, "position:y", base_y - 12.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    bounce_tw.tween_property(node, "position:y", base_y, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
