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
var target: PlayerController
var navigation_agent: NavigationAgent3D
var body_visual: Node3D
var humanoid_visual: HumanoidRetargetVisual
var is_dead := false
var _shot_cooldown := 0.7
var _path_refresh := 0.0
var _knockback_velocity := Vector3.ZERO
var _strafe_direction := 1.0
var _hit_tween: Tween
var _is_telegraphing := false
var _engaged := false
var _movement_direction := Vector3.ZERO
var _shot_aim_point := Vector3.ZERO


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
	return true


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	_build_collision()
	_build_visual()
	_build_navigation()
	_strafe_direction = -1.0 if randi() % 2 == 0 else 1.0
	_shot_cooldown = randf_range(0.9, 2.4)
	call_deferred("_find_target")


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target) or target.is_dead:
		_movement_direction = Vector3.ZERO
		_update_humanoid_visual(delta, global_position - global_basis.z * 8.0, 0.0)
		return
	var offset := target.global_position - global_position
	var flat_offset := Vector3(offset.x, 0.0, offset.z)
	_path_refresh -= delta
	if _path_refresh <= 0.0:
		navigation_agent.target_position = target.global_position
		_path_refresh = 0.35 if _engaged else 0.65
	if not _engaged:
		if flat_offset.length() <= detection_range:
			_engaged = true
		else:
			var approach_direction := _navigation_direction(flat_offset)
			_movement_direction = approach_direction
			var approach_velocity := approach_direction * approach_speed
			var approach_horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(approach_velocity, 7.0 * delta)
			velocity.x = approach_horizontal.x
			velocity.z = approach_horizontal.z
			velocity.y = -0.1 if is_on_floor() else velocity.y - 24.0 * delta
			move_and_slide()
			_face_direction(_movement_direction, delta)
			_update_humanoid_visual(delta, target.global_position + Vector3.UP * 1.05, approach_horizontal.length())
			return
	_shot_cooldown -= delta

	var distance := flat_offset.length()
	var desired := Vector3.ZERO
	if distance > preferred_distance + 1.2:
		desired = _navigation_direction(flat_offset)
	elif distance < preferred_distance - 2.0:
		desired = -flat_offset.normalized()
	else:
		desired = Vector3(-flat_offset.z, 0.0, flat_offset.x).normalized() * _strafe_direction * 0.45
	_movement_direction = desired

	var target_velocity := desired * movement_speed + _knockback_velocity
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, 13.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 9.0 * delta)
	velocity.y = -0.1 if is_on_floor() else velocity.y - 24.0 * delta
	move_and_slide()
	_face_direction(desired if desired.length_squared() > 0.01 else flat_offset, delta)
	var visual_aim_point := _shot_aim_point if _is_telegraphing else target.global_position + Vector3.UP * 1.05
	_update_humanoid_visual(delta, visual_aim_point, desired.length() * movement_speed)
	if distance <= attack_range and _shot_cooldown <= 0.0 and not _is_telegraphing:
		_telegraph_shot()


func receive_damage(packet: DamagePacket) -> float:
	if is_dead:
		return 0.0
	var applied_damage := maxf(packet.base_damage - maxf(armor - packet.armor_penetration, 0.0), 0.0)
	health = maxf(health - applied_damage, 0.0)
	_knockback_velocity += packet.knockback_impulse
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
	navigation_agent.radius = 0.45
	navigation_agent.height = 1.8
	navigation_agent.avoidance_enabled = true
	add_child(navigation_agent)


func _build_visual() -> void:
	humanoid_visual = HumanoidRetargetVisual.new()
	humanoid_visual.name = "EnemyCharacterVisual"
	humanoid_visual.scale = BASE_VISUAL_SCALE
	body_visual = humanoid_visual
	add_child(humanoid_visual)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.42
	ring_mesh.outer_radius = 0.5
	var marker := MeshInstance3D.new()
	marker.name = "EnemyMarker"
	marker.mesh = ring_mesh
	marker.position.y = 0.045
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.material_override = VisualFactory.material(Color("d63d55"), 0.1, 0.18, Color("ff3657"), 3.2)
	humanoid_visual.add_child(marker)


func _face_direction(direction: Vector3, delta: float) -> void:
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() < 0.01:
		return
	var target_yaw := atan2(-flat_direction.x, -flat_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-12.0 * delta))


func _update_humanoid_visual(delta: float, aim_point: Vector3, locomotion_speed: float) -> void:
	if not humanoid_visual:
		return
	humanoid_visual.update_visual(aim_point, _movement_direction, locomotion_speed, delta)


func _flash_hit(knockback_impulse: Vector3) -> void:
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	var flash_material := VisualFactory.material(Color("fff8dd"), 0.0, 0.05, Color("ffb45c"), 4.5)
	for node in body_visual.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = flash_material
	body_visual.scale = Vector3(1.19, 1.03, 1.19)
	var reaction_side := signf(knockback_impulse.x + 0.01)
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
	if target:
		navigation_agent.target_position = target.global_position


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
	var from := humanoid_visual.get_muzzle_position()
	CombatEffects.telegraph(get_tree().current_scene, from, _shot_aim_point)
	await get_tree().create_timer(0.38).timeout
	if is_dead or not is_instance_valid(target) or target.is_dead:
		_is_telegraphing = false
		_shot_aim_point = Vector3.ZERO
		return
	from = humanoid_visual.get_muzzle_position()
	var shot_direction := humanoid_visual.get_muzzle_direction()
	var ray_length := maxf(from.distance_to(_shot_aim_point) + 2.0, 16.0)
	var ray_end := from + shot_direction * ray_length
	var query := PhysicsRayQueryParameters3D.create(from, ray_end, 5)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var hit_position: Vector3 = result.position if not result.is_empty() else ray_end
	humanoid_visual.fire_recoil()
	AudioDirector.play_sfx(&"enemy_fire", -1.0, 0.045)
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
	var ragdoll := RAGDOLL_SCENE.instantiate() as RagdollProxy
	get_parent().add_child(ragdoll)
	ragdoll.global_position = global_position
	ragdoll.rotation.y = rotation.y
	ragdoll.build(Color("a53d4f"), impact + Vector3.UP * 1.8)
	died.emit(self)
	queue_free()
