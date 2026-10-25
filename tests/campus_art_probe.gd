extends Node
## Same metric cameras before/after. Synthetic view fixtures, not playthroughs.
var survey: Node3D
var evidence:=OS.get_environment("BUNNY_EVIDENCE")
var shots:=[]

func shot(label: String, point: Vector2, distance: float, yaw: float, pitch: float) -> void:
	survey.focus=survey.geo.at3(point,2.5)
	survey.target_focus=survey.focus
	survey.distance=distance
	survey.target_distance=distance
	survey.yaw=yaw
	survey.pitch=pitch
	survey._update_camera(0)
	for i in 18:await get_tree().process_frame
	if not evidence.is_empty() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(evidence.path_join(label+".png"))
	shots.append({"name":label,"point":[point.x,point.y],"distance":distance,"yaw":yaw,"pitch":pitch,"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})

func _ready() -> void:
	await get_tree().process_frame
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	add_child(survey)
	survey.screen.hide()
	for i in 10:await get_tree().process_frame
	await shot("overview",Vector2(0,0),1550,0,1.05)
	await shot("main_hall",Vector2(332,82),84,-.27,.60)
	await shot("library",Vector2(141,111),88,.5,.64)
	await shot("youth_lake",Vector2(258,-150),100,.7,.72)
	await shot("jingye_lake",Vector2(95,235),100,-.3,.75)
	await shot("dormitory",Vector2(-101,-343),76,.25,.65)
	await shot("east_gate",Vector2(652,230),65,-.3,.64)
	await shot("street_gameplay",Vector2(290,94),27,0,1.0)
	await shot("foliage_detail",Vector2(304,-180),32,-.65,.60)
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("camera_fixtures.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(shots,"  "))
	print("CAMPUS ART PROBE: ",shots.size()," actual camera captures")
	get_tree().quit()
