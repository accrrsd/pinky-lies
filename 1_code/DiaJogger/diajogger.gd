## DiaJoggerFacade (Autoload: DiaJogger)
##
## Purpose:
##   The central facade and global singleton for the DiaJogger dialogue runtime.
##
## Role in Architecture:
##   The primary public API for game code. Coordinates documents, caret, runtime,
##   and view. Keeps the public surface area minimal:
##   - DiaJogger.load_file(path)
##   - await DiaJogger.play(target)
##   - var choice := await DiaJogger.choice(options)
##   - DiaJogger.serialize_state() / DiaJogger.restore_state(data)
##
## Usage:
##   # In any gameplay script:
##   DiaJogger.load_file("res://1_code/DiaJogger/examples/station.md")
##   await DiaJogger.play("Station/Act 1")
##   var choice := await DiaJogger.choice(["Truth", "Lie"])

extends Node
class_name DiaJoggerFacade

signal dialogue_started(target: String)
signal dialogue_finished(target: String)
signal choice_made(index: int, text: String)

static var instance: DiaJoggerFacade

var runtime: DiaJoggerRuntime
var caret: DiaJoggerCaret
var view: DiaJoggerView
var active_document: DiaJoggerDocument
var documents: Dictionary = {}
var target_to_document: Dictionary = {}
var current_target: String = ""

func _init() -> void:
  instance = self
  runtime = DiaJoggerRuntime.new()
  caret = DiaJoggerCaret.new()

func _ready() -> void: if instance == null: instance = self

func play(target_name: String = "", document: DiaJoggerDocument = null) -> void:
  if document != null:
    register_document(document)
    active_document = document
  elif not target_name.is_empty():
    if target_to_document.has(target_name): active_document = target_to_document[target_name]
    elif active_document == null or not active_document.has_target(target_name):
      printerr("DiaJogger: Target not found: ", target_name)
      return
  
  if active_document == null:
    printerr("DiaJogger: No active document loaded.")
    return
  
  caret.document = active_document
  if not target_name.is_empty():
    current_target = target_name
    caret.seek_target(target_name)
  
  _ensure_view()
  dialogue_started.emit(target_name)
  await runtime.run(caret, view)
  dialogue_finished.emit(target_name)

func resume() -> void:
  if active_document == null or caret == null:
    printerr("DiaJogger: Cannot resume without an active document or caret.")
    return
  _ensure_view()
  dialogue_started.emit(current_target)
  await runtime.run(caret, view)
  dialogue_finished.emit(current_target)

func choice(options: Array[String]) -> int:
  _ensure_view()
  var idx := await view.show_choice(options)
  var chosen_text := options[idx] if idx >= 0 and idx < options.size() else ""
  choice_made.emit(idx, chosen_text)
  return idx

func select_choice(index: int) -> void: if view != null: view.select_choice(index)
func is_waiting_choice() -> bool: return view != null and view.is_waiting_choice()

func stop() -> void:
  if runtime != null: runtime.stop()
  if view != null: view.cancel()

func load_file(path: String) -> DiaJoggerDocument:
  var doc := DiaJoggerParser.parse_file(path)
  if doc != null: register_document(doc)
  return doc

func load_string(content: String, source_id: String = "inline") -> DiaJoggerDocument:
  var doc := DiaJoggerParser.parse_string(content, source_id)
  if doc != null: register_document(doc)
  return doc

func load_directory(dir_path: String, recursive: bool = true) -> void:
  var dir := DirAccess.open(dir_path)
  if not dir: return
  dir.list_dir_begin()
  var file_name := dir.get_next()
  while not file_name.is_empty():
    var full_path := dir_path.path_join(file_name)
    if dir.current_is_dir():
      if recursive and not file_name.begins_with("."): load_directory(full_path, true)
    elif file_name.ends_with(".md"): load_file(full_path)
    file_name = dir.get_next()
  dir.list_dir_end()

func register_document(doc: DiaJoggerDocument) -> void:
  if doc == null: return
  if not doc.source_path.is_empty(): documents[doc.source_path] = doc
  for target_name in doc.get_target_names(): target_to_document[target_name] = doc
  if active_document == null: active_document = doc

func set_view(custom_view: DiaJoggerView) -> void:
  if view != null and view.get_parent() == self and view != custom_view: view.queue_free()
  view = custom_view

func get_state() -> DiaJoggerState: return caret.state if caret != null else null
func get_caret() -> DiaJoggerCaret: return caret
func get_runtime() -> DiaJoggerRuntime: return runtime
func get_view() -> DiaJoggerView: return view

func serialize_state() -> Dictionary:
  var pos := caret.position if caret != null else 0
  if runtime != null and runtime.is_active() and caret != null and caret.position > 0: pos = caret.position - 1
  return {
    "document_path": active_document.source_path if active_document != null else "",
    "position": pos,
    "current_target": current_target,
    "state": {
      "speaker": caret.state.speaker if caret != null and caret.state != null else "",
      "emotion": caret.state.emotion if caret != null and caret.state != null else "",
      "portrait": caret.state.portrait if caret != null and caret.state != null else "",
      "background": caret.state.background if caret != null and caret.state != null else "",
      "music": caret.state.music if caret != null and caret.state != null else "",
      "data": caret.state.data.duplicate(true) if caret != null and caret.state != null else {},
    }
  }

func restore_state(saved: Dictionary) -> void:
  var path: String = saved.get("document_path", "")
  if not path.is_empty():
    if not documents.has(path): load_file(path)
    active_document = documents.get(path, active_document)
    if caret != null: caret.document = active_document
  if caret != null:
    caret.position = saved.get("position", 0)
    current_target = saved.get("current_target", "")
    var st: Dictionary = saved.get("state", {})
    caret.state.reset()
    caret.state.speaker = st.get("speaker", "")
    caret.state.emotion = st.get("emotion", "")
    caret.state.portrait = st.get("portrait", "")
    caret.state.background = st.get("background", "")
    caret.state.music = st.get("music", "")
    caret.state.data = st.get("data", {}).duplicate(true)

func _ensure_view() -> void:
  if view != null: return
  var default_view := DiaJoggerView.new()
  default_view.name = "DefaultDiaJoggerView"
  add_child(default_view)
  view = default_view
