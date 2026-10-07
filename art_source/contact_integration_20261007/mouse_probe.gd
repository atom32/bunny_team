extends Node
const OUT := "/Users/xudawei/bunny_team/art_source/contact_integration_20261007/"
var checks := 0
var failures := []
func check(ok: bool, message: String) -> void:
	checks += 1
	print("CONTACT_MOUSE ", "PASS " if ok else "FAIL ", message)
	if not ok: failures.append(message)
func _ready() -> void:
	_run.call_deferred()
func _click(button: Button) -> void:
	await get_tree().process_frame
	var pos := button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = pos
	get_viewport().push_input(move)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = pos
		event.global_position = pos
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event)
		await get_tree().process_frame
	await get_tree().create_timer(.2).timeout
func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OUT+"captures/"+name+".png") == OK, "screen capture "+name)
func _run() -> void:
	GameLanguage.set_language("zh_CN",false)
	var profile := ProfileRuntime.get_profile()
	check(profile.narrative_slice.settled.Q04, "load actual completed graphics-route profile")
	var base: Node3D = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(base)
	base.show_section("Overview")
	await get_tree().create_timer(1.0).timeout
	await _click(base.find_child("ContactsToggle",true,false))
	var panel: ContactPanel = base.find_child("ContactPanel",true,false)
	check(panel != null, "pointer opens base contact entry")
	for id: String in ContactDefinition.CONTACTS:
		await _click(panel.find_child("Contact_"+id,true,false))
		check(panel.contact_id == id, "pointer selects "+id)
		await _click(panel.find_child("ContactQuests",true,false))
		check(panel.selected_tab == "quests", "pointer opens quests "+id)
		await _capture("final_"+id+"_quests")
		await _click(panel.find_child("ContactTrade",true,false))
		check(panel.selected_tab == "trade", "pointer opens trade "+id)
		await _capture("final_"+id+"_trade")
	await _click(panel.find_child("Contact_tang_kui",true,false))
	var shop: SupplyPanel = panel.find_child("SupplyPanel",true,false)
	var buy: Button = shop.find_child("Supply_buy_medical_field_dressing",true,false)
	shop._scrolls["BUY SUPPLIES"].ensure_control_visible(buy)
	await get_tree().process_frame
	var before := SupplyService.count(profile,&"medical.field_dressing")
	var credits := profile.credits
	var old_ids := []
	for item in profile.inventory.get_items(): old_ids.append(item.instance_id)
	var price := SupplyService.buy_price(ContentDB.get_item(&"medical.field_dressing"),profile)
	await _click(buy)
	check(SupplyService.count(profile,&"medical.field_dressing") == before+1 and profile.credits == credits-price, "mouse purchase uses existing wallet/warehouse")
	var added: ItemInstance
	for item in profile.inventory.get_items():
		if item.instance_id not in old_ids: added = item
	var tabs: TabContainer = shop.find_children("*","TabContainer",true,false)[0]
	# Existing shop tab selection API only; the actual sell uses pointer input.
	tabs.current_tab = 1
	await get_tree().process_frame
	var sell: Button = shop.find_child("Supply_sell_"+added.instance_id,true,false)
	shop._scrolls["SELL RECOVERED"].ensure_control_visible(sell)
	await get_tree().process_frame
	var sale := SupplyService.sell_price(added)
	await _click(sell)
	check(SupplyService.count(profile,&"medical.field_dressing") == before and profile.credits == credits-price+sale, "mouse sale preserves original transaction semantics")
	check(SaveService.load_profile(SaveService.DEFAULT_SAVE_PATH,false).to_dict() == profile.to_dict(), "pointer trades publish exact durable state")
	await _click(panel.find_child("ContactQuests",true,false))
	# Presentation-only ready fixture; full real observation/submission route was verified separately.
	profile.narrative_slice.settled.Q04 = false
	profile.narrative_slice.q04.log = ""
	var quests: CampaignPanel = panel.find_child("CampaignPanel",true,false)
	quests._refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	var submit: Button = quests.find_child("SubmitQ04",true,false)
	var scroll: ScrollContainer = quests.get_child(0)
	check(not submit.disabled and scroll.get_global_rect().encloses(submit.get_global_rect()), "ready Q04 submit fits without scrolling at 720p")
	await _capture("final_q04_ready_layout")
	profile.narrative_slice.settled.Q04 = true
	profile.narrative_slice.q04.log = NarrativeSlice.Q04_LOG
	quests._refresh()
	check(quests.find_child("SubmitQ04",true,false) == null, "hard stop restored with no next action")
	get_viewport().gui_release_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	base.free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("CONTACT_MOUSE_PROBE: ", "PASS" if failures.is_empty() else "FAIL", " / ", checks, " / ", failures)
	await get_tree().create_timer(.3).timeout
	get_tree().quit(0 if failures.is_empty() else 1)
