class_name EnemySpawnPoint
extends Marker3D

@export var enemy_definition_id: StringName
@export var initial_spawn := true
@export var activation_group_id: StringName

var has_spawned := false


func is_reinforcement_for(group_id: StringName) -> bool:
	return not initial_spawn and not group_id.is_empty() and activation_group_id == group_id


func mark_spawned() -> bool:
	if has_spawned:
		return false
	has_spawned = true
	return true
