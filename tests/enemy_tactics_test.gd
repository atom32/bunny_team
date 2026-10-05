extends Node3D
var checks := 0
var failures: Array[String] = []
var player: PlayerController
var enemy: EnemyController
const R := EnemyTactics.Role

func _ready() -> void:
	await get_tree().process_frame
	_box(Vector3(0, -.2, 0), Vector3(100, .4, 100))
	_navigation(Vector3.ZERO, 44)
	_navigation(Vector3(100, 0, 0), 4)
	player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.position = Vector3(0, 0, -12)
	_spawn(R.PATROL)
	enemy.set_physics_process(false)
	await _sync()
	_test_roles()
	await _test_planning()
	_test_save()
	await _test_live_roles()
	enemy.free()
	player.free()
	await _test_production_assignment()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("TACTICS: " + failure)
	print("ENEMY_TACTICS_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _spawn(role: int) -> void:
	enemy = EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_basic_enemy"), Transform3D.IDENTITY, self)
	enemy.tactics.role = role
	enemy._strafe_direction = 1
	enemy.target = player
	enemy.ensure_awareness()

func _contact(at := Vector3(0, 0, -12)) -> void:
	enemy.awareness.state = EnemyAwareness.State.COMBAT
	enemy.awareness.target_visible = true
	enemy.awareness.suspicion = 1
	enemy.awareness.last_known = at
	enemy.awareness.memory_remaining = enemy.search_duration
	enemy.awareness.search_elapsed = 0

func _test_roles() -> void:
	var definition := ContentDB.get_enemy_definition(&"prototype_basic_enemy").duplicate() as EnemyDefinition
	for role in [R.PATROL, R.GUARD, R.FLANKER, R.PRESSURE]:
		definition.tactical_role = role
		check(definition.validate_definition(), "definition accepts authored role " + str(role))
	for role in [-1, 4]:
		definition.tactical_role = role
		check(not definition.validate_definition(), "invalid role definition rejected")
	check(ContentDB.get_enemy_definition(&"prototype_heavy_enemy").tactical_role == R.PRESSURE, "production heavy drone closes distance instead of copying patrol strafe")
	_contact()
	check(enemy.tactics.destination(enemy, .1) == enemy.awareness.last_known, "patrol retains original combat target convention")
	enemy.tactics.role = R.GUARD
	check(enemy.tactics.destination(enemy, .1) == enemy.awareness.home, "engaged guard holds post, not player position")
	enemy.awareness.hear(Vector3(0, 0, -40), 12) # Confirmed visible sight wins.
	check(enemy.awareness.last_known == Vector3(0, 0, -12), "role does not override existing knowledge priority")
	enemy.awareness.target_visible = false
	enemy.awareness.hear(Vector3(0, 0, -40), 12)
	check(is_equal_approx(enemy.tactics.destination(enemy, .1).distance_to(enemy.awareness.home), 6.0), "guard sound investigation stays within six-metre post radius")
	enemy.awareness.state = EnemyAwareness.State.SEARCH
	enemy.awareness.search_elapsed = 6
	check(enemy.tactics.destination(enemy, .1).distance_to(enemy.awareness.home) <= 6.001, "guard search is leashed too")
	enemy.awareness.state = EnemyAwareness.State.RETURN
	check(enemy.tactics.destination(enemy, .1) == enemy.awareness.home, "guard returns home through existing disengagement state")
	enemy.tactics.role = R.PRESSURE
	_contact()
	var pushed := enemy.tactics.destination(enemy, .1)
	check(pushed.z < -7 and is_equal_approx(pushed.distance_to(enemy.awareness.last_known), 4.5), "pressure advances to close standoff rather than orbiting at patrol distance")
	player.position = Vector3(20, 0, -20)
	check(enemy.tactics.destination(enemy, .1) == pushed, "movement plan never reads unobserved live player coordinates")
	player.position = Vector3(0, 0, -12)
	check(enemy.attack_damage == definition.attack_damage and enemy.movement_speed == definition.move_speed and enemy.attack_range == definition.attack_range, "roles do not buff damage/speed/range")

func _test_planning() -> void:
	var map := enemy.navigation_agent.get_navigation_map()
	var probe := Vector3(6, 0, -7)
	# The map can already have an empty first iteration while newly added
	# regions are still syncing. Wait for our actual floor, not merely an ID.
	for tick in 120:
		if NavigationServer3D.map_get_iteration_id(map) > 0 and NavigationServer3D.map_get_closest_point(map, probe).distance_to(probe) < .01: break
		await get_tree().physics_frame
	check(NavigationServer3D.map_get_iteration_id(map) > 0 and NavigationServer3D.map_get_closest_point(map, probe).distance_to(probe) < .01, "fixture navigation region synchronized before path planning")
	enemy.tactics.role = R.FLANKER
	_contact()
	var goal := enemy.tactics.destination(enemy, 0)
	check(enemy.tactics.has_plan and goal.x > 3 and goal.z < -3, "flanker selects a real lateral firing position")
	check(not EnemyTactics.reachable_flank(enemy, goal, enemy.awareness.last_known).is_empty(), "chosen position has nav path, body clearance and firing sightline")
	check(enemy.tactics.destination(enemy, 1) == goal and enemy.tactics.plan_remaining == 3, "flank destination stays stable while moving, not per-frame oscillation")
	var before := SortieCheckpoint.fields(enemy.tactics, SortieCheckpoint.TACTICS_FIELDS)
	check(enemy.tactics.current_destination(enemy) == goal and SortieCheckpoint.fields(enemy.tactics, SortieCheckpoint.TACTICS_FIELDS) == before, "reading/resuming destination does not mutate tactical timer/plan")
	check(EnemyTactics.reachable_flank(enemy, Vector3(100, 0, 0), enemy.awareness.last_known).is_empty(), "disconnected navigation island rejected")
	check(EnemyTactics.reachable_flank(enemy, Vector3(80, 0, -12), enemy.awareness.last_known).is_empty(), "off-mesh candidate cannot snap across missing space")
	var wall := _box(Vector3(3.5, 1.5, -4), Vector3(1, 3, 14))
	await _sync()
	enemy.tactics.plan_remaining = 0
	goal = enemy.tactics.destination(enemy, 0)
	check(goal.x < -3, "blocked preferred flank tries the other reachable side")
	var wall2 := _box(Vector3(-3.5, 1.5, -4), Vector3(1, 3, 14))
	await _sync()
	enemy.tactics.plan_remaining = 0
	check(enemy.tactics.destination(enemy, 0) == enemy.position, "both sides blocked holds current legal firing position")
	wall.free()
	wall2.free()
	await _sync()
	var door: Door = load("res://scenes/world/door.tscn").instantiate()
	add_child(door)
	door.position = Vector3(-1.1, 0, -2)
	await _sync()
	check(EnemyTactics.reachable_flank(enemy, Vector3(0, 0, -4), Vector3(0, 0, -10)).is_empty(), "capsule sweep rejects closed door even when static nav says connected")
	door.open()
	await _sync()
	check(not EnemyTactics.reachable_flank(enemy, Vector3(0, 0, -4), Vector3(0, 0, -10)).is_empty(), "same navigation segment is usable when actual door opens")
	door.free()
	await _sync()
	var occupied := _box(Vector3(5, 1, -5), Vector3(2, 2, 2))
	await _sync()
	check(EnemyTactics.reachable_flank(enemy, Vector3(5, 0, -5), Vector3(0, 0, -10)).is_empty(), "occupied destination cannot become a flank position")
	occupied.free()
	await _sync()
	enemy.tactics.plan_remaining = 0
	goal = enemy.tactics.destination(enemy, 0)
	check(goal.x > 3, "removing obstacles restores an actual reachable flank")
	enemy.awareness.update(false, Vector3(200, 0, 200), enemy.position, .1, .35, 12, 3)
	var remembered := enemy.awareness.last_known
	check(enemy.tactics.destination(enemy, .1) == remembered and not enemy.tactics.has_plan, "losing sight abandons flank and searches last observation, not hidden player")
	enemy.awareness.update(false, Vector3(200, 0, 200), enemy.position, 13, .35, 12, 3)
	check(enemy.tactics.destination(enemy, .1) == enemy.awareness.home, "flanker still disengages after finite memory")

func _test_save() -> void:
	_contact()
	enemy.tactics.destination(enemy, 0)
	enemy.tactics.plan_remaining = 1.25
	var raw: Dictionary = JSON.parse_string(JSON.stringify(SortieCheckpoint.fields(enemy.tactics, SortieCheckpoint.TACTICS_FIELDS)))
	check(SortieCheckpoint.valid_tactics(raw, R.FLANKER), "real flank plan validates after JSON roundtrip")
	var restored := EnemyTactics.new()
	SortieCheckpoint.apply_fields(raw, restored, SortieCheckpoint.TACTICS_FIELDS)
	check(restored.role == R.FLANKER and restored.has_plan and restored.goal == enemy.tactics.goal and restored.plan_remaining == 1.25, "saved duty/contact/goal/remaining interval restore exactly")
	check(SortieCheckpoint.valid_tactics({}, R.GUARD), "old checkpoint without tactical data can retain authored duty")
	check(not SortieCheckpoint.valid_tactics(raw, R.GUARD), "saved role mismatch cannot silently change an authored guard to flanker")
	for field in ["role", "has_plan", "plan_remaining", "goal", "planned_contact"]:
		var bad := raw.duplicate(true)
		bad[field] = [INF, 0, 0] if field in ["goal", "planned_contact"] else -1
		check(not SortieCheckpoint.valid_tactics(bad, R.FLANKER), "corrupt plan field rejected: " + field)
	var extra := raw.duplicate(true)
	extra["player_tracking"] = true
	check(not SortieCheckpoint.valid_tactics(extra, R.FLANKER), "unknown plan field rejected by explicit serialization whitelist")

func _test_live_roles() -> void:
	enemy.free()
	for role in [R.GUARD, R.FLANKER, R.PRESSURE]:
		_spawn(role)
		player.position = Vector3(0, 0, -12)
		var health := player.health
		var hit_seen := false
		for tick in 240:
			await get_tree().physics_frame
			if player.health < health: hit_seen = true
		check(enemy.awareness.state == EnemyAwareness.State.COMBAT, "actual role acquires target through sight: " + str(role))
		check(hit_seen, "actual role fires through unchanged attack timer/ray: " + str(role))
		match role:
			R.GUARD: check(enemy.position.distance_to(enemy.awareness.home) < .8, "live guard holds its post while shooting")
			R.FLANKER: check(absf(enemy.position.x) > 1.5 and enemy.tactics.has_plan, "live flanker really traverses sideways through navigation")
			R.PRESSURE: check(enemy.position.z < -4 and enemy.position.distance_to(player.position) > 3, "live pressure unit closes distance without overlapping player")
		enemy.free()
	_spawn(R.GUARD)
	enemy.set_physics_process(false)
	player.position = Vector3(0, 0, -20)
	await _sync()
	_contact(player.position)
	enemy._shot_cooldown = 0
	enemy._physics_process(.1)
	check(not enemy._is_telegraphing, "guard at waypoint distance zero cannot fire beyond actual weapon range")

func _test_production_assignment() -> void:
	ProfileRuntime._profile = ProfileState.create_new()
	var profile := ProfileRuntime.get_profile()
	SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district", &"streets_recon", DeploymentPlan.build(profile).carried_ids()), profile)
	SortieRuntime.layout_seed = 907
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	var roles := {}
	for instance in battle.enemy_container.get_children():
		if not instance is EnemyController: continue
		var point: EnemySpawnPoint = battle.area_root.get_node(instance.get_meta("spawn_key"))
		check(instance.tactics.role == point.tactical_role, "normal production Battle passes authored duty to controller")
		roles[instance.tactics.role] = true
	check(roles.has(R.PATROL) and roles.has(R.GUARD) and roles.has(R.FLANKER) and roles.has(R.PRESSURE), "normal Streets deployment contains every actual duty, not a lab-only feature")
	battle.free()
	SortieRuntime.clear_session()

func _box(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 4
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return body

func _navigation(at: Vector3, radius: float) -> void:
	var region := NavigationRegion3D.new()
	region.position = at
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([Vector3(-radius, 0, -radius), Vector3(radius, 0, -radius), Vector3(radius, 0, radius), Vector3(-radius, 0, radius)])
	mesh.add_polygon(PackedInt32Array([0, 3, 2, 1]))
	region.navigation_mesh = mesh
	add_child(region)

func _sync() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func check(condition: bool, message: String) -> void:
	checks += 1
	print("TACTICS %s: %s" % ["PASS" if condition else "FAIL", message])
	if not condition: failures.append(message)
