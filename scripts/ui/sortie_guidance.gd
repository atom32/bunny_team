class_name SortieGuidance
extends RefCounted
## Read-only presentation of existing contracts. Never selects a mission or advances it.

static func campus(facts: Dictionary) -> Array:
	if facts.is_empty() or facts.stage == "complete": return []
	if not facts.recorder_instance.is_empty():
		return [tr_text("CAMPUS / EXPERIMENT RECORDER"), tr_text("Experiment recorder / bring it home")]
	if facts.version == 1 and facts.stage in ["relay", "recorder"]:
		return [tr_text("CAMPUS / LEGACY SORTIE"), tr_text("Legacy sortie / recorder at dormitory registration desk")]
	match facts.stage:
		"relay":
			if facts.relays.size() == 2:
				return [tr_text("CAMPUS / EXPERIMENT RECORDER"), tr_text("Relays repaired. Take the recorder, or extract first.")]
			return [tr_text("CAMPUS / L-02 RELAYS"), tr_text("L-02 relays %d/2 / repair both, then extract") % facts.relays.size()]
		"recorder":
			return [tr_text("CAMPUS / EXPERIMENT RECORDER"), tr_text("Archive reading hall / take the device and extract.")]
		"power":
			return [tr_text("CAMPUS / L-02 BRANCH"), tr_text("L-02B OFF / L-02A ON / Extract") if facts.power_cut else tr_text("Maintenance control / disconnect L-02B, preserve L-02A.")]
		"supply":
			return [tr_text("CAMPUS / EQUIPMENT"), CampusChapter.supply_status(facts)]
	return []

static func field(profile: ProfileState, session: SortieSession) -> Array:
	if session and session.area_id==FinaleStory.AREA:return FinaleStory.guide(session)
	if session and session.area_id == MaintenanceStory.AREA:return MaintenanceStory.guide(session)
	if session and session.area_id == BlockadeStory.AREA: return BlockadeStory.guide(session)
	if session and session.area_id == WaterworksStory.AREA: return WaterworksStory.guide(session)
	if not session or session.area_id != &"street_district": return []
	if not session.campus.is_empty():
		if session.campus.version>=3 and session.campus.stage=="power" and not session.campus.power_cut:
			var tree:=Engine.get_main_loop() as SceneTree
			var encounter:=tree.get_first_node_in_group("campus_power_encounter") as CampusPowerEncounter
			if encounter:
				return [tr_text("CAMPUS / L-02 BRANCH"),tr_text("STEP OUT OF THE CHARGE / BAIT A WALL IMPACT") if encounter.phase==CampusPowerEncounter.Phase.ACTIVE else tr_text("CUT L-02B / SHELTER STAYS ON") if encounter.phase==CampusPowerEncounter.Phase.CLEARED else tr_text("Maintenance control / start isolation; watch for a shielded charger.")]
		return campus(session.campus)
	if not session.slice_context.is_empty():
		return [tr_text("Q01 / EXIT SCOUTING"), NarrativeSlice.status_text(profile, session)]
	if session.q02_active:
		var tree:=Engine.get_main_loop() as SceneTree
		var runners:=tree.get_first_node_in_group("campus_medical_runners") as CampusMedicalRunners
		if runners and runners.phase in [CampusMedicalRunners.Phase.PACKING,CampusMedicalRunners.Phase.LEAVING]:
			return [tr_text("Q02 / MEDICAL SUPPLIES"),tr_text("Recover supplies and extract. Optional: intercept the clinic carrier.")]
		return [tr_text("Q02 / MEDICAL SUPPLIES"), tr_text("Recover supplies and extract. Deliver to Tang Kui at base.")]
	return [] # Legacy suspended worlds never acquire today's profile contract.

