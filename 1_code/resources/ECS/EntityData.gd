class_name EntityData
const varName: StringName = StringName("entityData")

enum ENTITY_TYPE {NONE, CHARACTER}
enum ENTITY_DIMENSION {DIMENSION_2D, DIMENSION_3D}

var entityType: ENTITY_TYPE
var dimension: ENTITY_DIMENSION
var components: Dictionary[StringName, ComponentsInfo]

func _init(_entityType: ENTITY_TYPE, _dimension: ENTITY_DIMENSION = ENTITY_DIMENSION.DIMENSION_2D) -> void:
  entityType = _entityType
  dimension = _dimension

func get_component_by_name_on_ready(node: Node, comp_name: StringName) -> Node:
  if not node.is_node_ready(): await node.ready
  return components.get(comp_name, null)

func add_component(compData: CompData, comp: Node) -> bool:
  var compsDatas = components.get_or_add(compData.comp_name, ComponentsInfo.new())
  if not compData.allow_multiple and compsDatas.comps.size() > 0: return false
  # if try to add comp that already exists in list
  if compsDatas.comps.has(comp): return false
  compsDatas.comps[comp] = true
  return true
  
func get_component(comp_name: StringName, idx := 0) -> Node:
  var comp_group = components.get(comp_name, null)
  if not comp_group: return null
  return comp_group.comps.keys()[idx]

func remove_component(compData: CompData, comp: Node) -> bool:
  if not components.has(compData.comp_name) or not components[compData.comp_name].comps.has(comp): return false
  components[compData.comp_name].comps.erase(comp)
  return true

class ComponentsInfo:
  var comps: Array[Node]