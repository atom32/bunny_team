extends Node
const OUT := "/Users/xudawei/bunny_team/art_source/contact_portraits_v1_20261007/"
var failures := []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PORTRAIT ","PASS " if ok else "FAIL ",message)
	if not ok: failures.append(message)
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	GameLanguage.set_language("zh_CN",false)
	var profile := ProfileRuntime.new_profile()
	# Display fixture only: expose Q02/Q04 publisher avatars, no rewards or disk writes.
	profile.first_mission_completed = true
	profile.narrative_slice.settled.Q01 = true
	profile.narrative_slice.q01_exits = ["streets_exit_0","streets_exit_1"]
	check(profile.validate(),"presentation fixture remains valid")
	var base: Node3D = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(base)
	base.show_section("Workshop")
	await get_tree().create_timer(1.0).timeout
	var panel: ContactPanel = base.find_child("ContactPanel",true,false)
	for id: String in ContactDefinition.CONTACTS:
		var contact := ContactDefinition.get_contact(id)
		var pixels: Image = contact.portrait.get_image()
		check(pixels.get_pixel(0,0).a < .01,"generated portrait has genuine transparent alpha "+id)
		for tab in ["trade","quests"]:
			panel.open_contact(id,tab)
			await get_tree().create_timer(.5).timeout
			check(panel.get_global_rect().end.y < 644,"portrait page fits above base navigation "+id+"/"+tab)
			var portrait: ContactPortrait = panel.find_child("Portrait",true,false)
			check(portrait.get_child(0) is TextureRect and portrait.get_child(0).texture == contact.portrait,"UI renders actual generated image "+id+"/"+tab)
			if tab == "quests":
				for avatar in panel.find_children("*","ContactPortrait",true,false):
					if avatar.compact: check(avatar.get_child(0).texture is AtlasTexture,"publisher uses face crop from same portrait")
			await RenderingServer.frame_post_draw
			check(get_viewport().get_texture().get_image().save_png(OUT+"captures/"+id+"_"+tab+".png") == OK,"capture "+id+"/"+tab)
	await get_tree().process_frame
	base.free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("PORTRAIT_PROBE: ", "PASS" if failures.is_empty() else "FAIL", " / ", checks," / ",failures)
	await get_tree().create_timer(.3).timeout
	get_tree().quit(0 if failures.is_empty() else 1)
