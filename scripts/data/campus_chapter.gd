class_name CampusChapter
extends RefCounted
## Campus Batch 2. Separate from immutable legacy logistics facts/rewards.
const FACTS_VERSION := 2 # v1 suspended sorties keep the original dormitory device site.
const RECORDER_ID := &"story.experiment_recorder"
const RELAYS := ["relay_office", "relay_repair"]
const ARMOR_IDS := [&"armor.recon_shell_01", &"armor.bulwark_plate_01"]
const RELAY_REWARD := 100
const RECORDER_REWARD := 150
const POWER_REWARD := 100
const FINAL_REWARD := 200
const WARNING := "L-02 / Radio: This is not a reception point. Do not enter the sealed zone. The people inside have lost control, and the line still connects to them."
const RECORD := "Research center experiment recorder\nMilitary neural-control and endurance project: containment failure; subjects lost control. Outer guards continue the blockade. Experimental assets must not leave. Test equipment remains powered.\nL-02A: shelter communications and lighting. L-02B: experimental equipment. Separate branches share the upstream line."
const POWER_REPLY := "Tang Kui / Radio: The lights stayed on. Another building just answered."
const STAGES := ["relay", "recorder", "power", "supply", "complete"]
const QUESTS := {
	"campus_relay": ["03 / Restore communications", "Su Mi: Restore the reading-hall and maintenance-yard relays on L-02, then extract. Each requires 12 seconds nearby; damage interrupts work. No materials required."],
	"campus_recorder": ["04 / Recover the experiment recorder", "Shen Yanshuang: The recorder is fixed in the archive reading hall. Take it and bring it home. Read its project and equipment log immediately; no decryption or second evidence item."],
	"campus_power": ["05 / Disconnect the experimental branch", "Su Mi: At the maintenance console, disconnect L-02B experimental equipment and keep L-02A shelter communications and lighting. Confirm the branch choice, finish the work, then extract."],
	"campus_supply": ["06 / Arm the people who stayed", "Shen Yanshuang: Deliver one unequipped spare armor (Recon Shell or Bulwark Plate, at least 50 durability) and 60 standard 5.56 rounds from the warehouse, then complete a campus extraction."],
}

static func initial_state() -> Dictionary:
	return {"version":1,"relays_returned":false,"recorder_revealed":false,"recorder_returned":false,"branch_disconnected":false,"power_returned":false,"delivered_armor":false,"delivered_ammo":0,"finished":false}

static func valid_state(raw: Variant) -> bool:
	if typeof(raw)!=TYPE_DICTIONARY or raw.size()!=9 or raw.get("version")!=1: return false
	for key in ["relays_returned","recorder_revealed","recorder_returned","branch_disconnected","power_returned","delivered_armor","finished"]:
		if typeof(raw.get(key))!=TYPE_BOOL: return false
	if not SortieCheckpoint.integer(raw.get("delivered_ammo"),0,60): return false
	if raw.recorder_returned and (not raw.relays_returned or not raw.recorder_revealed): return false
	if raw.branch_disconnected and not raw.recorder_returned: return false
	if raw.power_returned and not raw.branch_disconnected: return false
	if (raw.delivered_armor or raw.delivered_ammo>0) and not raw.power_returned: return false
	return not raw.finished or (raw.delivered_armor and raw.delivered_ammo==60)

static func started(state: Dictionary) -> bool:
	for key in ["relays_returned","recorder_revealed","recorder_returned","branch_disconnected","power_returned","delivered_armor","finished"]:
		if state[key]:return true
	return state.delivered_ammo>0

static func stage(state: Dictionary) -> String:
	if state.finished: return "complete"
	if not state.relays_returned: return "relay"
	if not state.recorder_returned: return "recorder"
	if not state.power_returned: return "power"
	return "supply"

static func initial_facts(profile: ProfileState, area: StringName) -> Dictionary:
	if area!=&"street_district" or not profile.first_mission_completed or not profile.narrative_slice.settled.Q02: return {}
	var state := profile.campus_chapter
	return {"version":FACTS_VERSION,"stage":stage(state),"relay_ready":state.relays_returned,"recorder_ready":state.recorder_returned,"gear_ready":state.delivered_armor and state.delivered_ammo==60,"relays":[],"recorder_revealed":false,"recorder_instance":"","power_cut":state.branch_disconnected,"power_confirmed":state.branch_disconnected}

