extends Node
## Controlled packet/visibility fixtures and a live-AI attack, not blind playtesting.
var checks := 0
var failures: Array[String] = []
var battle: Node3D


func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)


func _ready() -> void:
	_run.call_deferred()


func frames(count := 4) -> void:
	for index in count: await get_tree().physics_frame


func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))


func start() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	check(DeploymentPlan.deploy(profile, SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, "", false).error == OK, "real deployment succeeds")
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await frames()


func _run() -> void:
	seed(91245)
	GameLanguage.set_language("en", false)
	if DisplayServer.get_name() != "headless": get_window().size = Vector2i(1280,720)
	await start()
	var feedback: CombatFeedback = battle.hud.combat_feedback
	check(feedback.mouse_filter == Control.MOUSE_FILTER_IGNORE and feedback.get_parent().layer == 30, "noninteractive feedback sits above live cache and below pause menu")
	check(not feedback.hit_label.visible and not feedback.danger_label.visible and feedback.incoming.is_empty(), "new sortie has no fabricated combat observations")
	var tilt := Basis.from_euler(Vector3(deg_to_rad(-55),0,0))
	check(CombatFeedback.screen_bearing(Vector3.RIGHT, tilt).distance_to(Vector2.RIGHT) < .001, "east incoming projects right")
	check(CombatFeedback.screen_bearing(Vector3.LEFT, tilt).distance_to(Vector2.LEFT) < .001, "west incoming projects left")
	check(CombatFeedback.screen_bearing(Vector3.FORWARD, tilt).distance_to(Vector2.UP) < .001, "north incoming projects up in tilted camera")
	check(CombatFeedback.screen_bearing(Vector3.BACK, tilt).distance_to(Vector2.DOWN) < .001, "south incoming projects down")
	for index in 12: feedback.receive_hit(Vector3(sin(index*TAU/12),0,cos(index*TAU/12)))
	check(feedback.incoming.size() <= 4, "crossfire directions remain bounded")
	feedback.incoming.clear()
	for index in 12: feedback.receive_hit(Vector3.RIGHT)
	check(feedback.incoming.size() == 1, "repeated same-bearing hits refresh rather than flood")
	feedback.incoming.clear()
	feedback.receive_hit(Vector3.ZERO)
	check(feedback.incoming.is_empty() and feedback.danger_remaining > 0, "unknown impulse signals danger without inventing a bearing")
	feedback.receive_hit(Vector3(NAN,0,0))
	check(feedback.incoming.is_empty(), "nonfinite impact cannot create a corrupt indicator")
	feedback.danger_remaining = 0

	# Normal actor stats and real AI perception/telegraph/raycast, at a controlled
	# open-ground placement. No damage API, invulnerability or enemy stat changes.
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var enemy: EnemyController = battle.enemy_container.get_child(0)
	battle.player.global_position = Vector3(0,.1,26)
	battle.player.velocity = Vector3.ZERO
	enemy.global_position = Vector3(0,.1,21)
	enemy.velocity = Vector3.ZERO
	enemy.rotation.y = PI
	enemy.awareness = EnemyAwareness.new()
	enemy.target = battle.player
	enemy.set_physics_process(true)
	var before_health: float = battle.player.health
	for tick in 600:
		await get_tree().physics_frame
		if battle.player.health < before_health: break
	print("COMBAT_FEEDBACK_LIVE_AI health_before=",before_health," health_after=",battle.player.health," damage_taken=",battle.session.damage_taken)
	check(battle.player.is_physics_processing() and enemy.is_physics_processing(), "player and attacking AI physics remain live during the contact")
	check(battle.player.health < before_health and not battle.player.is_dead, "normal AI fires a real damaging attack at the live player")
	check(feedback.incoming.size() > 0 and feedback.danger_remaining > 0, "real AI damage, not a test-only HUD call, raises incoming warning")
	check(battle.session.damage_taken > 0, "existing damage accounting still records actual harm")
	enemy.set_physics_process(false)
	battle.player.set_physics_process(false)
	await frames(1)
	await capture("incoming_normal_ai")

	# Freeze positions for deterministic weapon and information-boundary checks.
	enemy.global_position = Vector3(0,.1,21)
	enemy.health = 1000
	enemy.armor = 0
	battle.player.global_position = Vector3(0,.1,26)
	battle.player.aim_direction = Vector3.FORWARD
	battle.player.aim_world_point = enemy.global_position+Vector3.UP*1.25
	await frames(40)
	battle.player_visibility.refresh()
	check(battle.player_visibility.can_see_enemy(enemy), "controlled target is actually observed")
	var rounds: int = battle.player.get_magazine_ammo()
	var health := enemy.health
	check(battle.player.debug_fire_once(), "production rifle fires through normal ammo runtime")
	check(enemy.health < health and battle.player.get_magazine_ammo() == rounds-1, "confirmed rifle hit actually damages and spends ammunition")
	check(feedback.hit_remaining > 0 and not feedback.hit_defeated, "visible own rifle damage confirms HIT")
	await frames(1)
	check(feedback.hit_label.visible and feedback.hit_label.text == "CONFIRMED HIT", "hit label renders the real observation")
	await capture("confirmed_hit_en")
	feedback.hit_remaining = 0
	enemy.armor = 10000
	health = enemy.health
	battle.player.debug_fire_once()
	check(enemy.health == health and feedback.hit_remaining == 0, "armor-blocked contact never falsely confirms damage")
	enemy.armor = 0
	var cover := load("res://scenes/world/cover_obstacle.tscn").instantiate() as CoverObstacle
	cover.position = Vector3(0,0,23.5)
	battle.add_child(cover)
	await frames()
	health = enemy.health
	battle.player.debug_fire_once()
	check(enemy.health == health and feedback.hit_remaining == 0, "actual ballistic cover blocks health loss and hit confirmation")
	cover.free()
	await frames()
	battle.player.aim_direction = Vector3.BACK
	check(not battle.player_visibility.can_see_enemy(enemy), "rear target is outside observed information")
	enemy.receive_damage(DamagePacket.new(1,0,0,battle.player,&"test",&"player"))
	check(feedback.hit_remaining == 0, "own splash damage on an unobserved target reveals no marker or kill information")
	battle.player.aim_direction = Vector3.FORWARD
	enemy.receive_damage(DamagePacket.new(1,0,0,null,&"test",&"player"))
	check(feedback.hit_remaining == 0, "faction string alone cannot spoof a player hit")
	for file in DirAccess.get_files_at("res://resources/weapons"):
		if not file.ends_with(".tres"): continue
		var weapon := load("res://resources/weapons/"+file) as WeaponDefinition
		feedback.hit_remaining = 0
		enemy.receive_damage(DamagePacket.new(weapon.damage,weapon.armor_penetration,weapon.structure_damage,battle.player,weapon.id,&"player"))
		check(feedback.hit_remaining > 0, "shared damage event supports weapon: "+String(weapon.id))
	# Exercise the production reinforcement connection with the campus melee
	# subtype too. This authored point is changed only in this explicit fixture.
	var reserve: EnemySpawnPoint
	for point in battle.area_root.find_children("*","EnemySpawnPoint",true,false):
		if not point.has_spawned: reserve=point; break
	check(reserve != null, "fixture has an authored unused reinforcement point")
	if reserve:
		reserve.enemy_definition_id = &"campus_infected"
		reserve.global_position = enemy.global_position+Vector3(.9,0,0)
		var infected: EnemyController = battle._spawn_enemy_at_point(reserve)
		check(infected != null, "real reinforcement spawn creates and wires the campus infected subtype")
		if infected:
			infected.set_physics_process(false)
			await frames()
			feedback.hit_remaining = 0
			infected.receive_damage(DamagePacket.new(1,0,0,battle.player,&"test",&"player"))
			check(feedback.hit_remaining > 0, "infected damage override preserves the shared confirmation event")
			infected.health = 1
	# Use the actual radial explosion path, not just a packet labelled as a rocket.
	feedback.hit_remaining = 0
	var rocket = PlayerController.ROCKET_SCENE.instantiate()
	battle.add_child(rocket)
	rocket.global_position = enemy.global_position
	rocket.setup(battle.player,Vector3.FORWARD,ContentDB.get_weapon(&"weapon.rocket_launcher_01"))
	health = enemy.health
	rocket._explode()
	check(enemy.health < health and feedback.hit_remaining > 0, "real rocket radial damage is connected to the same visible-hit feedback")
	if reserve:
		check(feedback.hit_defeated, "actual mixed lethal/nonlethal blast retains its DOWN cue")
	feedback.hit_remaining = 0
	enemy.health = 1
	var kills: int = battle.session.enemies_defeated
	enemy.receive_damage(DamagePacket.new(2,0,0,battle.player,&"test",&"player"))
	check(feedback.hit_defeated and feedback.hit_remaining > 0 and battle.session.enemies_defeated == kills+1, "actual lethal damage has a distinct DOWN cue and exactly the normal kill credit")
	var remaining := feedback.hit_remaining
	enemy.receive_damage(DamagePacket.new(100,0,0,battle.player,&"test",&"player"))
	check(feedback.hit_remaining == remaining and battle.session.enemies_defeated == kills+1, "dead target receives no duplicate kill or confirmation")
	feedback.confirm_hit(Vector3.ZERO,false)
	check(feedback.hit_defeated, "same-blast nonlethal contact cannot erase the DOWN cue")
	GameLanguage.set_language("zh_CN",false)
	await frames(1)
	check(feedback.hit_label.text == "目标击倒", "active confirmation updates in Chinese")
	await capture("target_down_zh")

	# Damage must be legible during the live, opaque inspection UI too.
	var ui: Node = battle.get_node("SlicePresentation")
	ui.container = ui.crates.values()[0]
	battle.player.global_position = ui.container.global_position+Vector3.RIGHT
	ui._show_loot()
	await frames()
	var cargo_before: Dictionary = battle.session.inventory.to_dict()
	feedback.incoming.clear()
	health = battle.player.health
	battle.player.receive_damage(DamagePacket.new(5,0,0,null,&"fixture",&"enemy",battle.player.global_position,Vector3.ZERO,Vector3.LEFT*.3))
	await frames(1)
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	check(battle.player.health < health and feedback.danger_label.visible and feedback.is_visible_in_tree(), "actual damage warning remains above the live supply panel")
	check(not battle.hud._root.visible and not get_tree().paused, "inspection still hides ordinary HUD but never pauses danger")
	check(feedback.danger_label.get_global_rect().end.y < ui.panel.get_global_rect().position.y, "inspection warning stays above the case instead of overlapping its heading")
	check(battle.session.inventory.to_dict() == cargo_before, "feedback does not change carried ownership or rounds")
	check(feedback.incoming.size() == 1 and feedback.incoming[0].direction == Vector3.RIGHT, "direction is snapshotted from the impact, without an attacker reference")
	var unchanged: float = feedback.danger_remaining
	battle.player.receive_damage(DamagePacket.new(0,0,0,null,&"fixture",&"enemy",Vector3.ZERO,Vector3.ZERO,Vector3.BACK))
	check(feedback.danger_remaining == unchanged and feedback.incoming.size() == 1, "zero applied damage cannot refresh warnings or invent a second bearing")
	await capture("incoming_cache_zh")
	ui._close_loot()
	var frozen: float = feedback.danger_remaining
	get_tree().paused = true
	# A process-always SceneTree timer proves the presentation timer is paused.
	await get_tree().create_timer(.1,true).timeout
	check(feedback.danger_remaining == frozen, "pause freezes transient feedback alongside combat")
	get_tree().paused = false
	for tick in 100: await get_tree().physics_frame
	check(feedback.incoming.is_empty() and not feedback.danger_label.visible and not feedback.hit_label.visible, "observations expire without stale arrows or labels")
	battle.player.receive_damage(DamagePacket.new(100000,0,0,null,&"fixture",&"enemy"))
	check(battle.session.status == SortieSession.Status.FAILED, "actual lethal player damage follows the existing failure path")
	feedback.receive_hit(Vector3.RIGHT)
	feedback.confirm_hit(Vector3.ZERO,true)
	check(not feedback.active and feedback.incoming.is_empty() and feedback.hit_remaining == 0, "failure clears cues and rejects delayed projectile feedback")
	battle.free()
	await start()
	feedback = battle.hud.combat_feedback
	var before: Dictionary = SortieCheckpoint.capture_world(battle)
	feedback.confirm_hit(Vector3.ZERO,true)
	feedback.receive_hit(Vector3.RIGHT)
	check(SortieCheckpoint.capture_world(battle) == before and SortieCheckpoint.validate_world(before,battle), "transient combat UI changes no checkpoint fields or validation")
	var exit: ExtractionPoint
	for point in battle.area_root.find_children("*","ExtractionPoint",true,false):
		if point.can_extract(battle.session): exit=point; break
	check(exit != null and exit.extract(battle.session), "existing extraction still succeeds")
	check(not feedback.active and feedback.incoming.is_empty(), "extraction clears combat observations too")
	battle.free()
	SortieRuntime.clear_session()
	GameLanguage.set_language("en",false)
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	print("COMBAT_FEEDBACK_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
