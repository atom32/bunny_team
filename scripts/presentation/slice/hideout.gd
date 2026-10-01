extends Node3D
## Hanger remains the loadout owner; the hub adds rooms and camera destinations only.
@export var menu_backdrop := false
const KIT := "res://assets/environment/kenney_space_station_kit/"
var hanger: Node3D
var camera: Camera3D
var ui: CanvasLayer
var screen: Control
var section := "Overview"
var camera_tween: Tween
var elapsed := 0.0

func _ready() -> void:
	hanger = load("res://scenes/hanger/hanger.tscn").instantiate()
	add_child(hanger)
	hanger.hanger_ui.hide()
	hanger.hanger_ui.deploy_requested.disconnect(hanger._on_deploy_requested)
	hanger.hanger_ui.deploy_requested.connect(func(): show_section("Operations"))
	for button in hanger.hanger_ui.find_children("*", "Button", true, false):
		if button.text == "DEPLOY":
			button.text = "MISSION TERMINAL"
			# Keep the existing equipment panel clear of the hub navigation bar.
			var equipment_panel := button.get_parent().get_parent() as Control
			equipment_panel.position.y -= 32.0
	camera = hanger.get_node("PreviewCamera")
	_build_rooms()
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	screen = SliceUI.root(ui)
	if menu_backdrop:
		for room in get_children():
			if room.has_meta("hub_section") or room is Label3D: room.hide()
		camera.position = Vector3(-5.2, 2.7, 6.1)
		camera.look_at(Vector3(-2.2, 1.35, 0.0))
		return
	GameState.presentation_enabled = true
	AudioDirector.set_music_context(&"hideout")
	AudioDirector.play_sfx(&"ui_confirm", -4)
	show_section(GameState.hideout_section)
	GameLanguage.language_changed.connect(func(): show_section(section))
	GameState.hideout_section = "Overview"

func _process(delta: float) -> void:
	elapsed += delta
	if menu_backdrop:
		camera.position.x = -5.2 + sin(elapsed * 0.13) * 0.35
		camera.look_at(Vector3(-2.2, 1.35, 0.0))

func _build_rooms() -> void:
	for row in [[Vector3(-16,0,0),"02 / WORKSHOP"], [Vector3(14,0,-2),"03 / OPERATIONS"], [Vector3(14,0,9),"04 / PERSONAL QUARTERS"]]:
		var room := Node3D.new()
		room.set_meta("hub_section", "Operations" if row[1].contains("OPERATIONS") else ("Workshop" if row[1].contains("WORKSHOP") else "Rest"))
		room.position = row[0]
		add_child(room)
		VisualFactory.box(room, Vector3(10,0.2,9), Vector3(0,-0.1,0), Color("293b49"), "RoomFloor")
		VisualFactory.box(room, Vector3(10,3,0.25), Vector3(0,1.5,-4.5), Color("1b2d3d"), "RoomWall")
		SliceUI.sign(room, row[1], Vector3(0,2.6,-4.3))
		for x in [-4,4]:
			SliceUI.prop(room, KIT+"container-tall.glb", Vector3(x,0,-3.6), 1.4)
		SliceUI.prop(room, KIT+"table.glb", Vector3(0,0,-2), 1.5)
		SliceUI.prop(room, KIT+"chair.glb", Vector3(0,0,0), 1.4)
		if row[1].contains("OPERATIONS"):
			SliceUI.prop(room, KIT+"computer-screen.glb", Vector3(0,1.0,-2), 2.2)
			SliceUI.sign(room, "DISTRICT 07\nFIELD OFFICE / SIGNAL RECOVERY", Vector3(0,1.7,-4.2), Color("f5c887"))
		elif row[1].contains("WORKSHOP"):
			SliceUI.prop(room, "res://scenes/presentation/service_props/maintenance_cluster.tscn", Vector3(0,0,2), 0.8)
		else:
			VisualFactory.box(room, Vector3(2.2,0.45,1), Vector3(-2,0.3,2), Color("718491"), "Bunk")
			VisualFactory.box(room, Vector3(0.45,0.15,0.8), Vector3(-2.7,0.6,2), Color("b7c6cc"), "Pillow")
			SliceUI.sign(room, "KOHAKU / ON STANDBY", Vector3(0,1.5,-4.2), Color("f5c887"))
	VisualFactory.box(self, Vector3(42,0.12,3), Vector3(0,-0.1,5), Color("344b56"), "ConnectingWalkway")
	SliceUI.sign(self, "01 / HANGER", Vector3(-2.2,3.4,-4.7))

