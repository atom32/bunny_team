class_name NarrativeSlice
extends RefCounted
## Fixed slice data and Q01/Q02/Q04 validation; no task graph or event dispatcher.
const TASK_IDS := ["Q01", "Q02", "Q04", "Q03", "Q05", "Q06"]
const CHAINS := {"A": ["Q01", "Q02", "Q04"], "B": ["Q03", "Q05", "Q06"]}
const ENDPOINTS := {"A": "Q04", "B": "Q06"}
const EXIT_IDS := ["streets_exit_0", "streets_exit_1", "streets_exit_2", "streets_exit_3"]
const Q01_REWARD := 150
const Q02_REWARD := 150
const Q04_REWARD := 200
const PHARMACY_BATCH := "MED-TK-071"
const PHARMACY_POSITION := Vector3(17, 0, -23) # Inside the pharmacy, beyond exterior-wall interaction range.
const BATCH_INFORMATION := "配送批次 MED-TK-071\n收货登记：D-1，敷料×2、织物×2，标记已收齐\n该批次现场收货格：敷料×0、织物×0；普通库存另计"
const Q02_REQUEST := "唐葵：药房牌子还亮着。替我查看 MED-TK-071 收货批次，再带回敷料×2、织物×2。买来的也行，我要的是今晚能用。"
const Q02_MESSAGE := "唐葵：够今晚了。奇怪，送货表上写着昨天就收齐了。配送记录还得再核对。"
const DELIVERY_RECEIPT := "MED-TK-071-RECEIPT"
const RECEIPT_POSITION := Vector3(-25, 0, 19)
const RECEIPT_INFORMATION := "配送回执 MED-TK-071-RECEIPT\n批次：MED-TK-071；登记日：D-1\n配送记录：已完成签收；签收数量：敷料×2、织物×2"
const Q04_LOG := "该批次配送记录显示已完成签收，但药房现场记录与签收数量存在差异。相关配送调度记录可进一步核对。"
const Q02_INPUTS := {&"medical.field_dressing": 2, &"material.fabric": 2}

static func initial_state() -> Dictionary:
	var settled := {}
	for id in TASK_IDS: settled[id] = false
	return {"version": 3, "settled": settled, "q01_exits": [], "q04": {"receipt_id": "", "observed_batch": "", "log": ""}, "q02": {"observed_batch": "", "delivered": {"medical.field_dressing": 0, "material.fabric": 0}, "message": ""}}

