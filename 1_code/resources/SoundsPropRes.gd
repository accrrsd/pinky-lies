class_name SoundsPropsRes
extends Resource

@export var stream: AudioStream
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var pitch_randomness_min: float = 0.0
@export var pitch_randomness_max: float = 0.0
@export var max_polyphony: int = 1
@export var mix_target: AudioStreamPlayer.MixTarget
@export var bus: String = "Sound"

func apply_props_on_stream_player(audio_stream_player: Variant) -> void:
  # if not audio_stream_player is AudioStreamPlayer or not audio_stream_player is AudioStreamPlayer2D or audio_stream_player not is AudioStreamPlayer3D: return
  assert(audio_stream_player is AudioStreamPlayer or audio_stream_player is AudioStreamPlayer2D or audio_stream_player is AudioStreamPlayer3D, "audio_stream_player must be AudioStreamPlayer, AudioStreamPlayer2D or AudioStreamPlayer3D")

  audio_stream_player.stream = stream
  audio_stream_player.bus = bus
  audio_stream_player.volume_db = volume_db
  audio_stream_player.pitch_scale = pitch_scale
  if pitch_randomness_min != 0.0 or pitch_randomness_max != 0.0:
    audio_stream_player.pitch_scale += randf_range(pitch_randomness_min, pitch_randomness_max)
  audio_stream_player.max_polyphony = max_polyphony
