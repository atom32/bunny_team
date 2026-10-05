class_name CombatNoise
extends RefCounted
## Short-lived observations, not an omniscient broadcast of the player transform.
## Walls attenuate hearing; they never turn a sound into visual confirmation.
static func emit_at(source: Node3D, origin: Vector3, radius: float, kind: StringName) -> void:
	if not is_instance_valid(source) or not source.is_inside_tree() or source.get_tree().paused: return
	if kind == &"footstep" and source is PlayerController:
		AudioDirector.play_movement(.25 if radius <= 3.0 else .6)
	var world := source.get_world_3d().direct_space_state
	for node in source.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyController
		if not enemy or enemy.is_dead or not enemy.is_physics_processing(): continue
		var distance := enemy.global_position.distance_to(origin)
		if distance > radius: continue
		var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.8, enemy.global_position + Vector3.UP * 1.4, 4)
		var audible_range := radius if world.intersect_ray(query).is_empty() else radius * 0.45
		if distance <= audible_range: enemy.hear_noise(origin, kind)

static func weapon_radius(id: StringName) -> float:
	match id:
		&"weapon.pistol_01": return 28.0
		&"weapon.smg_01": return 32.0
		&"weapon.assault_rifle_01": return 40.0
		&"weapon.shotgun_01": return 45.0
		&"weapon.lmg_01": return 50.0
	return 60.0
