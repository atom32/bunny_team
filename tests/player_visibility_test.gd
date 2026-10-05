extends Node3D
var checks := 0
var failures: Array[String] = []
var player: PlayerController
var enemy: EnemyController
var sensor: PlayerVisibility
var camera: Camera3D
var hud: BattleHUD

func _ready() -> void:
	await get_tree().process_frame
	await _prepare()
	await _movement_audio()
	await _vision()
	await _hearing_and_fire()
	await _aim_and_cover()
	await _cutaway_aim()
	await _death()
	SortieRuntime.clear_session()
	player.free()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.5).timeout
	for failure in failures: push_error("VISIBILITY: " + failure)
	print("PLAYER_VISIBILITY_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _prepare() -> void:
	_box(Vector3(0, -.2, 0), Vector3(100, .4, 100))
	var navigation := NavigationRegion3D.new()
	var nav_mesh := NavigationMesh.new()
	nav_mesh.vertices = PackedVector3Array([Vector3(-45, 0, -45), Vector3(45, 0, -45), Vector3(45, 0, 45), Vector3(-45, 0, 45)])
	nav_mesh.add_polygon(PackedInt32Array([0, 3, 2, 1]))
	navigation.navigation_mesh = nav_mesh
	add_child(navigation)
	var profile := ProfileState.create_new()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"street_district", &"streets_recon", DeploymentPlan.build(profile).carried_ids()), profile)
	player = load("res://scenes/player/player.tscn").instantiate()
	player.configure_sortie(session)
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	player.aim_direction = Vector3.FORWARD
	enemy = EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_heavy_enemy"), Transform3D(Basis.IDENTITY, Vector3(0, 0, -10)), self)
	enemy.set_physics_process(false)
	sensor = PlayerVisibility.new()
	sensor.actor = player
	add_child(sensor)
	sensor.set_physics_process(false)
	sensor.track_enemy(enemy)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24
	add_child(camera)
	camera.position = Vector3(0, 18, 14)
	camera.look_at(Vector3.ZERO)
	hud = BattleHUD.new()
	add_child(hud)
	await _sync()
	check(not enemy.presentation.visible and enemy.visible and enemy.collision_layer == 2, "spawn starts hidden without disabling root or collision")

func _vision() -> void:
	sensor.refresh()
	check(enemy.presentation.is_visible_in_tree() and enemy.awareness_indicator.visible, "front unobstructed enemy and its indicator become visible")
	enemy.position.z = 8
	await _sync()
	sensor.refresh()
	check(not enemy.presentation.visible and not enemy.awareness_indicator.visible and enemy.visible, "rear enemy is hidden without hiding gameplay root")
	check(SortieCheckpoint.fields(enemy, SortieCheckpoint.ENEMY_FIELDS).visible, "tactical hiding cannot corrupt checkpoint root visibility")
	enemy.position.z = 3
	await _sync()
	check(sensor.can_see_enemy(enemy), "near unobstructed contact is visible from behind")
	enemy.position.z = -34
	await _sync()
	check(not sensor.can_see_enemy(enemy), "outside unscoped range remains hidden")
	var original_weapon := player.weapon_data
	player.weapon_data = ContentDB.get_weapon(&"weapon.sniper_01")
	Input.action_press("precision_walk")
	check(sensor.sight_range() > 32 and sensor.can_see_enemy(enemy), "existing optic extension increases scoped sight range")
	Input.action_release("precision_walk")
	player.weapon_data = original_weapon
	enemy.position.z = -10
	var door: Door = load("res://scenes/world/door.tscn").instantiate()
	add_child(door)
	door.position = Vector3(-1.1, 0, -5)
	await _sync()
	sensor.refresh()
	check(not sensor.can_see_enemy(enemy) and not enemy.presentation.visible, "closed production door occludes actual head/chest rays")
	for mesh in door.find_children("*", "MeshInstance3D", true, false): mesh.transparency = .95
	check(not sensor.can_see_enemy(enemy), "camera-faded door still obstructs player information")
	check(sensor.hear(enemy.position, 12, &"movement") == 0, "wall attenuates distant footsteps")
	check(sensor.hear(enemy.position, 40, &"gunfire") > 0 and not enemy.presentation.visible, "audible gunfire does not reveal hidden actor")
	var bearing := sensor.heard_direction
	enemy.position.x = .4
	await _sync()
	sensor.refresh()
	check(sensor.heard_direction == bearing, "unobserved relocation does not move last-heard bearing")
	enemy.position.x = 0
	door.open()
	await _sync()
	sensor.refresh()
	check(sensor.can_see_enemy(enemy) and enemy.presentation.visible, "opening production door reveals contact")
	door.close()
	await _sync()
	sensor.refresh()
	var before := get_child_count()
	CombatEffects.muzzle_flash(self, enemy.position + Vector3.UP, Vector3.BACK, Color.RED)
	CombatEffects.hit(self, enemy.position + Vector3.UP)
	CombatEffects.telegraph(self, enemy.position + Vector3.UP, Vector3.UP)
	CombatEffects.rocket_trail(self, enemy.position + Vector3.UP)
	check(get_child_count() == before, "hidden muzzle/hit/telegraph/trail do not leak exact origin")
	var segment := PlayerVisibility.visible_segment(self, Vector3(0, 1, -10), Vector3.UP)
	check(segment.size() == 2 and segment[0].z > -5 and segment[1] == Vector3.UP, "tracer shows visible impact-side segment, not hidden attacker")
	door.free()
	await _sync()

