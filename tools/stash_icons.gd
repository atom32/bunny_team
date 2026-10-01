extends Node
## Bake inventory thumbnails from the actual equipped models, with no runtime 3D cost.
func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384, 192)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0, 0, 0, 0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d5e2ec")
	environment.environment.ambient_light_energy = 0.8
	viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28, -35, 0)
	key.light_energy = 2.0
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20, 125, 0)
	fill.light_energy = 1.1
	viewport.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	viewport.add_child(camera)
	for definition in ContentDB.get_items():
		if not definition is EquipmentDefinition or not definition.scene: continue
		var model := definition.scene.instantiate() as Node3D
		if definition is WeaponDefinition: model.rotation_degrees.y = -82
		viewport.add_child(model)
		await get_tree().process_frame
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if not mesh.visible or mesh.name == "MuzzleFlash": continue
			var box := mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		var center := bounds.get_center()
		camera.position = center + Vector3(0, 0, maxf(bounds.size.length() * 2, 2))
		camera.look_at(center)
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.size = maxf(bounds.size.y, bounds.size.x / 2) * 1.2
		for frame in 5: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var name_key := String(definition.id).get_slice(".", 1)
		var path := "res://assets/ui/stash/" + name_key + ".png"
		var image := viewport.get_texture().get_image()
		var used := image.get_used_rect().grow(3).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		image.get_region(used).save_png(path)
		print("ICON / ", path)
		model.free()
	AudioDirector.shutdown_for_test()
	get_tree().quit()
