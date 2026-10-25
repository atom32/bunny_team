class_name MaintenanceJourney
extends RefCounted
## Empty facts preserve the original rescue map and timed controls.
const BRIEF:="Unlatch the service bulkhead and open the ward. The central steam corridor cycles: clear for 2.4s, warning for 0.8s, hot for 1.6s. Use the clear window to cross and shut the far-side valve. You may clear it before releasing Xu Tang, or ask her to wait while you cross alone. She will not step into the marked corridor until the valve is closed. Then open the north shutter and bring her to the exit. South retreat stays open. Hot steam also hurts pursuers. Leave it running to punish a chase, or isolate it early for a safe crossing; Xu Tang will still wait until it is off. South hall: hit the flashing alarm carrier before it calls nearby enemies, or use its call to pull them aside."
const WARNING:="Xu Tang: You are going again?\nSu Mi: She is still on this channel.\nXu Tang: That is what you said last time.\nShen: Look at the yellow line. She is coming back across it.\nTang Kui: And I am going to yell until she does."
const CLOSED:="[The pipe stops hammering.]\nTang Kui: There. I was not even that loud.\nSu Mi: The gauge shook when you shouted.\nXu Tang: ...Can she come back now?"
const FOLLOW:="Xu Tang: I kept my foot behind the line.\nShen: I saw.\nXu Tang: Both feet, actually.\nTang Kui: Good. Bring both of them."
const UNLATCH:="The service bulkhead is unlatched. The steam line beyond it is still cycling."
const NORTH:="North shutter open. The steam line is isolated; bring Xu Tang through."
const ZONE:=Rect2(-3.6,-16.0,7.2,6.0)

static func initial(area: StringName) -> Dictionary:
	return {"version":4,"steam_off":false} if area==MaintenanceStory.AREA else {}

static func valid(facts: Variant,area: StringName,mission: StringName,summaries: Array) -> bool:
	if typeof(facts)!=TYPE_DICTIONARY:return false
	if facts.is_empty():return true
	if facts.size()!=2 or not SaveService.is_number(facts.get("version")) or (facts.get("version")!=2 and facts.get("version")!=3 and facts.get("version")!=4) or typeof(facts.get("steam_off"))!=TYPE_BOOL or area!=MaintenanceStory.AREA or mission!=MaintenanceStory.MISSION:return false
	var done:={}
	for state in summaries:
		if int(state.get("status",-1))==ObjectiveState.Status.COMPLETED:done[String(state.objective_id)]=true
	if facts.steam_off and not done.has("maintenance_bypass"):return false
	return not done.has("maintenance_gate") or facts.steam_off

static func guide(session: SortieSession) -> Array:
	var detail:="Unlatch the service bulkhead. Clear the steam first, or open the ward and ask Xu Tang to wait."
	if session.maintenance.get("version",0)==4:
		detail="South hall / flashing beacon calls nearby enemies. Hit it to interrupt, bypass it, or draw them aside; unlatch the west bulkhead."
	if MaintenanceStory.done(session,&"maintenance_bypass"):
		detail="Central corridor / cross in a clear window, shut the far-side valve. Xu Tang will not cross the yellow line until it is off."
	if session.maintenance.steam_off:detail="Steam isolated / open the ward, then the north shutter. Keep Xu Tang within 12m."
	if MaintenanceStory.done(session,&"maintenance_gate"):detail="Bring Xu Tang through the north shutter. Stay near her; she will not teleport to you."
	if MaintenanceStory.done(session,&"maintenance_rescue"):detail="Xu Tang is at the north exit. Extract safely to bring this rescue home."
	return [TranslationServer.translate("SEALED MAINTENANCE / THE YELLOW LINE"),TranslationServer.translate(detail)]
