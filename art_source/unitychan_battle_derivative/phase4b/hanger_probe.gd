extends SceneTree
var dir := OS.get_environment("BUNNY_PHASE4B")
func _initialize():run.call_deferred()
func run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(2).timeout
 await load(dir.path_join("paired_capture.gd")).capture(self,current_scene.preview_character,dir.path_join("hanger"),"hanger")
 root.get_node("AudioDirector").shutdown_for_test()
 quit()
