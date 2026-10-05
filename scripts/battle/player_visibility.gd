class_name PlayerVisibility
extends Node
## Player information, separate from camera occluder fading and enemy AI.
## Environment geometry stays readable; unobserved actors and their markers do not.
const VIEW_RANGE := 32.0
const VIEW_ANGLE := 160.0
const NEAR_RANGE := 4.0
var actor: Node3D
var heard_direction := Vector3.ZERO
var heard_kind := &""
var heard_remaining := 0.0
var _motion := {}

func _ready() -> void:
	add_to_group("player_visibility")
	process_physics_priority = 20 # Observe after player aim/movement, never drive it.

func sight_range() -> float:
	var extension: float = actor.weapon_data.aim_camera_extension if actor.weapon_data and Input.is_action_pressed("precision_walk") else 0.0
	return VIEW_RANGE + extension

func in_view(point: Vector3) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree(): return false
	var gap := point - actor.global_position
	gap.y = 0
	if gap.length() > sight_range(): return false
	return gap.length() <= NEAR_RANGE or actor.aim_direction.dot(gap.normalized()) >= cos(deg_to_rad(VIEW_ANGLE * .5))

func can_see_point(point: Vector3) -> bool:
	if not in_view(point): return false
	var eye := actor.global_position + Vector3.UP * 1.55
	var query := PhysicsRayQueryParameters3D.create(eye, point, 4)
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	# A point on the visible wall surface is visible; a point BEHIND it is not.
	return hit.is_empty() or hit.position.distance_to(point) <= .08

func can_see_enemy(enemy: Node3D) -> bool:
	if not enemy.visible or not in_view(enemy.global_position): return false
	for offset in [Vector3(0, 1.75, 0), Vector3(0, 1.1, 0), Vector3(.3, 1.1, 0), Vector3(-.3, 1.1, 0)]:
		if can_see_point(enemy.global_position + offset): return true
	return false

func track_enemy(enemy: Node3D) -> void:
	# Hidden until the first physics visibility query, including newly restored
	# actors. Never hide the gameplay root or change its collision/process state.
	enemy.presentation.hide()
	enemy.awareness_indicator.hide()

func refresh() -> void:
	if not is_instance_valid(actor) or not actor.is_inside_tree(): return
	var alive := {}
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_dead: continue
		alive[enemy] = true
		var seen := can_see_enemy(enemy)
		enemy.presentation.visible = seen
		enemy.awareness_indicator.visible = seen
		var previous: Dictionary = _motion.get(enemy, {"at": enemy.global_position, "distance": 0.0})
		var gap: Vector3 = enemy.global_position - previous.at
		gap.y = 0
		var distance: float = previous.distance + minf(gap.length(), 1.4)
		if distance >= 1.4 and enemy.is_physics_processing() and enemy.visible:
			var gain := hear(enemy.global_position, 12.0, &"movement")
			if gain > 0:
				var gap_to_sound: Vector3 = enemy.global_position - actor.global_position
				var angle := roundf(atan2(gap_to_sound.x,gap_to_sound.z)/(PI/4.0))*(PI/4.0)
				var bearing := Vector3(sin(angle),0,cos(angle))
				var camera := actor.get_viewport().get_camera_3d()
				var pan := bearing.dot(camera.global_basis.x) if camera else bearing.x
				AudioDirector.play_movement(gain,pan,not enemy.humanoid_presentation)
			distance = 0.0
		_motion[enemy] = {"at": enemy.global_position, "distance": distance}
	for enemy in _motion.keys():
		if not alive.has(enemy): _motion.erase(enemy)
	for body in get_tree().get_nodes_in_group("sight_sensitive"):
		body.visible = can_see_point(body.global_position + Vector3.UP * float(body.get_meta("sight_height", 0.5)))

func _physics_process(delta: float) -> void:
	heard_remaining = maxf(0.0, heard_remaining - delta)
	refresh()

func hear(origin: Vector3, radius: float, kind: StringName) -> float:
	if not is_instance_valid(actor) or actor.is_dead: return 0.0
	var gap := origin - actor.global_position
	var distance := gap.length()
	if distance > radius: return 0.0
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 1.55, origin + Vector3.UP * 0.8, 4)
	var audible := radius if actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty() else radius * .45
	if distance > audible: return 0.0
	# Coarse event bearing only: no actor reference, range or continuously tracked
	# world position is exposed to the HUD. Footsteps do not overwrite gunfire.
	if kind != &"movement" or heard_remaining <= 0.0 or heard_kind == &"movement":
		var angle := roundf(atan2(gap.x, gap.z) / (PI / 4.0)) * PI / 4.0
		heard_direction = Vector3(sin(angle), 0, cos(angle))
		heard_kind = kind
		heard_remaining = 1.5
	return clampf(1.0 - distance / audible, .08, 1.0)

func aim_trace() -> Dictionary:
	var muzzle: Vector3 = actor.combat_rig.get_muzzle_position() if actor.combat_rig and actor.combat_rig.has_weapon() else actor.global_position + Vector3.UP * 1.25 + actor.aim_direction * .55
	var origin: Vector3 = actor.effective_fire_origin(muzzle)
	var direction: Vector3 = actor._shot_direction_from(origin)
	var reach: float = actor.weapon_data.weapon_range if actor.weapon_data else 30.0
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * reach, 6)
	query.exclude = [actor.get_rid()]
	query.hit_from_inside = true
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	var desired_distance := minf(origin.distance_to(actor.aim_world_point), reach)
	var point := origin + direction * desired_distance
	var blocked := origin.distance_to(muzzle) > .005
	if not hit.is_empty():
		# A hidden collider must not turn the crosshair red or give a precise dot.
		if hit.collider is EnemyController and not can_see_enemy(hit.collider):
			return {"blocked": blocked, "point": point}
		point = hit.position
		blocked = blocked or (not hit.collider is EnemyController and origin.distance_to(point) < desired_distance - .25)
	return {"blocked": blocked, "point": point}

static func observer(context: Node) -> PlayerVisibility:
	if not is_instance_valid(context) or not context.is_inside_tree(): return null
	return context.get_tree().get_first_node_in_group("player_visibility") as PlayerVisibility

static func point_visible(context: Node, point: Vector3) -> bool:
	var sensor := observer(context)
	return not sensor or sensor.can_see_point(point)

static func enemy_observed(context: Node, enemy: Node3D) -> bool:
	var sensor := observer(context)
	return not sensor or sensor.can_see_enemy(enemy)

static func visible_segment(context: Node, from: Vector3, to: Vector3) -> PackedVector3Array:
	var sensor := observer(context)
	if not sensor: return PackedVector3Array([from, to])
	# Render the last contiguous visible section, not a line back to an unseen
	# attacker. This changes VFX only; the actual ray still hits the same collider.
	var result := PackedVector3Array()
	for i in range(12, -1, -1):
		var point := from.lerp(to, float(i) / 12.0)
		if sensor.can_see_point(point):
			if result.is_empty(): result.append(point)
			if result.size() == 1: result.append(point)
			else: result[1] = point
		elif not result.is_empty(): break
	if result.size() == 2: return PackedVector3Array([result[1], result[0]])
	return result
