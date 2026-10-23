extends Resource
class_name TweenChainRes

## Fallback target NodePath for steps in this chain that do not specify their own target.
@export var default_target_path: NodePath
## List of tween steps executed within this chain.
@export var steps: Array[TweenPropsRes] = []
## If true, the tween starts playing immediately upon creation. Otherwise, it starts paused.
@export var autostart: bool = false
## Number of loops for the chain. -1 to disable looping, 0 for infinite loops.
@export var loops: int = -1
## Playback speed multiplier for the entire chain.
@export var speed_scale: float = 1.0

@export_group("Global Tween Modes")
## Process mode determining whether the tween updates during idle or physics frames.
@export var process_mode: Tween.TweenProcessMode = Tween.TWEEN_PROCESS_IDLE
## Pause behavior when the SceneTree is paused.
@export var pause_mode: Tween.TweenPauseMode = Tween.TWEEN_PAUSE_BOUND

## Creates and configures a Tween bound to the host node.
## host_node: The node that hosts the tween lifecycle and serves as root for relative paths.
func create_tween(host_node: Node) -> Tween:
  if steps.is_empty() or not host_node: return null
  var resolved_default_target: Node = TweenPropsRes.resolve_target(default_target_path, host_node)

  var chain_tween: Tween = host_node.create_tween()
  chain_tween.set_process_mode(process_mode)
  chain_tween.set_pause_mode(pause_mode)
  if loops >= 0: chain_tween.set_loops(loops)
  if speed_scale != 1.0: chain_tween.set_speed_scale(speed_scale)

  for step in steps: if step: step.apply_to_tween(chain_tween, host_node, resolved_default_target)
  if not autostart: chain_tween.pause()

  return chain_tween