func show_section(value: String) -> void:
	section = value
	for room in get_children():
		if room.has_meta("hub_section"): room.visible = value == "Overview" or value == room.get_meta("hub_section")
		elif room is Label3D: room.visible = value == "Overview"
	for child in screen.get_children():
		screen.remove_child(child)
		child.queue_free()
	hanger.hanger_ui.visible = value == "Hanger"
	var destination := Vector3(0,26,39)
	var focus := Vector3(0,0,2)
	if value == "Hanger":
		destination = Vector3(-2.2,2.45,5.25)
		focus = Vector3(-2.2,1.15,0)
	elif value == "Operations":
		destination = Vector3(10,7,9)
		focus = Vector3(14,0.8,-3)
	elif value == "Workshop":
		destination = Vector3(-20,6,10)
		focus = Vector3(-16,0.8,-1)
	elif value == "Rest":
		destination = Vector3(9,7,19)
		focus = Vector3(14,0.8,9)
	if camera_tween and camera_tween.is_valid(): camera_tween.kill()
	camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	camera_tween.tween_property(camera, "position", destination, 0.65)
	var target_basis := Transform3D(Basis.IDENTITY, destination).looking_at(focus).basis
	camera_tween.tween_property(camera, "quaternion", target_basis.get_rotation_quaternion(), 0.65)
	if value != "Hanger":
		SliceUI.label(screen, "BASTION 07  /  HIDEOUT", Vector2(42,30), 30)
		SliceUI.label(screen, "HOME SIGNAL STABLE    •    ESC / PAUSE", Vector2(44,72), 14, SliceUI.CYAN)
	if value in ["Operations", "Workshop", "Rest"]:
		var panel := SliceUI.panel(screen, Vector2(882,150), Vector2(360,430))
		SliceUI.label(panel, tr(value).to_upper(), Vector2(24,24), 28, SliceUI.CYAN)
		var description := "Your forward operating base.\n\nEquip in the Hanger.\nReview the operation at the Terminal.\nReturn here with what you recover."
		if value == "Operations":
			description = tr("OPERATION / SIGNAL RECOVERY\nURBAN DISTRICT 07\n\n")
			var mission := ContentDB.get_mission(&"first_mission" if not ProfileRuntime.get_profile().first_mission_completed else SortieRequest.PROTOTYPE_MISSION_ID)
			for objective in mission.objective_definitions:
				description += "• " + tr(objective.display_name) + "\n"
			description += tr("\nRecover supplies. Reach the south\nextraction beacon to return alive.")
		elif value == "Workshop": description = "MODERN ARMORY\n\nPistol / SMG / Assault Rifle\nShotgun / Sniper / Light Machine Gun\nRPG Field Launcher\n\nSelect two weapons in the Hanger.\nAmmo is carried for your loadout.\nHold Shift with the sniper to survey."
		elif value == "Rest": description = "PERSONAL QUARTERS\n\nKohaku — field operator.\nThe city's security network is hostile.\nThis room is still yours.\n\nRecover. Re-equip. Come home."
		if value == "Workshop":
			var profile := ProfileRuntime.get_profile()
			description = tr("WAREHOUSE / SALVAGE CORE × %d\n\nAR / WEAPON UPGRADE\nCost: 1 Salvage Core\nDamage: 20 → 22 (+10%%)\n\n%s") % [FirstMissionPreparation.salvage_count(profile), tr("INSTALLED / READY FOR SORTIE 02" if profile.ar_damage_upgraded else ("Materials secured. Install your upgrade." if profile.first_mission_completed else "Bring materials home from First Mission."))]
			if profile.first_mission_completed and not profile.ar_damage_upgraded:
				var upgrade := SliceUI.button(panel, "UPGRADE AR / 1 SALVAGE CORE", Vector2(24,276), Vector2(312,48), _upgrade_weapon)
				upgrade.disabled = FirstMissionPreparation.salvage_count(profile) < 1
		var detail := SliceUI.label(panel, description, Vector2(24,88), 16, SliceUI.MUTED)
		detail.size = Vector2(312, 180)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		SliceUI.button(panel, "CONFIRM DEPLOYMENT" if value == "Operations" else ("SECOND SORTIE / LOADOUT" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "MISSION TERMINAL"), Vector2(24,338), Vector2(312,58), _deploy if value == "Operations" else func(): show_section("Hanger" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "Operations"))
	if value == "Overview":
		_first_mission_panel()
		SliceUI.label(screen, "SELECT A BAY BELOW  /  PREPARE • DEPLOY • RECOVER", Vector2(44,104),16,SliceUI.MUTED)
	for index in 5:
		var names := ["Overview", "Hanger", "Operations", "Workshop", "Rest"]
		var key: String = names[index]
		SliceUI.button(screen, tr("%02d  %s") % [index+1,tr(key).to_upper()], Vector2(42+index*226,644), Vector2(212,48), func(): show_section(key))
	if value != "Hanger": SliceUI.button(screen, "MENU", Vector2(1140,30), Vector2(100,36), func(): FlowMenu.request_leave("menu"))

