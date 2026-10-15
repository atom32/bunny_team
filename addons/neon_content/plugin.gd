@tool
extends EditorPlugin
## Editor only: mirrors definitions into YARD, never replaces ContentDB or saves profiles.
const REGISTRY := preload("res://addons/yard/registry.gd")
const ROOT := "res://resources/editor_catalogs/"
const CATALOGS := {
	"weapons": ["resources/weapons"],
	"items": ["resources/weapons", "resources/equipment", "resources/ammo", "resources/items"],
	"enemies": ["resources/enemies"],
}
var menu: MenuButton
var weapon_gizmo: EditorNode3DGizmoPlugin
var item_wizard: ConfirmationDialog
var audit_dialog: AcceptDialog
var asset_window: Window

func _enter_tree() -> void:
	weapon_gizmo = preload("res://addons/neon_content/weapon_gizmo.gd").new()
	add_node_3d_gizmo_plugin(weapon_gizmo)
	menu = MenuButton.new()
	menu.text = "Neon Tools"
	menu.get_popup().add_item("Open editable campus", 0)
	menu.get_popup().add_item("Open weapon workbench", 1)
	menu.get_popup().add_item("Open module sample", 2)
	menu.get_popup().add_separator()
	menu.get_popup().add_item("Synchronize YARD catalogs / stable IDs", 3)
	menu.get_popup().add_item("Audit content / references", 4)
	menu.get_popup().add_item("Create item / review changes", 5)
	menu.get_popup().add_item("Review model / animation (isolated viewport)", 6)
	menu.get_popup().id_pressed.connect(_action)
	add_control_to_container(CONTAINER_TOOLBAR, menu)
	if not OS.get_environment("NEON_CONTENT_BOOTSTRAP").is_empty():
		_bootstrap.call_deferred()

func _exit_tree() -> void:
	if is_instance_valid(asset_window): asset_window.queue_free()
	if is_instance_valid(item_wizard): item_wizard.queue_free()
	if is_instance_valid(audit_dialog): audit_dialog.queue_free()
	if weapon_gizmo:
		remove_node_3d_gizmo_plugin(weapon_gizmo)
		weapon_gizmo = null
	if is_instance_valid(menu):
		remove_control_from_container(CONTAINER_TOOLBAR, menu)
		menu.queue_free()

func _action(id: int) -> void:
	if id == 6:
		_open_asset_review()
		return
	if id == 4:
		_audit()
		return
	if id == 5:
		if not is_instance_valid(item_wizard):
			item_wizard = preload("res://addons/neon_content/item_wizard.gd").new()
			EditorInterface.get_base_control().add_child(item_wizard)
			item_wizard.on_published = synchronize
		item_wizard.popup_centered(Vector2i(760, 680))
		return
	if id == 3:
		var report := synchronize()
		print("NEON_CATALOG_SYNC ", JSON.stringify(report))
		return
	var paths := ["res://scenes/areas/street_district.tscn", "res://scenes/tools/weapon_workbench.tscn", "res://scenes/tools/module_sample.tscn"]
	EditorInterface.open_scene_from_path(paths[id])

func _open_asset_review() -> void:
	if not is_instance_valid(asset_window):
		asset_window = Window.new()
		asset_window.title = "Neon / Model and Animation Review"
		asset_window.size = Vector2i(1280, 800)
		asset_window.close_requested.connect(asset_window.hide)
		EditorInterface.get_base_control().add_child(asset_window)
		var container := SubViewportContainer.new()
		container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		container.stretch = true
		asset_window.add_child(container)
		var viewport := SubViewport.new()
		viewport.size = asset_window.size
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		container.add_child(viewport)
		var preview := preload("res://scenes/tools/asset_workbench.tscn").instantiate()
		preview.set_meta("neon_asset_preview",true)
		viewport.add_child(preview)
	asset_window.popup_centered()

