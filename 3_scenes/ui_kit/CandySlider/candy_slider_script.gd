extends Slider

@export var _progressBar: ProgressBar
var _texture: TextureRect

func _ready() -> void:
  _texture = _progressBar.get_children()[0] as TextureRect
  value_changed.connect(_on_value_changed)

func _on_value_changed(l_value: float) -> void:
  _texture.visible = l_value > 0
  _progressBar.value = l_value
