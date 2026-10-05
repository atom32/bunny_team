class_name EnemyController
extends CharacterBody3D

signal died(enemy: EnemyController)

const RAGDOLL_SCENE := preload("res://scenes/player/ragdoll_proxy.tscn")
const BASE_VISUAL_SCALE := Vector3.ONE * 1.1

var max_health := 60.0
var health := 60.0
var armor := 0.0
var movement_speed := 3.2
var approach_speed := 1.15
var attack_damage := 3.2
var attack_range := 15.0
var attack_cooldown_min := 1.9
var attack_cooldown_max := 2.6
var definition_id: StringName
var preferred_distance := 8.5
var detection_range := 24.0
var view_angle := 110.0
var acquire_seconds := 0.35
var search_duration := 12.0
var patrol_radius := 3.0
var awareness := EnemyAwareness.new()
var tactics := EnemyTactics.new()
var awareness_indicator: Label3D
var target: PlayerController
var navigation_agent: NavigationAgent3D
var body_visual: Node3D
var presentation
var humanoid_presentation := false
var is_dead := false
var _shot_cooldown := 0.7
var _path_refresh := 0.0
var _knockback_velocity := Vector3.ZERO
var _strafe_direction := 1.0
var _hit_tween: Tween
var _hit_reaction_side := 1.0
var _is_telegraphing := false
var _engaged := false
var _movement_direction := Vector3.ZERO
var _shot_aim_point := Vector3.ZERO
var _shot_timer: SceneTreeTimer


func configure_from_definition(definition: EnemyDefinition) -> bool:
	if not definition or not definition.validate_definition():
		return false
	definition_id = definition.id
	max_health = definition.max_health
	health = max_health
	armor = definition.armor
	movement_speed = definition.move_speed
	approach_speed = definition.approach_speed
	attack_damage = definition.attack_damage
	attack_range = definition.attack_range
	attack_cooldown_min = definition.attack_cooldown_min
	attack_cooldown_max = definition.attack_cooldown_max
	humanoid_presentation = definition.humanoid_presentation
	detection_range = definition.detection_range
	view_angle = definition.view_angle
	acquire_seconds = definition.acquire_seconds
	search_duration = definition.search_duration
	patrol_radius = definition.patrol_radius
	tactics.role = definition.tactical_role
	return true


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	_build_collision()
	_build_visual()
	_build_navigation()
	awareness_indicator = Label3D.new()
	awareness_indicator.name = "AwarenessIndicator"
	awareness_indicator.position.y = 2.8
	awareness_indicator.font_size = 48
	awareness_indicator.pixel_size = 0.008
	awareness_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(awareness_indicator)
	_strafe_direction = -1.0 if randi() % 2 == 0 else 1.0
	_shot_cooldown = randf_range(0.9, 2.4)
	call_deferred("_find_target")


func _physics_process(delta: float) -> void:
	if is_dead: return
	ensure_awareness()
	var seen := can_see_target()
	# The target position is an observation ONLY when the visibility query passes.
	awareness.update(seen, target.global_position if seen else Vector3.ZERO, global_position, delta, acquire_seconds, search_duration, patrol_radius)
	_engaged = awareness.state == EnemyAwareness.State.COMBAT
	var goal := tactics.destination(self, delta)
	var flat_offset := goal - global_position
	flat_offset.y = 0.0
	_path_refresh -= delta
	navigation_agent.target_desired_distance = preferred_distance if _engaged and tactics.role == EnemyTactics.Role.PATROL else 0.65
	if _path_refresh <= 0.0 or navigation_agent.target_position.distance_to(goal) > 1.0:
		navigation_agent.target_position = goal
		_path_refresh = 0.35 if _engaged else 0.65
	_shot_cooldown -= delta
	var distance := flat_offset.length()
	var desired := Vector3.ZERO
	if _engaged and tactics.role == EnemyTactics.Role.PATROL:
		if distance > preferred_distance + 1.2:
			desired = _navigation_direction(flat_offset)
		elif distance < preferred_distance - 2.0:
			desired = -flat_offset.normalized()
		else:
			desired = Vector3(-flat_offset.z, 0.0, flat_offset.x).normalized() * _strafe_direction * 0.45
	elif distance > 0.7:
		desired = _navigation_direction(flat_offset)
	_movement_direction = desired
	var speed := movement_speed if awareness.state in [EnemyAwareness.State.COMBAT, EnemyAwareness.State.INVESTIGATE] else approach_speed
	var target_velocity := desired * speed + _knockback_velocity
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, 13.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 9.0 * delta)
	velocity.y = -0.1 if is_on_floor() else velocity.y - 24.0 * delta
	navigation_agent.velocity = velocity
	var aim := awareness.aim_point(global_position)
	_face_direction(aim - global_position if awareness.state in [EnemyAwareness.State.COMBAT, EnemyAwareness.State.INVESTIGATE, EnemyAwareness.State.SEARCH] else desired, delta)
	_update_presentation(delta, _shot_aim_point if _is_telegraphing else aim, horizontal.length())
	_update_awareness_indicator()
	# Firing range is measured to the observed contact, never to a flank waypoint.
	var contact_distance := Vector2(awareness.last_known.x - global_position.x, awareness.last_known.z - global_position.z).length()
	if _engaged and seen and contact_distance <= attack_range and _shot_cooldown <= 0.0 and not _is_telegraphing:
		_telegraph_shot()


