extends Resource
class_name TweenChainRes

@export var target: NodePath
@export var steps: Array[TweenPropsRes] = []
@export var autostart: bool = false
## -1 - disabled, 0 - endless
@export var loops: int = -1
@export var speed_scale: float = 1.0

@export_group("Global Tween Modes")
@export var process_mode: Tween.TweenProcessMode = Tween.TWEEN_PROCESS_IDLE
@export var pause_mode: Tween.TweenPauseMode = Tween.TWEEN_PAUSE_BOUND


func create_tween(parent: Node, default_target: Node = null) -> Tween:
	var chain_default_target: Node = TweenPropsRes._get_target(target, parent, default_target)
	if not chain_default_target or steps.is_empty(): return null

	var chain_tween: Tween = chain_default_target.create_tween()
	chain_tween.set_process_mode(process_mode)
	chain_tween.set_pause_mode(pause_mode)
	if loops >= 0: chain_tween.set_loops(loops)
	if speed_scale != 1.0: chain_tween.set_speed_scale(speed_scale)

	for step in steps: if step: step.apply_to_tween(chain_tween, parent, chain_default_target)
	if not autostart: chain_tween.pause()

	return chain_tween