func _hearing_and_fire() -> void:
	enemy.position = Vector3(0, 0, 8)
	enemy.rotation.y = 0
	await _sync()
	sensor.refresh()
	check(not enemy.presentation.visible, "rear attack fixture remains unobserved")
	check(sensor.hear(Vector3(100, 0, 0), 40, &"gunfire") == 0, "out-of-range gunfire supplies no cue")
	sensor.hear(Vector3(2, 0, -10), 40, &"gunfire")
	check(sensor.heard_direction.is_equal_approx(Vector3.FORWARD), "bearing quantizes into eight sectors instead of exposing target coordinates")
	sensor.hear(Vector3(10, 0, 0), 12, &"movement")
	check(sensor.heard_kind == &"gunfire" and sensor.heard_direction.is_equal_approx(Vector3.FORWARD), "footsteps cannot overwrite active gunfire cue")
	sensor._physics_process(2)
	check(sensor.heard_remaining == 0, "event bearing expires rather than tracking enemies")
	var health := player.health
	enemy.target = player
	enemy._shot_aim_point = player.global_position + Vector3.UP * 1.05
	for i in 30: enemy._update_presentation(1.0 / 60.0, enemy._shot_aim_point, 0)
	var origin: Vector3 = enemy.presentation.get_muzzle_position()
	var direction: Vector3 = enemy.presentation.get_muzzle_direction()
	enemy.presentation.show()
	check(enemy.presentation.get_muzzle_position().is_equal_approx(origin) and enemy.presentation.get_muzzle_direction().is_equal_approx(direction), "visibility alone cannot alter muzzle transform or direction")
	sensor.refresh()
	enemy._finish_telegraphed_shot(.01)
	await get_tree().create_timer(.1).timeout
	check(player.health < health and not enemy.presentation.visible, "unobserved real enemy shot still damages player; no invulnerability by hiding")
	check(sensor.heard_kind == &"gunfire" and sensor.heard_direction.is_equal_approx(Vector3.BACK), "actual enemy shot supplies coarse rear gunfire cue")
	hud.set_perception(sensor, camera)
	check(hud.sound_hint.visible and not hud.sound_hint.text.contains("m"), "HUD displays event bearing without exact range")
	var view := get_viewport().get_visible_rect()
	check(view.encloses(hud.sound_hint.get_global_rect()), "sound bearing stays fully inside viewport, not clipped off the left edge")
	sensor._physics_process(2)
	hud.set_perception(sensor, camera)
	check(not hud.sound_hint.visible, "HUD removes expired sound bearing")
	# Real autonomous movement, not a synthetic hear() call. Face away to patrol
	# rather than acquire the player; prevent attacks while isolating footfalls.
	enemy.position = Vector3(0, 0, 7)
	enemy.rotation.y = PI
	enemy.awareness = EnemyAwareness.new()
	enemy.ensure_awareness()
	enemy.velocity = Vector3.ZERO
	enemy._shot_cooldown = 1000
	await _sync()
	sensor._motion.erase(enemy) # Do not count fixture relocation as a footstep.
	sensor.refresh()
	enemy.set_physics_process(true)
	var heard_step := false
	var movement_before := AudioDirector.movement_events
	var walked := 0.0
	var previous := enemy.position
	for i in 180:
		await get_tree().physics_frame
		walked += Vector2(enemy.position.x - previous.x, enemy.position.z - previous.z).length()
		previous = enemy.position
		sensor._physics_process(1.0 / 60.0)
		if sensor.heard_remaining > 0 and sensor.heard_kind == &"movement": heard_step = true; break
	check(AudioDirector.movement_events > movement_before,"actual audible enemy movement plays Foley through presentation pool")
	check(heard_step and walked >= 1.4 and not enemy.presentation.visible and enemy.is_physics_processing(), "actual hidden patrol movement emits footsteps without disabling or revealing AI")
	enemy.set_physics_process(false)
	sensor._physics_process(2)
	check(sensor.heard_remaining == 0, "stationary disabled fixture emits no repeated movement cue")

