extends Node
## Run only in an isolated project/user-data directory (see the external test runner).
## Rotation-gap/first-fit cases adapted from Ragtail; see licenses/ragtail/UPSTREAM.md.
const PATH := "user://stash_rotation_test.json"
const EXPECTED := "user://stash_rotation_expected.json"
var checks := 0
var failures: Array[String] = []
var test_definitions: Array[StringName] = []

class NoFitLayout extends StashLayout:
	var tried_original := false
	var tried_rotated := false
	func can_place(instance_id: String, cell: Vector2i, rotated := false) -> bool:
		# Fault injection: exhaust both orientations without filling 10,000 rows.
		if instance_id == "test.stash.no_fit.wide":
			if rotated: tried_rotated = true
			else: tried_original = true
			return false
		return super.can_place(instance_id, cell, rotated)

func _ready() -> void:
	await get_tree().process_frame
	if "--gui" in OS.get_cmdline_user_args():
		# Keep injected pointers local; never warp or click the desktop cursor.
		var surface := SubViewport.new()
		surface.size = Vector2i(1280, 720)
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		surface.handle_input_locally = true
		get_tree().root.add_child(surface)
		reparent(surface)
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		_register(&"test.stash.block", Vector2i(11, 2))
		_register(&"test.stash.wide", Vector2i(2, 1))
		_register(&"test.stash.unit", Vector2i.ONE)
		_test_saved_layout()
	else:
		_test_rotation_gap()
		_test_first_fit_priority()
		await _test_refresh_and_sort_button()
		_test_sort_failure_is_atomic()
		_test_empty()
	for id in test_definitions: ContentDB._definitions.erase(id)
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	for failure in failures: push_error("STASH_ROTATION: " + failure)
	print("STASH_ROTATION_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
	checks += 1
	print("STASH_ROTATION %s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures.append(message)

func _register(id: StringName, size: Vector2i) -> void:
	var definition := ItemDefinition.new()
	definition.id = id
	definition.display_name = String(id)
	definition.stash_size = size
	definition.weight = .25
	ContentDB._definitions[id] = definition
	test_definitions.append(id)

func _add(profile: ProfileState, id: StringName, size: Vector2i) -> ItemInstance:
	_register(id, size)
	var item := ItemInstance.new(id, 1, 73.0, String(id))
	check(profile.inventory.add_item(item), "fixture owns " + String(id))
	return item

func _without_layout(profile: ProfileState) -> Dictionary:
	var data := profile.to_dict()
	data.erase("stash_layout")
	return data

func _valid_layout(model: StashLayout) -> void:
	var profile := model.profile
	var stored := 0
	for item in profile.inventory.get_items():
		if profile.loadout.is_equipped(item.instance_id):
			check(not profile.stash_layout.has(item.instance_id), "equipped item excluded: " + item.instance_id)
			continue
		stored += 1
		check(profile.stash_layout.has(item.instance_id), "owned item has exactly one placement: " + item.instance_id)
		if not profile.stash_layout.has(item.instance_id): continue
		var entry: Array = profile.stash_layout[item.instance_id]
		check(model._valid_entry(entry), "placement keeps [x, y, bool] format")
		check(model.can_place(item.instance_id, Vector2i(entry[0], entry[1]), entry[2]), "placement is in bounds and non-overlapping")
	check(stored == profile.stash_layout.size(), "layout has no missing or foreign instances")

func _test_rotation_gap() -> void:
	var profile := ProfileState.new(InventoryState.new(100), LoadoutState.new())
	var block := _add(profile, &"test.stash.block", Vector2i(11, 2))
	var wide := _add(profile, &"test.stash.wide", Vector2i(2, 1))
	var unit := _add(profile, &"test.stash.unit", Vector2i.ONE)
	var model := StashLayout.new(profile)
	var before := _without_layout(profile)
	model.sort_items()
	check(profile.stash_layout[block.instance_id] == [0, 0, false], "largest item starts at top left without rotation")
	check(profile.stash_layout[wide.instance_id] == [11, 0, true], "2x1 rotates into the 1x2 gap before using a later row")
	check(profile.stash_layout[unit.instance_id] == [0, 2, false], "occupied rotated cells force next item onto the next free row")
	check(_without_layout(profile) == before, "sorting changes layout only")
	check(profile.inventory.get_item(wide.instance_id) == wide, "sorting preserves the actual ItemInstance object")
	_valid_layout(model)
	var sorted_layout := profile.stash_layout.duplicate(true)
	model.sort_items()
	check(profile.stash_layout == sorted_layout, "second sort produces exactly the same cells and orientations")
	model.reconcile()
	check(profile.stash_layout == sorted_layout, "refresh reconciliation preserves sorted rotations")
	check(not model.move_item(wide.instance_id, Vector2i(11, 0), false), "unrotated right-edge overflow rejects")
	check(not model.move_item(wide.instance_id, Vector2i(0, 0), true), "overlapping move rejects")
	check(not model.move_item(wide.instance_id, Vector2i(-1, 0), true), "negative coordinates reject")
	check(profile.stash_layout == sorted_layout, "rejected moves leave every placement unchanged")
	check(SaveService.save_profile(profile, PATH) == OK, "normal save service writes the automatically rotated layout")
	var file := FileAccess.open(EXPECTED, FileAccess.WRITE)
	check(file != null, "isolated expected-layout file opens")
	if file:
		file.store_string(JSON.stringify(profile.to_dict()))
		file.close()
	_test_saved_layout()

func _test_saved_layout() -> void:
	var profile := SaveService.load_profile(PATH, false)
	check(profile != null and profile.validate(), "saved profile loads and validates")
	if not profile: return
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXPECTED))
	check(typeof(expected) == TYPE_DICTIONARY, "expected snapshot is readable")
	if typeof(expected) != TYPE_DICTIONARY: return
	check(profile.to_dict() == ProfileState.from_dict(expected).to_dict(), "persistence preserves all item, layout and profile fields")
	check(profile.stash_layout["test.stash.wide"] == [11, 0, true], "automatically chosen rotation survives persistence")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(SaveService.SCHEMA_VERSION == 8 and envelope.schema_version == 8, "existing schema 8 is unchanged")
	var layout := profile.stash_layout.duplicate(true)
	StashLayout.new(profile).reconcile()
	check(profile.stash_layout == layout, "load/refresh does not rearrange the saved layout")
	_valid_layout(StashLayout.new(profile))

