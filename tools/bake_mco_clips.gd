extends SceneTree
## Bake animation-only resources; archive original FBXs under source/.gdignore afterwards.
func _initialize() -> void:
	for clip_name in ["W2_Stand_Relaxed_Idle_v2", "W2_Stand_Aim_Idle_v2", "W2_Stand_Aim_To_Relaxed", "W2_Walk_Aim_F_Loop", "W2_Jog_Aim_F_Loop", "W2_Walk_Aim_F_Loop_IPC", "W2_Jog_Aim_F_Loop_IPC"]:
		var path := "res://assets/animations/mocap_online_rifle/"
		var source_path: String = path + "source/" + clip_name + ".fbx"
		if not ResourceLoader.exists(source_path): source_path = path + clip_name + ".fbx"
		var scene := load(source_path).instantiate() as Node
		var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var clip := player.get_animation(player.get_animation_list()[0]).duplicate(true) as Animation
		var error := ResourceSaver.save(clip, path + clip_name + ".tres")
		print("BAKE / ", clip_name, " / ", error_string(error))
		scene.free()
	quit()
