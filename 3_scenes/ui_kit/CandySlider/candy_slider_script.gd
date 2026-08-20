extends Slider

@export var _progressBar: Range
var _progress_texture: TextureRect

func _ready() -> void:
  _progress_texture = _progressBar.get_children()[0] as TextureRect
  value_changed.connect(_on_value_changed)
  changed.connect(_on_props_changed)

func _on_value_changed(l_value: float) -> void:
  _progressBar.value = l_value
  # fix progress texture with 0 count
  _progress_texture.visible = l_value > 0

func _on_props_changed() -> void:
  _progressBar.value = value
  # fix progress texture with 0 count
  _progress_texture.visible = value > 0