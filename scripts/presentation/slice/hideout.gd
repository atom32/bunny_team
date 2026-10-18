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
var section_camera_position := Vector3(0.35,1.6,1.82)
var camera_focus := Vector3(-0.85,1,-0.45)
var section_focus := Vector3(-0.85,1,-0.45)
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
	camera = hanger.get_node("PreviewCamera")
	_build_rooms()
	relaxed_preview = preload("res://scripts/presentation/slice/hideout_idle.gd").new()
	add_child(relaxed_preview)
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	screen = SliceUI.root(ui)
	screen.theme = FieldManualStyle.theme()
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
			var playback := {}
			if is_instance_valid(relaxed_preview.actor):
				var previous: PlayerController = relaxed_preview.actor
				for key in ["phase", "clip_name", "elapsed", "idle_elapsed", "route", "seated", "height_offset", "target_yaw", "speed", "destination_section", "enabled"]:
					playback[key] = relaxed_preview.get(key)
				playback["position"] = previous.position
				playback["yaw"] = previous.body_visual.rotation.y
				var poses: Array[Quaternion] = []
				for index in previous.character_skeleton.get_bone_count(): poses.append(previous.character_skeleton.get_bone_pose_rotation(index))
				playback["poses"] = poses
			relaxed_preview.bind(hanger.preview_character)
			relaxed_preview.transition_to("Overview" if menu_backdrop else section, true)
			if not playback.is_empty():
				relaxed_preview.set_relaxed(playback.enabled)
				hanger.preview_character.position = playback.position
				hanger.preview_character.body_visual.rotation.y = playback.yaw
				for key in playback:
					if key not in ["position", "yaw", "poses", "enabled"]: relaxed_preview.set(key, playback[key])
				for index in playback.poses.size(): hanger.preview_character.character_skeleton.set_bone_pose_rotation(index, playback.poses[index])
				relaxed_preview._change_clip(playback.clip_name)
				relaxed_preview.elapsed = playback.elapsed
				if not playback.enabled:
					relaxed_preview.equipment_blend = true
					relaxed_preview.equipment_start_yaw = playback.yaw
			relaxed_preview.original_position = STANDING_ANCHOR
		else:
			relaxed_preview.transition_to("Overview" if menu_backdrop else section)
	if menu_backdrop:
		_menu_camera()
	elif is_instance_valid(hanger.preview_character):
		var focus := section_focus
		if relaxed_preview.enabled and relaxed_preview.phase != "idle":
			focus = hanger.preview_character.position + Vector3(0, 1.0, 0)
		var moving: bool = relaxed_preview.enabled and relaxed_preview.phase != "idle"
		# Cross the partition inside its doorway, alongside the actor, before framing the destination.
		var destination := Vector3(hanger.preview_character.position.x, 2.25, 1.6) if moving else section_camera_position
		camera.position = camera.position.lerp(destination, 1.0 - exp(-delta * 5.0))
		var target_fov := 90.0 if moving else (75.0 if section == "Rest" else 65.0)
		camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-delta * 4.0))
		camera_focus = camera_focus.lerp(focus, 1.0 - exp(-delta * 5.0))
		camera.look_at(camera_focus)

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
	if value == "Hanger": hanger.hanger_ui.sync_loadout_selection()
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
		destination = Vector3(1.3,1.65,1.82)
		focus = Vector3(2.12,0.95,0.9)
	section_camera_position = destination
	section_focus = focus
	if value != "Hanger":
		_panel(screen, Vector2(24,16), Vector2(1232,96))
		_label(screen, "BASTION 07  /  HIDEOUT", Vector2(42,30), 30)
		_label(screen, "HOME SIGNAL STABLE    •    ESC / PAUSE", Vector2(44,72), 14, FieldManualStyle.ACCENT)
	if value in ["Operations", "Workshop", "Rest"]:
		var panel := _panel(screen, Vector2(882,150), Vector2(360,430))
		_label(panel, tr(value).to_upper(), Vector2(24,24), 28, FieldManualStyle.ACCENT)
		var description := "Your forward operating base.\n\nEquip in the Hanger.\nReview the operation at the Terminal.\nReturn here with what you recover."
		if value == "Operations":
			var first := not ProfileRuntime.get_profile().first_mission_completed
			if first:
				var notice := _label(panel, tr("LEGACY TUTORIAL / ART NOT REFURBISHED"), Vector2(24, 64), 12, FieldManualStyle.ACCENT)
				notice.name = "LegacyTutorialNotice"
			var mission := ContentDB.get_mission(&"first_mission" if first else DeploymentPlan.selected_street_mission)
			description = tr(mission.display_name) + "\n\n"
			for objective in mission.objective_definitions:
				description += "• " + tr(objective.display_name) + "\n"
			description += tr("\nRecover supplies. Reach the south\nextraction beacon to return alive.") if first else tr("\nTwo exits assigned on arrival.\n%s: objectives and extraction map.") % ControlBindings.label("route_map")
			if mission.mission_id == &"streets_relay":
				description = tr("REPAIR BOTH RELAYS, THEN EXTRACT\n\nReading hall + maintenance yard.\n12s nearby each; damage cancels.\nLocal noise; no materials needed.\n\nRecords: optional alternate exit.\n%s: objectives and extraction map.") % ControlBindings.label("route_map")
		elif value == "Workshop": description = "MODERN ARMORY\n\nPistol / SMG / Assault Rifle\nShotgun / Sniper / Light Machine Gun\nRPG Field Launcher\n\nSelect two weapons in the Hanger.\nAmmo is carried for your loadout.\nHold Shift with the sniper to survey."
		elif value == "Rest": description = "PERSONAL QUARTERS\n\nField operator quarters.\nThe city's security network is hostile.\nThis room is still yours.\n\nRecover. Re-equip. Come home."
		if value == "Workshop":
			var profile := ProfileRuntime.get_profile()
			description = tr("WAREHOUSE / SALVAGE CORE × %d\n\nAR / WEAPON UPGRADE\nCost: 1 Salvage Core\nDamage: 20 → 22 (+10%%)\n\n%s") % [FirstMissionPreparation.salvage_count(profile), tr("INSTALLED / READY FOR SORTIE 02" if profile.ar_damage_upgraded else ("Materials secured. Install your upgrade." if profile.first_mission_completed else "Bring materials home from First Mission."))]
			if profile.first_mission_completed and not profile.ar_damage_upgraded:
				var upgrade := SliceUI.button(panel, "UPGRADE AR / 1 SALVAGE CORE", Vector2(24,276), Vector2(312,48), _upgrade_weapon)
				upgrade.disabled = FirstMissionPreparation.salvage_count(profile) < 1
		var detail := _label(panel, description, Vector2(24,88), 16, FieldManualStyle.MUTED)
		if value == "Operations": detail.name = "MissionBriefing"
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size = Vector2(312, 236)
		var action := SliceUI.button(panel, "CONFIRM DEPLOYMENT" if value == "Operations" else ("SECOND SORTIE / LOADOUT" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "MISSION TERMINAL"), Vector2(24,338), Vector2(312,58), _deploy if value == "Operations" else func(): show_section("Hanger" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "Operations"))
		FieldManualStyle.primary(action)
	if value == "Overview":
		var brief := _panel(screen, Vector2(42,152), Vector2(350,344))
		brief.name = "BaseBriefing"
		_label(brief, tr("Overview").to_upper(), Vector2(22,20), 26)
		_label(brief, tr("QUARTERMASTER  /  %d CREDITS") % ProfileRuntime.get_profile().credits, Vector2(22,68), 16, FieldManualStyle.ACCENT)
		var briefing := _label(brief, "Your forward operating base.\n\nEquip in the Hanger.\nReview the operation at the Terminal.\nReturn here with what you recover.", Vector2(22,112), 18)
		briefing.size = Vector2(306,210)
		briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Keep onboarding present and visible when gear selection is actually needed.
		_first_mission_panel()
		var onboarding := screen.get_node_or_null("FirstMissionPanel") as Control
		if onboarding: onboarding.visible = not FirstMissionPreparation.has_starter_kit(ProfileRuntime.get_profile())
		var contracts := CampaignPanel.new()
		contracts.name = "CampaignPanel"
		contracts.position = Vector2(42, 150)
		contracts.size = Vector2(800, 474)
		screen.add_child(contracts)
		contracts.hide()
		var contact_button := SliceUI.button(screen, "补给与委托", Vector2(42, 516), Vector2(320, 40), func(): show_section("Workshop"))
		contact_button.name = "ContactsToggle"
		var contracts_toggle := SliceUI.button(screen, "委托记录", Vector2(908,44), Vector2(208,40), func():
			contracts.visible = not contracts.visible
			brief.visible = not contracts.visible
			contact_button.visible = not contracts.visible)
		contracts_toggle.name = "ContractsToggle"
		FieldManualStyle.primary(SliceUI.button(screen, "PREPARE SORTIE", Vector2(918,556), Vector2(320,52), func():
			if not ProfileRuntime.get_profile().first_mission_completed:
				if screen.has_node("FirstMissionPanel"):
					screen.get_node("FirstMissionPanel").visible = not screen.get_node("FirstMissionPanel").visible
			else: show_section("Operations")))
		contracts.contract_claimed.connect(func():
			hanger.hanger_ui.configure(ProfileRuntime.get_profile().inventory, ProfileRuntime.get_profile().loadout)
			hanger.hanger_ui.refresh_owned_items()
		)
	if value == "Workshop":
		var supplies := ContactPanel.new()
		supplies.name = "ContactPanel"
		supplies.position = Vector2(42,148)
		supplies.size = Vector2(1196,474)
		screen.add_child(supplies)
		# Contact content occupies the existing workshop area; keep tutorial upgrade reachable elsewhere.
		for child in screen.get_children():
			if child is Panel and child != supplies and child.position.y > 112: child.hide()
		supplies.supplies_changed.connect(func():
			var profile := ProfileRuntime.get_profile()
			hanger._build_preview_character(profile.inventory, profile.loadout)
			hanger.hanger_ui.configure(profile.inventory, profile.loadout)
			hanger.hanger_ui.refresh_owned_items()
		)
		var profile := ProfileRuntime.get_profile()
		if profile.first_mission_completed and not profile.ar_damage_upgraded:
			var upgrade := SliceUI.button(screen, "UPGRADE AR / 1 SALVAGE CORE", Vector2(882, 98), Vector2(360, 46), _upgrade_weapon)
			upgrade.name = "WorkshopUpgrade"
			upgrade.disabled = FirstMissionPreparation.salvage_count(profile) < 1
			upgrade.tooltip_text = "AR 伤害 20 → 22；消耗仓库回收核心 ×1"
		supplies.contract_claimed.connect(func():
			hanger.hanger_ui.configure(ProfileRuntime.get_profile().inventory, ProfileRuntime.get_profile().loadout)
			hanger.hanger_ui.refresh_owned_items()
		)
	if value == "Operations":
		if ProfileRuntime.get_profile().first_mission_completed:
			var choices := OptionButton.new()
			choices.name = "MissionChoice"
			choices.position = Vector2(42,144)
			choices.size = Vector2(348,48)
			for id in DeploymentPlan.STREET_MISSIONS: choices.add_item(tr(ContentDB.get_mission(id).display_name))
			choices.select(DeploymentPlan.STREET_MISSIONS.find(DeploymentPlan.selected_street_mission))
			choices.item_selected.connect(func(index: int):
				DeploymentPlan.selected_street_mission = DeploymentPlan.STREET_MISSIONS[index]
				show_section.call_deferred("Operations"))
			screen.add_child(choices)
			var time_choice := OptionButton.new()
			time_choice.name = "LightingChoice"
			time_choice.position = Vector2(402,144)
			time_choice.size = Vector2(188,48)
			time_choice.add_item(tr("DAY / CAMPUS"))
			time_choice.add_item(tr("NIGHT / CAMPUS"))
			time_choice.select(1 if DeploymentPlan.selected_lighting_variant == "night" else 0)
			time_choice.item_selected.connect(func(index: int): DeploymentPlan.selected_lighting_variant = "night" if index == 1 else "day")
			screen.add_child(time_choice)
		var preparation_panel := _panel(screen, Vector2(42,208), Vector2(548,386))
		preparation_panel.name = "DeploymentReview"
		preparation_panel.add_theme_stylebox_override("panel", FieldManualStyle.panel())
		var review := Label.new()
		review.name = "DeploymentQuantities"
		review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		review.text = DeploymentPlan.build(ProfileRuntime.get_profile()).message
		review.position = Vector2(18,18)
		review.add_theme_font_size_override("font_size",18)
		review.add_theme_color_override("font_color",FieldManualStyle.INK)
		review.size = Vector2(512, 164)
		preparation_panel.add_child(review)
		SliceUI.button(preparation_panel, "CHARACTER / STASH", Vector2(18,190), Vector2(512,48), func(): show_section("Hanger"))
		var warning := Label.new()
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.text = "AT RISK: all deployed equipment and supplies.\nDeath or abandonment loses carried items. Base storage is safe."
		warning.position = Vector2(18,266)
		warning.add_theme_font_size_override("font_size",16)
		warning.add_theme_color_override("font_color",FieldManualStyle.ACCENT)
		warning.size = Vector2(512, 100)
		warning.name = "PackingRisk"
		preparation_panel.add_child(warning)
	_panel(screen, Vector2(24,632), Vector2(1232,72))
	for index in 5:
		var names := ["Overview", "Hanger", "Operations", "Workshop", "Rest"]
		var key: String = names[index]
		var navigation := SliceUI.button(screen, tr("%02d  %s") % [index+1,tr(key).to_upper()], Vector2(42+index*242,644), Vector2(228,48), func(): show_section(key))
		navigation.name = "Nav" + key
		navigation.add_theme_font_size_override("font_size", 15)
		if key == value: FieldManualStyle.primary(navigation)
	SliceUI.button(screen, "MENU", Vector2(1140,30), Vector2(100,36), func(): FlowMenu.request_leave("menu"))