func _test_first_fit_priority() -> void:
	var profile := ProfileState.new(InventoryState.new(100), LoadoutState.new())
	var block := _add(profile, &"test.stash.priority_block", Vector2i(10, 2))
	var wide := _add(profile, &"test.stash.priority_wide", Vector2i(2, 1))
	var unit := _add(profile, &"test.stash.priority_unit", Vector2i.ONE)
	var model := StashLayout.new(profile)
	model.sort_items()
	check(profile.stash_layout[block.instance_id] == [0, 0, false], "scan is y outer / x inner")
	check(profile.stash_layout[wide.instance_id] == [10, 0, false], "original orientation wins when both fit at the same cell")
	check(profile.stash_layout[unit.instance_id] == [10, 1, false], "row-major scan fills the next earliest cell")
	_valid_layout(model)

func _test_refresh_and_sort_button() -> void:
	var profile := ProfileRuntime.new_profile()
	var pistol := ItemInstance.new(&"weapon.pistol_01", 1, 61, "stash_rotation_pistol")
	pistol.fitting = "quickloader"
	check(profile.inventory.add_item(pistol), "real fitted pistol added")
	check(profile.inventory.add_item(ItemInstance.new(&"ammo.556_ap", 37, 84, "stash_rotation_ammo")), "real ammunition stack added")
	var model := StashLayout.new(profile)
	model.reconcile()
	check(model.move_item(pistol.instance_id, Vector2i(8, 10), true), "fixture has a manual distant rotated placement")
	var before := _without_layout(profile)
	var references := profile.inventory.get_items()
	var weight := profile.inventory.current_weight
	var carried_capacity := profile.get_carried_capacity()
	var layout := profile.stash_layout.duplicate(true)
	var ui := HangerUI.new()
	ui.configure(profile.inventory, profile.loadout)
	add_child(ui)
	ui.stash_grid.refresh()
	ui.refresh_owned_items()
	check(profile.stash_layout == layout, "opening and refreshing actual UI preserves every existing cell and orientation")
	check(_without_layout(profile) == before, "opening UI changes no inventory or profile fields")
	var sort_button: Button
	for button in ui.find_children("*", "Button", true, false):
		if button.text == "SORT": sort_button = button
	check(sort_button != null, "production SORT button exists")
	if sort_button: sort_button.pressed.emit()
	check(profile.stash_layout != layout, "only explicit SORT action rearranges the manual layout")
	check(_without_layout(profile) == before, "SORT preserves quantities, durability, fittings, wallet, equipment and sortie fields")
	check(profile.inventory.current_weight == weight and profile.get_carried_capacity() == carried_capacity, "SORT preserves inventory weight and carried capacity")
	for item in references:
		check(profile.inventory.get_item(item.instance_id) == item, "SORT retains each original object: " + item.instance_id)
	_valid_layout(ui.stash_grid.model)
	var sorted_layout := profile.stash_layout.duplicate(true)
	ui.stash_grid.refresh()
	check(profile.stash_layout == sorted_layout, "UI refresh after SORT preserves its exact result")
	if "--gui" in OS.get_cmdline_user_args(): await _test_gui_drag(ui, pistol.instance_id)
	var drag := {"stash": ui.stash_grid, "instance_id": pistol.instance_id, "rotated": true}
	ui.stash_grid._drop_data(Vector2(10 * 48 + 4, 12 * 48 + 4), drag)
	check(profile.stash_layout[pistol.instance_id] == [10, 12, true], "production manual-drop callback preserves requested cells and rotation")
	layout = profile.stash_layout.duplicate(true)
	ui.stash_grid._drop_data(Vector2(12 * 48, 0), drag)
	check(profile.stash_layout == layout, "production invalid-drop callback leaves layout unchanged")
	ui.stash_grid.select_item(pistol.instance_id)
	ui.stash_grid.rotate_selected()
	check(profile.stash_layout[pistol.instance_id] == [10, 12, false], "manual rotation still changes only the selected item")
	var primary := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var secondary := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY)
	ui.secondary_weapon_option._drop_data(Vector2.ZERO, {"stash": ui.stash_grid, "instance_id": primary})
	check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == secondary and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY) == primary, "production slot-drop callback swaps occupied weapon slots atomically")
	check(profile.stash_layout[pistol.instance_id] == [10, 12, false], "equipment reconciliation does not auto-sort unrelated items")
	ui.stash_grid._drop_data(Vector2(4, 14 * 48 + 4), {"stash": ui.stash_grid, "instance_id": primary, "rotated": false})
	check(not profile.loadout.is_equipped(primary) and profile.stash_layout[primary] == [0, 14, false], "equipped weapon can still be dropped back into the warehouse")
	ui.weapon_option._drop_data(Vector2.ZERO, {"stash": ui.stash_grid, "instance_id": pistol.instance_id})
	check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == pistol.instance_id and not profile.stash_layout.has(pistol.instance_id), "warehouse item equips without duplicate placement")
	check(profile.inventory.to_dict() == before.inventory and profile.credits == before.credits, "manual transfers preserve inventory identity, counts, durability, fittings and money")
	check(profile.validate(), "profile remains valid after all manual interactions")
	_valid_layout(ui.stash_grid.model)
	ui.free()

