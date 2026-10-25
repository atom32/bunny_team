extends Node
## Controlled local reporting/privacy tests, not human feedback or platform ratings.
var checks := 0
var failures: Array[String] = []
var context: Dictionary
var answers := {"stuck":"","remembered":"","replay":"undecided","first_play":"unspecified"}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func normalized(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

func reject(c: Dictionary, a: Dictionary, message: String) -> void:
	var result := PlaytestReport.compose(c,a)
	check(result.error == ERR_INVALID_DATA and result.report.is_empty(),message)

func _ready() -> void:
	await get_tree().process_frame
	_context()
	_answers()
	_storage()
	_source_boundary()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	for failure in failures: push_error("PLAYTEST_REPORT: " + failure)
	print("PLAYTEST_REPORT_TEST: %s (%d checks; controlled local reporting)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _context() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	var before := profile.to_dict()
	var disk_exists := FileAccess.file_exists(SaveService.DEFAULT_SAVE_PATH)
	var disk_hash := FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH) if disk_exists else ""
	context = PlaytestReport.build_context(get_tree())
	check(profile.to_dict() == before and FileAccess.file_exists(SaveService.DEFAULT_SAVE_PATH) == disk_exists and (not disk_exists or FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH) == disk_hash),"context collection neither mutates profile nor writes its disk")
	check(PlaytestReport._exact(context,PlaytestReport.CONTEXT_KEYS) and PlaytestReport._exact(context.build,PlaytestReport.BUILD_KEYS),"runtime context exposes only the twelve explicit fields and four build fields")
	check(context.build == BuildIdentity.current() and context.profile_stage == "first_mission" and context.sortie_status == "none" and context.area.is_empty() and context.mission.is_empty(),"unstarted profile reports actual build and neutral no-sortie state")
	check(PlaytestReport.compose(context,answers).error == OK and PlaytestReport.build_context(null).is_empty(),"actual headless/native context is valid and missing tree is safely empty")
	for entry in [["res://scenes/presentation/slice/boot.tscn","boot"],["res://scenes/presentation/slice/hideout.tscn","base"],["res://scenes/hanger/hanger.tscn","base"],["res://scenes/battle/battle.tscn","battle"],["res://scenes/result/result.tscn","result"],["res://scenes/presentation/slice/training_room.tscn","training"],["res://scenes/presentation/slice/workshop_moment.tscn","story"],["C:/Users/private_name/secret.tscn","other"],["user://private/save.json","other"]]:
		check(PlaytestReport._scene_kind(entry[0]) == entry[1],"scene classification never returns a file path: " + entry[1])
	profile.first_mission_completed = true
	var deployed := DeploymentPlan.deploy(profile,&"prototype_arena",&"prototype_combat","user://unused_report_fixture.json",false)
	check(deployed.error == OK,"explicit fixture establishes a real active session without saving it")
	if deployed.error == OK:
		before = profile.to_dict()
		var session: SortieSession = deployed.session
		var session_before := SortieCheckpoint.session_data(session)
		context = PlaytestReport.build_context(get_tree())
		check(context.area == "prototype_arena" and context.mission == "prototype_combat" and context.sortie_status == "active" and context.profile_stage == "q01", "context reads actual mission and unsettled profile stage")
		check(profile.to_dict() == before and SortieCheckpoint.session_data(session) == session_before,"live context collection is read-only, including original IDs, ammunition and objectives")
	var serialized := JSON.stringify(context)
	check(not serialized.contains("session_id") and not serialized.contains("instance_id") and not serialized.contains("inventory") and not serialized.contains("user://") and not serialized.contains("C:/") and not serialized.contains("res://"),"automatic context contains no full save, identities or paths")
	for key in ["profile","session_id","inventory","userdata_path","machine","ip","gpu_id"]:
		var bad := context.duplicate(true); bad[key] = "private"
		reject(bad,answers,"unknown context key rejected: " + key)
	for change in [{"scene":"C:/private/game.tscn"},{"area":"user://save"},{"mission":"unknown"},{"renderer":"gpu-serial"},{"locale":null},{"window":[1]},{"viewport":[1280,-1]},{"viewport":[1.0,2]},{"successful_sorties":"1"},{"failed_sorties":true},{"profile_stage":"unknown"},{"sortie_status":1}]:
		var bad := context.duplicate(true); bad.merge(change,true); reject(bad,answers,"invalid context value rejected")
	var bad_build := context.duplicate(true); bad_build.build.machine = "private"
	reject(bad_build,answers,"build identity does not admit machine metadata")
	bad_build = context.duplicate(true); bad_build.build.id = "C:/private/build"
	reject(bad_build,answers,"build ID cannot become an OS path")
	bad_build = context.duplicate(true); bad_build.build.packaged = true; bad_build.build.source_sha256 = ""
	reject(bad_build,answers,"packaged identity requires an actual source digest")