func _deploy() -> void:
	hanger._on_deploy_requested()

func _first_mission_panel() -> void:
	var profile := ProfileRuntime.get_profile()
	if profile.ar_damage_upgraded: return
	var panel := _panel(screen, Vector2(882,150), Vector2(360,430))
	panel.name = "FirstMissionPanel"
	_label(panel, "FIRST MISSION / 10 MIN", Vector2(24,24), 23, FieldManualStyle.ACCENT)
	if profile.first_mission_completed:
		_label(panel, "HOME SIGNAL RECOVERED\n\nSalvage is now in your warehouse.\nVisit Workshop for your first upgrade.", Vector2(24,92), 17)
		SliceUI.button(panel, "WORKSHOP / FIRST UPGRADE", Vector2(24,338), Vector2(312,58), func(): show_section("Workshop"))
		return
	if profile.failed_sorties > 0 or not FirstMissionPreparation.owns_starter_weapons(profile):
		_label(panel, "REBUILD / TRY AGAIN\n\nLost equipment stays lost.\nBuy supplies or claim emergency aid\nat the Workshop, then equip a weapon.\nAny equipped weapon can retry.", Vector2(24,92), 17)
		SliceUI.button(panel, "WORKSHOP / RESUPPLY", Vector2(24,272), Vector2(312,48), func(): show_section("Workshop"))
		SliceUI.button(panel, "MISSION TERMINAL", Vector2(24,338), Vector2(312,58), func(): show_section("Operations"))
		return
	_label(panel, "BUNNY / FIELD OPERATOR\n\nAR + SMG / starter kit\n\nLearn. Investigate. Choose your risk.\nExtract. Upgrade. Deploy again.", Vector2(24,92), 17)
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


# Presentation-only adapters; callbacks and data ownership remain unchanged.
func _panel(parent: Node, at: Vector2, extent: Vector2) -> Panel:
	var result := SliceUI.panel(parent, at, extent)
	result.add_theme_stylebox_override("panel", FieldManualStyle.panel())
	return result

func _label(parent: Node, text: String, at: Vector2, font_size: int = 18, color: Color = FieldManualStyle.INK) -> Label:
	return SliceUI.label(parent, text, at, font_size, color)
