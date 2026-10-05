extends SceneTree
func _initialize(): run.call_deferred()
func run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(1).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OS.get_environment("BUNNY_CAPTURE"))
 root.get_node("AudioDirector").shutdown_for_test()
 quit()
