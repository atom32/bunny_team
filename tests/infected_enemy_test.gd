extends Node3D
var failures: Array[String] = []
var checks := 0
var player: PlayerController
var enemy: EnemyController

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func sync() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func _ready() -> void:
	await get_tree().process_frame
	var definition := ContentDB.get_enemy_definition(&"campus_infected")
	check(definition != null and definition.validate_definition(), "registered infected content")
	var floor_body := StaticBody3D.new(); floor_body.collision_layer = 4
	var floor_shape := CollisionShape3D.new(); var floor_box := BoxShape3D.new(); floor_box.size = Vector3(30,.4,30)
	floor_shape.shape = floor_box; floor_body.position.y = -.2; floor_body.add_child(floor_shape); add_child(floor_body)
	player = PlayerController.new()
	add_child(player)
	player.set_physics_process(false); player.set_process(false)
	enemy = EnemySpawnService.spawn(definition, Transform3D.IDENTITY, self)
	enemy.set_physics_process(false)
	await sync()
	enemy.target = player
	check(enemy.presentation.pistol == null and not enemy.presentation.legacy_mode and enemy.presentation.animation_player.current_animation == "Idle", "independent unarmed subject idle presentation")
	enemy.awareness.state = EnemyAwareness.State.COMBAT
	enemy.awareness.last_known = Vector3(0,0,-8)
	check(enemy._movement_goal(.1) == Vector3(0,0,-8), "chases contact rather than holding ranged distance")
	player.position = Vector3(0,0,-1.3)
	await sync()
	var before := player.health
	enemy._telegraph_shot()
	check(enemy._is_telegraphing and enemy.presentation.animation_player.current_animation == "Punch_Left", "visible melee windup")
	await get_tree().create_timer(.45).timeout
	check(player.health < before, "nearby visible target receives melee damage")
	before = player.health
	enemy._telegraph_shot()
	player.position = Vector3(0,0,-5)
	await sync()
	await get_tree().create_timer(.45).timeout
	check(player.health == before, "escaping windup avoids damage")
	# Remain in the existing range AND 140-degree sight cone, but step clear of
	# the punch direction after it is committed. No damage API or stat changes.
	player.position = Vector3(0,0,-1.3)
	enemy.rotation = Vector3.ZERO
	await sync()
	before = player.health
	enemy._telegraph_shot()
	player.position = Vector3(1.13,0,-.65)
	await sync()
	check(enemy.can_see_target() and enemy.global_position.distance_to(player.global_position) < enemy.attack_range, "side-step remains visible and inside melee radius")
	await get_tree().create_timer(.45).timeout
	check(player.health == before, "side-step clear of committed punch avoids damage without leaving radius")
	check(not enemy._strike_warning.visible, "ground warning closes after a missed punch")
	# Hold the original direction: this is still an attack, not cosmetic-only.
	player.position = Vector3(0,0,-1.3)
	enemy.rotation = Vector3.ZERO
	await sync()
	before = player.health
	enemy._telegraph_shot()
	var timer := enemy._shot_timer
	enemy._telegraph_shot()
	check(enemy._shot_timer == timer, "repeated request cannot stack punches or restart windup")
	check(enemy._strike_warning.visible and enemy._strike_warning.mesh.get_surface_count() == 1, "visible punch has a real ground sector")
	var vertices: PackedVector3Array = enemy._strike_warning.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size() == 36 and Array(vertices).all(func(point): return point.length() <= enemy.attack_range + .001 and (point.is_zero_approx() or point.normalized().dot(Vector3.FORWARD) >= cos(PI/4) - .001)), "ground vertices match exact melee range and 90-degree sector")
	check(enemy._movement_goal(.1) == enemy.global_position, "windup brakes pursuit instead of sliding after player")
	check(enemy._in_strike_arc(Vector3(.5,0,-1)) and not enemy._in_strike_arc(Vector3(1,0,-.5)), "sector matches locked forward direction rather than a damage circle")
	await get_tree().create_timer(.45).timeout
	check(player.health < before, "holding ground inside committed sector still takes actual damage")
	before = player.health
	player.position = Vector3(0,0,-1.3)
	await sync()
	enemy._telegraph_shot()
	var wall := StaticBody3D.new(); wall.collision_layer = 4
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(3,3,.1)
	shape.shape = box; wall.add_child(shape); wall.position = Vector3(0,1,-.65); add_child(wall)
	await sync()
	enemy._refresh_strike_warning()
	vertices = enemy._strike_warning.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(Array(vertices).all(func(point): return point.z > -.6), "sector edges clip before cover instead of drawing through it")
	await get_tree().create_timer(.45).timeout
	check(player.health == before, "wall prevents melee damage")
	wall.free()
	enemy.awareness.state = EnemyAwareness.State.PATROL
	enemy.set_physics_process(true)
	enemy.hear_noise(Vector3(6,0,0), &"gunfire")
	enemy.set_physics_process(false)
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE and enemy.awareness.last_known == Vector3(6,0,0), "noise investigates event origin")
	player.position = Vector3(0,0,-7)
	enemy.awareness = EnemyAwareness.new()
	enemy.ensure_awareness()
	var start := enemy.position
	enemy.set_physics_process(true)
	await get_tree().create_timer(2.0).timeout
	enemy.set_physics_process(false)
	check(enemy.awareness.state == EnemyAwareness.State.COMBAT and enemy.position.distance_to(start) > 2, "live infected actually pursues through physics/navigation")
	enemy.take_damage(1000)
	await get_tree().process_frame
	check(not is_instance_valid(enemy), "death removes controller without retaining an attacking actor")
	player.free()
	await _campus_melee()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	for failure in failures: push_error(failure)
	print("INFECTED_ENEMY_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name + ".png"))

func _campus_melee() -> void:
	# Controlled placements in the real campus Battle. Other actors are frozen;
	# this is not an unaided six-commission run or a physical-controller test.
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	var path := "user://infected_melee_checkpoint.json"
	check(DeploymentPlan.deploy(profile, &"street_district", &"streets_recon", path).error == OK, "campus deploy uses real equipment and persistence")
	SortieRuntime.layout_seed = 907
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	for actor in battle.enemy_container.get_children(): actor.set_physics_process(false)
	player = battle.player
	player.set_physics_process(false)
	for actor in battle.enemy_container.get_children():
		if actor.definition_id == &"campus_infected": enemy = actor; break
	check(is_instance_valid(enemy), "actual authored campus has infected encounter")
	if not is_instance_valid(enemy): battle.free(); SortieRuntime.clear_session(); return
	enemy.position = Vector3(0,.1,27.3)
	enemy.rotation = Vector3.ZERO
	enemy.velocity = Vector3.ZERO
	player.position = Vector3(0,.1,26)
	player.velocity = Vector3.ZERO
	player.aim_direction = Vector3.BACK
	await sync()
	battle.player_visibility.refresh()
	check(enemy.can_see_target() and battle.player_visibility.can_see_enemy(enemy), "real campus open-ground sight is mutual")
	# Controlled placement must also move the real camera before freezing time.
	battle.camera.position = player.position + Vector3.UP * .85 + Vector3(0,18.2,13.7)
	var screen: Vector2 = battle.camera.unproject_position(enemy.global_position)
	check(get_viewport().get_visible_rect().has_point(screen) and not battle.camera.is_position_behind(enemy.global_position), "capture camera actually contains encounter")
	get_tree().paused = true
	enemy._telegraph_shot()
	var locked: Vector3 = enemy._shot_aim_point
	var duration: float = enemy._shot_timer.time_left
	check(enemy._strike_warning.visible, "observed campus enemy shows ground tell")
	await get_tree().create_timer(.45).timeout
	check(is_equal_approx(enemy._shot_timer.time_left, duration) and enemy._is_telegraphing, "pause holds punch and warning without damage")
	get_tree().paused = false
	await get_tree().create_timer(.12).timeout
	get_tree().paused = true
	duration = enemy._shot_timer.time_left
	check(duration > 0 and duration < .38, "checkpoint captures a partially elapsed punch, not just its starting frame")
	await _capture("campus_melee_windup")
	var key: String = enemy.get_meta("spawn_key")
	check(SortieRuntime.save_checkpoint() == OK, "save real paused windup")
	var saved := ProfileRuntime.get_profile().sortie_checkpoint.duplicate(true)
	check(saved.version == SortieCheckpoint.VERSION and SortieCheckpoint.VERSION == 6, "no checkpoint schema migration for the warning")
	battle.free()
	SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(path) and SortieRuntime.resume_saved(path) == OK, "resume durable real session")
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	player = battle.player
	for actor in battle.enemy_container.get_children():
		if actor.get_meta("spawn_key") == key: enemy = actor; break
	check(not FlowMenu.is_open() and enemy._is_telegraphing and enemy._shot_aim_point.is_equal_approx(locked), "saved punch restores original locked point")
	check(is_equal_approx(enemy._shot_timer.time_left, duration), "saved punch retains remaining delay, not a new attack")
	battle.player_visibility.refresh()
	enemy._refresh_strike_warning()
	check(enemy._strike_warning.visible, "restored warning reconstructed without extra save fields")
	var before := player.health
	player.position = enemy.position + Vector3(1.13,0,-.65)
	get_tree().paused = false
	await get_tree().create_timer(.45).timeout
	check(player.health == before and not enemy._is_telegraphing and not enemy._strike_warning.visible, "resumed side-step avoids same punch and clears warning")
	# Visibility/wall clipping uses production sensing, not a fabricated HUD flag.
	player.position = enemy.position + Vector3(0,0,-1.3)
	await sync()
	enemy.rotation = Vector3.ZERO
	get_tree().paused = true
	enemy._telegraph_shot()
	var wall := StaticBody3D.new()
	wall.collision_layer = 4
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(4,3,.12)
	collision.shape = box; wall.add_child(collision)
	wall.position = enemy.position + Vector3(0,1,-.65)
	battle.add_child(wall)
	await sync()
	battle.player_visibility.refresh()
	enemy._refresh_strike_warning()
	check(not enemy._strike_warning.visible, "wall hides unseen attacker warning, no through-wall tell")
	get_tree().paused = false
	await get_tree().create_timer(.45).timeout
	check(player.health == before, "real campus cover blocks resumed melee")
	wall.free()
	# Real generated movement input, with enemy AI/avoidance and player physics live.
	player.position = Vector3(0,.1,26)
	player.velocity = Vector3.ZERO
	enemy.position = Vector3(0,.1,27.3)
	enemy.velocity = Vector3.ZERO
	enemy.rotation = Vector3.ZERO
	enemy.awareness.state = EnemyAwareness.State.COMBAT
	enemy.awareness.last_known = player.position
	enemy.awareness.target_visible = true
	enemy.set_physics_process(true)
	player.set_physics_process(true)
	enemy._telegraph_shot()
	var from := player.position
	Input.action_press("move_right")
	await get_tree().create_timer(.22).timeout
	Input.action_release("move_right")
	await get_tree().create_timer(.25).timeout
	check(player.position.distance_to(from) > .8 and player.health == before, "real live physics/input side-step avoids punch")
	check(enemy.position.distance_to(Vector3(0,.1,27.3)) < .5, "live windup brakes chasing rather than following side-step")
	await _capture("campus_melee_side_step")
	# Killing a winding-up actor must not leave a marker or a delayed hit.
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	player.position = enemy.position + Vector3(0,0,-1.3)
	enemy._telegraph_shot()
	var marker: WeakRef = weakref(enemy._strike_warning)
	enemy.take_damage(1000)
	await get_tree().create_timer(.45).timeout
	check(marker.get_ref() == null and player.health == before, "death during windup removes warning and pending damage")
	battle.free()
	SortieRuntime.clear_session()
