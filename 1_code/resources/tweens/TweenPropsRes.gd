extends Resource
class_name TweenPropsRes

## Optional NodePath to the target node relative to host_node. If empty, fallback target or host_node is used.
@export var target_node_path: NodePath
## Property name or sub-property path to animate (e.g. "position:y", "modulate:a", "scale").
@export var property: String
## Optional initial value before interpolation starts. If null, current property value is used.
@export var start_value: Variant
## Target value to interpolate towards.
@export var final_value: Variant
## If true, final_value is treated as relative to the starting value rather than absolute.
@export var is_relative: bool = false
## If true, this step runs in parallel with preceding step instead of waiting for it to finish.
@export var is_parallel: bool = false

## Delay in seconds to wait after this step before continuing the chain.
@export var delay_after: float = 0.0
## If true, standalone tween created from this resource starts playing immediately.
@export var autostart: bool = false
## Duration of the interpolation in seconds.
@export var duration: float = 1.0
## Number of loops for standalone tween. -1 to disable looping, 0 for infinite loops.
@export var loops: int = -1
## Standalone tween playback speed multiplier.
@export var speed_scale: float = 1.0

@export_group("Transition")
## Transition curve type (e.g. TRANS_LINEAR, TRANS_SINE, TRANS_BACK).
@export var trans_type: Tween.TransitionType
## Easing style (e.g. EASE_IN, EASE_OUT, EASE_IN_OUT).
@export var ease_type: Tween.EaseType
## Process mode determining whether standalone tween updates during idle or physics frames.
@export var process_mode: Tween.TweenProcessMode
## Pause behavior when the SceneTree is paused.
@export var pause_mode: Tween.TweenPauseMode

## Resolves the target node given a path, host context node, and optional fallback target.
static func resolve_target(target_path: NodePath, host_node: Node, fallback_target: Node = null) -> Node:
  if not target_path.is_empty():
    if target_path.is_absolute() and host_node and host_node.get_tree(): return host_node.get_tree().root.get_node_or_null(target_path)
    elif host_node: return host_node.get_node_or_null(target_path)
  return fallback_target if fallback_target else host_node

## Applies this step animation to an existing Tween.
func apply_to_tween(tween: Tween, host_node: Node, fallback_target: Node = null) -> PropertyTweener:
  var target_node: Node = resolve_target(target_node_path, host_node, fallback_target)
  if not target_node or property.is_empty() or not tween: return null
  if is_parallel: tween.parallel()
  var tweener: PropertyTweener = tween.tween_property(target_node, property, final_value, duration).set_trans(trans_type).set_ease(ease_type)
  if start_value != null: tweener.from(start_value)
  if is_relative: tweener.as_relative()
  if delay_after > 0.0: tween.tween_interval(delay_after)
  return tweener

## Creates and configures a standalone Tween for this single step.
func create_tween(host_node: Node) -> Tween:
  if not host_node or property.is_empty(): return null
  var target_node: Node = resolve_target(target_node_path, host_node)
  if not target_node: return null

  var tween: Tween = host_node.create_tween()
  tween.set_process_mode(process_mode)
  tween.set_pause_mode(pause_mode)
  if loops >= 0: tween.set_loops(loops)
  if speed_scale != 1.0: tween.set_speed_scale(speed_scale)
  apply_to_tween(tween, host_node)
  if not autostart: tween.pause()
  return tween