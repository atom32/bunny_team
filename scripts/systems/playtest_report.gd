class_name PlaytestReport
extends RefCounted
## Opt-in local text only. Never reads a whole save or identifies a person/device.
const CONTEXT_KEYS := ["build","locale","renderer","viewport","window","scene","area","mission","profile_stage","sortie_status","successful_sorties","failed_sorties"]
const BUILD_KEYS := ["id","source_sha256","packaged","engine"]
const ANSWER_KEYS := ["stuck","remembered","replay","first_play"]
const REPORT_KEYS := ["schema","purpose","time_basis","rating_basis","context","answers"]
const STAGES := ["unavailable","first_mission","q01","q02","relay","recorder","power","supply","complete"]
const STATUSES := ["preparing","active","completed","failed","abandoned"]
const SCENES := ["boot","base","battle","result","training","story","other"]
const RENDERERS := ["forward_plus","mobile","gl_compatibility","unknown"]

static func build_context(tree: SceneTree) -> Dictionary:
	if not tree or not is_instance_valid(tree.root): return {}
	var identity := BuildIdentity.current()
	var profile := ProfileRuntime.get_profile()
	var session := SortieRuntime.get_current_session()
	var pending: Dictionary = profile.sortie_checkpoint.get("session",{}) if profile else {}
	var area := String(session.area_id) if session else String(pending.get("area",""))
	var mission := String(session.mission_id) if session else String(pending.get("mission",""))
	var status: int = session.status if session else int(pending.get("status",-1))
	var viewport_size := tree.root.get_visible_rect().size
	var window_size := tree.root.size
	var renderer := RenderingServer.get_current_rendering_method()
	var locale := TranslationServer.get_locale()
	return {"build":{"id":identity.get("id","development"),"source_sha256":identity.get("source_sha256",""),"packaged":identity.get("packaged",false),"engine":identity.get("engine","")},
		"locale":locale if locale in ["en","zh_CN"] else "other","renderer":renderer if renderer in RENDERERS else "unknown",
		"viewport":[roundi(viewport_size.x),roundi(viewport_size.y)],"window":[window_size.x,window_size.y],
		"scene":_scene_kind(tree.current_scene.scene_file_path if tree.current_scene else ""),
		"area":area if ContentDB.has_area(StringName(area)) else "","mission":mission if ContentDB.has_mission(StringName(mission)) else "",
		"profile_stage":_profile_stage(profile),"sortie_status":STATUSES[status] if status >= 0 and status < STATUSES.size() else "none",
		"successful_sorties":profile.successful_sorties if profile else 0,"failed_sorties":profile.failed_sorties if profile else 0}

static func _scene_kind(path: String) -> String:
	match path:
		"res://scenes/presentation/slice/boot.tscn": return "boot"
		"res://scenes/presentation/slice/hideout.tscn", "res://scenes/hanger/hanger.tscn": return "base"
		"res://scenes/battle/battle.tscn": return "battle"
		"res://scenes/result/result.tscn": return "result"
		"res://scenes/presentation/slice/training_room.tscn": return "training"
	return "story" if path.begins_with("res://scenes/presentation/slice/") else "other"

static func _profile_stage(profile: ProfileState) -> String:
	if not profile: return "unavailable"
	if not profile.first_mission_completed: return "first_mission"
	if not profile.narrative_slice.settled.Q01: return "q01"
	if not profile.narrative_slice.settled.Q02: return "q02"
	return CampusChapter.stage(profile.campus_chapter)

static func compose(context: Dictionary, answers: Dictionary) -> Dictionary:
	if not _valid_context(context) or not _valid_answers(answers): return {"error":ERR_INVALID_DATA,"report":{}}
	return {"error":OK,"report":{"schema":1,"purpose":"local_playtest_feedback","time_basis":"player_estimate_not_measured","rating_basis":"not_a_platform_rating","context":context.duplicate(true),"answers":answers.duplicate(true)}}

static func preview(report: Dictionary) -> String:
	return JSON.stringify(report,"\t",true) if _valid_report(report) else ""

