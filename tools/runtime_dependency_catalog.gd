extends SceneTree
## Read imported dependencies in an isolated build copy. Does not instantiate game scenes.
var files: Array[String] = []

func scan(path: String) -> void:
	if FileAccess.file_exists(path.path_join(".gdignore")): return
	var directory := DirAccess.open(path)
	if not directory: return
	var names := directory.get_files();names.sort()
	for name in names:
		if not name.begins_with("."): files.append(path.path_join(name))
	var folders := directory.get_directories();folders.sort()
	for folder in folders:
		if not folder.begins_with("."): scan(path.path_join(folder))

func _initialize() -> void:
	var destination := OS.get_environment("BUNNY_EXPORT_CATALOG")
	if destination.is_empty(): push_error("BUNNY_EXPORT_CATALOG is required");quit(1);return
	for folder in ["assets","resources","scripts","scenes","local_qa","localization"]: scan("res://"+folder)
	files.sort()
	var dependencies := {}
	var plain_types := ["gd","tres","tscn","gdshader","gdshaderinc","res"]
	for path in files:
		if path.get_extension() in plain_types or FileAccess.file_exists(path+".import"):
			var normalized: Array[String] = []
			for dependency in ResourceLoader.get_dependencies(path):
				var parts := dependency.split("::",false)
				var resolved := ""
				for part in parts:
					if part.begins_with("res://"): resolved = part
				if resolved.is_empty() and parts[0].begins_with("uid://"):
					var uid := ResourceUID.text_to_id(parts[0])
					if ResourceUID.has_id(uid): resolved = ResourceUID.get_id_path(uid)
				if resolved.is_empty(): push_error("Unresolved imported dependency: "+dependency);quit(1);return
				normalized.append(resolved)
			normalized.sort();dependencies[path] = normalized
	var autoloads: Array[String] = []
	for property in ProjectSettings.get_property_list():
		if String(property.name).begins_with("autoload/"):
			autoloads.append(String(ProjectSettings.get_setting(property.name)).trim_prefix("*"))
	var output := FileAccess.open(destination,FileAccess.WRITE)
	if not output: push_error("Could not write dependency catalog");quit(1);return
	output.store_string(JSON.stringify({"version":1,"engine":Engine.get_version_info().string,"engine_license_text":Engine.get_license_text(),"engine_license_info":Engine.get_license_info(),"engine_copyright_info":Engine.get_copyright_info(),"main_scene":ProjectSettings.get_setting("application/run/main_scene"),"autoloads":autoloads,"classes":ProjectSettings.get_global_class_list(),"files":files,"dependencies":dependencies},"\t"))
	output.close()
	print("RUNTIME_DEPENDENCY_CATALOG: PASS / ",dependencies.size()," resource records")
	quit()