func _answers() -> void:
	var context_before := context.duplicate(true)
	var answers_before := answers.duplicate(true)
	var composed := PlaytestReport.compose(context,answers)
	check(composed.error == OK and context == context_before and answers == answers_before,"composition preserves caller context and answers")
	check(composed.report.answers.replay == "undecided" and composed.report.answers.first_play == "unspecified" and not composed.report.answers.has("estimated_minutes"),"neutral unanswered questions never default to praise, first play or zero minutes")
	check(composed.report.time_basis == "player_estimate_not_measured" and composed.report.rating_basis == "not_a_platform_rating","report explicitly distinguishes an estimate from measured time and platform ratings")
	composed.report.context.build.id = "changed"; composed.report.answers.stuck = "changed"
	check(context == context_before and answers == answers_before,"report owns detached copies rather than mutable profile/caller references")
	for key in PlaytestReport.ANSWER_KEYS:
		var bad := answers.duplicate(); bad.erase(key); reject(context,bad,"missing required question rejected: " + key)
	for key in ["stuck","remembered"]:
		for value in [null,1,true,[],{},StringName("text")]:
			var bad := answers.duplicate(); bad[key] = value; reject(context,bad,"non-string answer rejected")
		var bad := answers.duplicate(); bad[key] = "字".repeat(2001)
		reject(context,bad,"oversized answer rejected without silent truncation")
		check(bad[key].length() == 2001,"rejection does not edit the original long answer")
	for key in ["replay","first_play"]:
		for value in [null,1,true,[],"maybe",StringName("yes")]:
			var bad := answers.duplicate(); bad[key] = value; reject(context,bad,"invalid question enum rejected")
	for minutes in [-1,601,1.0,1.5,NAN,INF,"5",true,null,[]]:
		var bad := answers.duplicate(); bad.estimated_minutes = minutes; reject(context,bad,"minutes require an actual bounded integer, not coercion")
	for minutes in [0,600]:
		var valid := answers.duplicate(); valid.estimated_minutes = minutes
		check(PlaytestReport.compose(context,valid).error == OK,"explicit minute boundary is retained")
	for key in ["rating","elapsed_seconds","profile","contact","friction"]:
		var bad := answers.duplicate(); bad[key] = "unexpected"; reject(context,bad,"unexpected answer field rejected")
	var unicode := answers.duplicate(); unicode.stuck = "中😀".repeat(1000); unicode.remembered = "  保留空白\n\"引号\"\\斜线  "
	var report := PlaytestReport.compose(context,unicode)
	check(report.error == OK and report.report.answers == unicode and unicode.stuck.length() == 2000,"two thousand Unicode characters and intentional whitespace survive without alteration")
	var text := PlaytestReport.preview(report.report)
	check(text.contains("\n\t") and JSON.parse_string(text).answers == unicode,"pretty UTF-8 JSON previews complete answers with correct escaping")
	check(PlaytestReport.preview({}).is_empty(),"invalid report has no misleading preview")