func _test_gui_drag(ui: HangerUI, instance_id: String) -> void:
	await get_tree().process_frame
	var grid := ui.stash_grid
	var was_rotated: bool = grid.model.profile.stash_layout[instance_id][2]
	var tile: StashTile
	for child in grid.get_children():
		if child is StashTile and child.instance_id == instance_id: tile = child
	check(tile != null, "GUI has a tile for the sorted item")
	if not tile: return
	await _gui_drag(tile, grid.global_position + Vector2(10 * 48 + 4, 6 * 48 + 4), true)
	check(grid.model.profile.stash_layout[instance_id] == [10, 6, not was_rotated], "native GUI R-drag toggles the actual sorted orientation, then drops at requested cells")
	var primary := grid.model.profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var secondary := grid.model.profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY)
	await _gui_drag((ui.weapon_option as StashSlot).drag_handle, ui.secondary_weapon_option.global_position + Vector2(25, 20))
	check(grid.model.profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == secondary and grid.model.profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY) == primary, "native GUI drag swaps occupied equipment slots after rotation-aware sorting")

func _gui_drag(source: Control, target: Vector2, rotate := false) -> void:
	var start := source.global_position + source.size * .5
	var press := InputEventMouseButton.new()
	press.position = start
	press.global_position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	get_viewport().push_input(press)
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = start + Vector2(24, 0)
	motion.global_position = motion.position
	motion.relative = Vector2(24, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion)
	await get_tree().process_frame
	check(get_viewport().gui_is_dragging(), "injected mouse press/movement starts a native GUI drag")
	if rotate:
		var data: Variant = get_viewport().gui_get_drag_data()
		check(typeof(data) == TYPE_DICTIONARY, "native drag exposes production item data")
		if typeof(data) == TYPE_DICTIONARY:
			var before: bool = data.rotated
			var key := InputEventKey.new()
			key.keycode = KEY_R
			key.pressed = true
			get_viewport().push_input(key)
			await get_tree().process_frame
			check(data.rotated == not before, "R toggles rather than assumes a previously unrotated item")
			key.pressed = false
			get_viewport().push_input(key)
	motion = InputEventMouseMotion.new()
	motion.position = target
	motion.global_position = target
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.position = target
	release.global_position = target
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	get_viewport().push_input(release)
	await get_tree().process_frame
	await get_tree().process_frame

