extends EnemyController

func _movement_goal(_delta: float) -> Vector3:
	return awareness.destination(patrol_radius) if awareness.state != EnemyAwareness.State.COMBAT else awareness.last_known

func _create_presentation() -> Node3D:
	var visual := preload("res://scripts/presentation/infected_presentation.gd").new()
	visual.profile = presentation_profile
	return visual

func receive_damage(packet: DamagePacket) -> float:
	var applied := super.receive_damage(packet)
	if applied > 0 and not is_dead: presentation.play_hit()
	return applied

func _build_visual() -> void:
	super._build_visual()
	presentation.get_node("EnemyMarker").material_override = VisualFactory.material(Color("9fba68"), 0, .1, Color("9fba68"), 1.2)

func _update_awareness_indicator() -> void:
	awareness_indicator.text = "!" if _engaged else ("?" if awareness.state in [EnemyAwareness.State.INVESTIGATE, EnemyAwareness.State.SEARCH] else "")
	awareness_indicator.modulate = Color("c7d580")

func _telegraph_shot() -> void:
	_is_telegraphing = true
	_shot_cooldown = attack_cooldown_min
	_shot_aim_point = target.global_position + Vector3.UP
	presentation.fire_recoil()
	_finish_telegraphed_shot(0.38)

func _finish_telegraphed_shot(remaining: float) -> void:
	_shot_timer = get_tree().create_timer(remaining, false)
	await _shot_timer.timeout
	_shot_timer = null
	# A wind-up is avoidable: moving away or behind a wall cancels the hit.
	if is_inside_tree() and can_process() and not is_dead and can_see_target() and global_position.distance_to(target.global_position) <= attack_range:
		target.receive_damage(DamagePacket.new(attack_damage, 0, 0, self, &"enemy.infected_melee", &"enemy", target.global_position, Vector3.UP, global_position.direction_to(target.global_position) * 0.3))
	_is_telegraphing = false
	_shot_aim_point = Vector3.ZERO
