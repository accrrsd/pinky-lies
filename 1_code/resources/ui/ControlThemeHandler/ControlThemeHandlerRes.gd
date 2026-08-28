@tool
extends Resource
class_name ControlThemeHandlerRes

@export var props: Array[ControlThemePropRes]

## Parent - owner node, override_ttv - theme_type_variation, most of the time you wanna pass it. If you dont - each element would use own type.
func apply_theme(parent: Node, override_ttv: StringName) -> void:
  for prop in props: if prop: prop.apply_all_props(parent, override_ttv)