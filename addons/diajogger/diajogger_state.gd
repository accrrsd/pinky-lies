## DiaJoggerState
##
## Purpose:
##   Holds the current presentation state (speaker, emotion, portrait, bg, music, data)
##   at any given point in the dialogue.
##
## Role in Architecture:
##   As the Caret moves through the event stream, it applies MARKUP and DATA events
##   to this state. When a TEXT event occurs, this state is passed to DiaJoggerView
##   so the UI knows who is speaking, what portrait/emotion to show, and what music to play.
##   Supports @r (reset all or selective @r s m) and "none" values.
##
## Usage:
##   state.apply(markup_event)
##   print(state.speaker, state.emotion)
##   var voice = state.get_data("voice")

extends RefCounted
class_name DiaJoggerState

var speaker: String = ""
var emotion: String = ""
var portrait: String = ""
var background: String = ""
var music: String = ""
var data: Dictionary = {}

func apply(event: DiaJoggerEvent) -> void:
  if event == null: return
  if event.type == DiaJoggerEvent.Type.MARKUP:
    match event.key:
      "r":
        var targets := str(event.value).strip_edges()
        if targets.is_empty(): reset()
        else: for t in targets.split(" ", false): _reset_tag(t.trim_prefix("@"))
      "s":
        speaker = "" if event.value == "none" else str(event.value)
      "e":
        emotion = "" if event.value == "none" else str(event.value)
      "p":
        portrait = "" if event.value == "none" else str(event.value)
      "b":
        background = "" if event.value == "none" else str(event.value)
      "m":
        music = "" if event.value == "none" else str(event.value)
      _: printerr("DiaJoggerState: Unrecognized markup key: ", event.key)
  elif event.type == DiaJoggerEvent.Type.DATA:
    if event.value == "none": data.erase(event.key)
    else: data[event.key] = event.value

func _reset_tag(tag: String) -> void:
  match tag:
    "s": speaker = ""
    "e": emotion = ""
    "p": portrait = ""
    "b": background = ""
    "m": music = ""
    "d": data.clear()
    _: data.erase(tag)

func get_data(data_key: String, default_value: Variant = null) -> Variant: return data.get(data_key, default_value)
func has_speaker() -> bool: return not speaker.is_empty()

func reset() -> void:
  speaker = ""
  emotion = ""
  portrait = ""
  background = ""
  music = ""
  data.clear()

func clone() -> DiaJoggerState:
  var copy := DiaJoggerState.new()
  copy.speaker = speaker
  copy.emotion = emotion
  copy.portrait = portrait
  copy.background = background
  copy.music = music
  copy.data = data.duplicate(true)
  return copy

func _to_string() -> String: return "DiaJoggerState(speaker='%s', emotion='%s', portrait='%s', bg='%s', music='%s', data=%s)" % [speaker, emotion, portrait, background, music, str(data)]
