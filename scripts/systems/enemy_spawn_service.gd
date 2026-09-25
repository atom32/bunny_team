class_name EnemySpawnService
extends RefCounted


static func spawn(definition: EnemyDefinition, spawn_transform: Transform3D, parent: Node) -> EnemyController:
	if not definition or not definition.validate_definition() or not parent:
		return null
	var instance := definition.scene.instantiate()
	var enemy := instance as EnemyController
	if not enemy:
		instance.free()
		push_error("Enemy definition %s scene root must be an EnemyController" % definition.id)
		return null
	if not enemy.configure_from_definition(definition):
		enemy.free()
		return null
	parent.add_child(enemy)
	enemy.global_transform = spawn_transform
	return enemy
