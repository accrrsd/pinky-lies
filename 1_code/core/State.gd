@abstract
extends Node
class_name State

@abstract
func start()

@abstract
func end()

# also can have methods; if has it, they would be called in StateManager.gd
# func s_process(delta:float)->void:
    # pass
# func s_physics_process(delta:float)->void:
    # pass