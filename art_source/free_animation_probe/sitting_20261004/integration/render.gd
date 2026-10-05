extends SceneTree
func _initialize(): run.call_deferred()
func capture(hub, name):
    await create_timer(1.0).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))
    print("CAPTURE ",name," actor_position=",hub.hanger.preview_character.position)
func run():
    root.get_node("ProfileRuntime").new_profile()
    var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
    hub.menu_backdrop = true
    root.add_child(hub)
    await capture(hub,"menu")
    hub.queue_free()
    await process_frame
    hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
    root.add_child(hub)
    await capture(hub,"overview")
    hub.show_section("Rest")
    await capture(hub,"rest")
    hub.show_section("Hanger")
    await capture(hub,"equipment")
    root.get_node("AudioDirector").shutdown_for_test()
    quit()