func _storage() -> void:
	var directory := "user://playtest_report_test_" + Crypto.new().generate_random_bytes(8).hex_encode()
	var profile_before := ProfileRuntime.get_profile().to_dict()
	var session_before := SortieCheckpoint.session_data(SortieRuntime.get_current_session()) if SortieRuntime.get_current_session() else {}
	var response := answers.duplicate(); response.stuck = "保留 😀\n反馈"; response.replay = "no"; response.estimated_minutes = 17
	var report: Dictionary = PlaytestReport.compose(context,response).report
	var text := PlaytestReport.preview(report)
	check(not DirAccess.dir_exists_absolute(directory),"building and previewing a report do not create local output")
	var first := PlaytestReport.save_local(report,directory)
	check(first.error == OK and first.path.begins_with(directory+"/report-") and first.path.ends_with("/report.json"),"explicit save returns only the new user-scheme report path")
	if first.error != OK: return
	var hash := FileAccess.get_sha256(first.path)
	check(FileAccess.get_file_as_string(first.path) == text and JSON.parse_string(text) == normalized(report),"saved UTF-8 JSON reopens with every exact answer and whitelisted field")
	var second := PlaytestReport.save_local(report,directory)
	check(second.error == OK and second.path != first.path and FileAccess.get_sha256(first.path) == hash,"each explicit save uses an exclusively new directory and never overwrites history")
	# Construct the deliberately forbidden path: it is test data, not a packaged dependency.
	for path in ["res"+"://feedback","C:/feedback","../feedback","user://","user://../feedback","user://feedback/../escape","user://feedback//nested","user://feedback/.","user://feedback\\escape","user://feedback:stream"]:
		var rejected := PlaytestReport.save_local(report,path)
		check(rejected.error == ERR_INVALID_PARAMETER and rejected.path.is_empty() and FileAccess.get_sha256(first.path) == hash,"unsafe destination is rejected without touching historical feedback")
	var blocked := directory+"/blocked"
	var file := FileAccess.open(blocked,FileAccess.WRITE); file.store_string("existing history sentinel"); file.close()
	var blocked_hash := FileAccess.get_sha256(blocked)
	var failed := PlaytestReport.save_local(report,blocked)
	check(failed.error != OK and failed.path.is_empty() and FileAccess.get_sha256(blocked) == blocked_hash and FileAccess.get_sha256(first.path) == hash,"directory creation failure preserves both old report and blocking file")
	var poisoned := report.duplicate(true); poisoned.context.profile = {"private":"save"}
	failed = PlaytestReport.save_local(poisoned,directory)
	check(failed.error == ERR_INVALID_DATA and failed.path.is_empty() and PlaytestReport.preview(poisoned).is_empty() and FileAccess.get_sha256(first.path) == hash,"save revalidates whitelist rather than accepting bypassed compose data")
	check(ProfileRuntime.get_profile().to_dict() == profile_before and (not SortieRuntime.get_current_session() or SortieCheckpoint.session_data(SortieRuntime.get_current_session()) == session_before),"all report saves and failures leave profile and live session untouched")

func _source_boundary() -> void:
	var path := "res://scripts/systems/playtest_report.gd"
	if not FileAccess.file_exists(path):
		print("PLAYTEST_REPORT_SOURCE_BOUNDARY: source unavailable in compiled export; source check not claimed")
		return
	var source := FileAccess.get_file_as_string(path)
	for forbidden in ["HTTPRequest.new","HTTPClient.new","OS.shell_open","DisplayServer.clipboard_set","SaveService.save_profile","ProfileRuntime.save_profile","ProjectSettings.globalize_path","OS.get_user_data_dir","session_id","instance_id","get_processor_name","get_unique_id"]:
		check(not source.contains(forbidden),"source boundary has no automatic network, clipboard, profile write or identifying accessor: " + forbidden)
