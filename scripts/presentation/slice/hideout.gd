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
		OperationUI.block(screen, Vector2(24,16), Vector2(1232,96), OperationUI.DARK)
		OperationUI.eyebrow(screen, "BASTION / HOME BASE", Vector2(44,27), true)
		OperationUI.text(screen, tr(value), Vector2(42,49), 30, Color.WHITE)
		OperationUI.text(screen, "NEON BASTION", Vector2(704,42), 24, Color("c0c8bd"), true)
	if value == "Operations":
		var geography := OperationUI.action(screen,"整校园 1:1 / 室内任务",Vector2(430,116),Vector2(360,32),func():
			GameState.hideout_section="Operations"
			GameState.set_meta("campus_geography_return","res://scenes/presentation/slice/hideout.tscn")
			GameState.present_scene("res://scenes/presentation/campus_survey.tscn","WEIJIN CAMPUS / 1:1"))
		geography.name="OpenRealCampus"
		geography.add_theme_font_size_override("font_size",13)
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
			if mission.mission_id in [MaintenanceStory.MISSION,FinaleStory.MISSION]:
				description=tr(mission.display_name)+"\n\n"+tr(mission.description)
			if mission.mission_id == BlockadeStory.MISSION:
				description = tr(mission.display_name) + "\n\n" + tr(BlockadeJourney.BRIEF)
			if mission.mission_id == WaterworksStory.MISSION:
				description = tr(mission.display_name) + "\n\n" + tr("West garage: 8kg battery. East pump: 8s installation.\nChoose courtyard water + dressings, or tanker water + ammunition.\nSouth retreat stays open. %s: street map.") % ControlBindings.label("route_map")
		elif value == "Workshop": description = "MODERN ARMORY\n\nPistol / SMG / Assault Rifle\nShotgun / Sniper / Light Machine Gun\nRPG Field Launcher\n\nSelect two weapons in the Hanger.\nAmmo is carried for your loadout.\nHold Shift with the sniper to survey."
		elif value == "Rest": description = "PERSONAL QUARTERS\n\nField operator quarters.\nThe city's security network is hostile.\nThis room is still yours.\n\nRecover. Re-equip. Come home."
		if value=="Rest" and ProfileRuntime.get_profile().maintenance_closed:description=tr("HOME / EVERYONE IS BACK\n\nThe food is still warm. The radio can wait.\n\nFree sorties remain available.")
		if value == "Workshop":
			var profile := ProfileRuntime.get_profile()
			description = tr("WAREHOUSE / SALVAGE CORE × %d\n\nAR / WEAPON UPGRADE\nCost: 1 Salvage Core\nDamage: 20 → 22 (+10%%)\n\n%s") % [FirstMissionPreparation.salvage_count(profile), tr("INSTALLED / READY FOR SORTIE 02" if profile.ar_damage_upgraded else ("Materials secured. Install your upgrade." if profile.first_mission_completed else "Bring materials home from First Mission."))]
			if profile.first_mission_completed and not profile.ar_damage_upgraded:
				var upgrade := SliceUI.button(panel, "UPGRADE AR / 1 SALVAGE CORE", Vector2(24,276), Vector2(312,48), _upgrade_weapon)
				upgrade.disabled = FirstMissionPreparation.salvage_count(profile) < 1
		var request: Array = SortieGuidance.at_base(ProfileRuntime.get_profile()) if value == "Operations" else []
		if value=="Operations" and ProfileRuntime.get_profile().campus_chapter.finished:request=[]
		if value == "Operations" and DeploymentPlan.selected_street_mission in [WaterworksStory.MISSION, BlockadeStory.MISSION, MaintenanceStory.MISSION, FinaleStory.MISSION]: request = []
		if not request.is_empty():
			var operation := ContentDB.get_mission(DeploymentPlan.selected_street_mission)
			description = "%s\n\n%s\n\n%s" % [request[0], request[1], tr("Optional operation: %s") % tr(operation.display_name)]
			var details := SliceUI.button(panel, "OPEN REQUEST / CONTACT", Vector2(24,282), Vector2(312,44), func():
				var contact := SortieGuidance.contact_at_base(ProfileRuntime.get_profile())
				show_section("Workshop")
				screen.get_node("ContactPanel").open_contact(contact, "quests"))
			details.name = "RequestDetails"
			if CampusChapter.stage(ProfileRuntime.get_profile().campus_chapter)=="supply" and ProfileRuntime.get_profile().narrative_slice.settled.Q02:
				details.text=tr("PACK EQUIPMENT / SHEN") if not ProfileRuntime.get_profile().campus_chapter.delivered_armor or ProfileRuntime.get_profile().campus_chapter.delivered_ammo<60 else tr("VIEW DORMITORY HANDOFF / SHEN")
		var brief_scroll := ScrollContainer.new()
		brief_scroll.name = "BriefingScroll"
		brief_scroll.position = Vector2(24,88)
		brief_scroll.size = Vector2(312,100 if value == "Rest" else (184 if not request.is_empty() else 236))
		brief_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		panel.add_child(brief_scroll)
		var detail := Label.new()
		detail.text = description
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.add_theme_font_size_override("font_size",16)
		detail.add_theme_color_override("font_color",FieldManualStyle.MUTED)
		brief_scroll.add_child(detail)
		if value == "Operations": detail.name = "MissionBriefing"
		var action := SliceUI.button(panel, "CONFIRM DEPLOYMENT" if value == "Operations" else ("SECOND SORTIE / LOADOUT" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "MISSION TERMINAL"), Vector2(24,338), Vector2(312,58), _deploy if value == "Operations" else (_open_training if value == "Rest" else func(): show_section("Hanger" if value == "Workshop" and ProfileRuntime.get_profile().ar_damage_upgraded else "Operations")))
		if value == "Rest":
			var door_ready:=preload("res://scripts/presentation/slice/rescue_return.gd").unlocked(ProfileRuntime.get_profile())
			var bucket_ready:=preload("res://scripts/presentation/slice/bucket_return.gd").unlocked(ProfileRuntime.get_profile())
			var replay_size:=Vector2(168 if door_ready and bucket_ready else 350,42)
			if door_ready:
				var replay:=SliceUI.button(screen,"THE DOOR CAN WAIT",Vector2(42,590),replay_size,func():GameState.present_scene("res://scenes/presentation/slice/rescue_return.tscn","THE DOOR CAN WAIT"))
				replay.name="OpenRescueMoment"
				if bucket_ready:replay.add_theme_font_size_override("font_size",14)
			if bucket_ready:
				var replay:=SliceUI.button(screen,"THE BIGGEST BUCKET",Vector2(224 if door_ready else 42,590),replay_size,func():GameState.present_scene("res://scenes/presentation/slice/bucket_return.tscn","THE BIGGEST BUCKET"))
				replay.name="OpenBucketMoment"
				if door_ready:replay.add_theme_font_size_override("font_size",14)
			action.text = tr("OPEN TRAINING ROOM")
			action.name = "OpenTrainingRoom"
			if ProfileRuntime.get_profile().maintenance_closed:
				SliceUI.button(panel,"REPLAY / EVERYONE IS HOME",Vector2(24,214),Vector2(312,48),_open_finale).name="ReplayHomecoming"
			if preload("res://scripts/presentation/slice/seat_moment.gd").available(ProfileRuntime.get_profile()):
				var moment := SliceUI.button(panel, "SAVED YOU A SEAT", Vector2(24,276), Vector2(312,48), _open_seat_moment)
				moment.name = "OpenSeatMoment"
		FieldManualStyle.primary(action)
	if value == "Overview":
		_build_overview()
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
		elif profile.ar_damage_upgraded:
			var fitting := SliceUI.button(screen, "REPLAY / ONE SPARE SCREW", Vector2(882,98), Vector2(360,46), _open_upgrade_moment)
			fitting.name = "ReplayWorkshopMoment"
		supplies.contract_claimed.connect(func():
			hanger.hanger_ui.configure(ProfileRuntime.get_profile().inventory, ProfileRuntime.get_profile().loadout)
			hanger.hanger_ui.refresh_owned_items()
		)
	if value == "Operations":
		if ProfileRuntime.get_profile().first_mission_completed:
			var operation_tag := _panel(screen, Vector2(42,116), Vector2(348,24))
			var next_story:=FinaleStory.next_mission(ProfileRuntime.get_profile())
			var operation_label := _label(operation_tag, "MAIN STORY / NEXT OPERATION" if not next_story.is_empty() and DeploymentPlan.selected_street_mission==next_story else "FIELD OPERATION / OPTIONAL", Vector2(8,3), 12)
			operation_label.name = "OptionalOperationLabel"
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
			time_choice.disabled = DeploymentPlan.selected_street_mission in [WaterworksStory.MISSION, BlockadeStory.MISSION, MaintenanceStory.MISSION, FinaleStory.MISSION]
			time_choice.position = Vector2(402,144)
			time_choice.size = Vector2(188,48)
			time_choice.add_item(tr("DAY / CAMPUS"))
			time_choice.add_item(tr("NIGHT / CAMPUS"))
			time_choice.select(1 if DeploymentPlan.selected_lighting_variant == "night" else 0)
			if DeploymentPlan.selected_street_mission in [WaterworksStory.MISSION, BlockadeStory.MISSION, MaintenanceStory.MISSION, FinaleStory.MISSION]:
				time_choice.clear(); time_choice.add_item(tr("WORK LIGHTS / MAINTENANCE" if DeploymentPlan.selected_street_mission in [MaintenanceStory.MISSION,FinaleStory.MISSION] else "DAWN / WATER TOWER")); time_choice.select(0)
			time_choice.item_selected.connect(func(index: int): DeploymentPlan.selected_lighting_variant = "night" if index == 1 else "day")
			screen.add_child(time_choice)
		var mission_id := &"first_mission" if not ProfileRuntime.get_profile().first_mission_completed else DeploymentPlan.selected_street_mission
		var plan := DeploymentPlan.build(ProfileRuntime.get_profile(), mission_id)
		var preparation_panel := _panel(screen, Vector2(42,208), Vector2(548,386))
		preparation_panel.name = "DeploymentReview"
		OperationUI.eyebrow(preparation_panel, "LOADOUT / CARRIED SUPPLIES", Vector2(18,14))
		OperationUI.text(preparation_panel, "%.1f / %.0f kg" % [plan.weight,plan.capacity], Vector2(18,36), 35, FieldManualStyle.INK, true)
		OperationUI.rule(preparation_panel, Vector2(18,96),512)
		var scroll := ScrollContainer.new()
		scroll.position = Vector2(18,110)
		scroll.size = Vector2(512,140)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		preparation_panel.add_child(scroll)
		var review := Label.new()
		review.name = "DeploymentQuantities"
		review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		review.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		review.text = plan.message if plan.error.is_empty() else tr(plan.error) + "\n\n" + plan.message
		review.add_theme_font_size_override("font_size",16)
		review.add_theme_color_override("font_color",FieldManualStyle.MUTED)
		scroll.add_child(review)
		OperationUI.action(preparation_panel, "CHARACTER / STASH", Vector2(18,264), Vector2(512,44), func(): show_section("Hanger"))
		var warning := _wrapped_label(preparation_panel, tr("AT RISK: all deployed equipment and supplies.\nDeath or abandonment loses carried items. Base storage is safe."), Vector2(18,322), Vector2(512,58), 13)
		warning.name = "PackingRisk"
		for candidate in screen.find_children("*", "Button", true, false):
			if candidate.text in ["CONFIRM DEPLOYMENT", tr("CONFIRM DEPLOYMENT")]:
				candidate.name = "ConfirmDeployment"
				candidate.disabled = not plan.error.is_empty()
				candidate.tooltip_text = tr(plan.error) if candidate.disabled else tr("Review your carried supplies before leaving.")

	OperationUI.block(screen, Vector2(24,632), Vector2(1232,72), FieldManualStyle.PAPER)
	OperationUI.rule(screen, Vector2(24,632),1232)
	for index in 5:
		var names := ["Overview", "Hanger", "Operations", "Workshop", "Rest"]
		var key: String = names[index]
		var navigation := OperationUI.action(screen, tr("%02d  %s") % [index+1,tr(key).to_upper()], Vector2(42+index*242,644), Vector2(228,48), func(): show_section(key), key == value)
		navigation.name = "Nav" + key
		navigation.add_theme_font_size_override("font_size", 15)
		navigation.tooltip_text = tr({"Overview":"Current request and next step", "Hanger":"Weapons, storage and sortie supplies", "Operations":"Mission briefing and deployment", "Workshop":"Contacts, trade and deliveries", "Rest":"Training and homecoming"}[key])
	var menu := SliceUI.button(screen, "MENU", Vector2(1140,38), Vector2(100,48), func(): FlowMenu.request_leave("menu"))
	menu.add_theme_stylebox_override("normal",FieldManualStyle.button_style(FieldManualStyle.PAPER))