func _test_sort_failure_is_atomic() -> void:
	var profile := ProfileState.new(InventoryState.new(100), LoadoutState.new())
	var block := _add(profile, &"test.stash.no_fit.block", Vector2i(4, 2))
	var wide := _add(profile, &"test.stash.no_fit.wide", Vector2i(2, 1))
	profile.stash_layout = {block.instance_id: [4, 8, true], wide.instance_id: [1, 1, false]}
	var before := profile.to_dict()
	var model := NoFitLayout.new(profile)
	model.sort_items()
	check(model.tried_original and model.tried_rotated, "failed search exhausts both orientations")
	check(profile.to_dict() == before, "no-fit SORT rolls back partial placements and keeps all profile fields")
	check(profile.inventory.get_item(block.instance_id) == block and profile.inventory.get_item(wide.instance_id) == wide, "no-fit SORT preserves actual item objects")
	_valid_layout(StashLayout.new(profile))
	model.sort_items()
	check(profile.to_dict() == before, "repeated failed SORT leaves the original valid layout stable")
	var bounds := StashLayout.new(profile)
	check(not bounds.can_place(wide.instance_id, Vector2i(0, StashLayout.MAX_ROW), false) and not bounds.can_place(wide.instance_id, Vector2i(0, StashLayout.MAX_ROW), true), "both orientations reject the hard row boundary")

func _test_empty() -> void:
	var profile := ProfileState.new(InventoryState.new(100), LoadoutState.new())
	var before := profile.to_dict()
	StashLayout.new(profile).sort_items()
	check(profile.to_dict() == before, "sorting an empty warehouse is a no-op")
