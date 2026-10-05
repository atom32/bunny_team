extends Node
## Preview-only idle must never change the equipped loadout or combat actor.
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	var profile := ProfileRuntime.new_profile()
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hub)
	# Existing base UI initializes stash layout synchronously before idle playback.
	var before := JSON.stringify(profile.to_dict())
	await get_tree().process_frame
	await get_tree().process_frame
	var player: PlayerController = hub.hanger.preview_character
	var preview = hub.relaxed_preview
	check(preview.enabled and not player.is_processing(), "base idle owns preview playback, not combat update")
	check(not player.animation_tree.active and not player.retarget_modifier.active, "combat retarget cannot overwrite authored idle")
	check(not player.combat_rig.visible, "off-duty presentation has no floating combat weapon")
	check(hub.has_node("CompactEnvironment/RestSeat"), "compact imported environment has authored physical rest seat")
	check(player.position.is_equal_approx(hub.STANDING_ANCHOR), "base preview uses floor-level compact room anchor")
	var equipment_position := player.position
	var hip_position := player.character_skeleton.get_bone_pose_position(player.character_skeleton.find_bone("Character1_Hips"))
	var bone := player.character_skeleton.find_bone("Character1_LeftArm")
	var first := player.character_skeleton.get_bone_pose_rotation(bone)
	preview._process(2.0)
	var second := player.character_skeleton.get_bone_pose_rotation(bone)
	check(first.angle_to(second) > 0.0001, "real clip plays rather than freezing a pose")
	for index in player.character_skeleton.get_bone_count():
		check(player.character_skeleton.get_bone_pose_scale(index).is_equal_approx(Vector3.ONE), "idle must not rescale bones")
	var rotation := player.body_visual.rotation.y
	preview._process(0.5)
	check(is_equal_approx(rotation, player.body_visual.rotation.y), "base character does not spin like a turntable")
	hub.show_section("Hanger")
	await get_tree().process_frame
	await get_tree().process_frame
	check(player.position.is_equal_approx(equipment_position), "equipment preview original position restored")
	check(not preview.enabled and player.is_processing(), "equipment inspection restores existing preview")
	check(player.animation_tree.active and player.retarget_modifier.active and player.combat_rig.visible, "weapon animation and retarget restored")
	hub.show_section("Rest")
	await get_tree().process_frame
	check(preview.enabled and preview.seated, "personal area uses sourced sitting state")
	preview._process(0.1)
	check(is_equal_approx(player.position.x,hub.SEAT_ANCHOR.x) and player.position.y < 0.0, "authored sitting height transferred at seat")
	check(preview.semantics.size() == 52, "body and authored fingers mapped")
	var hips := player.character_skeleton.find_bone("Character1_Hips")
	check(player.character_skeleton.get_bone_pose_position(hips).is_equal_approx(hip_position), "presentation height does not change local skeletal translation")
	hub.show_section("Overview")
	await get_tree().process_frame
	preview._process(0.1)
	check(not preview.seated and player.position.is_equal_approx(equipment_position), "leaving rest restores standing location")
	hub.show_section("Rest")
	await get_tree().process_frame
	hub.hanger._build_preview_character(profile.inventory,profile.loadout)
	await get_tree().process_frame
	await get_tree().process_frame
	check(preview.actor == hub.hanger.preview_character and preview.enabled, "equipment rebuild binds replacement preview safely")
	preview._process(0.1)
	check(preview.seated and is_equal_approx(preview.actor.position.x,hub.SEAT_ANCHOR.x), "replacement preview retains seated section")
	hub.show_section("Hanger")
	await get_tree().process_frame
	check(preview.actor.position.is_equal_approx(equipment_position), "rebuilt equipment preview restores location")
	check(JSON.stringify(profile.to_dict()) == before, "preview leaves inventory, identity and save data unchanged")
	hub.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("HIDEOUT_IDLE_TEST: ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)

