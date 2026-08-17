extends Node

var sound_cooldown: float = 0.1

var _last_play_times: Dictionary = {}

func _should_throttle(props: SoundsPropsRes, custom_cooldown: float = -1.0) -> bool:
  if not props or not props.stream: return false
  var cooldown := sound_cooldown if custom_cooldown < 0.0 else custom_cooldown
  if cooldown <= 0.0: return false
  var now := Time.get_ticks_msec()
  var last_time: int = _last_play_times.get(props.stream, 0)
  if now - last_time < cooldown * 1000.0: return true
  _last_play_times[props.stream] = now
  return false

## Plays a sound non-positionally. The AudioStreamPlayer node will be added to the `parent`
## specified as parameter. The AudioStreamPlayer node will be freed automatically
## when the sound is done playing.
func play(parent: Node, props: SoundsPropsRes, custom_cooldown: float = -1.0) -> void:
  if not is_instance_valid(parent): return
  if _should_throttle(props, custom_cooldown): return
  var audio_stream_player := AudioStreamPlayer.new()
  props.apply_props_on_stream_player(audio_stream_player)
  parent.add_child(audio_stream_player)
  audio_stream_player.play()
  audio_stream_player.finished.connect(audio_stream_player.queue_free)

## Plays a sound with 2D position. The AudioStreamPlayer2D node will be added to the `parent`
## specified as parameter. The AudioStreamPlayer2D node will be freed automatically
## when the sound is done playing.
func play_2d(parent: Node, props: SoundsPropsRes, global_position: Vector2 = Vector2.ZERO, custom_cooldown: float = -1.0) -> void:
  if not is_instance_valid(parent): return
  if _should_throttle(props, custom_cooldown): return
  var audio_stream_player_2d := AudioStreamPlayer2D.new()
  props.apply_props_on_stream_player(audio_stream_player_2d)
  parent.add_child(audio_stream_player_2d)
  audio_stream_player_2d.global_position = parent.global_position if global_position == Vector2.ZERO else global_position
  audio_stream_player_2d.play()
  audio_stream_player_2d.finished.connect(audio_stream_player_2d.queue_free)

## Plays a sound with 3D position. The AudioStreamPlayer3D node will be added to the `parent`
## specified as parameter. The AudioStreamPlayer3D node will be freed automatically
## when the sound is done playing.
## The default unit size is greatly increased to make sounds easier to hear.
func play_3d(parent: Node, props: SoundsPropsRes, unit_db: float = 0.0, unit_size = 25.0, custom_cooldown: float = -1.0) -> void:
  if not is_instance_valid(parent): return
  if _should_throttle(props, custom_cooldown): return
  var audio_stream_player_3d := AudioStreamPlayer3D.new()
  props.apply_props_on_stream_player(audio_stream_player_3d)
  audio_stream_player_3d.unit_db = unit_db
  audio_stream_player_3d.unit_size = unit_size
  parent.add_child(audio_stream_player_3d)
  audio_stream_player_3d.play()
  audio_stream_player_3d.finished.connect(audio_stream_player_3d.queue_free)