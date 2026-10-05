class_name MedicalTreatment
extends Node
## A carried consumable and an interruptible action, not passive regeneration.
signal feedback(message: String, success: bool)
const IDS := ["medical.field_dressing", "medical.medkit"]
const ACTIONS := ["use_dressing", "use_medkit"]
var actor: PlayerController
var session: SortieSession
var item_id := ""
var remaining := 0.0

static func install_input_actions() -> void:
	for index in ACTIONS.size():
		if InputMap.has_action(ACTIONS[index]): continue
		InputMap.add_action(ACTIONS[index])
		var key := InputEventKey.new()
		key.physical_keycode = KEY_H if index == 0 else KEY_J
		InputMap.action_add_event(ACTIONS[index], key)

func count(definition_id: String) -> int:
	var total := 0
	if session:
		for item in session.inventory.get_items():
			if item.definition_id == StringName(definition_id): total += item.quantity
	return total

func is_active() -> bool:
	return not item_id.is_empty()

func definition() -> MedicalDefinition:
	var item := session.inventory.get_item(item_id) if session else null
	return ContentDB.get_item(item.definition_id, false) as MedicalDefinition if item else null

func begin(definition_id: String) -> bool:
	if not session or session.status != SortieSession.Status.ACTIVE or actor.is_dead or get_tree().paused: return false
	if is_active():
		cancel()
		return false
	if actor.health >= actor.max_health:
		feedback.emit(tr("No treatment needed / health full."), false)
		return false
	if _busy():
		feedback.emit(tr("Stand still and finish reloading before treatment."), false)
		return false
	for item in session.inventory.get_items():
		var medical := ContentDB.get_item(item.definition_id, false) as MedicalDefinition
		if not medical or item.definition_id != StringName(definition_id): continue
		item_id = item.instance_id
		remaining = medical.use_seconds
		actor.clear_buffered_input()
		AudioDirector.play_sfx(&"reload", -6.0) # Existing kit-handling placeholder, not a new animation.
		SortieRuntime.request_checkpoint()
		return true
	feedback.emit(tr("No medical supplies carried. Buy and pack them at base, or search containers."), false)
	return false

func _busy() -> bool:
	if actor._dodge_time > 0.0 or Vector2(actor.velocity.x, actor.velocity.z).length() > 0.2: return true
	if actor.combat_rig and actor.combat_rig.is_reloading(): return true
	for time: float in actor._reload_remaining_by_weapon.values():
		if time > 0.0: return true
	for action in ["move_left", "move_right", "move_forward", "move_back", "fire", "dodge", "reload", "switch_weapon", "interact"]:
		if Input.is_action_pressed(action): return true
	return false

func tick(delta: float) -> void:
	if not is_active() or get_tree().paused: return
	if actor.is_dead or session.status != SortieSession.Status.ACTIVE or _busy():
		cancel()
		return
	var medical := definition()
	if not medical:
		cancel()
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining > 0: return
	var restored := minf(medical.healing, actor.max_health - actor.health)
	if restored > 0 and session.inventory.consume_item(item_id, 1):
		actor.health += restored
		actor.health_changed.emit(actor.health, actor.max_health)
		AudioDirector.play_sfx(&"ui_confirm", -3.0)
		feedback.emit(tr("TREATMENT COMPLETE / +%d HP") % roundi(restored), true)
	item_id = ""
	remaining = 0.0
	SortieRuntime.request_checkpoint()

func cancel() -> void:
	if not is_active(): return
	item_id = ""
	remaining = 0.0
	feedback.emit(tr("Treatment interrupted / supplies retained."), false)
	SortieRuntime.request_checkpoint()

func snapshot() -> Dictionary:
	return {"item": item_id, "remaining": remaining}

func valid_snapshot(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY: return false
	if data.is_empty(): return true # Pre-medical schema-3 checkpoint.
	if data.size() != 2 or typeof(data.get("item")) != TYPE_STRING or not SaveService.is_number(data.get("remaining")): return false
	if data.item.is_empty(): return data.remaining == 0.0
	var item := session.inventory.get_item(data.item)
	var medical := ContentDB.get_item(item.definition_id, false) as MedicalDefinition if item else null
	return medical != null and data.remaining > 0 and data.remaining <= medical.use_seconds

func restore(data: Dictionary) -> void:
	item_id = data.get("item", "")
	remaining = data.get("remaining", 0.0)
