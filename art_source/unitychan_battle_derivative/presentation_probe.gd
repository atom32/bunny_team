extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/hanger/hanger.tscn")
	await create_timer(1.0).timeout
	var player = current_scene.preview_character
	var report := {"method": "automated graphics/API; production Hanger camera", "weapons": [], "mounts": {}, "animations": []}
	var compatible := true
	for socket in ["Chest", "ShoulderL", "ShoulderR", "Backpack", "HipL", "HipR", "HandL", "HandR"]:
		report.mounts[socket] = player.find_child(socket, true, false) != null
		compatible = compatible and report.mounts[socket]
	report.animations = Array(player.animation_player.get_animation_list())
	for id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
		player.equip_weapon(root.get_node("ContentDB").get_weapon(id))
		await create_timer(0.8).timeout
		var row := {"id": String(id), "right_grip_error_m": player.combat_rig.get_hand_error(&"right"), "left_grip_error_m": player.combat_rig.get_hand_error(&"left")}
		report.weapons.append(row)
		compatible = compatible and row.right_grip_error_m < 0.01 and row.left_grip_error_m < 0.01
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE") + "/" + String(id) + ".png")
	var f := FileAccess.open(OS.get_environment("BUNNY_EVIDENCE") + "/presentation_probe.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	print("PRESENTATION_PROBE: ", "PASS" if compatible else "FAIL", " (all mounts and both grips < 1 cm; NOT visual acceptance)")
	quit(0 if compatible else 1)
