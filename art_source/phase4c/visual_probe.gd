extends SceneTree
var folder := OS.get_environment("BUNNY_EVIDENCE")
var world: Node3D
var camera: Camera3D
var results := {}

func _initialize() -> void:
	_run.call_deferred()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(label+".png"))

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	VisualFactory.add_world_environment(world, Color("1c262f"))
	VisualFactory.box(world, Vector3(14,.1,10), Vector3(0,-.06,0), Color("323e47"))
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(3.4,2.7,4.0)
	camera.look_at(Vector3(0,.4,0))
	camera.fov = 37
	camera.current = true
	var old_barrier := VisualFactory.box(world,Vector3(2.8,.9,.58),Vector3(0,.45,0),Color("85847d"))
	var barrier = load("res://scenes/presentation/urban_defense/security_barrier.tscn").instantiate()
	world.add_child(barrier)
	barrier.visible = false
	await create_timer(.4).timeout
	await _capture("barrier_before")
	old_barrier.hide()
	barrier.show()
	await _capture("barrier_after")
	var before = load(folder.path_join("before/combat_effects.gd"))
	for version in ["before", "after"]:
		var fx = before if version=="before" else CombatEffects
		for effect in ["muzzle", "impact", "death", "dodge", "rocket"]:
			var effects := Node3D.new()
			world.add_child(effects)
			seed(1248)
			match effect:
				"muzzle": fx.muzzle_flash(effects,Vector3(-.65,1.15,.7),Vector3.RIGHT,Color("fbc77d"),1.0)
				"impact": fx.hit(effects,Vector3(.3,.7,.65),Color("fff1cf"),1.0)
				"death": fx.hit(effects,Vector3(.3,.7,.65),Color("ff6b55"),1.65)
				"dodge": fx.dodge_pulse(effects,Vector3(0,.08,1.2),Vector3.RIGHT)
				"rocket":
					fx.explosion(effects,Vector3(.3,.7,.65),1.25)
					fx.rocket_trail(effects,Vector3(-.65,1.15,.7))
			results[version+"_"+effect+"_next_rng"] = randf()
			# Sample both versions at exactly 20 ms, independent of shader warm-up.
			var tweens := get_processed_tweens()
			for tween in tweens:
				tween.pause()
				tween.custom_step(.02)
			await _capture(version+"_"+effect)
			for tween in tweens:
				tween.play()
			await create_timer(.65).timeout
			results[version+"_"+effect+"_cleanup"] = effects.get_child_count()==0
			effects.queue_free()
			await process_frame
	for effect in ["muzzle", "impact", "death", "dodge", "rocket"]:
		results[effect+"_rng_unchanged"] = results["before_"+effect+"_next_rng"]==results["after_"+effect+"_next_rng"]
	var f := FileAccess.open(folder.path_join("visual_probe.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(results,"  "))
	root.get_node("AudioDirector").shutdown_for_test()
	quit()
