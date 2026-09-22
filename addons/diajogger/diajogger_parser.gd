## DiaJoggerParser
##
## Purpose:
##   Parses raw Markdown dialogue text into a structured DiaJoggerDocument.
##
## Role in Architecture:
##   The bridge between human-authored Markdown in Obsidian/editors and the runtime
##   event stream. It recognizes structure tags (@target, @dirty, @write_wait),
##   presentation tags (@s, @e, @p, @b, @m, @r), arbitrary data (@d), multiple tags
##   per line, escapes (\@), and compiles dialogue text into TEXT events.
##
## Usage:
##   var doc := DiaJoggerParser.parse_file("res://addons/diajogger/examples/station.md")
##   # Or from raw string:
##   var doc := DiaJoggerParser.parse_string("@target Intro\n@s Ren\nHello!")

extends RefCounted
class_name DiaJoggerParser

static var _tag_regex: RegEx

static func _get_regex() -> RegEx:
  if _tag_regex != null: return _tag_regex
  _tag_regex = RegEx.new()
  _tag_regex.compile("@([a-zA-Z0-9_]+)(?:[ \\t]+([^@]*))?")
  return _tag_regex

static func parse_file(file_path: String) -> DiaJoggerDocument:
  if not FileAccess.file_exists(file_path):
    printerr("DiaJoggerParser: File not found: ", file_path)
    return null
  var file := FileAccess.open(file_path, FileAccess.READ)
  if not file:
    printerr("DiaJoggerParser: Failed to open file: ", file_path)
    return null
  var content := file.get_as_text()
  file.close()
  return parse_string(content, file_path)

static func parse_string(content: String, source_path: String = "") -> DiaJoggerDocument:
  var doc := DiaJoggerDocument.new()
  doc.source_path = source_path
  var lines := content.split("\n")
  var pending := {"dirty": false, "write_wait": -1.0}
  
  for raw_line in lines:
    var line := raw_line.strip_edges()
    if line.is_empty(): continue
    if line.begins_with("<!--") and line.ends_with("-->"): continue
    if line.begins_with("# ") or line.begins_with("//"): continue
    if line.begins_with("\\@"):
      doc.add_event(DiaJoggerEvent.make_text(line.substr(1), pending["dirty"], pending["write_wait"]))
      pending["dirty"] = false
      pending["write_wait"] = -1.0
      continue
    if line.begins_with("@target ") or line == "@target":
      doc.add_event(DiaJoggerEvent.make_target(line.substr(7).strip_edges() if line.begins_with("@target ") else ""))
      continue
    if line.begins_with("@"):
      _parse_tag_line(line, doc, pending)
      continue
    doc.add_event(DiaJoggerEvent.make_text(line, pending["dirty"], pending["write_wait"]))
    pending["dirty"] = false
    pending["write_wait"] = -1.0
  return doc

static func _parse_tag_line(line: String, doc: DiaJoggerDocument, pending: Dictionary) -> void:
  var regex := _get_regex()
  var matches := regex.search_all(line)
  for m in matches:
    var tag := m.get_string(1)
    var payload := m.get_string(2).strip_edges()
    
    if tag == "target": doc.add_event(DiaJoggerEvent.make_target(payload))
    elif tag == "dirty": pending["dirty"] = true
    elif tag == "write_wait": pending["write_wait"] = float(payload) if not payload.is_empty() else 0.0
    elif tag == "r": doc.add_event(DiaJoggerEvent.make_markup("r", payload))
    elif tag == "d":
      var space_pos := payload.find(" ")
      if space_pos != -1:
        var key := payload.substr(0, space_pos).strip_edges()
        var val := payload.substr(space_pos + 1).strip_edges()
        doc.add_event(DiaJoggerEvent.make_data(key, val))
      else: doc.add_event(DiaJoggerEvent.make_data(payload, true))
    elif tag in ["s", "e", "p", "b", "m"]: doc.add_event(DiaJoggerEvent.make_markup(tag, payload))
    else: printerr("DiaJoggerParser: Unrecognized tag '@%s' in line '%s'. Use '@d %s <value>' for custom metadata." % [tag, line, tag])
