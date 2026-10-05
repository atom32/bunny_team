extends Node3D
var checks := 0
var failures: Array[String] = []
var player: PlayerController
var enemy: EnemyController

func _ready() -> void:
	await get_tree().process_frame
	_test_knowledge()
	await _test_senses()
	player.free()
	enemy.free()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.5).timeout
	for failure in failures: push_error("PERCEPTION: " + failure)
	print("ENEMY_PERCEPTION_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_knowledge() -> void:
	var a := EnemyAwareness.new()
	a.initialize(Vector3(3, 0, 7), Vector3.FORWARD)
	a.initialize(Vector3(500, 0, 500), Vector3.RIGHT)
	check(a.home == Vector3(3, 0, 7), "home initialized once after spawn; later calls cannot move it")
	check(a.destination(3) == Vector3(3, 0, 4), "unaware patrol uses home, not player coordinates")
	a.update(false, Vector3(100, 0, 100), a.home, 1, .35, 12, 3)
	check(a.last_known == a.home and a.state == a.State.PATROL, "unobserved coordinates ignored")
	a.hear(Vector3(0, 0, -5), 12)
	check(a.state == a.State.INVESTIGATE and a.suspicion == 0 and not a.target_visible, "hearing triggers investigation, not combat lock")
	a.update(false, Vector3(100, 0, 100), a.home, 1, .35, 12, 3)
	check(a.destination(3) == Vector3(0, 0, -5) and a.memory_remaining == 11, "sound remains at event origin, no tracking afterward")
	a.update(true, Vector3(1, 0, -5), a.home, .1, .35, 12, 3)
	check(a.suspicion > 0 and a.suspicion < 1 and a.state != a.State.COMBAT, "acquisition takes time")
	a.update(true, Vector3(2, 0, -5), a.home, .3, .35, 12, 3)
	check(a.state == a.State.COMBAT and a.last_known == Vector3(2, 0, -5), "continuous visible observation confirms target")
	a.hear(Vector3(90, 0, 90), 12)
	check(a.last_known == Vector3(2, 0, -5), "noise cannot redirect confirmed visible contact")
	a.update(false, Vector3(90, 0, 90), a.home, .5, .35, 12, 3)
	check(a.state == a.State.SEARCH and a.last_known == Vector3(2, 0, -5), "breaking sight searches last known point")
	a.update(false, Vector3(90, 0, 90), a.home, 4, .35, 12, 3)
	check(a.destination(3).distance_to(a.last_known) <= 2.01 and a.suspicion == 0, "search is local and acquisition decays")
	a.update(false, Vector3(90, 0, 90), a.home + Vector3.RIGHT * 5, 13, .35, 12, 3)
	check(a.state == a.State.RETURN and a.destination(3) == a.home, "finite search expires to return-home")
	a.update(false, Vector3.ZERO, a.home, .1, .35, 12, 3)
	check(a.state == a.State.PATROL, "return completes disengagement")
	a.update(false, Vector3.ZERO, a.destination(3), 2, .35, 12, 3)
	check(a.patrol_index == 1, "patrol advances independently of player")
	a.update(false, Vector3.ZERO, a.home, 8, .35, 12, 3)
	check(a.patrol_index == 2, "unreachable patrol waypoint times out without tracking player")
	for state in [a.State.PATROL, a.State.INVESTIGATE, a.State.COMBAT, a.State.SEARCH, a.State.RETURN]:
		a.state = state
		var raw: Dictionary = JSON.parse_string(JSON.stringify(SortieCheckpoint.fields(a, SortieCheckpoint.AWARENESS_FIELDS)))
		check(SortieCheckpoint.valid_awareness(raw), "persisted awareness validates: " + str(state))
		var restored := EnemyAwareness.new()
		SortieCheckpoint.apply_fields(raw, restored, SortieCheckpoint.AWARENESS_FIELDS)
		check(restored.destination(3) == a.destination(3) and restored.last_known == a.last_known and restored.state == a.state, "JSON roundtrip preserves knowledge and intent: " + str(state))
	var good := SortieCheckpoint.fields(a, SortieCheckpoint.AWARENESS_FIELDS)
	for key in ["state", "suspicion", "memory_remaining", "patrol_index", "home_forward"]:
		var bad := good.duplicate(true)
		bad[key] = [0, 0, 0] if key == "home_forward" else -1
		check(not SortieCheckpoint.valid_awareness(bad), "invalid saved perception rejected: " + key)
	check(SortieCheckpoint.valid_awareness({}), "legacy snapshots may lack perception; no fabricated target intel")
	var basic := ContentDB.get_enemy_definition(&"prototype_basic_enemy")
	var heavy := ContentDB.get_enemy_definition(&"prototype_heavy_enemy")
	check(heavy.view_angle > basic.view_angle and heavy.acquire_seconds > basic.acquire_seconds and heavy.search_duration > basic.search_duration, "human/drone have distinct detection profiles")

func _test_senses() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -.2
	floor_body.collision_layer = 4
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(100, .4, 100)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	player = PlayerController.new()
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	var definition := ContentDB.get_enemy_definition(&"prototype_heavy_enemy")
	enemy = EnemySpawnService.spawn(definition, Transform3D(Basis.IDENTITY, Vector3.ZERO), self)
	# Freeze automatic scheduling for deterministic geometry checks, not the
	# sensing implementation. Every query below uses actual physics colliders.
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector3(0, 0, -10)
	await _sync()
	enemy.target = player
	check(enemy.awareness.home == Vector3.ZERO, "deferred setup captures actual spawn transform")
	check(enemy.can_see_target(), "unobstructed target inside forward cone is visible")
	player.position = Vector3(0, 0, 10)
	await _sync()
	check(not enemy.can_see_target(), "target behind enemy is not visually detected")
	player.position.z = 1
	await _sync()
	check(enemy.can_see_target(), "very close unobstructed contact visible from rear")
	player.position.z = -40
	await _sync()
	check(not enemy.can_see_target(), "target outside detection range not visible")
	player.position.z = -10
	var door: Door = load("res://scenes/world/door.tscn").instantiate()
	add_child(door)
	door.position = Vector3(-1.1, 0, -5)
	await _sync()
	check(not enemy.can_see_target(), "closed actual door blocks vision")
	for mesh in door.find_children("*", "MeshInstance3D", true, false): mesh.transparency = .95
	check(not enemy.can_see_target(), "camera transparency does not remove sight obstruction")
	_reset_knowledge()
	CombatNoise.emit_at(player, player.global_position, 10, &"footstep")
	check(enemy.awareness.state == EnemyAwareness.State.PATROL, "wall attenuates footsteps below hearing threshold")
	CombatNoise.emit_at(player, player.global_position, 40, &"gunfire")
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE and not enemy.awareness.target_visible, "loud gunfire through door gives sound position, not vision")
	var heard := enemy.awareness.last_known
	player.position.x = 8
	enemy.awareness.update(false, Vector3.ZERO, enemy.position, 1, enemy.acquire_seconds, enemy.search_duration, enemy.patrol_radius)
	check(enemy.awareness.last_known == heard, "moving after sound does not update remembered position")
	player.position.x = 0
	door.open()
	await _sync()
	check(enemy.can_see_target(), "opening door restores actual line of sight")
	_reset_knowledge()
	CombatNoise.emit_at(player, player.global_position, 10, &"footstep")
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE, "same footsteps audible with door open")
	_reset_knowledge()
	CombatNoise.emit_at(player, player.global_position, 3, &"footstep")
	check(enemy.awareness.state == EnemyAwareness.State.PATROL, "precision-walk radius avoids distant investigation")
	_reset_knowledge()
	enemy.set_physics_process(false)
	CombatNoise.emit_at(player, player.global_position, 100, &"gunfire")
	check(enemy.awareness.state == EnemyAwareness.State.PATROL, "disabled tutorial enemy does not hear before activation")
	enemy.set_physics_process(true)
	get_tree().paused = true
	CombatNoise.emit_at(player, player.global_position, 100, &"gunfire")
	get_tree().paused = false
	check(enemy.awareness.state == EnemyAwareness.State.PATROL, "paused simulation emits no sound observations")
	# Exercise autonomous controller: observation -> acquisition -> locked shot.
	enemy._shot_cooldown = 0
	enemy._physics_process(.1)
	check(not enemy._is_telegraphing, "controller cannot fire before acquisition")
	enemy._physics_process(.6)
	check(enemy._is_telegraphing and enemy._engaged, "confirmed visible target triggers unchanged attack API")
	var locked := enemy._shot_aim_point
	door.close()
	await _sync()
	enemy._physics_process(.1)
	check(enemy.awareness.state == EnemyAwareness.State.SEARCH and enemy._shot_aim_point == locked, "lost sight starts search but does not retarget an already telegraphed shot")
	await get_tree().create_timer(.45).timeout
	check(not enemy._is_telegraphing, "pending shot resolves instead of remaining stuck")
	enemy._shot_cooldown = 0
	enemy._physics_process(.1)
	check(not enemy._is_telegraphing, "no new autonomous shots through closed door")
	var destination := enemy.navigation_agent.target_position
	player.position = Vector3(7, 0, -12)
	enemy._physics_process(.7)
	check(enemy.navigation_agent.target_position.distance_to(destination) < .001, "controller navigation cannot follow hidden target")
	door.free()
	await _sync()
	_reset_knowledge()
	player.equip_weapon(ContentDB.get_weapon(&"weapon.pistol_01"))
	player.aim_direction = Vector3.FORWARD
	player.aim_world_point = player.global_position + Vector3.FORWARD * 30
	check(player.debug_fire_once(), "real player weapon fires for noise integration")
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE and enemy.awareness.last_known == player.global_position, "actual successful player shot emits localized noise")
	_reset_knowledge()
	check(not player._try_fire() and enemy.awareness.state == EnemyAwareness.State.PATROL, "fire rejected by cooldown emits no phantom sound")
	player.position = Vector3(0, 0, -7)
	player.velocity = Vector3.ZERO
	player._footstep_distance = 0
	Input.action_press("move_right")
	Input.action_press("precision_walk")
	# Real movement/physics, fixed tick fixture (not a synthetic hear call).
	for i in 35:
		player._update_movement(1.0 / 60.0)
		await get_tree().physics_frame
	Input.action_release("precision_walk")
	Input.action_release("move_right")
	check(player.position.x > 1.4 and enemy.awareness.state == EnemyAwareness.State.PATROL, "actual precision movement remains inaudible at seven metres")
	player.position = Vector3(0, 0, -7)
	player.velocity = Vector3.ZERO
	player._footstep_distance = 0
	Input.action_press("move_right")
	for i in 20:
		player._update_movement(1.0 / 60.0)
		await get_tree().physics_frame
	Input.action_release("move_right")
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE, "actual normal movement produces audible footsteps")
	_reset_knowledge()
	player.position = Vector3(0, 0, -7)
	player.velocity = Vector3.ZERO
	player._footstep_distance = 0
	for i in 20:
		player._update_movement(1.0 / 60.0)
		await get_tree().physics_frame
	check(enemy.awareness.state == EnemyAwareness.State.PATROL, "stationary actor emits no footsteps")

func _reset_knowledge() -> void:
	enemy.awareness = EnemyAwareness.new()
	enemy.ensure_awareness()

func _sync() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func check(condition: bool, message: String) -> void:
	checks += 1
	print("PERCEPTION %s: %s" % ["PASS" if condition else "FAIL", message])
	if not condition: failures.append(message)