func _aim_and_cover() -> void:
	enemy.position = Vector3(0, 0, 8)
	await _sync()
	var screen := camera.unproject_position(enemy.position + Vector3.UP)
	var hidden_aim := player._world_aim_point(camera, screen)
	check(absf(hidden_aim.y) < .05, "hidden actor collider is skipped by screen aim picking")
	player.aim_direction = Vector3.BACK
	var visible_aim := player._world_aim_point(camera, screen)
	check(visible_aim.y > .2, "observed actor remains pickable for vertical aiming")
	player.aim_direction = Vector3.FORWARD
	enemy.position = Vector3(0, 0, -6)
	await _sync()
	var muzzle: Vector3 = player.combat_rig.get_muzzle_position()
	check(player.effective_fire_origin(muzzle) == muzzle, "unobstructed production muzzle remains bit-exact")
	var origin := Vector3(0, 1.25, -2)
	var wall := _box(Vector3(0, 1.5, -1), Vector3(4, 3, .2))
	await _sync()
	var corrected := player.effective_fire_origin(origin)
	check(corrected.z > -.91 and corrected.z < -.85, "barrel through wall is clamped to near face, not far side")
	player.aim_world_point = enemy.position + Vector3.UP
	var health := enemy.health
	player._fire_hitscan(corrected, corrected.direction_to(player.aim_world_point))
	check(enemy.health == health, "clamped live hitscan hits wall, not enemy behind it")
	var ammo_before: int = player._get_weapon_runtime_state().magazine_ammo
	check(player.debug_fire_once(), "blocked shot still uses ordinary firing API")
	check(player._get_weapon_runtime_state().magazine_ammo == ammo_before - 1 and enemy.health == health, "cover neither refunds ammo nor leaks hits")
	var trace := sensor.aim_trace()
	check(trace.blocked, "centerline feedback reports muzzle/cover obstruction")
	hud.set_perception(sensor, camera)
	check(hud.cover_hint.visible and hud.impact_dot.visible, "HUD shows cover warning and actual interception")
	check(get_viewport().get_visible_rect().encloses(hud.cover_hint.get_global_rect()), "cover warning stays on screen even when cursor is near the edge")
	var rocket: Node3D = load("res://scenes/weapons/rocket_projectile.tscn").instantiate()
	add_child(rocket)
	rocket.position = corrected
	rocket.setup(player, Vector3.FORWARD, ContentDB.get_weapon(&"weapon.rocket_launcher_01"))
	await get_tree().create_timer(.1).timeout
	check(not is_instance_valid(rocket), "rocket from corrected muzzle collides immediately with wall")
	wall.free()
	await _sync()
	check(player.effective_fire_origin(origin) == origin, "removing cover restores exact origin without moving weapon markers")
	player.aim_world_point = Vector3(0, 1.1, -5)
	var clear := sensor.aim_trace()
	check(not clear.blocked, "clear centerline no longer warns")

