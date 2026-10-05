extends Node3D
## Hanger remains the loadout owner; the hub adds rooms and camera destinations only.
@export var menu_backdrop := false
const ENVIRONMENT := preload("res://scenes/presentation/compact_hideout/environment.tscn")
const STANDING_ANCHOR := Vector3(-0.55,0,-0.1)
const SEAT_ANCHOR := Vector3(2.12,0.045,0.9)
var hanger: Node3D
var camera: Camera3D
var ui: CanvasLayer
var screen: Control
var section := "Overview"
var camera_tween: Tween
var elapsed := 0.0
var relaxed_preview: Node

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
	relaxed_preview = preload("res://scripts/presentation/slice/hideout_idle.gd").new()
	add_child(relaxed_preview)
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	screen = SliceUI.root(ui)
	if menu_backdrop:
		camera.fov = 65.0
		_menu_camera()
		return
	GameState.presentation_enabled = true
	AudioDirector.set_music_context(&"hideout")
	AudioDirector.play_sfx(&"ui_confirm", -4)
	show_section(GameState.hideout_section)
	GameLanguage.language_changed.connect(func(): show_section(section))
	GameState.hideout_section = "Overview"

func _process(delta: float) -> void:
	elapsed += delta
	if relaxed_preview and is_instance_valid(hanger.preview_character):
		if relaxed_preview.actor != hanger.preview_character:
			hanger.preview_character.position = STANDING_ANCHOR
		relaxed_preview.bind(hanger.preview_character)
		relaxed_preview.set_relaxed(menu_backdrop or section != "Hanger")
		relaxed_preview.set_seated(not menu_backdrop and section == "Rest", SEAT_ANCHOR)
	if menu_backdrop: _menu_camera()

func _menu_camera() -> void:
	# The imported compact room replaces the display stage; actor geometry is unchanged.
	camera.position = Vector3(0.35 + sin(elapsed * 0.10) * 0.025, 1.6, 1.82)
	camera.look_at(Vector3(-1.0, 1.05, -0.45))

func _build_rooms() -> void:
	# Hanger keeps equipment/save ownership. Disable only its legacy presentation shell.
	for item in hanger.get_children():
		if item is MeshInstance3D or item is Light3D: item.hide()
		if item is WorldEnvironment: item.environment = null
	for node_name in ["Floor", "BackWall", "MaintenanceBackground"]:
		var old_shell := hanger.get_node_or_null(node_name) as Node3D
		if old_shell: old_shell.hide()
	var room := ENVIRONMENT.instantiate()
	room.name = "CompactEnvironment"
	add_child(room)
	camera.fov = 65.0

