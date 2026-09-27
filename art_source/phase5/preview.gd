extends SceneTree
var out := OS.get_environment("BUNNY_EVIDENCE")
func _initialize() -> void:
	_run.call_deferred()
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(label+".png"))
func _run() -> void:
	root.size = Vector2i(1280,720)
	change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await create_timer(0.7).timeout
	await capture("01_opening")
	current_scene.show_menu()
	await capture("02_menu")
	current_scene._settings()
	await capture("03_settings")
	current_scene._enter()
	await create_timer(1.8).timeout
	await capture("04_hideout")
	for region in ["Hanger","Workshop","Rest","Operations"]:
		current_scene.show_section(region)
		await create_timer(0.85).timeout
		await capture("05_"+region)
	current_scene._deploy()
	await create_timer(2.0).timeout
	await capture("06_deployment")
	await create_timer(5.0).timeout
	await capture("07_arrival")
	await create_timer(2.0).timeout
	await capture("08_arena")
	root.get_node("AudioDirector").shutdown_for_test()
	quit()
