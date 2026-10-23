extends State

@export var default_target_node: Node
@export var show_chain: TweenChainRes
@export var hide_chain: TweenChainRes

func start():
  if not show_chain: return
  var host: Node = default_target_node if default_target_node else self
  var tween: Tween = show_chain.create_tween(host)
  if not tween: return
  tween.play()
  await tween.finished

func end():
  if not hide_chain: return
  var host: Node = default_target_node if default_target_node else self
  var tween: Tween = hide_chain.create_tween(host)
  if not tween: return
  tween.play()
  await tween.finished
