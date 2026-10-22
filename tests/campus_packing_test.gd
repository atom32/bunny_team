extends "res://tests/sortie_guidance_test.gd"
## Controlled progression/inventory fixture; not an earned playthrough.

func packing_profile() -> ProfileState:
	var profile:=profile_at("supply")
	profile.campus_chapter.delivered_armor=true;profile.campus_chapter.delivered_ammo=35
	profile.ammo_pack["ammo.556_standard"]=82
	for item in profile.inventory.get_items():
		if item.definition_id==&"ammo.556_standard":profile.inventory.remove_item(item.instance_id)
	return profile

func _run() -> void:
	await frames()
	for language in ["en","zh_CN"]:
		GameLanguage.set_language(language,false)
		var profile:=packing_profile()
		check(profile.validate(),"valid partial-packing fixture")
		var before:=profile.to_dict()
		check(CampusChapter.delivery_shortage(profile)=={"armor":0,"ammo":25},"35/60 means 25 warehouse rounds missing; an 82-round deployment plan adds no stock")
		check(profile.to_dict()==before,"shortage calculation never writes inventory, preferences or progression")
		profile.campus_chapter.delivered_armor=false
		check(CampusChapter.delivery_shortage(profile).armor==1,"worn armor is not a usable spare")
		var spare:=ItemInstance.new(&"armor.bulwark_plate_01");spare.durability=49;profile.inventory.add_item(spare)
		check(CampusChapter.delivery_shortage(profile).armor==1,"damaged spare below 50 does not satisfy delivery")
		spare.durability=50
		check(CampusChapter.delivery_shortage(profile).armor==0,"unequipped heavy armor at exactly 50 is usable")
		profile.inventory.add_item(ItemInstance.new(&"ammo.556_ap",60))
		check(CampusChapter.delivery_shortage(profile).ammo==25,"AP and existing 9mm are not standard 5.56")
		profile.inventory.add_item(ItemInstance.new(&"ammo.556_standard",10))
		check(CampusChapter.delivery_shortage(profile).ammo==15,"warehouse standard rounds reduce actual shortage")
		profile.inventory.add_item(ItemInstance.new(&"ammo.556_standard",30))
		check(CampusChapter.delivery_shortage(profile).ammo==0,"enough warehouse rounds never produce a negative shortage")
		profile=packing_profile()
		var hub=load("res://scenes/presentation/slice/hideout.tscn").instantiate();add_child(hub)
		hub.show_section("Operations");await frames()
		before=profile.to_dict()
		var shortcut:=hub.screen.find_child("RequestDetails",true,false) as Button
		check(shortcut.text==tr("PACK EQUIPMENT / SHEN"),"operations names the actual next packing action")
		await click(shortcut)
		var contact:=hub.screen.get_node("ContactPanel") as ContactPanel
		var card:=contact.find_child("CampusPackingCard",true,false) as Control
		var scroll:=card.get_parent().get_parent() as ScrollContainer
		if not scroll.get_global_rect().encloses(card.get_global_rect()):print("PACKING_LAYOUT_DIAGNOSTIC ",language," card=",card.get_global_rect()," scroll=",scroll.get_global_rect()," min=",card.get_combined_minimum_size())
		check(contact.contact_id=="shen_yanshuang" and contact.selected_tab=="quests" and card!=null,"shortcut opens owning contact and actual packing card")
		check(scroll.scroll_vertical==0 and scroll.get_global_rect().encloses(card.get_global_rect()),"active packing card and both actions fit before the long recorder archive")
		check(card.find_child("CampusPackingShortage",true,false).text==(tr("MISSING FROM WAREHOUSE / spare armor %d / standard 5.56 %d rounds") % [0,25]),"both languages show exact missing warehouse stock")
		var submit:=card.find_child("SubmitCampusEquipment",true,false) as Button
		check(submit.disabled,"no warehouse supplies means no accidental empty hand-in")
		await capture("packing_request_"+language,hub)
		await click(card.find_child("GoCampusSupplyShop",true,false))
		var shop:=contact.find_child("SupplyPanel",true,false) as SupplyPanel
		var buy:=shop.find_child("Supply_buy_ammo_556_standard",true,false) as Button
		var quantity:=buy.get_parent().get_child(2) as SpinBox
		check(shop.campus_delivery_mode and quantity.value==25 and buy.text==(tr("BUY / %d") % 75),"normal shop pre-fills only missing 25 rounds at the normal 75-credit price")
		var shop_scroll:=buy.get_parent().get_parent().get_parent() as ScrollContainer
		check(shop_scroll.scroll_vertical==0 and shop_scroll.get_global_rect().encloses(buy.get_global_rect()),"missing ammunition is visible at the top without searching the catalog")
		var back:=shop.find_child("BackToCampusPacking",true,false) as Button
		check(contact.get_global_rect().encloses(back.get_global_rect()),"return-to-packing action fits actual contact panel")
		await capture("packing_shop_"+language,hub)
		await click(back)
		check(contact.selected_tab=="quests" and profile.to_dict()==before,"opening shop and returning neither buys nor hands in anything")
		profile.campus_chapter.delivered_ammo=60
		contact.open_contact("shen_yanshuang","quests");await frames()
		card=contact.find_child("CampusPackingCard",true,false)
		check(card.find_child("GoCampusSupplyShop",true,false)==null and card.find_child("SubmitCampusEquipment",true,false).disabled,"packed state does not request a second purchase or payment")
		var bindings:=ControlBindings.current.duplicate();bindings.interact=KEY_K;ControlBindings._publish(bindings)
		contact.open_contact("shen_yanshuang","quests");await frames()
		var directions:=false
		for label in contact.find_children("*","Label",true,false):
			if label.text==(tr("NEXT / Deploy to campus. Clear the two gunmen at the dormitory south window, press %s to send the crate inside, then extract.") % "K"):directions=true
		check(directions,"packed instructions use the rebound interact key, not hardcoded E")
		ControlBindings._publish(ControlBindings.defaults)
		hub.show_section("Operations");await frames()
		check(hub.screen.find_child("RequestDetails",true,false).text==tr("VIEW DORMITORY HANDOFF / SHEN"),"packed base points to field handoff without claiming chapter completion")
		check(not profile.campus_chapter.finished,"guidance never fabricates the field receipt or extraction")
		hub.free();await frames()
	AudioDirector.shutdown_for_test()
	print("CAMPUS_PACKING_TEST: %s (%d checks; controlled fixtures, not earned gameplay)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
