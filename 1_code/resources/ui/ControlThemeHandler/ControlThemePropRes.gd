@tool
extends Resource
class_name ControlThemePropRes

## Paths to Control nodes.
@export var paths: Array[NodePath]
## Name of original property would be overrited.
@export var prop_name: StringName
## Custom name of theme property. Leave empty if same as prop_name
@export var custom_prop_name: StringName
## Type of property would be overrited.
@export var prop_type: Theme.DataType

func apply_prop(elem: Control, override_ttv: StringName) -> void:
  var ttv: StringName = override_ttv if override_ttv else elem.theme_type_variation
  var cpn = custom_prop_name if custom_prop_name else prop_name
  match prop_type:
    Theme.DATA_TYPE_COLOR:
      if elem.has_theme_color(cpn, ttv): elem.add_theme_color_override(prop_name, elem.get_theme_color(cpn, ttv))
    Theme.DATA_TYPE_CONSTANT:
      if elem.has_theme_constant(cpn, ttv): elem.add_theme_constant_override(prop_name, elem.get_theme_constant(cpn, ttv))
    Theme.DATA_TYPE_FONT:
      if elem.has_theme_font(cpn, ttv): elem.add_theme_font_override(prop_name, elem.get_theme_font(cpn, ttv))
    Theme.DATA_TYPE_FONT_SIZE:
      if elem.has_theme_font_size(cpn, ttv): elem.add_theme_font_size_override(prop_name, elem.get_theme_font_size(cpn, ttv))
    Theme.DATA_TYPE_ICON:
      if elem.has_theme_icon(cpn, ttv): elem.add_theme_icon_override(prop_name, elem.get_theme_icon(cpn, ttv))
    Theme.DATA_TYPE_STYLEBOX:
      if elem.has_theme_stylebox(cpn, ttv): elem.add_theme_stylebox_override(prop_name, elem.get_theme_stylebox(cpn, ttv))

func apply_all_props(parent: Node, override_ttv: StringName) -> void:
  for path in paths:
    var node = get_node(path, parent)
    if node: apply_prop(node, override_ttv)

static func get_node(target: NodePath, parent: Node) -> Node:
  if not target.is_empty():
      if target.is_absolute() and parent and parent.get_tree(): return parent.get_tree().root.get_node_or_null(target)
      elif parent: return parent.get_node_or_null(target)
  return null