class_name CompData

# public data, one time set
var comp_name: StringName
var allow_multiple: bool = false

func _init(_allow_multiple := false) -> void:
  allow_multiple = _allow_multiple

func search_and_apply_self_to_entity(comp: Node) -> Node:
  comp_name = comp.get_script().get_global_name()
  apply_self_to_entity(comp.owner, comp)
  return comp.owner

func apply_self_to_entity(entity: Node, comp: Node) -> bool:
  # check if the entity is a valid entity
  assert(EntityData.varName in entity, "Entity " + entity.name + " doesn't have a valid entityData")
  return entity[EntityData.varName].add_component(self , comp)
