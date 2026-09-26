extends SceneTree
## Deterministic regression for the separately authorized coroutine lifecycle guard.
## Detached-but-still-valid references reproduce the scene-replacement boundary.
var checks := {}
var flashes := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for scenario in ["active", "enemy_detached", "target_detached", "both_detached"]:
		var world := Node3D.new()
		root.add_child(world)
		current_scene=world
		var player = load("res://scenes/player/player.tscn").instantiate()
		player.preview_mode=true
		world.add_child(player)
		player.position=Vector3(0,0,-8)
		var enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		world.add_child(enemy)
		enemy.set_physics_process(false)
		await process_frame
		await process_frame
		enemy.target=player
		flashes=0
		world.child_entered_tree.connect(func(node: Node):
			if str(node.name).begins_with("MuzzleFlash"): flashes+=1)
		enemy._telegraph_shot()
		checks[scenario+"_shot_pending"] = enemy._is_telegraphing
		if scenario in ["enemy_detached","both_detached"]: world.remove_child(enemy)
		if scenario in ["target_detached","both_detached"]: world.remove_child(player)
		await create_timer(.45).timeout
		checks[scenario+"_callback_completed"] = not enemy._is_telegraphing
		checks[scenario+"_correct_fire_count"] = flashes==(1 if scenario=="active" else 0)
		checks[scenario+"_aim_cleared"] = enemy._shot_aim_point==Vector3.ZERO
		if not enemy.is_inside_tree(): enemy.free()
		if not player.is_inside_tree(): player.free()
		world.queue_free()
		await process_frame
		await process_frame
	var path := OS.get_environment("BUNNY_EVIDENCE").path_join("lifecycle_probe.json")
	var f := FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"scope":"Only scene membership after the existing 0.38 s await. Active shot still fires; detached actor/target/both cancel cleanly."},"  "))
	print(checks)
	root.get_node("AudioDirector").shutdown_for_test()
	quit(1 if checks.values().has(false) else 0)
