class_name WaterworksJourney
extends RefCounted
## Empty facts identify the original map, including suspended pre-expansion trips.
const PUBLIC_CHOICE := "Tang Kui: They have been standing here with pots since morning.\nShen: The people in the north cannot even carry a pot.\nTang Kui: Then stop looking at me like that!\nShen: ...I wanted to start here too.\n\nStart the courtyard delivery. If the relief latch jams, use the west bypass wheel or shoot the red latch. Supplies and extraction unlock only after water reaches the courtyard."
const TANKER_CHOICE := "Shen: I found the key.\nTang Kui: Then start it.\nShen: My hands are shaking.\nTang Kui: ...Leave it. Let her open the road first.\n\nStart the north delivery. Release the truck's handbrake, raise the loading gate and clear its front. The truck stops for people. Supplies and extraction unlock only when it reaches the north yard."
const JAM := "[The relief lever snaps back. Water hammers the pipe.]\nSu Mi: Who welded this shut?\nTang Kui: I cannot read that name.\nShen: Back. Both of you.\n\nRelieve the pressure at the west bypass wheel, or shoot the red latch. Stay out of the marked jet."

static func initial(area: StringName) -> Dictionary:
	return {"version":3,"branch":"","public_fix":"","gate_open":false,"delivered":false} if area==WaterworksStory.AREA else {}

static func valid(facts: Variant,area: StringName,mission: StringName,summaries: Array) -> bool:
	if typeof(facts)!=TYPE_DICTIONARY:return false
	if facts.is_empty():return true
	if area!=WaterworksStory.AREA or mission!=WaterworksStory.MISSION or facts.size()!=5:return false
	if not SortieCheckpoint.integer(facts.get("version"),2,3):return false
	if typeof(facts.get("branch"))!=TYPE_STRING or facts.branch not in ["","public","tanker"]:return false
	if typeof(facts.get("public_fix"))!=TYPE_STRING or facts.public_fix not in ["","bypass","shot"]:return false
	if typeof(facts.get("gate_open"))!=TYPE_BOOL or typeof(facts.get("delivered"))!=TYPE_BOOL:return false
	var done:={}
	for state in summaries:
		if int(state.get("status",-1))==ObjectiveState.Status.COMPLETED:done[String(state.objective_id)]=true
	if not facts.branch.is_empty() and not done.has("water_pump"):return false
	if facts.gate_open and facts.branch!="tanker":return false
	if not facts.public_fix.is_empty() and (facts.branch!="public" or not facts.delivered):return false
	if facts.delivered:
		if facts.branch=="public" and facts.public_fix.is_empty():return false
		if facts.branch=="tanker" and not facts.gate_open:return false
		if facts.branch.is_empty():return false
	if done.has("water_delivery")!=facts.delivered:return false
	return done.has("water_public")== (facts.delivered and facts.branch=="public") and done.has("water_tanker")== (facts.delivered and facts.branch=="tanker")

static func pending(session: SortieSession,branch: String) -> bool:
	return session!=null and session.status==SortieSession.Status.ACTIVE and not session.waterworks.is_empty() and session.waterworks.branch==branch and not session.waterworks.delivered

static func guide(session: SortieSession) -> Array:
	if pending(session,"public"):return [TranslationServer.translate("COURTYARD / JAMMED RELIEF"),TranslationServer.translate("West bypass wheel OR shoot the red latch / avoid the pressure jet")]
	if pending(session,"tanker"):return [TranslationServer.translate("NORTH / BRING THE WATER TRUCK"),TranslationServer.translate("Release handbrake at truck / raise loading gate / keep its front clear")]
	if session and session.waterworks.get("version",0)==3 and not WaterworksStory.battery(session) and not WaterworksStory.done(session,&"water_pump"):
		return [TranslationServer.translate("WATER TOWER / CROSS THE SOUTH MARKET"),TranslationServer.translate("West stalls: cover / East lane: exposed / Depot optional / Leave 8kg for the garage battery")]
	return []