func _deploy() -> void:
	hanger._on_deploy_requested()

func _first_mission_panel() -> void:
	var profile := ProfileRuntime.get_profile()
	if profile.ar_damage_upgraded: return
	var panel := SliceUI.panel(screen, Vector2(882,150), Vector2(360,430))
	SliceUI.label(panel, "FIRST MISSION / 10 MIN", Vector2(24,24), 23, SliceUI.CYAN)
	if profile.first_mission_completed:
		SliceUI.label(panel, "HOME SIGNAL RECOVERED\n\nSalvage is now in your warehouse.\nVisit Workshop for your first upgrade.", Vector2(24,92), 17)
		SliceUI.button(panel, "WORKSHOP / FIRST UPGRADE", Vector2(24,338), Vector2(312,58), func(): show_section("Workshop"))
		return
	SliceUI.label(panel, "BUNNY / FIELD OPERATOR\n\nAR + SMG / starter kit\n\nLearn. Investigate. Choose your risk.\nExtract. Upgrade. Deploy again.", Vector2(24,92), 17)
	if not profile.bunny_selected and not FirstMissionPreparation.has_starter_kit(profile):
		SliceUI.button(panel, "SELECT BUNNY", Vector2(24,338), Vector2(312,58), func(): profile.bunny_selected = true; show_section("Overview"))
	elif not FirstMissionPreparation.has_starter_kit(profile):
		SliceUI.button(panel, "SELECT AR + SMG", Vector2(24,338), Vector2(312,58), func(): FirstMissionPreparation.equip_starter_kit(profile); hanger._build_preview_character(profile.inventory, profile.loadout); hanger.hanger_ui.configure(profile.inventory, profile.loadout); hanger.hanger_ui.sync_loadout_selection(); show_section("Overview"))
	else:
		SliceUI.button(panel, "FIRST MISSION / DEPLOY", Vector2(24,338), Vector2(312,58), func(): show_section("Operations"))

func _upgrade_weapon() -> void:
	var error := FirstMissionPreparation.upgrade_weapon()
	if error != OK:
		FlowMenu.show_error(tr("Upgrade could not be saved: %s. Your materials are unchanged.") % error_string(error))
		return
	hanger.hanger_ui.configure(ProfileRuntime.get_profile().inventory, ProfileRuntime.get_profile().loadout)
	hanger.hanger_ui.sync_loadout_selection()
	AudioDirector.play_sfx(&"ui_confirm")
	show_section("Workshop")
