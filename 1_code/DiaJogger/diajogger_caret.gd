## DiaJoggerCaret
##
## Purpose:
##   Tracks the current playback position in a DiaJoggerDocument and maintains the
##   active DiaJoggerState at that position.
##
## Role in Architecture:
##   The central conceptual playhead / scrubber ("jogger") of the system.
##   It answers the question: "Where are we in the document, and what presentation
##   state applies right now?" It advances event by event, updating the state.
##
## Usage:
##   var caret := DiaJoggerCaret.new(doc)
##   caret.seek_target("Station/Act 1")
##   while caret.has_next():
##     var event := caret.next()
##     caret.apply(event)

extends RefCounted
class_name DiaJoggerCaret

var document: DiaJoggerDocument
var position: int = 0
var state: DiaJoggerState

func _init(doc: DiaJoggerDocument = null) -> void:
  document = doc
  position = 0
  state = DiaJoggerState.new()

func has_next() -> bool: return document != null and position < document.events.size()
func peek() -> DiaJoggerEvent: return document.events[position] if has_next() else null
func step_back() -> void: if position > 0: position -= 1
func apply(event: DiaJoggerEvent) -> void: state.apply(event)

func next() -> DiaJoggerEvent:
  if not has_next(): return null
  var event := document.events[position]
  position += 1
  return event

func seek_target(target_name: String, carry_over_state: bool = true) -> bool:
  if document == null or not document.has_target(target_name): return false
  var idx := document.get_target_index(target_name)
  if carry_over_state: state = document.compute_state_at(idx)
  else: state.reset()
  position = idx + 1
  return true

func reset(doc: DiaJoggerDocument = null) -> void:
  if doc != null: document = doc
  position = 0
  state.reset()
