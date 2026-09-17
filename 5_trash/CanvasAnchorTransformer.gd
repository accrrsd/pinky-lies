@tool
extends CanvasGroup

## If outer modulate changes, it can have modulate_parent nodepath metadata.
@export var outer: Control
@export var inner: Control

const meta:StringName = StringName("modulate_parent")

func _ready() -> void:
	outer.resized.connect(_on_outer_resized)
	outer.draw.connect(_on_outer_draw)
	_on_outer_resized()

func _on_outer_draw()->void:
	if not outer.has_meta(meta): return
	var path:NodePath = outer.get_meta(meta)
	self_modulate = outer.get_node(path).modulate
	print(self_modulate)

func _on_outer_resized() -> void:
	if not outer or not inner: return
	var body = func():
		inner.size = outer.size
		inner.position = Vector2.ZERO
	body.call_deferred()