func _audit() -> void:
	var recipes := SupplyService.RECIPES.duplicate()
	recipes.merge(SupplyService.FACILITY_RECIPES)
	var manifest := ResourceLoader.load("res://resources/content/content_manifest.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as ContentManifest
	var report: Dictionary = preload("res://addons/neon_content/content_audit.gd").audit(manifest, true, recipes)
	if not is_instance_valid(audit_dialog):
		audit_dialog = AcceptDialog.new(); audit_dialog.title = "Neon / Content Audit"
		var text := TextEdit.new(); text.name = "Report"; text.editable = false; text.custom_minimum_size = Vector2(900, 560)
		audit_dialog.add_child(text); EditorInterface.get_base_control().add_child(audit_dialog)
	var lines := PackedStringArray(["%s / errors %d / warnings %d" % ["PASS" if report.pass else "FAIL", report.errors.size(), report.warnings.size()]])
	for severity in ["errors", "warnings"]:
		for entry in report[severity]: lines.append("[%s] %s | %s\n%s" % [severity, entry.code, entry.path, entry.message])
	lines.append("\nITEMS / ID | TYPE | EN | ZH | ACQUISITION CHANNELS")
	for item in report.items: lines.append("%s | %s | %s | %s | %s" % [item.id, item.type, item.name_en, item.name_zh, ", ".join(item.channels)])
	audit_dialog.get_node("Report").text = "\n".join(lines)
	audit_dialog.popup_centered(Vector2i(940, 620))

func synchronize() -> Dictionary:
	var report := {"pass": true, "catalogs": {}, "errors": []}
	DirAccess.make_dir_recursive_absolute(ROOT)
	var expression := RegEx.new()
	expression.compile('(?m)^id = &?"([^"]+)"')
	var pending: Dictionary = {}
	for title: String in CATALOGS:
		var existing: Resource = load(ROOT + title + ".tres") if FileAccess.file_exists(ROOT + title + ".tres") else null
		var registry: Resource = REGISTRY.new()
		registry.set("_version", 2)
		# No basename-based auto-scan: definition.id remains the only content ID.
		registry.set("_scan_auto", false)
		var forward: Dictionary = registry.get("_uids_to_string_ids")
		var reverse: Dictionary = registry.get("_string_ids_to_uids")
		for folder: String in CATALOGS[title]:
			for filename: String in DirAccess.get_files_at("res://" + folder):
				if not filename.ends_with(".tres"): continue
				var path := "res://" + folder + "/" + filename
				var source := FileAccess.get_file_as_string(path)
				var match_id := expression.search(source)
				if not match_id:
					report.errors.append("Missing definition.id: " + path)
					continue
				var content_id := StringName(match_id.get_string(1))
				if reverse.has(content_id):
					report.errors.append("Duplicate definition.id: " + String(content_id))
					continue
				# Embed UID in the header only; all gameplay properties stay byte-identical.
				var header := source.get_slice("\n", 0)
				var uid_pattern := RegEx.new()
				uid_pattern.compile('uid="([^"]+)"')
				var uid_match := uid_pattern.search(header)
				var uid: int = ResourceUID.text_to_id(uid_match.get_string(1)) if uid_match else ResourceUID.create_id()
				var uid_text := ResourceUID.id_to_text(uid)
				if forward.has(StringName(uid_text)):
					report.errors.append("Duplicate resource UID: " + path)
					continue
				if existing and existing.has_uid(uid_text) and existing.get_string_id(uid_text) != content_id:
					report.errors.append("Established definition.id changed; explicit migration required: " + path)
					continue
				if not uid_match:
					var new_header := header.replace("]", ' uid="' + uid_text + '"]')
					var file := FileAccess.open(path, FileAccess.WRITE)
					if not file:
						report.errors.append("Cannot persist resource UID: " + path)
						continue
					file.store_string(new_header + source.substr(header.length()))
					file.close()
				if ResourceUID.has_id(uid):
					ResourceUID.set_id(uid, path)
				else:
					ResourceUID.add_id(uid, path)
				forward[StringName(uid_text)] = content_id
				reverse[content_id] = StringName(uid_text)
		pending[title] = {"registry": registry, "existing": existing}
		report.catalogs[title] = reverse.size()
	# Invalid definitions must not replace the last known-good editor catalogs.
	if report.errors.is_empty():
		for title: String in pending:
			# Preserve the loaded resource identity, including an already-open YARD table.
			var target: Resource = pending[title].existing if pending[title].existing else pending[title].registry
			if pending[title].existing:
				for property in ["_version", "_scan_auto", "_uids_to_string_ids", "_string_ids_to_uids"]:
					target.set(property, pending[title].registry.get(property))
				target.emit_changed()
			var error := ResourceSaver.save(target, ROOT + title + ".tres")
			if error != OK: report.errors.append("Cannot save catalog: " + title)
	report.pass = report.errors.is_empty()
	EditorInterface.get_resource_filesystem().scan()
	return report

func _bootstrap() -> void:
	if EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().create_timer(.2).timeout
		_bootstrap.call_deferred()
		return
	var report := synchronize()
	var path := OS.get_environment("NEON_CONTENT_BOOTSTRAP")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("NEON_CONTENT_BOOTSTRAP ", "PASS" if report.pass else "FAIL", " ", report.catalogs)