static func valid_state(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY or raw.size() != 5 or raw.get("version") != 3: return false
	var settled: Variant = raw.get("settled")
	if typeof(settled) != TYPE_DICTIONARY or settled.size() != TASK_IDS.size(): return false
	for id in TASK_IDS:
		if typeof(settled.get(id)) != TYPE_BOOL: return false
		# Only these three fixed tasks have an implementation.
		if id not in ["Q01", "Q02", "Q04"] and settled[id]: return false
	var exits: Variant = raw.get("q01_exits")
	if not valid_exit_ids(exits) or exits.size() != (2 if settled.Q01 else 0): return false
	var q02: Variant = raw.get("q02")
	if typeof(q02) != TYPE_DICTIONARY or q02.size() != 3: return false
	if typeof(q02.get("observed_batch")) != TYPE_STRING or q02.observed_batch not in ["", PHARMACY_BATCH]: return false
	if typeof(q02.get("delivered")) != TYPE_DICTIONARY or q02.delivered.size() != 2: return false
	var complete: bool = q02.observed_batch == PHARMACY_BATCH
	for id in Q02_INPUTS:
		if not SortieCheckpoint.integer(q02.delivered.get(String(id)), 0, 2): return false
		if q02.delivered[String(id)] > 0 and q02.observed_batch.is_empty(): return false
		complete = complete and q02.delivered[String(id)] == 2
	if not settled.Q01 and (not q02.observed_batch.is_empty() or settled.Q02): return false
	if typeof(q02.get("message")) != TYPE_STRING or settled.Q02 != complete or q02.message != (Q02_MESSAGE if complete else ""): return false
	var q04: Variant = raw.get("q04")
	if typeof(q04) != TYPE_DICTIONARY or q04.size() != 3: return false
	if typeof(q04.get("receipt_id")) != TYPE_STRING or q04.receipt_id not in ["", DELIVERY_RECEIPT]: return false
	if typeof(q04.get("observed_batch")) != TYPE_STRING or q04.observed_batch not in ["", PHARMACY_BATCH]: return false
	if not settled.Q02 and (not q04.receipt_id.is_empty() or not q04.observed_batch.is_empty() or settled.Q04): return false
	if settled.Q04 and (q04.receipt_id != DELIVERY_RECEIPT or q04.observed_batch != PHARMACY_BATCH): return false
	return typeof(q04.get("log")) == TYPE_STRING and q04.log == (Q04_LOG if settled.Q04 else "")

static func restore_state(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY: return {}
	var state: Dictionary = raw.duplicate(true)
	if state.get("version") == 1:
		# Validate the exact Q01 contract before adding Q02 defaults.
		if state.size() != 3 or not state.has("settled") or not state.has("q01_exits"): return {}
		state.version = 2
		state.q02 = initial_state().q02
	if state.get("version") == 2:
		if state.size() != 4 or not state.has("q02"): return {}
		state.version = 3
		state.q04 = initial_state().q04
	if not valid_state(state): return {}
	state.version = 3
	for id in Q02_INPUTS: state.q02.delivered[String(id)] = int(state.q02.delivered[String(id)])
	return state

static func valid_pharmacy(active: Variant, batch: Variant, area: StringName) -> bool:
	return typeof(active) == TYPE_BOOL and typeof(batch) == TYPE_STRING and batch in ["", PHARMACY_BATCH] and (batch.is_empty() or active) and (not active or area == &"street_district")

static func valid_q04(active: Variant, receipt: Variant, area: StringName) -> bool:
	return typeof(active) == TYPE_BOOL and typeof(receipt) == TYPE_STRING and receipt in ["", DELIVERY_RECEIPT] and (receipt.is_empty() or active) and (not active or area == &"street_district")

static func valid_exit_ids(raw: Variant) -> bool:
	if typeof(raw) != TYPE_ARRAY or raw.size() > 2: return false
	var seen := []
	for id in raw:
		if typeof(id) != TYPE_STRING or id not in EXIT_IDS or id in seen: return false
		seen.append(id)
	return true

static func valid_facts(context: Variant, observations: Variant, area: StringName) -> bool:
	if typeof(context) != TYPE_DICTIONARY or not valid_exit_ids(observations): return false
	if context.is_empty(): return observations.is_empty()
	if area != &"street_district" or context.size() != 2 or context.get("quest_id") != "Q01": return false
	var assigned: Variant = context.get("exit_conditions")
	if typeof(assigned) != TYPE_DICTIONARY or assigned.size() not in [0, 2]: return false
	var retreat := 0
	for id in assigned:
		if typeof(id) != TYPE_STRING or id not in EXIT_IDS or typeof(assigned[id]) != TYPE_STRING or assigned[id] not in ["", "streets_terminal"]: return false
		if assigned[id].is_empty(): retreat += 1
	if assigned.size() == 2 and retreat != 1: return false
	for id in observations:
		if not assigned.has(id): return false
	return true

static func world_matches(world: Dictionary, session: SortieSession) -> bool:
	return world.get("slice_context", {}) == session.slice_context and world.get("exit_observations", []) == session.exit_observations and world.get("q02_active", false) == session.q02_active and world.get("pharmacy_batch", "") == session.pharmacy_batch and world.get("q04_active", false) == session.q04_active and world.get("delivery_receipt", "") == session.delivery_receipt

static func record_outcome(profile: ProfileState, outcome: SortieOutcome) -> void:
	if not profile.first_mission_completed or outcome.result_type != SortieOutcome.ResultType.COMPLETED: return
	if not profile.narrative_slice.settled.Q01 and not outcome.slice_context.is_empty() and outcome.exit_observations.size() == 2:
		profile.narrative_slice.q01_exits = outcome.exit_observations.duplicate()
		profile.narrative_slice.settled.Q01 = true
		profile.credits += Q01_REWARD
	if profile.narrative_slice.settled.Q01 and outcome.q02_active and outcome.pharmacy_batch == PHARMACY_BATCH:
		profile.narrative_slice.q02.observed_batch = PHARMACY_BATCH
	if profile.narrative_slice.settled.Q02 and not profile.narrative_slice.settled.Q04 and outcome.q04_active:
		if outcome.delivery_receipt == DELIVERY_RECEIPT: profile.narrative_slice.q04.receipt_id = DELIVERY_RECEIPT
		if outcome.pharmacy_batch == PHARMACY_BATCH: profile.narrative_slice.q04.observed_batch = PHARMACY_BATCH

static func prepare_q02_delivery(profile: ProfileState) -> Dictionary:
	if not profile or not profile.validate(): return {"error": ERR_INVALID_DATA, "message": "Invalid profile."}
	if not profile.narrative_slice.settled.Q01 or profile.narrative_slice.settled.Q02 or profile.narrative_slice.q02.observed_batch.is_empty():
		return {"error": ERR_UNAVAILABLE, "message": "先在药房观察指定批次并成功撤离；已完成的交付不能重复提交。"}
	var candidate := ProfileState.from_dict(profile.to_dict())
	var delivered: Dictionary = candidate.narrative_slice.q02.delivered
	var used_total := 0
	for id in Q02_INPUTS:
		var remaining := mini(2 - int(delivered[String(id)]), SupplyService.count(candidate, id))
		delivered[String(id)] += remaining
		used_total += remaining
		for item in candidate.inventory.get_items():
			if item.definition_id != id or remaining == 0: continue
			var used := mini(item.quantity, remaining)
			candidate.inventory.consume_item(item.instance_id, used)
			if not candidate.inventory.contains(item.instance_id): candidate.stash_layout.erase(item.instance_id)
			remaining -= used
	if used_total == 0: return {"error": ERR_UNAVAILABLE, "message": "仓库没有尚需交付的敷料或织物。"}
	if delivered["medical.field_dressing"] == 2 and delivered["material.fabric"] == 2:
		candidate.narrative_slice.settled.Q02 = true
		candidate.narrative_slice.q02.message = Q02_MESSAGE
		candidate.credits += Q02_REWARD
	if not candidate.validate(): return {"error": ERR_INVALID_DATA, "message": "Invalid delivery state."}
	return {"error": OK, "candidate": candidate, "message": "Q02 实际交付已保存。"}

static func submit_q02(path := SaveService.DEFAULT_SAVE_PATH) -> Dictionary:
	var profile := ProfileRuntime.get_profile()
	if SortieRuntime.get_current_session() or ProfileRuntime.recovery_required or not profile.sortie_checkpoint.is_empty():
		return {"error": ERR_BUSY, "message": "只能在基地交付。"}
	var result := prepare_q02_delivery(profile)
	if result.error != OK: return result
	var error := SaveService.save_profile(result.candidate, path)
	if error != OK: return {"error": error, "message": "保存失败，材料、进度和奖励均未变更。"}
	profile.replace_with(result.candidate)
	return result

static func q02_status(profile: ProfileState, session: SortieSession = null) -> String:
	if not profile.narrative_slice.settled.Q01: return "Q02 今晚的药 / 完成 Q01 后可提交"
	var state: Dictionary = profile.narrative_slice.q02
	var observation := "现场观察后成功撤离" if state.observed_batch.is_empty() else "批次观察已带回"
	if session and not session.pharmacy_batch.is_empty() and state.observed_batch.is_empty(): observation = "已观察批次，尚未成功带回"
	if profile.narrative_slice.settled.Q02: observation = "已结算"
	return "Q02 今晚的药 / %s / 已交敷料 %d/2、织物 %d/2" % [observation, state.delivered["medical.field_dressing"], state.delivered["material.fabric"]]

static func status_text(profile: ProfileState, session: SortieSession = null) -> String:
	if profile.narrative_slice.settled.Q01: return "Q01 已结算 / Q01 SETTLED"
	var count := session.exit_observations.size() if session else 0
	if count == 2: return "Q01 已观察两个出口，尚未成功带回 / 2 EXITS OBSERVED, EXTRACT TO SETTLE"
	if count == 1: return "Q01 已观察一个出口 / 1 OF 2 EXITS OBSERVED"
	return "Q01 未完成：现场查看两个出口铭牌 / INSPECT BOTH ASSIGNED EXIT PLAQUES"


static func prepare_q04_submission(profile: ProfileState) -> Dictionary:
	if not profile or not profile.validate(): return {"error": ERR_INVALID_DATA, "message": "Invalid profile."}
	var facts: Dictionary = profile.narrative_slice.q04
	if not profile.narrative_slice.settled.Q02 or profile.narrative_slice.settled.Q04 or facts.receipt_id != DELIVERY_RECEIPT or facts.observed_batch != PHARMACY_BATCH:
		return {"error": ERR_UNAVAILABLE, "message": "同批次配送回执与药房现场记录均须成功带回；已结算的记录不能重复提交。"}
	var candidate := ProfileState.from_dict(profile.to_dict())
	candidate.narrative_slice.settled.Q04 = true
	candidate.narrative_slice.q04.log = Q04_LOG
	candidate.credits += Q04_REWARD
	if not candidate.validate(): return {"error": ERR_INVALID_DATA, "message": "Invalid submission state."}
	return {"error": OK, "candidate": candidate, "message": "Q04 已结算 / 调查日志已保存。"}

static func submit_q04(path := SaveService.DEFAULT_SAVE_PATH) -> Dictionary:
	var profile := ProfileRuntime.get_profile()
	if SortieRuntime.get_current_session() or ProfileRuntime.recovery_required or not profile.sortie_checkpoint.is_empty():
		return {"error": ERR_BUSY, "message": "只能在基地提交。"}
	var result := prepare_q04_submission(profile)
	if result.error != OK: return result
	var error := SaveService.save_profile(result.candidate, path)
	if error != OK: return {"error": error, "message": "保存失败，调查状态和奖励均未变更。"}
	profile.replace_with(result.candidate)
	# Q04 is chain A's endpoint. No successor, marker or narrative state is generated.
	return result

static func q04_status(profile: ProfileState, session: SortieSession = null) -> String:
	if profile.narrative_slice.settled.Q04: return "Q04 账上已经送到 / 已结算"
	var facts: Dictionary = profile.narrative_slice.q04
	var receipt := "已带回" if not facts.receipt_id.is_empty() else "未带回"
	var pharmacy := "已带回" if not facts.observed_batch.is_empty() else "未带回"
	if session and not session.delivery_receipt.is_empty() and facts.receipt_id.is_empty(): receipt = "已取得，尚未成功带回"
	if session and not session.pharmacy_batch.is_empty() and facts.observed_batch.is_empty(): pharmacy = "已观察，尚未成功带回"
	return "Q04 账上已经送到 / MED-TK-071 配送回执：%s / 药房现场记录：%s" % [receipt, pharmacy]
