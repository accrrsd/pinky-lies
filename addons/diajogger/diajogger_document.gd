## DiaJoggerDocument
##
## Purpose:
##   Represents a parsed dialogue document in memory, storing the sequential
##   event stream and a dictionary of target entry points.
##
## Role in Architecture:
##   Produced by DiaJoggerParser and consumed by DiaJoggerCaret. It provides fast
##   target indexing and can compute the presentation state at any event index.
##
## Usage:
##   var doc := DiaJoggerParser.parse_file("res://addons/diajogger/examples/station.md")
##   var target_idx := doc.get_target_index("Station/Act 1")
##   var state_at_target := doc.compute_state_at(target_idx)

extends RefCounted
class_name DiaJoggerDocument

var source_path: String = ""
var events: Array[DiaJoggerEvent] = []
var targets: Dictionary = {}

func add_event(event: DiaJoggerEvent) -> void:
  if event == null: return
  if event.type == DiaJoggerEvent.Type.TARGET: targets[event.key] = events.size()
  events.append(event)

func has_target(target_name: String) -> bool: return targets.has(target_name)
func get_target_index(target_name: String) -> int: return targets.get(target_name, -1)
func get_target_names() -> Array: return targets.keys()
func size() -> int: return events.size()
func is_empty() -> bool: return events.is_empty()
func get_event(index: int) -> DiaJoggerEvent: return events[index] if index >= 0 and index < events.size() else null

func compute_state_at(index: int) -> DiaJoggerState:
  var state := DiaJoggerState.new()
  var limit := mini(index, events.size())
  for i in range(limit):
    var ev := events[i]
    if ev.type == DiaJoggerEvent.Type.MARKUP or ev.type == DiaJoggerEvent.Type.DATA: state.apply(ev)
  return state
