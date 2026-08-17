extends Resource
class_name ScaleHoverPropRes

@export_custom(PROPERTY_HINT_LINK, "suffix:") var scale_when_hovered: Vector2 = Vector2.ONE
@export_custom(PROPERTY_HINT_LINK, "suffix:") var scale_when_focused: Vector2 = Vector2.ONE
@export var duration: float = 0.2
