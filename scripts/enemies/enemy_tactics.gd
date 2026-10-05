class_name EnemyTactics
extends RefCounted
## Decisions use observed/remembered contact only. No live player reference.
enum Role { PATROL, GUARD, FLANKER, PRESSURE }
const GUARD_RADIUS := 6.0
const PRESSURE_DISTANCE := 4.5
var role: int = Role.PATROL
var has_plan := false
var goal := Vector3.ZERO
var planned_contact := Vector3.ZERO
var plan_remaining := 0.0

func current_destination(enemy: Node3D) -> Vector3:
	var awareness: EnemyAwareness = enemy.awareness
	var normal := awareness.destination(enemy.patrol_radius)
	if role == Role.GUARD:
		# Defend the post; a distant sound must not pull guards across the map.
		if awareness.state == EnemyAwareness.State.COMBAT: return awareness.home
		var offset := normal - awareness.home
		offset.y = 0
		return awareness.home + offset.limit_length(GUARD_RADIUS)
	if awareness.state != EnemyAwareness.State.COMBAT: return normal
	var contact := awareness.last_known
	var away: Vector3 = enemy.global_position - contact
	away.y = 0
	if away.is_zero_approx(): away = -awareness.home_forward
	if role == Role.PRESSURE:
		# Close the gap, then stop short; no extra speed, health or damage.
		return contact + away.normalized() * PRESSURE_DISTANCE
	return goal if role == Role.FLANKER and has_plan else normal

func destination(enemy: Node3D, delta: float) -> Vector3:
	if role != Role.FLANKER: return current_destination(enemy)
	if enemy.awareness.state != EnemyAwareness.State.COMBAT:
		has_plan = false
		plan_remaining = 0
		return current_destination(enemy)
	plan_remaining = maxf(0, plan_remaining - delta)
	var contact: Vector3 = enemy.awareness.last_known
	var away: Vector3 = enemy.global_position - contact
	away.y = 0
	if away.is_zero_approx(): away = -enemy.awareness.home_forward
	if has_plan and plan_remaining > 0 and planned_contact.distance_to(contact) < 3:
		return goal
	planned_contact = contact
	plan_remaining = 4.0
	# Stable side preference from the existing saved strafe sign. Try the other
	# side if blocked. Reject closed doors, occupied cover and disconnected nav.
	var radius := minf(enemy.preferred_distance, 9.0)
	for side in [enemy._strafe_direction, -enemy._strafe_direction]:
		for angle in [55.0, 30.0]:
			var candidate := contact + away.normalized().rotated(Vector3.UP, deg_to_rad(angle) * side) * radius
			var reachable := reachable_flank(enemy, candidate, contact)
			if not reachable.is_empty():
				goal = reachable[0]
				has_plan = true
				return goal
	# No legal route is better than walking through a closed door or fabricating
	# a flank. The ordinary visible-target attack still works from this position.
	goal = enemy.global_position
	has_plan = true
	return goal

static func reachable_flank(enemy: Node3D, candidate: Vector3, contact: Vector3) -> PackedVector3Array:
	var map: RID = enemy.navigation_agent.get_navigation_map()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0: return []
	var point := NavigationServer3D.map_get_closest_point(map, candidate)
	if point.distance_to(candidate) > .8: return []
	var path := NavigationServer3D.map_get_path(map, enemy.global_position, point, true)
	if path.is_empty() or path[-1].distance_to(point) > .3: return []
	var space := enemy.get_world_3d().direct_space_state
	var sight := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.5, contact + Vector3.UP * 1.05, 4)
	if not space.intersect_ray(sight).is_empty(): return []
	var shape := CapsuleShape3D.new()
	shape.radius = .52
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 4
	var length := 0.0
	for index in path.size():
		query.transform.origin = path[index] + Vector3.UP * 1.05
		query.motion = Vector3.ZERO
		if not space.intersect_shape(query, 1).is_empty(): return []
		if index + 1 < path.size():
			query.motion = path[index + 1] - path[index]
			length += query.motion.length()
			if space.cast_motion(query)[0] < .999: return []
	if length > enemy.global_position.distance_to(point) * 2.5 + 2.0: return []
	return PackedVector3Array([point])

func alert_text() -> String:
	match role:
		Role.GUARD: return "GUARD !"
		Role.FLANKER: return "FLANK !"
		Role.PRESSURE: return "PUSH !"
	return "!"
