## DiaJoggerEvent
##
## Purpose:
##   Represents a single atomic event in the dialogue stream.
##
## Role in Architecture:
##   DiaJogger compiles Markdown into a linear stream of events. Instead of a
##   bloated class hierarchy for every tag, DiaJogger uses 4 minimal event types:
##   - TARGET: Named entry point / boundary marker (e.g. "@target Station/Act 1")
##   - MARKUP: Core presentation tags ('s' speaker, 'e' emotion, 'p' portrait, 'b' bg, 'm' music)
##   - DATA: Arbitrary presentation metadata (e.g. "@d voice emily_03")
##   - TEXT: Dialogue text to be displayed by the view
##
## Usage:
##   var text_ev := DiaJoggerEvent.make_text("Hello, world!")
##   var target_ev := DiaJoggerEvent.make_target("Act 1")
##   var markup_ev := DiaJoggerEvent.make_markup("s", "Emily")

extends RefCounted
class_name DiaJoggerEvent

enum Type {
  TARGET,
  MARKUP,
  DATA,
  TEXT,
}

var type: Type
var key: String = ""
var value: Variant = ""
var is_dirty: bool = false
var write_wait: float = -1.0

func _init(p_type: Type = Type.TEXT, p_key: String = "", p_value: Variant = "") -> void:
  type = p_type
  key = p_key
  value = p_value

static func make_target(target_name: String) -> DiaJoggerEvent: return DiaJoggerEvent.new(Type.TARGET, target_name, "")
static func make_markup(tag: String, val: String = "") -> DiaJoggerEvent: return DiaJoggerEvent.new(Type.MARKUP, tag, val)
static func make_data(data_key: String, val: Variant = "") -> DiaJoggerEvent: return DiaJoggerEvent.new(Type.DATA, data_key, val)
static func make_text(text_content: String, dirty: bool = false, p_write_wait: float = -1.0) -> DiaJoggerEvent:
  var ev := DiaJoggerEvent.new(Type.TEXT, "", text_content)
  ev.is_dirty = dirty
  ev.write_wait = p_write_wait
  return ev

func _to_string() -> String:
  match type:
    Type.TARGET: return "Target(\"%s\")" % key
    Type.MARKUP: return "Markup(\"%s\", \"%s\")" % [key, value]
    Type.DATA: return "Data(\"%s\", \"%s\")" % [key, value]
    Type.TEXT: return "Text(\"%s\"%s%s)" % [value, ", dirty" if is_dirty else "", ", write_wait=%.2f" % write_wait if write_wait >= 0.0 else ""]
  return "DiaJoggerEvent()"