func _build_overview() -> void:
	var profile := ProfileRuntime.get_profile()
	var brief := _panel(screen, Vector2(42,148), Vector2(350,448))
	brief.name = "BaseBriefing"
	OperationUI.heading(brief, "CURRENT REQUEST", tr("Next objective"), Vector2(22,20))
	OperationUI.rule(brief, Vector2(22,100),306)
	var request := SortieGuidance.at_base(profile)
	var title := str(request[0]) if not request.is_empty() else tr("No outstanding requests" if profile.first_mission_completed else "First time outside")
	var description := str(request[1]) if not request.is_empty() else tr("Choose a field operation at the terminal, or visit your contacts for supplies." if profile.first_mission_completed else "Choose your operator and equipment. Review the mission, then bring your supplies home.")
	_wrapped_label(brief, title, Vector2(22,120), Vector2(306,62), 21).name = "OverviewRequest"
	_wrapped_label(brief, description, Vector2(22,198), Vector2(306,142), 17, FieldManualStyle.MUTED)
	OperationUI.rule(brief, Vector2(22,352),306)
	OperationUI.eyebrow(brief, "CREDITS / EXTRACTED", Vector2(22,370))
	OperationUI.text(brief, "%d  /  %d" % [profile.credits,profile.successful_sorties], Vector2(22,390), 27, FieldManualStyle.INK, true)
	var contact_button := OperationUI.action(screen, "SUPPLIES & REQUESTS", Vector2(882,540), Vector2(360,48), func(): show_section("Workshop"))
	contact_button.name = "ContactsToggle"
	var preparation: Control
	if not profile.first_mission_completed:
		_first_mission_panel()
		preparation = screen.get_node("FirstMissionPanel")
	else:
		preparation = _panel(screen, Vector2(882,148), Vector2(360,374))
		preparation.name = "SortiePreparation"
		OperationUI.heading(preparation, "PREPARATION", tr("Before you leave"), Vector2(22,20))
		OperationUI.rule(preparation, Vector2(22,100),316)
		var mission := FinaleStory.next_mission(profile)
		var plan := DeploymentPlan.build(profile, mission if not mission.is_empty() else DeploymentPlan.selected_street_mission)
		OperationUI.eyebrow(preparation, "CARRIED / CAPACITY", Vector2(22,116))
		OperationUI.text(preparation, "%.1f / %.0f kg" % [plan.weight,plan.capacity], Vector2(22,138), 32, FieldManualStyle.INK, true)
		var ready := tr("Ready for mission review.") if plan.error.is_empty() else tr(plan.error)
		_wrapped_label(preparation, ready, Vector2(22,194), Vector2(316,74), 16, FieldManualStyle.MUTED)
		OperationUI.action(preparation, "CHARACTER / STASH", Vector2(22,268), Vector2(316,40), func(): show_section("Hanger")).name = "EditPreparation"
		var next := OperationUI.action(preparation, "CONTINUE MAIN STORY" if not mission.is_empty() else "PREPARE SORTIE", Vector2(22,318), Vector2(316,44), func():
			if not mission.is_empty(): DeploymentPlan.selected_street_mission = mission
			show_section("Operations"), true)
		next.name = "ContinueStory"
	var contracts := CampaignPanel.new()
	contracts.name = "CampaignPanel"
	contracts.position = Vector2(42,148)
	contracts.size = Vector2(800,474)
	screen.add_child(contracts)
	contracts.hide()
	var toggle := OperationUI.action(screen, "CONTRACT RECORDS", Vector2(908,38), Vector2(208,48), func():
		contracts.visible = not contracts.visible
		brief.visible = not contracts.visible
		preparation.visible = not contracts.visible
		contact_button.visible = not contracts.visible)
	toggle.name = "ContractsToggle"
	toggle.add_theme_font_size_override("font_size",14)
	contracts.contract_claimed.connect(func():
		hanger.hanger_ui.configure(profile.inventory, profile.loadout)
		hanger.hanger_ui.refresh_owned_items())

