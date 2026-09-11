extends Control
@export var offset: Vector2

@export_group("inner")
@export var _progress_texture: TextureRect
@export var _slider:Slider

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_slider.value_changed.connect(_on_value_changed)
	_slider.changed.connect(_on_props_changed)

	_update_progress_deferred()
	_on_props_changed()

func _on_value_changed(l_value: float) -> void:
	var percent := l_value / _slider.max_value
	_progress_texture.size = Vector2(_slider.size.x * percent + offset.x, _progress_texture.size.y)

func _on_visibility_changed() -> void: if is_visible_in_tree(): _update_progress_deferred()

func _update_progress_deferred() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if is_instance_valid(self) and is_visible_in_tree(): _on_value_changed(_slider.value)

func _on_props_changed() -> void:
	_slider.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if not _slider.editable else Control.CURSOR_POINTING_HAND
