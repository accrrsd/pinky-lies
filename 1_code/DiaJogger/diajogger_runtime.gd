## DiaJoggerRuntime
##
## Purpose:
##   The minimal event interpreter loop that executes events until a Target boundary or EOF.
##
## Role in Architecture:
##   Kept intentionally "dumb": contains no gameplay logic, scene switching, or branching.
##   It simply steps the Caret forward:
##   - TEXT: awaits view.show_text(text, caret.state)
##   - MARKUP / DATA: caret.apply(event)
##   - TARGET: stops execution (steps back so target remains boundary) and breaks
##
## Usage:
##   await runtime.run(caret, view)

extends RefCounted
class_name DiaJoggerRuntime

signal dialogue_started(caret: DiaJoggerCaret)
signal dialogue_finished(caret: DiaJoggerCaret)
signal event_processed(event: DiaJoggerEvent, state: DiaJoggerState)
signal text_emitted(text: String, state: DiaJoggerState)

var is_running: bool = false

func stop() -> void: is_running = false
func is_active() -> bool: return is_running

func run(caret: DiaJoggerCaret, view: DiaJoggerView) -> void:
  if caret == null: return
  is_running = true
  dialogue_started.emit(caret)
  
  while is_running and caret.has_next():
    var event := caret.next()
    if event == null: break
    match event.type:
      DiaJoggerEvent.Type.TEXT:
        event_processed.emit(event, caret.state)
        text_emitted.emit(str(event.value), caret.state)
        if view != null: await view.show_text(str(event.value), caret.state, event.is_dirty, event.write_wait)
      DiaJoggerEvent.Type.MARKUP, DiaJoggerEvent.Type.DATA:
        caret.apply(event)
        event_processed.emit(event, caret.state)
      DiaJoggerEvent.Type.TARGET:
        caret.step_back()
        break
  
  is_running = false
  dialogue_finished.emit(caret)
