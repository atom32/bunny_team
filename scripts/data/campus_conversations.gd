class_name CampusConversations
extends RefCounted
## Presentation derived only from settled facts. Reading never changes a save.
const SCENES = preload("res://resources/narrative/campus_conversations.json")
const SPEAKERS := {"player": "You", "tang_kui": "Tang Kui", "su_mi": "Su Mi", "shen_yanshuang": "Shen Yanshuang"}

static func scene_id(profile: ProfileState, contact: String) -> String:
	if not ContactDefinition.CONTACTS.has(contact): return ""
	var suffix: String = {"tang_kui":"tang", "su_mi":"su", "shen_yanshuang":"shen"}[contact]
	var state := profile.campus_chapter
	if state.finished: return "finish_" + suffix
	if state.delivered_armor and state.delivered_ammo == 60 and contact == "shen_yanshuang": return "packed_shen"
	if state.branch_disconnected: return "cut_" + suffix
	if state.recorder_returned: return "power_" + suffix
	if state.recorder_revealed and contact != "tang_kui": return "lost_" + suffix
	if state.relays_returned and contact != "tang_kui": return "recover_" + suffix
	if profile.narrative_slice.settled.Q02: return "relay_" + suffix
	if profile.narrative_slice.settled.Q01: return "medicine_" + suffix
	return "intro_" + suffix

static func get_scene(profile: ProfileState, contact: String) -> Dictionary:
	return SCENES.data.get(scene_id(profile, contact), {}).duplicate(true)
