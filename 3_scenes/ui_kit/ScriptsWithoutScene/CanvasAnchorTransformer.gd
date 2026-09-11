@tool
extends Node

# Outer and inner control nodes
@export var outer: Control
@export var inner: Control

func _ready() -> void:
	outer.resized.connect(_sync_size)
	_sync_size()

func _sync_size() -> void:
	if not outer or not inner: return
	var body = func():
		inner.size = outer.size
		inner.position = Vector2.ZERO
	body.call_deferred()
