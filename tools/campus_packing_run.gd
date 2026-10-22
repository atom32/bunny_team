extends "res://tests/normal_start_test.gd"
## Only accepts an external copy of the actual player's 35/60 base save.
## Normal BOOT/buttons/store transaction; no fixture stock or progression writes.

func _ready() -> void:
	get_tree().create_timer(180.0,true).timeout.connect(func():check(false,"actual packing route deadline");_finish())
	_run.call_deferred()

func _capture(name: String) -> void:
	if DisplayServer.get_name()!="headless":
		var hub:=tree.current_scene
		var deadline:=Time.get_ticks_msec()+10000
		while Time.get_ticks_msec()<deadline and (hub.camera.position.distance_to(hub.section_camera_position)>.03 or hub.relaxed_preview.phase!="idle"):
			await tree.process_frame
		check(hub.camera.position.distance_to(hub.section_camera_position)<.03 and hub.relaxed_preview.phase=="idle","normal base camera settled before capture")
	await super._capture(name)

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	if "--english" in OS.get_cmdline_user_args():check(GameLanguage.set_language("en",true)==OK,"persist English only in isolated test preferences before BOOT reads it")
	var profile:=ProfileRuntime.get_profile()
	var reading:="--read-packed" in OS.get_cmdline_user_args()
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.validate() and profile.sortie_checkpoint.is_empty(),"load actual external base profile without recovery")
	check(CampusChapter.stage(profile.campus_chapter)=="supply" and profile.campus_chapter.delivered_armor and profile.campus_chapter.delivered_ammo==(60 if reading else 35),"actual input has expected partial or normally packed supplies")
	if not failures.is_empty():_finish();return
	evidence["method"]="External unedited actual player save copied to isolated userdata. Normal BOOT/Continue, request shortcut, normal stock purchase, return and partial submission. No field sortie or human acceptance claimed."
	evidence["profile_input"]=profile.to_dict()
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):_finish();return
	evidence["language"]=TranslationServer.get_locale()
	if "--english" in OS.get_cmdline_user_args():check(TranslationServer.get_locale()=="en","actual post-BOOT UI is English, not merely an English test flag")
	var before:=profile.to_dict()
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _click(tree.current_scene.screen.find_child("RequestDetails",true,false))
	var contact:=tree.current_scene.screen.get_node("ContactPanel") as ContactPanel
	if reading:
		check(contact.find_child("GoCampusSupplyShop",true,false)==null and contact.find_child("SubmitCampusEquipment",true,false).disabled,"independent BOOT retains packed state and forbids second payment")
		check(profile.to_dict()==before and not profile.campus_chapter.finished,"independent read invents no receipt, extraction, inventory or reward")
		evidence["profile_after"]=profile.to_dict();_finish();return
	check(CampusChapter.delivery_shortage(profile)=={"armor":0,"ammo":25},"actual blocker is 25 standard warehouse rounds, not another armor")
	await _capture("01_partial_delivery")
	await _click(contact.find_child("GoCampusSupplyShop",true,false))
	var buy:=contact.find_child("Supply_buy_ammo_556_standard",true,false) as Button
	check((buy.get_parent().get_child(2) as SpinBox).value==25 and buy.text==(tr("BUY / %d") % 75),"actual normal store offers the missing 25 at unchanged price")
	check(profile.to_dict()==before,"navigating to shop never auto-buys or auto-submits")
	await _capture("02_missing_stock_pinned")
	await _click(buy)
	check(profile.credits==before.credits-75 and SupplyService.count(profile,&"ammo.556_standard")==25,"ordinary purchase charges 75 credits and creates only 25 rounds")
	await _click(contact.find_child("BackToCampusPacking",true,false))
	await _click(contact.find_child("SubmitCampusEquipment",true,false))
	check(profile.campus_chapter.delivered_armor and profile.campus_chapter.delivered_ammo==60 and not profile.campus_chapter.finished,"ordinary submission packs remaining rounds but does not fabricate field handoff")
	check(profile.inventory.to_dict()==before.inventory and profile.loadout.to_dict()==before.loadout and profile.ammo_pack==before.ammo_pack,"buy then pack leaves original owned items, loadout and deployment plan unchanged")
	check(profile.successful_sorties==before.successful_sorties and profile.failed_sorties==before.failed_sorties,"no invented sortie or rewards")
	await _capture("03_packed_next_dormitory")
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	check(tree.current_scene.find_child("RequestDetails",true,false).text==tr("VIEW DORMITORY HANDOFF / SHEN"),"base now shows the real next field action")
	await _capture("04_next_field_action")
	evidence["profile_after"]=profile.to_dict();_finish()
