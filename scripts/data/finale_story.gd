class_name FinaleStory
extends RefCounted
## The local crisis ends here; repeatable free sorties are not another chapter.
const AREA := &"maintenance_core"
const MISSION := &"maintenance_shutdown"
const BRIDGE := &"core_shelter_bridge"
const LEFT := &"core_left_feed"
const RIGHT := &"core_right_feed"
const STOP := &"core_shutdown"
const INTRO := "Xu Tang: It starts again when the lights go out. I used to count the clicks.\nSu Mi: The battery room. The campus branch is already off; this thing has its own supply.\nTang Kui: Do not touch the green cable. That is our kitchen.\nShen: We are outside the north door. This time, nobody waits in there alone."
const BRIDGE_LINE := "[The green shelter lamp stays on.]\nTang Kui: Still cooking.\nSu Mi: That is how you check the power?\nTang Kui: It is a very good test."
const FIRST_FEED := "Xu Tang: One less click.\nShen: Keep your eyes on the floor. We heard something moving."
const BOTH_FEEDS := "Su Mi: Both battery feeds are isolated. The middle lane will discharge once more.\nTang Kui: Then pull its teeth out. I am not reheating this a third time."
const STOP_LINE := "[The rotor slows. No new click follows.]\nXu Tang: ...Is that it?\nSu Mi: That is it.\nShen: The north door is open. Come home."
const END := "[L-02A is still lit. The test equipment stays dark.]\nSu Mi: No restart signal. No backup feed.\nTang Kui: I can hear the pot boiling again.\nXu Tang: I want to hear that.\nShen: Then stop standing in the doorway. All of you."

static func done(session: SortieSession, id: StringName) -> bool:
	return WaterworksStory.done(session, id)

static func available(profile: ProfileState) -> bool:
	return profile and profile.campus_chapter.finished and profile.maintenance_rescued and profile.blockade_cleared and not profile.waterworks_memory.is_empty()

static func returned(outcome: SortieOutcome) -> bool:
	return outcome and outcome.result_type==SortieOutcome.ResultType.COMPLETED and outcome.area_id==AREA and outcome.mission_id==MISSION and outcome.mission_completed

static func valid_objectives(area: StringName, mission: StringName, summaries: Array) -> bool:
	if (area==AREA)!=(mission==MISSION):return false
	if area!=AREA:return true
	var completed:={}
	for raw in summaries:
		if int(raw.get("status",-1))==ObjectiveState.Status.COMPLETED:completed[StringName(raw.objective_id)]=true
	if (completed.has(LEFT) or completed.has(RIGHT)) and not completed.has(BRIDGE):return false
	return not completed.has(STOP) or (completed.has(LEFT) and completed.has(RIGHT))

static func next_mission(profile: ProfileState) -> StringName:
	if not profile.campus_chapter.finished or profile.maintenance_closed:return &""
	if profile.waterworks_memory.is_empty():return WaterworksStory.MISSION
	if not profile.blockade_cleared:return BlockadeStory.MISSION
	if not profile.maintenance_rescued:return MaintenanceStory.MISSION
	return MISSION

static func at_base(profile: ProfileState) -> Array:
	if not profile.campus_chapter.finished:return []
	if profile.maintenance_closed:return [tr_text("STORY COMPLETE / EVERYONE IS HOME"),tr_text("The local crisis is over. Replay the homecoming in Rest, or prepare a free sortie.")]
	var mission:=next_mission(profile)
	var detail:="Water Tower Street / choose a delivery and bring it home."
	if mission==BlockadeStory.MISSION:detail="Checkpoint / disable the broadcast truck and extract."
	elif mission==MaintenanceStory.MISSION:detail="Sealed maintenance / bring the caller home."
	elif mission==MISSION:detail="Backup power room / keep shelter power, isolate the feeds, stop the restart."
	return [tr_text("MAIN STORY / A WAY HOME"),tr_text(detail)]

static func guide(session: SortieSession) -> Array:
	var detail:="South bridge / keep L-02A shelter power before touching either battery feed."
	if done(session,BRIDGE):detail="Cut both side feeds during blue cooling windows. Amber lane: move aside. The white bar is the live discharge."
	if done(session,LEFT) and done(session,RIGHT):detail="Both feeds isolated / use the north master stop during a blue cooling window."
	if done(session,STOP):detail="The backup core is stopped. North door open; extract and go home."
	return [tr_text("BACKUP POWER / THE LAST CLICK"),tr_text(detail)]

static func ending(outcome: SortieOutcome) -> String:
	return tr_text(END) if returned(outcome) else ""

static func tr_text(value: String) -> String:return TranslationServer.translate(value)