func _deploy() -> void:
	hanger._on_deploy_requested()

func _open_training() -> void:
	GameState.present_scene("res://scenes/presentation/slice/training_room.tscn", "OFF-DUTY TRAINING")

func _open_seat_moment() -> void:
	if preload("res://scripts/presentation/slice/seat_moment.gd").available(ProfileRuntime.get_profile()):
		GameState.present_scene("res://scenes/presentation/slice/seat_moment.tscn", "SAVED YOU A SEAT")

func _first_mission_panel() -> void:
	var profile := ProfileRuntime.get_profile()
	var panel := _panel(screen, Vector2(882,148), Vector2(360,374))
	panel.name = "FirstMissionPanel"
	OperationUI.heading(panel, "FIRST SORTIE", tr("Prepare to leave"), Vector2(22,20))
	OperationUI.rule(panel, Vector2(22,100),316)
	var retry := profile.failed_sorties > 0 or not FirstMissionPreparation.owns_starter_weapons(profile)
	var equipped := FirstMissionPreparation.has_starter_kit(profile)
	var rows := [tr("Choose Bunny"), tr("Equip AR + SMG"), tr("Review the mission")]
	var stage := 2 if equipped else (1 if profile.bunny_selected else 0)
	if retry:
		rows = [tr("Visit Shen for supplies"), tr("Equip a weapon and ammunition"), tr("Review the mission")]
		stage = 2 if DeploymentPlan.build(profile, &"first_mission").error.is_empty() else 0
	for index in 3:
		var y := 119 + index*48
		if index == stage: OperationUI.block(panel, Vector2(14,y-2), Vector2(332,40), OperationUI.SIGNAL)
		OperationUI.text(panel, "%02d" % (index+1), Vector2(22,y), 17, FieldManualStyle.INK if index == stage else FieldManualStyle.MUTED, true)
		OperationUI.text(panel, rows[index], Vector2(64,y), 16)
		OperationUI.rule(panel, Vector2(22,y+39),316)
	var caption := "FIRST MISSION / DEPLOY" if equipped else ("SELECT AR + SMG" if profile.bunny_selected else "SELECT BUNNY")
	var callback := func(): show_section("Operations")
	if retry:
		if DeploymentPlan.build(profile, &"first_mission").error.is_empty():
			caption = "FIRST MISSION / DEPLOY"
		else:
			caption = "WORKSHOP / RESUPPLY"
			callback = func():
				show_section("Workshop")
				screen.get_node("ContactPanel").open_contact("shen_yanshuang", "trade")
	elif not profile.bunny_selected and not equipped:
		callback = func(): profile.bunny_selected = true; show_section("Overview")
	elif not equipped:
		callback = func():
			FirstMissionPreparation.equip_starter_kit(profile)
			hanger._build_preview_character(profile.inventory, profile.loadout)
			hanger.hanger_ui.configure(profile.inventory, profile.loadout)
			hanger.hanger_ui.sync_loadout_selection()
			show_section("Overview")
	var next := OperationUI.action(panel, caption, Vector2(22,300), Vector2(316,52), callback, true)
	next.name = "FirstSortieNext"
	next.grab_focus()