func show_section(value: String) -> void:
	section = value
	for room in get_children():
		if room.has_meta("hub_section"): room.visible = true
		elif room is Label3D: room.visible = true
	for child in screen.get_children():
		screen.remove_child(child)
		child.queue_free()
	hanger.hanger_ui.visible = value == "Hanger"
	if value != "Hanger": hanger.hanger_ui.set_warehouse_open(false)
	var destination := Vector3(0.35,1.6,1.82)
	var focus := Vector3(-0.85,1,-0.45)
	if value == "Hanger":
		destination = Vector3(0.1,1.55,1.82)
		focus = Vector3(-0.55,1.05,-0.1)
	elif value == "Operations":
		destination = Vector3(-1.4,1.5,1.65)
		focus = Vector3(-1.05,1,-1.4)
	elif value == "Workshop":
		destination = Vector3(-0.6,1.65,1.65)
		focus = Vector3(-1.8,0.95,-1.37)
	elif value == "Rest":
		destination = Vector3(0.45,1.6,1.72)
		focus = Vector3(2.12,0.95,0.9)
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
			var first := not ProfileRuntime.get_profile().first_mission_completed
			var mission := ContentDB.get_mission(&"first_mission" if first else DeploymentPlan.selected_street_mission)
			description = tr(mission.display_name) + "\n\n"
			for objective in mission.objective_definitions:
				description += "• " + tr(objective.display_name) + "\n"
			description += tr("\nRecover supplies. Reach the south\nextraction beacon to return alive.") if first else tr("\nTwo exits assigned on arrival.\n%s: objectives and extraction map.") % ControlBindings.label("route_map")
			if mission.mission_id == &"streets_relay":
				description = tr("REPAIR BOTH RELAYS, THEN EXTRACT\n\nMunicipal office + repair shop.\n12s nearby each; damage cancels.\nLocal noise; no materials needed.\n\nRecords: optional alternate exit.\n%s: objectives and extraction map.") % ControlBindings.label("route_map")
		elif value == "Workshop": description = "MODERN ARMORY\n\nPistol / SMG / Assault Rifle\nShotgun / Sniper / Light Machine Gun\nRPG Field Launcher\n\nSelect two weapons in the Hanger.\nAmmo is carried for your loadout.\nHold Shift with the sniper to survey."
		elif value == "Rest": description = "PERSONAL QUARTERS\n\nKohaku — field operator.\nThe city's security network is hostile.\nThis room is still yours.\n\nRecover. Re-equip. Come home."
		if value == "Workshop":
			var profile := ProfileRuntime.get_profile()
			description = tr("WAREHOUSE / SALVAGE CORE × %d\n\nAR / WEAPON UPGRADE\nCost: 1 Salvage Core\nDamage: 20 → 22 (+10%%)\n\n%s") % [FirstMissionPreparation.salvage_count(profile), tr("INSTALLED / READY FOR SORTIE 02" if profile.ar_damage_upgraded else ("Materials secured. Install your upgrade." if profile.first_mission_completed else "Bring materials home from First Mission."))]
			if profile.first_mission_completed and not profile.ar_damage_upgraded:
				var upgrade := SliceUI.button(panel, "UPGRADE AR / 1 SALVAGE CORE", Vector2(24,276), Vector2(312,48), _upgrade_weapon)
				upgrade.disabled = FirstMissionPreparation.salvage_count(profile) < 1
		var detail := SliceUI.label(panel, description, Vector2(24,88), 16, SliceUI.MUTED)
		if value == "Operations": detail.name = "MissionBriefing"
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size = Vector2(312, 236)
		SliceUI.button(panel, "CONFIRM DEPLOYMENT" if value == "Operations" else ("SECOND SORTIE / LOADOUT" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "MISSION TERMINAL"), Vector2(24,338), Vector2(312,58), _deploy if value == "Operations" else func(): show_section("Hanger" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "Operations"))
	if value == "Overview":
		# Keep onboarding present and visible when gear selection is actually needed.
		_first_mission_panel()
		var onboarding := screen.get_node_or_null("FirstMissionPanel") as Control
		if onboarding: onboarding.visible = not FirstMissionPreparation.has_starter_kit(ProfileRuntime.get_profile())
		SliceUI.label(screen, "SELECT A BAY BELOW  /  PREPARE • DEPLOY • RECOVER", Vector2(44,104),16,SliceUI.MUTED)
		var contracts := CampaignPanel.new()
		contracts.name = "CampaignPanel"
		contracts.position = Vector2(42, 150)
		contracts.size = Vector2(800, 474)
		screen.add_child(contracts)
		contracts.hide()
		var contracts_toggle := SliceUI.button(screen, "OPERATIONS / CONTRACTS", Vector2(750,100), Vector2(320,40), func(): contracts.visible = not contracts.visible)
		contracts_toggle.name = "ContractsToggle"
		SliceUI.button(screen, "PREPARE SORTIE", Vector2(918,556), Vector2(320,52), func():
			if not ProfileRuntime.get_profile().first_mission_completed:
				if screen.has_node("FirstMissionPanel"):
					screen.get_node("FirstMissionPanel").visible = not screen.get_node("FirstMissionPanel").visible
			else: show_section("Operations"))
		contracts.contract_claimed.connect(func():
			hanger.hanger_ui.configure(ProfileRuntime.get_profile().inventory, ProfileRuntime.get_profile().loadout)
			hanger.hanger_ui.refresh_owned_items()
		)
	if value == "Workshop":
		var supplies := SupplyPanel.new()
		supplies.name = "SupplyPanel"
		supplies.position = Vector2(42,148)
		supplies.size = Vector2(800,474)
		screen.add_child(supplies)
		supplies.supplies_changed.connect(func():
			var profile := ProfileRuntime.get_profile()
			hanger._build_preview_character(profile.inventory, profile.loadout)
			hanger.hanger_ui.configure(profile.inventory, profile.loadout)
			hanger.hanger_ui.refresh_owned_items()
		)
	if value == "Operations":
		if ProfileRuntime.get_profile().first_mission_completed:
			var choices := OptionButton.new()
			choices.name = "MissionChoice"
			choices.position = Vector2(42,144)
			choices.size = Vector2(548,48)
			for id in DeploymentPlan.STREET_MISSIONS: choices.add_item(tr(ContentDB.get_mission(id).display_name))
			choices.select(DeploymentPlan.STREET_MISSIONS.find(DeploymentPlan.selected_street_mission))
			choices.item_selected.connect(func(index: int):
				DeploymentPlan.selected_street_mission = DeploymentPlan.STREET_MISSIONS[index]
				show_section.call_deferred("Operations"))
			screen.add_child(choices)
		var medical := MedicalPacking.new()
		medical.name = "MedicalPacking"
		medical.position = Vector2(42, 206)
		medical.size = Vector2(548, 330)
		screen.add_child(medical)
		var warning := SliceUI.label(screen, "AT RISK: all deployed equipment and supplies.\nDeath or abandonment loses carried items. Base storage is safe.", Vector2(44,540), 16, Color("ffbd72"))
		warning.size = Vector2(790,72)
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.name = "PackingRisk"
		medical.resized.connect(func(): warning.position.y = medical.position.y + medical.size.y + 8)
		warning.position.y = medical.position.y + medical.size.y + 8
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
	panel.name = "FirstMissionPanel"
	SliceUI.label(panel, "FIRST MISSION / 10 MIN", Vector2(24,24), 23, SliceUI.CYAN)
	if profile.first_mission_completed:
		SliceUI.label(panel, "HOME SIGNAL RECOVERED\n\nSalvage is now in your warehouse.\nVisit Workshop for your first upgrade.", Vector2(24,92), 17)
		SliceUI.button(panel, "WORKSHOP / FIRST UPGRADE", Vector2(24,338), Vector2(312,58), func(): show_section("Workshop"))
		return
	if profile.failed_sorties > 0 or not FirstMissionPreparation.owns_starter_weapons(profile):
		SliceUI.label(panel, "REBUILD / TRY AGAIN\n\nLost equipment stays lost.\nBuy supplies or claim emergency aid\nat the Workshop, then equip a weapon.\nAny equipped weapon can retry.", Vector2(24,92), 17)
		SliceUI.button(panel, "WORKSHOP / RESUPPLY", Vector2(24,272), Vector2(312,48), func(): show_section("Workshop"))
		SliceUI.button(panel, "MISSION TERMINAL", Vector2(24,338), Vector2(312,58), func(): show_section("Operations"))
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
