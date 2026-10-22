class_name BlockadeStory
extends RefCounted
const AREA := &"blockade_checkpoint"
const MISSION := &"blockade_run"
const INTRO := "Tang Kui: It is telling us to remain calm again.\nSu Mi: You tried arguing with it?\nTang Kui: I hit it with a bucket. It told me to remain calm louder.\nShen Yanshuang: Red line: move. Four shots, then its vents open. Shoot then.\nSu Mi: The PA supply is in the west service alley. Cut that, not the street lights."
const CUT := "[The recorded voice stops mid-syllable.]\nTang Kui: Finally.\nSu Mi: The gun still has power. Do not go over there to give it your review."
const END := "[Metal clatters. For a moment, only the empty buckets rattle.]\nTang Kui: Is it dead?\nSu Mi: It is a truck.\nTang Kui: I was asking politely.\nShen Yanshuang: North gate is clear. Come back. Both of you."

static func done(session: SortieSession, id: StringName) -> bool:
	return WaterworksStory.done(session, id)

static func guide(session: SortieSession) -> Array:
	if session and not session.blockade.is_empty():return BlockadeJourney.guide(session)
	if done(session, &"blockade_van"): return [tr_text("CHECKPOINT / THE STREET IS QUIET"), tr_text("Van disabled / north gate open / recover supplies and extract")]
	return [tr_text("CHECKPOINT / REMAIN CALM"), tr_text("Red line: move or take cover. Four shots, then blue vents: fire. West alley cuts PA only; south retreat stays open.")]

static func ending(outcome: SortieOutcome) -> String:
	return tr_text(END if outcome.blockade.is_empty() else BlockadeJourney.END) if outcome and outcome.area_id==AREA and outcome.mission_completed else ""

static func valid_pair(area: StringName, mission: StringName) -> bool:
	return (area == AREA) == (mission == MISSION)

static func tr_text(text: String) -> String: return TranslationServer.translate(text)
