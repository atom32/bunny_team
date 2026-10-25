extends Node
## Compatibility with the actually archived pre-expansion chapter save payload.
const Spaces := preload("res://scripts/world/geography/campus_spaces.gd")
var failures: Array[String]=[]
var checks:=0
func check(value: bool,text: String) -> void:
	checks+=1
	if not value:failures.append(text);push_error(text)
func _ready() -> void:
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/weijin_interiors_2026-10-23/native/fieldwork_run.json"))
	var path: String="user://spaces_old_save_%s.json"%Time.get_ticks_usec()
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"flags":old.flags,"history":old.history,"blackout":false}));file.close()
	var journal:=CampusFieldworkJournal.new(path)
	check(journal.load_progress() and journal.flags==old.flags and journal.history==old.history and journal.space_notes.is_empty(),"Pre-expansion completed chapter loads with zero invented exploration progress")
	journal.space_notes.append("network_control")
	check(journal.save_progress()==OK,"New space record extends, rather than resets, the actual old chapter payload")
	var loaded:=CampusFieldworkJournal.new(path)
	check(loaded.load_progress() and loaded.flags==old.flags and loaded.space_notes==["network_control"],"New record and old completion both survive replacement/reload")
	check(Spaces.SITES.size()==12 and Spaces.ROOMS.size()==21,"Open-space catalogue contains exactly twelve buildings and twenty-one areas")
	var pairs:=0
	for id: String in Spaces.ROOMS:
		var partner:=Spaces.partner(id)
		check(not Spaces.building(id).is_empty(),"Area belongs to a source building: "+id)
		if not partner.is_empty():
			check(Spaces.partner(partner)==id and Spaces.building(partner)==Spaces.building(id),"Floor connection is reciprocal within the same building: "+id)
			pairs+=1
	check(pairs==18,"Nine reciprocal pairs, not links to arbitrary campus buildings")
	print("CAMPUS SPACES STATE: ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
