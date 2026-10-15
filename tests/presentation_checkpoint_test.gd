extends Node3D
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func spawn(id: StringName) -> EnemyController:
	var actor := EnemySpawnService.spawn(ContentDB.get_enemy_definition(id), Transform3D.IDENTITY, self)
	actor.set_physics_process(false)
	return actor
func _ready() -> void:
	var definition := ContentDB.get_enemy_definition(&"campus_infected")
	var infected := spawn(&"campus_infected")
	var pmc := spawn(&"prototype_basic_enemy")
	await get_tree().process_frame
	# Force manual animation sampling so each saved pose is stable and non-rest.
	for actor in [infected, pmc]:
		actor.presentation.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		actor.presentation.animation_player.advance(.2)
	var current := SortieCheckpoint._firing_pose(infected)
	var human := SortieCheckpoint._firing_pose(pmc)
	check(current.bones.size() == 65 and human.bones.size() != 65, "Mixed infected/PMC rigs differ")
	check(SortieCheckpoint._valid_firing_pose(current,true,definition,true), "Independent infected bone schema accepted")
	check(SortieCheckpoint._valid_firing_pose(human,true,ContentDB.get_enemy_definition(&"prototype_basic_enemy")), "Original PMC schema accepted independently")
	var corrupt: Dictionary = current.duplicate(true); corrupt.bones.erase("pelvis")
	check(not SortieCheckpoint._valid_firing_pose(corrupt,true,definition,true), "Incomplete new bone schema rejected")
	corrupt = current.duplicate(true); corrupt.bones["foreign"] = corrupt.bones["pelvis"]
	check(not SortieCheckpoint._valid_firing_pose(corrupt,true,definition,true), "Foreign bone schema rejected")
	infected.presentation.play_hit(); infected.presentation.animation_player.advance(.1)
	check(SortieCheckpoint._valid_firing_pose(SortieCheckpoint._firing_pose(infected),true,definition,true), "Hit reaction checkpoint accepted")
	SortieCheckpoint._restore_firing_pose(current,infected)
	check(JSON.stringify(SortieCheckpoint._firing_pose(infected).bones) == JSON.stringify(current.bones), "New sampled bone pose roundtrips exactly")
	# Build a real legacy presentation, not a fabricated dictionary of bone names.
	infected.presentation.use_legacy_model()
	infected.presentation.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	infected.presentation.fire_recoil(); infected.presentation.animation_player.advance(.21)
	var legacy := SortieCheckpoint._firing_pose(infected)
	check(SortieCheckpoint._valid_firing_pose(legacy,true,definition,true), "Old suspended infected pose remains readable without schema bump")
	corrupt = legacy.duplicate(true); corrupt.clip = "Hit_Chest"
	check(not SortieCheckpoint._valid_firing_pose(corrupt,true,definition,true), "New-only hit clip cannot be replayed on a legacy rig")
	var custom := definition.duplicate() as EnemyDefinition
	custom.presentation_profile = definition.presentation_profile.duplicate() as PresentationProfile
	custom.presentation_profile.semantic_clips = definition.presentation_profile.semantic_clips.duplicate()
	custom.presentation_profile.semantic_clips[&"idle"] = &"Standing"
	check(not SortieCheckpoint._valid_firing_pose(current,true,custom,true), "New rig clips must match the current semantic profile, not legacy aliases")
	var fresh := spawn(&"campus_infected")
	await get_tree().process_frame
	SortieCheckpoint._restore_firing_pose(legacy,fresh)
	check(fresh.presentation.legacy_mode and fresh.presentation.pistol != null and not fresh.presentation.pistol.visible, "Old saved infected retains its exact legacy unarmed rig")
	check(JSON.stringify(SortieCheckpoint._firing_pose(fresh).bones) == JSON.stringify(legacy.bones), "Actual old sampled poses restore exactly")
	for actor in [infected,pmc,fresh]: actor.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("PRESENTATION_CHECKPOINT_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
