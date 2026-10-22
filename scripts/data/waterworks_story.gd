class_name WaterworksStory
extends RefCounted

const AREA := &"waterworks_district"
const MISSION := &"waterworks_run"
const CELL := &"story.pump_battery"
const RETURNS = preload("res://resources/narrative/waterworks_returns.json")
const INTRO := "Tang Kui: Leave that loudspeaker alone. It has been telling us to wait patiently since last night.\nSu Mi: Did you not swear it into a power cut?\nTang Kui: That was my own radio.\nShen Yanshuang: Pump battery. West garage. Tang Kui, stop volunteering her for two trips.\nTang Kui: ...I said one and a half."
const FOUND := "Su Mi: Eight kilos. The handle is not decorative.\nTang Kui: Mine broke.\nSu Mi: On the battery?\nTang Kui: On my bucket. I wanted sympathy first."
const PUMP_REPLY := "[Water knocks inside the empty pipe.]\nTang Kui: There! The buckets are by the west courtyard. Open their tap first.\nShen Yanshuang: The tanker is waiting north. Fill it and the people who cannot walk will not have to cross this street.\nTang Kui: And the people standing right here?\nShen Yanshuang: I can see them, Tang Kui."
const PUBLIC_CHOICE := "Tang Kui: Look at the bottoms of those buckets. Let them fill one.\nShen Yanshuang: Then keep the queue out of the road.\nTang Kui: I will stand in front. Do not put me down as another bucket.\n\nRoute: west courtyard exit. Two field dressings in the unlocked cupboard. The north tanker exit stays closed. This choice cannot be changed during this sortie."
const TANKER_CHOICE := "Shen Yanshuang: Fill the tanker. I will take it into the back lanes myself.\nTang Kui: You come back. The truck comes back too. I am not chasing another truck.\nShen Yanshuang: Save me a bucket.\n\nRoute: north loading exit. Ninety standard 5.56 rounds in the unlocked crate. The west courtyard exit stays closed. This choice cannot be changed during this sortie."
const PUBLIC_END := "[Water splashes over the courtyard gutter.]\nTang Kui: One at a time! That is a cooking pot, not a bucket-- fine, give it here.\nShen Yanshuang: West courtyard gate is open. Get home before she volunteers you again."
const TANKER_END := "[The tank rings hollow, then the sound deepens.]\nShen Yanshuang: Loading gate is open. I have the truck.\nTang Kui: You had better. I wrote your name on the bucket.\nShen Yanshuang: Which bucket?\nTang Kui: The biggest one."

static func done(session: SortieSession, id: StringName) -> bool:
	if not session: return false
	var state := session.get_objective_state(id)
	return state != null and state.status == ObjectiveState.Status.COMPLETED

static func returned_branch(outcome: SortieOutcome) -> String:
	if not outcome or outcome.result_type != SortieOutcome.ResultType.COMPLETED or not outcome.mission_completed or outcome.area_id != AREA or outcome.mission_id != MISSION: return ""
	for state in outcome.objective_summaries:
		if state.objective_id in ["water_public", "water_tanker"] and int(state.status) == ObjectiveState.Status.COMPLETED: return state.objective_id
	return ""

static func return_scene(profile: ProfileState, contact: String) -> Dictionary:
	if not profile or profile.waterworks_memory.is_empty(): return {}
	return RETURNS.data.get(profile.waterworks_memory + "_" + contact, {}).duplicate(true)

static func battery(session: SortieSession) -> ItemInstance:
	if session:
		for item in session.inventory.get_items():
			if item.definition_id == CELL: return item
	return null

static func guide(session: SortieSession) -> Array:
	var journey:=WaterworksJourney.guide(session)
	if not journey.is_empty():return journey
	var tr_text := func(text: String): return TranslationServer.translate(text)
	if done(session, &"water_public"): return [tr_text.call("WATER TOWER / COURTYARD SUPPLY"), tr_text.call("West courtyard gate open / dressings cupboard unlocked / extract")]
	if done(session, &"water_tanker"): return [tr_text.call("WATER TOWER / TANKER SUPPLY"), tr_text.call("North loading gate open / ammunition crate unlocked / extract")]
	if done(session, &"water_pump"): return [tr_text.call("WATER TOWER / CHOOSE THE FIRST DELIVERY"), tr_text.call("West courtyard tap OR north tanker valve / inspect the route before confirming")]
	if battery(session): return [tr_text.call("WATER TOWER / BRING THE BATTERY"), tr_text.call("East pump house / install battery, stay close for 8s / damage cancels")]
	return [tr_text.call("WATER TOWER / THE LAST PUMP"), tr_text.call("West garage / take the 8kg battery / loudspeaker switch can draw patrols away")]

static func ending(outcome: SortieOutcome) -> String:
	if not outcome or outcome.area_id != AREA or not outcome.mission_completed: return ""
	for state in outcome.objective_summaries:
		if state.objective_id == "water_public" and int(state.status) == ObjectiveState.Status.COMPLETED: return TranslationServer.translate(PUBLIC_END)
	return TranslationServer.translate(TANKER_END)

static func valid_choices(area: StringName, mission: StringName, summaries: Array) -> bool:
	if area != AREA and mission != MISSION: return true
	if area != AREA or mission != MISSION: return false
	var completed := {}
	for state in summaries:
		if int(state.get("status", -1)) == ObjectiveState.Status.COMPLETED: completed[String(state.objective_id)] = true
	var courtyard := completed.has("water_public")
	var tanker := completed.has("water_tanker")
	return not (courtyard and tanker) and completed.has("water_delivery") == (courtyard or tanker) and (not (courtyard or tanker) or completed.has("water_pump"))
