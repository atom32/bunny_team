extends Node
## Explicit whole-room camera fixtures; not movement or entrance evidence.
const Spaces := preload("res://scripts/world/geography/campus_spaces.gd")
func _ready() -> void:
	await get_tree().process_frame
	var survey:=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	survey.fieldwork_path="user://spaces_visual_fixture_unused.json";add_child(survey)
	survey.toggle_walking();survey.screen.hide();survey.set_process(false)
	var field: Node3D=survey.fieldwork
	for id: String in Spaces.ROOMS:
		field._show_room(id)
		var room: Node3D=field.rooms[id]
		var center: Vector3=room.position+Vector3.UP*.5
		survey.camera.position=center+Vector3(0,sin(1.10),cos(1.10))*34
		survey.camera.look_at(center)
		for frame in 14:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var destination:=OS.get_environment("BUNNY_EVIDENCE").path_join("overview_"+id+".png")
		get_viewport().get_texture().get_image().save_png(destination)
		print("SPACE OVERVIEW ",id)
	print("CAMPUS SPACES PROBE: ",Spaces.ROOMS.size()," rendered design areas; camera fixtures only")
	get_tree().quit()