func ensure_awareness() -> void:
	# Spawn service assigns the world transform AFTER add_child; never capture
	# home in _ready. This also leaves restored knowledge intact.
	awareness.initialize(global_position, -global_basis.z)


func can_see_target() -> bool:
	if not is_instance_valid(target) or not target.is_inside_tree() or target.is_dead: return false
	var offset := target.global_position - global_position
	var flat := Vector3(offset.x, 0, offset.z)
	if flat.length() > detection_range: return false
	if flat.length() > 2.0 and (-global_basis.z).dot(flat.normalized()) < cos(deg_to_rad(view_angle * 0.5)): return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, target.global_position + Vector3.UP * 1.05, 5)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == target


func hear_noise(origin: Vector3, _kind: StringName) -> void:
	if is_dead or not is_physics_processing(): return
	ensure_awareness()
	awareness.hear(origin, search_duration)
	_path_refresh = 0.0


func _update_awareness_indicator() -> void:
	var alert := awareness.state == EnemyAwareness.State.COMBAT
	awareness_indicator.text = tr(tactics.alert_text()) if alert else ("?" if awareness.state in [EnemyAwareness.State.INVESTIGATE, EnemyAwareness.State.SEARCH] else "")
	awareness_indicator.modulate = Color("ff6d64") if alert else Color("ffd581")


func receive_damage(packet: DamagePacket) -> float:
	if is_dead:
		return 0.0
	var applied_damage := maxf(packet.base_damage - maxf(armor - packet.armor_penetration, 0.0), 0.0)
	health = maxf(health - applied_damage, 0.0)
	_knockback_velocity += packet.knockback_impulse
	if applied_damage > 0 and packet.knockback_impulse.length_squared() > 0.001:
		# Infer incoming fire direction, not the shooter's live/hidden position.
		hear_noise(global_position - packet.knockback_impulse.normalized() * 5.0, &"impact")
	CombatEffects.hit(get_tree().current_scene, global_position + Vector3.UP * 1.25, Color("fff1cf"), clampf(applied_damage / 18.0, 0.65, 1.35))
	_flash_hit(packet.knockback_impulse)
	if health <= 0.0:
		_die(packet.knockback_impulse)
	return applied_damage


func take_damage(amount: float, knockback_impulse: Vector3 = Vector3.ZERO) -> void:
	# Compatibility entry point for existing debug helpers; gameplay attacks deliver DamagePacket.
	receive_damage(DamagePacket.new(amount, 0.0, 0.0, null, &"debug.scalar", &"", global_position, Vector3.ZERO, knockback_impulse))


func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)


func _build_navigation() -> void:
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.name = "NavigationAgent3D"
	navigation_agent.path_desired_distance = 0.45
	navigation_agent.target_desired_distance = preferred_distance
	navigation_agent.radius = 0.55
	navigation_agent.height = 1.8
	navigation_agent.avoidance_enabled = true
	navigation_agent.velocity_computed.connect(_on_safe_velocity)
	add_child(navigation_agent)


func _on_safe_velocity(safe_velocity: Vector3) -> void:
	# The existing RVO agent must receive AND apply velocity; enabling it alone
	# leaves every pursuer on the same path. Keep AI decisions and gravity intact.
	if not is_physics_processing() or is_dead or not is_instance_valid(target) or target.is_dead:
		return
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()


func _build_visual() -> void:
	presentation = HumanoidEnemyPresentation.new() if humanoid_presentation else KiteEnemyPresentation.new()
	presentation.name = "EnemyPresentation"
	presentation.scale = BASE_VISUAL_SCALE
	body_visual = presentation
	add_child(presentation)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.42
	ring_mesh.outer_radius = 0.5
	var marker := MeshInstance3D.new()
	marker.name = "EnemyMarker"
	marker.mesh = ring_mesh
	marker.position.y = 0.045
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.material_override = VisualFactory.material(Color("d63d55"), 0.1, 0.18, Color("ff3657"), 3.2)
	presentation.add_child(marker)


func _face_direction(direction: Vector3, delta: float) -> void:
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() < 0.01:
		return
	var target_yaw := atan2(-flat_direction.x, -flat_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-12.0 * delta))


func _update_presentation(delta: float, aim_point: Vector3, locomotion_speed: float) -> void:
	if not presentation:
		return
	presentation.update_visual(aim_point, _movement_direction, locomotion_speed, delta)


