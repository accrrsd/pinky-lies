extends CanvasLayer
class_name NovelCharacterStage

@export var auto_connect_diajogger: bool = true
@export var active_modulate: Color = Color.WHITE
@export var inactive_modulate: Color = Color(0.65, 0.65, 0.75, 1.0)
@export var tween_duration: float = 0.25

var actors: Dictionary = {}

func _ready() -> void:
  layer = 10
  _find_child_actors(self)
  if auto_connect_diajogger and typeof(DiaJogger) != TYPE_NIL and DiaJogger != null:
    if not DiaJogger.state_changed.is_connected(apply_state):
      DiaJogger.state_changed.connect(apply_state)

func register_actor(actor_name: String, node: TextureRect) -> void: actors[actor_name.to_lower()] = node

func apply_state(state: DiaJoggerState) -> void:
  if state == null: return
  var current_speaker: String = state.speaker.to_lower() if state.has_speaker() else ""

  for actor_name in actors:
    var node: TextureRect = actors[actor_name]
    if not is_instance_valid(node): continue
    var is_speaker: bool = (actor_name == current_speaker) or (current_speaker.is_empty())
    var target_modulate: Color = active_modulate if is_speaker else inactive_modulate

    var tw := create_tween()
    tw.tween_property(node, "modulate", target_modulate, tween_duration)

func _find_child_actors(node: Node) -> void:
  for child in node.get_children():
    if child is TextureRect and child.name.ends_with("Sprite"):
      var clean_name = child.name.trim_suffix("Sprite").to_lower()
      register_actor(clean_name, child as TextureRect)
    _find_child_actors(child)
