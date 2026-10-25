extends Node
## Inspect all four source-named signs at actual world placements, not mockups.
func _ready() -> void:
	await get_tree().process_frame
	var survey:=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	add_child(survey)
	survey.set_process(false)
	survey.screen.hide()
	var count:=0
	var directory:=OS.get_environment("BUNNY_EVIDENCE")
	for sign: Label3D in survey.get_node("WeijinGeographicWorld").find_children("LakeWayfinding*","Label3D",false,false):
		var front: Vector3=sign.global_basis.z.normalized()
		survey.camera.position=sign.global_position+front*5.5+Vector3.UP*1.25
		survey.camera.look_at(sign.global_position-Vector3.UP*.25)
		for i in 15:await get_tree().process_frame
		if not directory.is_empty() and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory.path_join("sign_%d.png"%count))
		count+=1
	print("CAMPUS SIGN PROBE: ",count," actual sign views")
	get_tree().quit(0 if count==4 else 1)
