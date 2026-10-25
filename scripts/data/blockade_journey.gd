class_name BlockadeJourney
extends RefCounted
## Empty facts preserve the original checkpoint map and its van-only contract.
const BRIEF:="Use cover to pass the sweeping searchlight. Open the west service shutter quietly, or shoot the street chain and face the alarm response. Fight from cover during blue vents, or flank north and hit the rear radiator without waiting. The gun still fires behind itself. Disable the van, enter the north yard, release the east-booth counterweight and extract through the raised north gate. South retreat stays open."
const INTRO:="Tang Kui: It told me to put down my bucket.\nSu Mi: Did it say please?\nTang Kui: Three times. Then it shot the bucket.\nShen: Stay behind the delivery vans. I can see the searchlight from here.\nTang Kui: Stop staring at her marker. I am right here.\nShen: Then stop standing in front of it."
const SERVICE:="[The maintenance shutter rattles upward.]\nTang Kui: You kept that little key for THIS?\nSu Mi: I keep every little key.\nShen: Of course you do."
const ALARM:="[The searchlight turns red.]\nTang Kui: Do not look at me. I did not touch it!\nSu Mi: For once, it was not you.\nShen: Argue inside. Move!"
const DOWN:="[The recorded voice breaks off. Beyond the gate, someone hammers on metal.]\nTang Kui: Keep moving! The north shutter is stuck!\nShen: I can go back--\nTang Kui: NO. Stay there. Just this once.\nSu Mi: East booth. Counterweight release. I marked it."
const OPENING:="Shen: There is room. Come through!\nTang Kui: You are not counting people, are you?\nShen: I am counting YOU.\nTang Kui: ...Then count slower."
const CLEAR:="[The counterweight hits its stop.]\nSu Mi: North road is open.\nTang Kui: She is coming. Move your foot.\nShen: I am not in the--\n[The radio crackles. Someone laughs too hard.]"
const END:="Shen: ...Everyone here?\nTang Kui: Everyone.\nShen: ...Good.\nSu Mi: Her palms are soaking.\nShen: Have you two nothing else to do?\nTang Kui: Yes. Dinner. Come on."

static func initial(area: StringName) -> Dictionary:
	return {"version":3,"alarm":false,"van_down":false,"escape_open":false} if area==BlockadeStory.AREA else {}

static func valid(facts: Variant,area: StringName,mission: StringName,summaries: Array) -> bool:
	if typeof(facts)!=TYPE_DICTIONARY:return false
	if facts.is_empty():return true
	if facts.size()!=4 or not SortieCheckpoint.integer(facts.get("version"),2,3) or area!=BlockadeStory.AREA or mission!=BlockadeStory.MISSION:return false
	for key in ["alarm","van_down","escape_open"]:
		if typeof(facts.get(key))!=TYPE_BOOL:return false
	if facts.escape_open and not facts.van_down:return false
	var complete:=false
	for state in summaries:
		if state.get("objective_id")=="blockade_van":complete=int(state.get("status",-1))==ObjectiveState.Status.COMPLETED
	return complete==facts.escape_open

static func guide(session: SortieSession) -> Array:
	if session.blockade.escape_open:return [tr_text("CHECKPOINT / NORTH ROAD OPEN"),tr_text("Counterweight gate raised / reach the north exit or retreat south")]
	if session.blockade.van_down:return [tr_text("CHECKPOINT / THROUGH THE NORTH YARD"),tr_text("East booth / release the counterweight, then fight through to the north exit")]
	if session.blockade.version>=3:return [tr_text("CHECKPOINT / GET PAST THE SEARCHLIGHT"),tr_text("Cover blocks the sweep. West service lever OR shoot the street chain. Fight from cover during blue vents, or flank north and hit the rear radiator. The gun still fires behind itself. South retreat stays open.")]
	return [tr_text("CHECKPOINT / GET PAST THE SEARCHLIGHT"),tr_text("Cover blocks the sweep. West service lever OR shoot the street chain. Four van shots, then fire at blue vents. South retreat stays open.")]

static func tr_text(text: String) -> String:return TranslationServer.translate(text)
