@tool
extends Resource
class_name ControlThemeHandlerRes

@export var props: Array[ControlThemePropRes]

## Parent - owner node, override_ttv - theme_type_variation, most of the time you wanna pass it. If you dont - each element would use own type.
func apply_theme(parent: Node, override_ttv: StringName = &"") -> void:
  for prop in props:
    if prop:
      _apply_all_props(prop, parent, override_ttv)

func _apply_all_props(prop: ControlThemePropRes, parent: Node, override_ttv: StringName) -> void:
  for path in prop.paths:
    var node = get_node(path, parent)
    if node is Control:
      _apply_prop(prop, node, override_ttv)

func _apply_prop(prop: ControlThemePropRes, elem: Control, override_ttv: StringName) -> void:
  var ttv: StringName = override_ttv if override_ttv else elem.theme_type_variation
  var cpn: StringName = prop.custom_prop_name if prop.custom_prop_name else prop.prop_name
  match prop.prop_type:
    Theme.DATA_TYPE_COLOR:
      if elem.has_theme_color(cpn, ttv):
        var col = elem.get_theme_color(cpn, ttv)
        if prop.prop_name == &"modulate": elem.modulate = col
        elif prop.prop_name == &"self_modulate": elem.self_modulate = col
        else: elem.add_theme_color_override(prop.prop_name, col)
    Theme.DATA_TYPE_CONSTANT: if elem.has_theme_constant(cpn, ttv):elem.add_theme_constant_override(prop.prop_name, elem.get_theme_constant(cpn, ttv))
    Theme.DATA_TYPE_FONT: if elem.has_theme_font(cpn, ttv): elem.add_theme_font_override(prop.prop_name, elem.get_theme_font(cpn, ttv))
    Theme.DATA_TYPE_FONT_SIZE: if elem.has_theme_font_size(cpn, ttv): elem.add_theme_font_size_override(prop.prop_name, elem.get_theme_font_size(cpn, ttv))
    Theme.DATA_TYPE_ICON: if elem.has_theme_icon(cpn, ttv): elem.add_theme_icon_override(prop.prop_name, elem.get_theme_icon(cpn, ttv))
    Theme.DATA_TYPE_STYLEBOX: if elem.has_theme_stylebox(cpn, ttv): elem.add_theme_stylebox_override(prop.prop_name, elem.get_theme_stylebox(cpn, ttv))

static func get_node(target: NodePath, parent: Node) -> Node:
  if target.is_empty(): return null
  if target.is_absolute() and parent and parent.get_tree(): return parent.get_tree().root.get_node_or_null(target)
  elif parent: return parent.get_node_or_null(target)
  return null