func _cutaway_aim() -> void:
	player.aim_direction = Vector3.FORWARD
	enemy.position = Vector3(0, 0, -6)
	var roof := _box(Vector3(0, 3.6, -3), Vector3(16, .18, 14))
	roof.add_to_group("aim_cutaway_roof")
	var occlusion := preload("res://scripts/battle/camera_occlusion.gd").new()
	add_child(occlusion)
	await _sync()
	var screen := camera.unproject_position(enemy.position + Vector3.UP)
	var before := player._world_aim_point(camera, screen)
	check(absf(before.y - 3.69) < .01, "reproduces mouse picking roof at 3.69m instead of enemy")
	occlusion.update_occlusion(camera, player, 1.0)
	check(roof.is_in_group("active_aim_cutaway"), "overhead production cutaway activates aim exclusion")
	var after := player._world_aim_point(camera, screen)
	check(after.y > .2 and after.y < 2 and after.z < -5, "cutaway mouse ray reaches observed enemy below ceiling")
	player.aim_world_point = after
	var health := enemy.health
	var muzzle := player.effective_fire_origin(player.combat_rig.get_muzzle_position())
	player._fire_hitscan(muzzle, player._shot_direction_from(muzzle))
	check(enemy.health < health, "actual below-roof hitscan reaches enemy without changing projectile masks")
	var query := PhysicsRayQueryParameters3D.create(Vector3(0, 2, -3), Vector3(0, 5, -3), 4)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == roof and roof.collision_layer == 4, "roof remains physical cover; upward projectile ray still hits it")
	var wall := _box(Vector3(0, 4, -3), Vector3(4, 8, .2))
	await _sync()
	occlusion.update_occlusion(camera, player, 1.0)
	check(not wall.is_in_group("active_aim_cutaway"), "faded ordinary wall never becomes aim-through cover")
	var wall_aim := player._world_aim_point(camera, screen)
	check(wall_aim.z > -3.2 and wall_aim.y > 2, "world aim still picks intervening wall")
	wall.free()
	roof.position.x = 50
	await _sync()
	occlusion.update_occlusion(camera, player, 1.0)
	check(not roof.is_in_group("active_aim_cutaway"), "roof aim exclusion ends on leaving the cutaway")
	roof.position.x = 0
	await _sync()
	occlusion.update_occlusion(camera, player, 1.0)
	occlusion.free()
	check(not roof.is_in_group("active_aim_cutaway"), "scene teardown clears temporary aim exclusion")
	roof.free()
	await _sync()

func _death() -> void:
	if is_instance_valid(enemy): enemy.free()
	enemy = EnemySpawnService.spawn(ContentDB.get_enemy_definition(&"prototype_basic_enemy"), Transform3D(Basis.IDENTITY, Vector3(0, 0, 8)), self)
	enemy.set_physics_process(false)
	await _sync()
	sensor.refresh()
	var corpse: Node3D = enemy.presentation
	check(not corpse.visible, "rear humanoid is unobserved before death")
	enemy.take_damage(999)
	await get_tree().process_frame
	check(is_instance_valid(corpse) and corpse.is_in_group("sight_sensitive") and not corpse.visible, "hidden human corpse does not reveal a death location")
	player.aim_direction = Vector3.BACK
	sensor.refresh()
	check(corpse.visible, "turning to observe reveals existing corpse without changing death state")
	corpse.free()

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

func _sync() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func check(condition: bool, message: String) -> void:
	checks += 1
	print("VISIBILITY %s: %s" % ["PASS" if condition else "FAIL", message])
	if not condition: failures.append(message)

func _movement_audio() -> void:
	check(AudioDirector._movement_players.size() == 8,"bounded separate movement pool exists")
	for stream in AudioDirector.MOVEMENT_STREAMS:
		check(stream.get_length() > .01,"licensed original movement audio decodes")
	var before := AudioDirector.movement_events
	AudioDirector.play_movement(0)
	check(AudioDirector.movement_events == before,"inaudible movement creates no voice")
	get_tree().paused = true
	AudioDirector.play_movement(1)
	get_tree().paused = false
	check(AudioDirector.movement_events == before,"pause blocks new movement audio")
	AudioDirector._next_movement = 0
	AudioDirector.play_movement(1,-1,false)
	var left: AudioStreamPlayer2D = AudioDirector._movement_players[0]
	var center := get_viewport().get_visible_rect().size.x*.5
	check(left.position.x < center and left.bus == &"SFX","left bearing uses left SFX voice")
	AudioDirector.play_movement(.2,1,true)
	var right: AudioStreamPlayer2D = AudioDirector._movement_players[1]
	check(right.position.x > center and right.volume_db < left.volume_db,"right quieter cue preserves bearing and attenuation")
	check(right.stream == AudioDirector.MOVEMENT_STREAMS[3],"drone uses mechanical sound rather than human footstep")
	AudioDirector.clear_movement()
	check(left.stream == null and right.stream == null,"scene cleanup releases movement streams")