static func valid_facts(raw: Variant, area: StringName) -> bool:
	if typeof(raw)!=TYPE_DICTIONARY: return false
	if raw.is_empty(): return true # Old suspended sorties never gain new-story facts.
	if area!=&"street_district" or raw.size()!=10 or not SortieCheckpoint.integer(raw.get("version"),1,FACTS_VERSION) or raw.get("stage") not in STAGES: return false
	for key in ["relay_ready","recorder_ready","gear_ready","recorder_revealed","power_cut","power_confirmed"]:
		if typeof(raw.get(key))!=TYPE_BOOL: return false
	if typeof(raw.get("relays"))!=TYPE_ARRAY or raw.relays.size()>2: return false
	var seen := []
	for id in raw.relays:
		if typeof(id)!=TYPE_STRING or id not in RELAYS or id in seen: return false
		seen.append(id)
	if typeof(raw.get("recorder_instance"))!=TYPE_STRING: return false
	if raw.recorder_revealed != (not raw.recorder_instance.is_empty()):return false
	if not raw.recorder_instance.is_empty():
		var pattern:=RegEx.new();pattern.compile("^[0-9a-f]{32}$")
		if not pattern.search(raw.recorder_instance) or not raw.recorder_revealed: return false
	if raw.recorder_revealed and (raw.recorder_ready or not (raw.relay_ready or raw.relays.size()==2)): return false
	if raw.power_confirmed!=raw.power_cut: return false
	match raw.stage:
		"relay":
			if raw.relay_ready or raw.recorder_ready or raw.gear_ready or raw.power_cut: return false
		"recorder":
			if not raw.relay_ready or raw.recorder_ready or raw.gear_ready or raw.power_cut or not raw.relays.is_empty(): return false
		"power":
			if not raw.relay_ready or not raw.recorder_ready or raw.gear_ready or raw.recorder_revealed or not raw.recorder_instance.is_empty() or not raw.relays.is_empty(): return false
		"supply", "complete":
			if not raw.relay_ready or not raw.recorder_ready or not raw.power_cut or raw.recorder_revealed or not raw.recorder_instance.is_empty() or not raw.relays.is_empty(): return false
			if raw.stage=="complete" and not raw.gear_ready: return false
	return true

static func matches_profile(facts: Dictionary, profile: ProfileState, area: StringName) -> bool:
	if facts.is_empty(): return true # Legacy suspended sorties retain their old contract.
	var baseline := initial_facts(profile, area)
	if baseline.is_empty(): return false
	for key in ["stage", "relay_ready", "recorder_ready", "gear_ready"]:
		if facts.get(key) != baseline[key]: return false
	return not baseline.power_cut or facts.get("power_cut") == true

static func valid_inventory(raw: Dictionary, inventory: InventoryState, require_recorder: bool) -> bool:
	if not inventory:return false
	if raw.is_empty() or raw.recorder_instance.is_empty(): return true
	if not require_recorder: return true
	var item:=inventory.get_item(raw.recorder_instance)
	return item!=null and item.definition_id==RECORDER_ID and item.quantity==1

static func recorder_available(facts: Dictionary) -> bool:
	return not facts.is_empty() and not facts.recorder_ready and facts.recorder_instance.is_empty() and (facts.relay_ready or facts.relays.size()==2)

static func record_relay(session: SortieSession, id: String) -> bool:
	if not session or session.status!=SortieSession.Status.ACTIVE or session.campus.is_empty() or session.campus.stage!="relay" or id not in RELAYS or id in session.campus.relays: return false
	session.campus.relays.append(id);session.campus.relays.sort()
	return true

static func record_outcome(profile: ProfileState, outcome: SortieOutcome) -> void:
	if outcome.campus.is_empty() or not profile.narrative_slice.settled.Q02: return
	var facts:=outcome.campus;var state:=profile.campus_chapter
	# Information and physical branch changes survive a failed return, but task
	# rewards/milestones still require actual extraction. Recorder remains lost.
	if facts.recorder_revealed: state.recorder_revealed=true
	if facts.power_cut and state.recorder_returned: state.branch_disconnected=true
	if outcome.result_type!=SortieOutcome.ResultType.COMPLETED: return
	if not state.relays_returned and facts.stage=="relay" and facts.relays.size()==2:
		state.relays_returned=true;profile.credits+=RELAY_REWARD
	if state.relays_returned and not state.recorder_returned and not facts.recorder_instance.is_empty():
		var item:=outcome.inventory.get_item(facts.recorder_instance)
		if item and item.definition_id==RECORDER_ID:
			state.recorder_revealed=true;state.recorder_returned=true;profile.credits+=RECORDER_REWARD
			# Archived in the contact record, not sold or handed between factions.
			profile.inventory.remove_item(item.instance_id);profile.stash_layout.erase(item.instance_id)
	if state.recorder_returned and not state.power_returned and facts.stage=="power" and facts.power_confirmed:
		state.branch_disconnected=true;state.power_returned=true;profile.credits+=POWER_REWARD
	if state.power_returned and not state.finished and facts.stage=="supply" and facts.gear_ready:
		state.finished=true;profile.credits+=FINAL_REWARD