func _upgrade_weapon() -> void:
	var error := FirstMissionPreparation.upgrade_weapon()
	if error != OK:
		FlowMenu.show_error(tr("Upgrade could not be saved: %s. Your materials are unchanged.") % error_string(error))
		return
	hanger.hanger_ui.configure(ProfileRuntime.get_profile().inventory, ProfileRuntime.get_profile().loadout)
	hanger.hanger_ui.sync_loadout_selection()
	AudioDirector.play_sfx(&"ui_confirm")
	show_section("Workshop")
	_open_upgrade_moment()

func _open_upgrade_moment() -> void:
	if not ProfileRuntime.get_profile().ar_damage_upgraded: return
	var error := GameState.present_scene("res://scenes/presentation/slice/workshop_moment.tscn", "ONE SPARE SCREW / BACK AT HOME")
	if error != OK and error != ERR_BUSY:
		FlowMenu.show_error(tr("Could not open the fitting. Your upgrade is saved; replay it from the workshop."))


# Presentation-only adapters; callbacks and data ownership remain unchanged.
func _wrapped_label(parent: Node, text: String, at: Vector2, extent: Vector2, font_size: int, color: Color = FieldManualStyle.INK) -> Label:
	var result := Label.new()
	# Establish wrapping before entering the tree: an unwrapped initial minimum
	# can clamp a subsequent size assignment and leave long briefs wider than the card.
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.text = text
	result.position = at
	result.size = extent
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result

func _panel(parent: Node, at: Vector2, extent: Vector2) -> Panel:
	var result := SliceUI.panel(parent, at, extent)
	result.add_theme_stylebox_override("panel", FieldManualStyle.panel())
	return result

func _label(parent: Node, text: String, at: Vector2, font_size: int = 18, color: Color = FieldManualStyle.INK) -> Label:
	return SliceUI.label(parent, text, at, font_size, color)

func _open_finale() -> void:
	if ProfileRuntime.get_profile().maintenance_closed:GameState.present_scene("res://scenes/presentation/slice/homecoming_finale.tscn","EVERYONE IS HOME")
