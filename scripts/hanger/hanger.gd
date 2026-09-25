extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const UI_SCENE := preload("res://scenes/ui/hanger_ui.tscn")

var preview_character: PlayerController
var hanger_ui: HangerUI


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.set_music_context(&"hanger")
	VisualFactory.add_world_environment(self, Color("0a111b"))
	_build_hanger()
	var profile := ProfileRuntime.get_profile()
	if not profile:
		push_error("Hanger requires a loaded ProfileState")
		return
	_build_preview_character(profile.inventory, profile.loadout)
	_build_camera()
	hanger_ui = UI_SCENE.instantiate() as HangerUI
	hanger_ui.configure(profile.inventory, profile.loadout)
	add_child(hanger_ui)
	hanger_ui.weapon_selected.connect(_on_weapon_selected)
	hanger_ui.secondary_weapon_selected.connect(_on_secondary_weapon_selected)
	hanger_ui.armor_selected.connect(_on_armor_selected)
	hanger_ui.backpack_selected.connect(_on_backpack_selected)
	hanger_ui.deploy_requested.connect(_on_deploy_requested)


func _build_hanger() -> void:
	VisualFactory.static_box(self, Vector3(24.0, 0.25, 16.0), Vector3(0.0, -0.14, 0.0), Color("27333d"), "Floor")
	VisualFactory.static_box(self, Vector3(24.0, 9.0, 0.3), Vector3(0.0, 4.5, -6.0), Color("1d2935"), "BackWall")
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		VisualFactory.box(self, Vector3(0.22, 8.6, 0.28), Vector3(x, 4.3, -5.8), Color("48596a"), "WallBeam")
		var wall_light := VisualFactory.box(self, Vector3(1.5, 0.08, 0.08), Vector3(x, 6.8, -5.58), Color("5aefff"), "WallLight")
		wall_light.material_override = VisualFactory.material(Color("36808a"), 0.2, 0.2, Color("5aefff"), 3.0)
	var platform_mesh := CylinderMesh.new()
	platform_mesh.top_radius = 2.15
	platform_mesh.bottom_radius = 2.35
	platform_mesh.height = 0.32
	var platform := MeshInstance3D.new()
	platform.name = "PreviewPlatform"
	platform.mesh = platform_mesh
	platform.position = Vector3(-2.2, 0.16, 0.0)
	platform.material_override = VisualFactory.material(Color("344657"), 0.65, 0.28)
	add_child(platform)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.88
	ring_mesh.outer_radius = 2.02
	var ring := MeshInstance3D.new()
	ring.name = "PlatformGlow"
	ring.mesh = ring_mesh
	ring.position = Vector3(-2.2, 0.35, 0.0)
	ring.material_override = VisualFactory.material(Color("2c8790"), 0.2, 0.2, Color("63f2f0"), 3.5)
	add_child(ring)
	for side in [-1.0, 1.0]:
		VisualFactory.box(self, Vector3(0.5, 6.0, 0.5), Vector3(-6.4 * side, 3.0, -3.8), Color("2f3b48"), "Support")


func _build_preview_character(inventory: InventoryState, loadout: LoadoutState) -> void:
	if is_instance_valid(preview_character):
		remove_child(preview_character)
		preview_character.queue_free()
	preview_character = PLAYER_SCENE.instantiate() as PlayerController
	preview_character.preview_mode = true
	preview_character.position = Vector3(-2.2, 0.34, 0.0)
	preview_character.configure_loadout(inventory, loadout)
	add_child(preview_character)
	preview_character.body_visual.rotation.y = 2.55


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector3(-2.2, 2.45, 5.25)
	camera.fov = 39.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(-2.2, 1.15, 0.0), Vector3.UP)
	var key_light := SpotLight3D.new()
	key_light.position = Vector3(-4.2, 5.6, 3.6)
	add_child(key_light)
	key_light.look_at(Vector3(-2.2, 1.0, 0.0), Vector3.UP)
	key_light.light_color = Color("c9f6ff")
	key_light.light_energy = 2.6
	key_light.spot_range = 10.0
	key_light.shadow_enabled = true


func _on_weapon_selected(instance_id: String) -> void:
	var profile := ProfileRuntime.get_profile()
	if not profile:
		return
	var changed := profile.loadout.unequip(LoadoutState.SLOT_WEAPON_PRIMARY) if instance_id.is_empty() else profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, instance_id, profile.inventory)
	if not changed:
		if hanger_ui:
			hanger_ui.sync_loadout_selection()
		return
	_build_preview_character(profile.inventory, profile.loadout)
	hanger_ui.sync_loadout_selection()


func _on_secondary_weapon_selected(instance_id: String) -> void:
	var profile := ProfileRuntime.get_profile()
	if not profile:
		return
	var changed := profile.loadout.unequip(LoadoutState.SLOT_WEAPON_SECONDARY) if instance_id.is_empty() else profile.loadout.equip(LoadoutState.SLOT_WEAPON_SECONDARY, instance_id, profile.inventory)
	if not changed:
		if hanger_ui:
			hanger_ui.sync_loadout_selection()
		return
	_build_preview_character(profile.inventory, profile.loadout)
	hanger_ui.sync_loadout_selection()


func _on_armor_selected(instance_id: String) -> void:
	var profile := ProfileRuntime.get_profile()
	if not profile:
		return
	var changed := profile.loadout.unequip(LoadoutState.SLOT_ARMOR) if instance_id.is_empty() else profile.loadout.equip(LoadoutState.SLOT_ARMOR, instance_id, profile.inventory)
	if not changed:
		hanger_ui.sync_loadout_selection()
		return
	_build_preview_character(profile.inventory, profile.loadout)
	hanger_ui.sync_loadout_selection()


func _on_backpack_selected(instance_id: String) -> void:
	var profile := ProfileRuntime.get_profile()
	if not profile:
		return
	var changed := profile.loadout.unequip(LoadoutState.SLOT_BACKPACK) if instance_id.is_empty() else profile.loadout.equip(LoadoutState.SLOT_BACKPACK, instance_id, profile.inventory)
	if not changed:
		hanger_ui.sync_loadout_selection()
		return
	_build_preview_character(profile.inventory, profile.loadout)
	hanger_ui.sync_loadout_selection()


func _on_deploy_requested() -> void:
	var profile := ProfileRuntime.get_profile()
	var carried_ammo_ids := _get_carried_ammo_ids(profile) if profile else [] as Array[String]
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		carried_ammo_ids
	) if profile else null
	if not request or not SortieRuntime.start_sortie(request, profile):
		push_error("Could not start prototype sortie")
		return
	GameState.begin_mission()


func _get_carried_ammo_ids(profile: ProfileState) -> Array[String]:
	var instance_ids: Array[String] = []
	var ammo_definition_ids: Dictionary = {}
	for slot_id in LoadoutState.WEAPON_SLOT_IDS:
		var weapon_item := profile.loadout.get_item(slot_id, profile.inventory)
		var weapon_definition := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
		var ammo_definition_id := weapon_definition.get_runtime_ammo_definition_id() if weapon_definition else &""
		if not ammo_definition_id.is_empty():
			ammo_definition_ids[ammo_definition_id] = true
	for item in profile.inventory.get_items():
		if ammo_definition_ids.has(item.definition_id):
			instance_ids.append(item.instance_id)
	return instance_ids
