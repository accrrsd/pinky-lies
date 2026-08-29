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