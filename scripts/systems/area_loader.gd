class_name AreaLoader
extends RefCounted


static func instantiate_area(definition: AreaDefinition) -> Node3D:
	if not definition or not definition.validate_definition():
		return null
	var instance := definition.scene.instantiate()
	if not instance is Node3D:
		instance.free()
		return null
	return instance as Node3D