static func at_base(profile: ProfileState) -> Array:
	if not profile.first_mission_completed: return []
	if not profile.narrative_slice.settled.Q01:
		return [tr_text("Q01 / EXIT SCOUTING"), tr_text("Read both assigned exit signs, then extract.")]
	if not profile.narrative_slice.settled.Q02:
		var delivered: Dictionary = profile.narrative_slice.q02.delivered
		return [tr_text("Q02 / MEDICAL SUPPLIES"), tr_text("Tang Kui / dressings %d/2, fabric %d/2. Deliver at base.") % [delivered["medical.field_dressing"], delivered["material.fabric"]]]
	var facts := CampusChapter.initial_facts(profile, &"street_district")
	var result := campus(facts)
	if result.is_empty():return FinaleStory.at_base(profile)
	if facts.stage == "supply" and not facts.gear_ready:
		result[1] = CampusChapter.status_text(profile)
	return result

static func contact_at_base(profile: ProfileState) -> String:
	if not profile.narrative_slice.settled.Q01: return "shen_yanshuang"
	if not profile.narrative_slice.settled.Q02: return "tang_kui"
	return {"relay":"su_mi", "recorder":"shen_yanshuang", "power":"su_mi", "supply":"shen_yanshuang"}.get(CampusChapter.stage(profile.campus_chapter), "")

static func tr_text(text: String) -> String:
	return TranslationServer.translate(text)

static func debrief(outcome: SortieOutcome) -> Array:
	# Immutable field facts, not today's profile. A legacy suspended sortie must
	# never acquire a commission just because the player has unlocked it since.
	if outcome.area_id != &"street_district": return []
	var extracted := outcome.result_type == SortieOutcome.ResultType.COMPLETED
	var facts := outcome.campus
	if not facts.is_empty() and facts.stage != "complete":
		var title := ""
		var lines: Array[String] = []
		match facts.stage:
			"relay":
				title = tr_text("CAMPUS / L-02 RELAYS")
				if not extracted: lines.append(tr_text("Relay work not banked without a safe return."))
				elif facts.relays.size() == 2: lines.append(tr_text("Relays repaired 2/2 / ready to settle."))
				else: lines.append(tr_text("Relays repaired %d/2 / repair both in one outing, then extract.") % facts.relays.size())
			"recorder": title = tr_text("CAMPUS / EXPERIMENT RECORDER")
			"power":
				title = tr_text("CAMPUS / L-02 BRANCH")
				if facts.power_cut and extracted and facts.power_confirmed:
					lines.append(tr_text("L-02B isolated; shelter L-02A preserved. Ready to settle."))
				elif facts.power_cut: lines.append(tr_text("L-02B remains isolated. A safe return is still needed."))
				else: lines.append(tr_text("Branch isolation not completed / no power-operation milestone."))
			"supply":
				title = tr_text("CAMPUS / EQUIPMENT")
				if extracted and facts.gear_ready and facts.version < 4:
					lines.append(tr_text("Legacy equipment sortie / ready to settle."))
				elif extracted and facts.gear_ready and facts.get("supply_received", false):
					lines.append(tr_text("Dormitory received the equipment / ready to settle."))
				else:
					lines.append(tr_text("Delivery milestone pending / hand off equipment, then return safely."))
				lines.append(tr_text("Base packing is kept. No second equipment payment."))
		if facts.stage in ["relay", "recorder"]:
			if not facts.recorder_instance.is_empty():
				lines.append(tr_text("Recorder carried back / ready to settle.") if extracted else tr_text("Recorder lost with carried gear; its information is remembered."))
			else: lines.append(tr_text("Recorder not brought back / collect it on a later sortie."))
		return [title, "\n".join(lines)]
	if not outcome.slice_context.is_empty():
		var details := tr_text("Exit signs 2/2 / ready to settle.") if extracted and outcome.exit_observations.size() == 2 else tr_text("Exit observations not banked / read both signs in one outing and return safely.")
		return [tr_text("Q01 / EXIT SCOUTING"), details]
	if outcome.q02_active:
		return [tr_text("Q02 / MEDICAL SUPPLIES"), tr_text("Deliver recovered dressings and fabric to Tang Kui at base. Extraction alone does not submit them.") if extracted else tr_text("No carried supplies recovered. Existing warehouse delivery progress is kept.")]
	return []