func _flash_hit(knockback_impulse: Vector3) -> void:
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	var flash_material := VisualFactory.material(Color("fff8dd"), 0.0, 0.05, Color("ffb45c"), 4.5)
	for node in body_visual.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = flash_material
	body_visual.scale = Vector3(1.19, 1.03, 1.19)
	var reaction_side := signf(knockback_impulse.x + 0.01)
	_hit_reaction_side = reaction_side
	body_visual.rotation.z = -0.16 * reaction_side
	_hit_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(body_visual, "scale", BASE_VISUAL_SCALE, 0.14)
	_hit_tween.tween_property(body_visual, "rotation:z", 0.0, 0.14)
	_hit_tween.chain().tween_callback(_clear_hit_flash)


func _clear_hit_flash() -> void:
	if not is_instance_valid(body_visual):
		return
	for node in body_visual.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = null


func _find_target() -> void:
	target = get_tree().get_first_node_in_group("player") as PlayerController
	ensure_awareness()
	navigation_agent.target_position = tactics.current_destination(self)


func _navigation_direction(fallback_offset: Vector3) -> Vector3:
	var map_rid := navigation_agent.get_navigation_map()
	if map_rid.is_valid() and NavigationServer3D.map_get_iteration_id(map_rid) > 0 and not navigation_agent.is_navigation_finished():
		var next_point := navigation_agent.get_next_path_position()
		var path_direction := global_position.direction_to(next_point)
		path_direction.y = 0.0
		if path_direction.length_squared() > 0.01:
			return path_direction.normalized()
	return fallback_offset.normalized()


func _telegraph_shot() -> void:
	_is_telegraphing = true
	_shot_cooldown = randf_range(attack_cooldown_min, attack_cooldown_max)
	_shot_aim_point = target.global_position + Vector3.UP * 1.05
	var from: Vector3 = presentation.get_muzzle_position()
	CombatEffects.telegraph(get_tree().current_scene, from, _shot_aim_point)
	_finish_telegraphed_shot(0.38)


func _finish_telegraphed_shot(remaining: float) -> void:
	# The resumable timer retains the existing attack delay and locked aim point.
	_shot_timer = get_tree().create_timer(remaining, false)
	await _shot_timer.timeout
	_shot_timer = null
	if not is_inside_tree() or not can_process() or is_dead or not is_instance_valid(target) or not target.is_inside_tree() or target.is_dead:
		_is_telegraphing = false
		_shot_aim_point = Vector3.ZERO
		return
	var from: Vector3 = presentation.get_muzzle_position()
	var shot_direction: Vector3 = presentation.get_muzzle_direction()
	var ray_length := maxf(from.distance_to(_shot_aim_point) + 2.0, 16.0)
	var ray_end := from + shot_direction * ray_length
	var query := PhysicsRayQueryParameters3D.create(from, ray_end, 5)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var hit_position: Vector3 = result.position if not result.is_empty() else ray_end
	presentation.fire_recoil()
	var observer := PlayerVisibility.observer(self)
	var audibility := observer.hear(global_position, 40.0, &"gunfire") if observer else 1.0
	if audibility > 0.0:
		AudioDirector.play_sfx(&"enemy_fire", -1.0 + linear_to_db(audibility), 0.045)
	CombatEffects.muzzle_flash(get_tree().current_scene, from, shot_direction, Color("ff3658"), 0.68)
	CombatEffects.tracer(get_tree().current_scene, from, hit_position, Color("ff3658"), 0.052)
	if not result.is_empty() and result.collider == target and target.has_method("receive_damage"):
		var packet := DamagePacket.new(
			attack_damage,
			0.0,
			0.0,
			self,
			&"enemy.prototype_rifle",
			&"enemy",
			hit_position,
			result.normal,
			global_position.direction_to(target.global_position) * 0.3
		)
		target.receive_damage(packet)
	_is_telegraphing = false
	_shot_aim_point = Vector3.ZERO


func _die(impact: Vector3) -> void:
	is_dead = true
	CombatEffects.hit(get_tree().current_scene, global_position + Vector3.UP * 1.15, Color("ff6b55"), 1.65)
	if humanoid_presentation:
		if _hit_tween and _hit_tween.is_valid():
			_hit_tween.kill()
		_clear_hit_flash()
		presentation.scale = BASE_VISUAL_SCALE
		presentation.rotation.z = 0
		presentation.reparent(get_parent(), true)
		presentation.add_to_group("sight_sensitive")
		presentation.set_meta("sight_height", 1.0)
		presentation.play_death(impact)
	else:
		var ragdoll := RAGDOLL_SCENE.instantiate() as RagdollProxy
		get_parent().add_child(ragdoll)
		ragdoll.global_position = global_position
		ragdoll.rotation.y = rotation.y
		ragdoll.build(Color("a53d4f"), impact + Vector3.UP * 1.8)
		for part in ragdoll.get_children():
			if part is Node3D:
				part.add_to_group("sight_sensitive")
				part.set_meta("sight_height", 0.0)
				part.visible = PlayerVisibility.point_visible(self, part.global_position)
	died.emit(self)
	queue_free()
