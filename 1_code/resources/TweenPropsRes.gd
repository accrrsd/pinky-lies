extends Resource
class_name TweenPropsRes

## OPTIONAL. If not used - use default target from function call.
@export var target: NodePath
@export var property: String
@export var start_value: Variant
@export var final_value: Variant
@export var is_relative: bool = false
@export var is_parallel: bool = false

@export var delay_after: float = 0.0
@export var autostart: bool = false
@export var duration: float = 1.0
## -1 - disabled, 0 - endless
@export var loops: int = -1
@export var speed_scale: float = 1.0

@export_subgroup("Transition")
@export var trans_type: Tween.TransitionType
@export var ease_type: Tween.EaseType
@export var process_mode: Tween.TweenProcessMode
@export var pause_mode: Tween.TweenPauseMode

static func _get_target(l_target: NodePath, parent: Node, default_target: Node = null) -> Node:
	if not l_target.is_empty():
		if l_target.is_absolute() and parent and parent.get_tree(): return parent.get_tree().root.get_node_or_null(l_target)
		elif parent: return parent.get_node_or_null(l_target)
	if default_target: return default_target
	return null

func apply_to_tween(tween: Tween, parent: Node, default_target: Node = null) -> PropertyTweener:
	var current_target: Node = _get_target(target, parent, default_target)
	if not current_target or property.is_empty() or not tween: return null
	if is_parallel: tween.parallel()
	var tweener: PropertyTweener = tween.tween_property(current_target, property, final_value, duration).set_trans(trans_type).set_ease(ease_type)
	if start_value != null: tweener.from(start_value)
	if is_relative: tweener.as_relative()
	if delay_after > 0.0: tween.tween_interval(delay_after)
	return tweener

func create_tween(parent: Node, default_target: Node = null) -> Tween:
	var current_target: Node = _get_target(target, parent, default_target)
	if not current_target or property.is_empty(): return null
	var tween: Tween = current_target.create_tween()
	tween.set_process_mode(process_mode)
	tween.set_pause_mode(pause_mode)
	if loops >= 0: tween.set_loops(loops)
	if speed_scale != 1.0: tween.set_speed_scale(speed_scale)
	apply_to_tween(tween, parent, default_target)
	if not autostart: tween.pause()
	return tween