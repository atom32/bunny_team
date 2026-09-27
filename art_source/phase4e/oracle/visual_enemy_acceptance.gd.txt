extends Node

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")

var battle: Node3D
var player: PlayerController
var enemy: EnemyController
var phase_label: Label
var _advance_requested := false
var _fire_timer := 0.6


func _ready() -> void:
	var profile := ProfileRuntime.new_profile()
	SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	battle = BATTLE_SCENE.instantiate()
	add_child(battle)
	battle.result_transition_enabled = false
	player = battle.player
	player.max_health = 10000.0
	player.health = 10000.0
	player.visible = false
	player.set_physics_process(false)
	battle.set_process(false)
	battle.camera.size = 4.5

	var enemies := get_tree().get_nodes_in_group("enemies")
	for index in enemies.size():
		var candidate := enemies[index] as EnemyController
		if index == 0:
			enemy = candidate
			continue
		candidate.process_mode = Node.PROCESS_MODE_DISABLED
		candidate.visible = false
	enemy.global_position = player.global_position + Vector3(0.0, 0.0, -3.2)
	enemy.rotation.y = PI
	enemy.target = player
	enemy.set_physics_process(false)
	battle.enemies_remaining = 1
	battle.hud.set_enemy_count(1)
	battle.camera.global_position = enemy.global_position + Vector3(0.0, 18.2, 13.7)
	battle.camera.look_at(enemy.global_position + Vector3.UP * 0.85, Vector3.UP)
	await get_tree().physics_frame
	_build_phase_label()

	await _wait_for_enter("LIVE BATTLE RIG | STRAFE / AIM / FIRE")
	Engine.time_scale = 0.08
	enemy.take_damage(8.0, Vector3(1.8, 0.2, 0.0))
	await _wait_for_enter("HIT FLASH / REACTION / KNOCKBACK | SLOW MOTION")
	Engine.time_scale = 1.0
	enemy.take_damage(999.0, Vector3(2.0, 1.8, -1.2))
	Engine.time_scale = 0.22
	await _wait_for_enter("DEATH / RAGDOLL | SLOW MOTION")
	Engine.time_scale = 1.0
	await _wait_for_enter("AREA SECURE | EXTRACTION REQUIRED")
	var extraction_point := battle.find_child("ExtractionPoint", true, false) as ExtractionPoint
	if not extraction_point or not extraction_point.extract(battle.session):
		push_error("Visual enemy acceptance could not complete extraction")
		return
	await _wait_for_enter("EXTRACTION COMPLETE | CONTINUE TO RESULT")
	if DisplayServer.get_name() == "headless":
		await _finish_headless()
	else:
		GameState.finish_mission()


func _process(delta: float) -> void:
	if not is_instance_valid(enemy) or enemy.is_dead:
		return
	var aim_point := player.global_position + Vector3.UP * 1.05
	enemy.humanoid_visual.update_visual(aim_point, Vector3.LEFT, 1.2, delta)
	_fire_timer -= delta
	if _fire_timer <= 0.0 and not enemy._is_telegraphing:
		_fire_timer = 2.2
		enemy._telegraph_shot()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance_requested = true


func _wait_for_enter(title: String) -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.12).timeout
		return
	_advance_requested = false
	phase_label.text = "%s | ENTER" % title
	while not _advance_requested:
		await get_tree().process_frame


func _build_phase_label() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(346.0, 12.0)
	panel.size = Vector2(588.0, 38.0)
	panel.color = Color("101823e8")
	layer.add_child(panel)
	phase_label = Label.new()
	phase_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phase_label.add_theme_color_override("font_color", Color("ff7185"))
	phase_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(phase_label)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _finish_headless() -> void:
	# Complete the scripted visual smoke instead of leaving an Enter coroutine
	# suspended until --quit-after tears down its scene resources.
	set_process(false)
	battle.queue_free()
	await get_tree().process_frame
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	print("VISUAL_ENEMY_ACCEPTANCE: PASS (scripted smoke; no visual assertion)")
	get_tree().quit(0)
