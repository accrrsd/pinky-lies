extends State

@export var default_target_node: Node
@export var show_chain: TweenChainRes
@export var hide_chain: TweenChainRes

func start():
  if not show_chain: return
  var tween: Tween = show_chain.create_tween(self, default_target_node)
  tween.play()
  await tween.finished

func end():
  if not hide_chain: return
  var tween: Tween = hide_chain.create_tween(self, default_target_node)
  tween.play()
  await tween.finished