static func save_local(report: Dictionary, directory := "user://feedback") -> Dictionary:
	if not _valid_report(report): return {"error":ERR_INVALID_DATA,"path":""}
	if not _local_directory(directory): return {"error":ERR_INVALID_PARAMETER,"path":""}
	# A file occupying an ancestor is a normal save failure, not an engine error.
	var ancestor := "user:/"
	for part in directory.trim_prefix("user://").split("/"):
		ancestor += "/" + part
		if FileAccess.file_exists(ancestor): return {"error":ERR_CANT_CREATE,"path":""}
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return {"error":error,"path":""}
	# An exclusively created new directory owns its new report file. Never open
	# an existing report with WRITE, even if another process saves simultaneously.
	var folder := ""
	for attempt in 8:
		var candidate := directory + "/report-" + Crypto.new().generate_random_bytes(12).hex_encode()
		error = DirAccess.make_dir_absolute(candidate)
		if error == OK: folder = candidate; break
		if error != ERR_ALREADY_EXISTS: return {"error":error,"path":""}
	if folder.is_empty(): return {"error":ERR_ALREADY_EXISTS,"path":""}
	var path := folder + "/report.json"
	var file := FileAccess.open(path,FileAccess.WRITE)
	if not file: return {"error":FileAccess.get_open_error(),"path":""}
	var body := preview(report)
	file.store_string(body); file.flush(); error = file.get_error(); file.close()
	if error != OK: return {"error":error,"path":""}
	if FileAccess.get_file_as_string(path) != body: return {"error":ERR_FILE_CORRUPT,"path":""}
	return {"error":OK,"path":path}

static func _exact(value: Variant, keys: Array) -> bool:
	if typeof(value) != TYPE_DICTIONARY or value.size() != keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

static func _matches(value: Variant, pattern: String, maximum: int) -> bool:
	if typeof(value) != TYPE_STRING or value.length() > maximum: return false
	var regex := RegEx.new(); regex.compile(pattern)
	return regex.search(value) != null

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return typeof(value) == TYPE_INT and value >= minimum and value <= maximum

static func _dimensions(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and _integer(value[0],0,65535) and _integer(value[1],0,65535)

static func _valid_context(value: Variant) -> bool:
	if not _exact(value,CONTEXT_KEYS) or not _exact(value.build,BUILD_KEYS): return false
	var build: Dictionary = value.build
	if not _matches(build.id,"^[A-Za-z0-9_.-]+$",128) or typeof(build.packaged) != TYPE_BOOL: return false
	if not _matches(build.source_sha256,"^([0-9a-f]{64})?$",64) or (build.packaged and build.source_sha256.is_empty()): return false
	if not _matches(build.engine,"^[A-Za-z0-9_.+() -]+$",128): return false
	for key in ["locale","renderer","scene","profile_stage","sortie_status"]:
		if typeof(value[key]) != TYPE_STRING: return false
	if value.locale not in ["en","zh_CN","other"] or value.renderer not in RENDERERS or value.scene not in SCENES: return false
	if not _dimensions(value.viewport) or not _dimensions(value.window) or value.profile_stage not in STAGES: return false
	if value.sortie_status != "none" and value.sortie_status not in STATUSES: return false
	if typeof(value.area) != TYPE_STRING or (not value.area.is_empty() and not ContentDB.has_area(StringName(value.area))): return false
	if typeof(value.mission) != TYPE_STRING or (not value.mission.is_empty() and not ContentDB.has_mission(StringName(value.mission))): return false
	return _integer(value.successful_sorties,0,1000000000) and _integer(value.failed_sorties,0,1000000000)

static func _valid_answers(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY: return false
	var required := ANSWER_KEYS.duplicate()
	if value.has("estimated_minutes"): required.append("estimated_minutes")
	if not _exact(value,required): return false
	for key in ["stuck","remembered"]:
		if typeof(value[key]) != TYPE_STRING or value[key].length() > 2000: return false
	if typeof(value.replay) != TYPE_STRING or typeof(value.first_play) != TYPE_STRING: return false
	if value.replay not in ["undecided","yes","no"] or value.first_play not in ["unspecified","yes","no"]: return false
	return not value.has("estimated_minutes") or _integer(value.estimated_minutes,0,600)

static func _valid_report(report: Dictionary) -> bool:
	return _exact(report,REPORT_KEYS) and typeof(report.schema) == TYPE_INT and report.schema == 1 and report.purpose == "local_playtest_feedback" and report.time_basis == "player_estimate_not_measured" and report.rating_basis == "not_a_platform_rating" and _valid_context(report.context) and _valid_answers(report.answers)

static func _local_directory(path: String) -> bool:
	# No OS paths, traversal, aliases, Windows alternate streams or separators.
	if not path.begins_with("user://") or path.length() > 192: return false
	var relative := path.trim_prefix("user://")
	if relative.is_empty(): return false
	for part in relative.split("/",true):
		if not _matches(part,"^[A-Za-z0-9_-]+$",64): return false
	return true