static func prepare_delivery(profile: ProfileState) -> Dictionary:
	if not profile or not profile.validate(): return {"error":ERR_INVALID_DATA,"message":"Invalid campus state."}
	if stage(profile.campus_chapter)!="supply": return {"error":ERR_UNAVAILABLE,"message":"Finish the branch operation before the equipment delivery."}
	var candidate:=ProfileState.from_dict(profile.to_dict());var state:=candidate.campus_chapter;var used:=false
	if not state.delivered_armor:
		for item in candidate.inventory.get_items():
			if item.definition_id in ARMOR_IDS and item.durability>=50 and not candidate.loadout.is_equipped(item.instance_id):
				candidate.inventory.remove_item(item.instance_id);candidate.stash_layout.erase(item.instance_id);state.delivered_armor=true;used=true;break
	var remaining:=mini(60-int(state.delivered_ammo),SupplyService.count(candidate,&"ammo.556_standard"))
	state.delivered_ammo+=remaining;used=used or remaining>0
	for item in candidate.inventory.get_items():
		if item.definition_id!=&"ammo.556_standard" or remaining<=0: continue
		var count:=mini(remaining,item.quantity);candidate.inventory.consume_item(item.instance_id,count)
		if not candidate.inventory.contains(item.instance_id):candidate.stash_layout.erase(item.instance_id)
		remaining-=count
	if not used:return {"error":ERR_UNAVAILABLE,"message":"No required spare armor or standard 5.56 ammunition in the warehouse."}
	StashLayout.new(candidate).reconcile()
	if not candidate.validate():return {"error":ERR_INVALID_DATA,"message":"Invalid campus delivery."}
	return {"error":OK,"candidate":candidate,"message":"Equipment delivery saved. Once armor and 60 rounds are delivered, complete a campus extraction."}

static func submit_delivery(path:=SaveService.DEFAULT_SAVE_PATH) -> Dictionary:
	var profile:=ProfileRuntime.get_profile()
	if SortieRuntime.get_current_session() or ProfileRuntime.recovery_required or not profile.sortie_checkpoint.is_empty():return {"error":ERR_BUSY,"message":"Supplies are only available at base."}
	var result:=prepare_delivery(profile)
	if result.error!=OK:return result
	var error:=SaveService.save_profile(result.candidate,path)
	if error!=OK:return {"error":error,"message":"Could not save. Credits and items are unchanged."}
	profile.replace_with(result.candidate);return result

static func status_text(profile: ProfileState, session: SortieSession=null) -> String:
	var state:=profile.campus_chapter
	if session and not session.campus.is_empty():
		var facts:=session.campus
		if facts.stage=="relay" and not facts.recorder_instance.is_empty():return TranslationServer.translate("Experiment recorder / bring it home")
		if facts.stage=="relay": return TranslationServer.translate("L-02 / relays %d/2 / Extract; recorder available after both repairs") % facts.relays.size()
		if facts.stage=="recorder" and facts.version==1 and facts.recorder_instance.is_empty():return TranslationServer.translate("Legacy sortie / recorder at dormitory registration desk")
		if facts.stage=="recorder":return TranslationServer.translate("Experiment recorder / bring it home") if not facts.recorder_instance.is_empty() else TranslationServer.translate("Experiment recorder / archive reading hall")
		if facts.stage=="power":return TranslationServer.translate("L-02B OFF / L-02A ON / Extract") if facts.power_cut else TranslationServer.translate("L-02 control / disconnect experiment branch, preserve shelter power")
		if facts.stage=="supply":return TranslationServer.translate("Campus supplies delivered / Extract") if facts.gear_ready else TranslationServer.translate("Deliver spare armor and 60 standard 5.56 rounds at base")
	match stage(state):
		"relay":return TranslationServer.translate("L-02 / restore two relays and extract")
		"recorder":return TranslationServer.translate("Experiment recorder / archive reading hall")
		"power":return TranslationServer.translate("L-02 control / disconnect experiment branch, preserve shelter power")
		"supply":return TranslationServer.translate("Spare armor %d/1 / standard 5.56 %d/60 / then extract") % [int(state.delivered_armor),state.delivered_ammo]
	return TranslationServer.translate("Campus chapter complete / free sorties remain available")
