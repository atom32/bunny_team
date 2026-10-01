class_name DeploymentPlan
extends RefCounted

# Carry whole, identity-preserving stacks up to three magazines per equipped weapon.
# A stack may exceed the target; remaining warehouse stacks stay at home.
var ammo_ids: Array[String] = []
var weight := 0.0
var message := ""
var error := ""

static func build(profile: ProfileState) -> DeploymentPlan:
	var plan := DeploymentPlan.new()
	if not profile or not profile.validate():
		plan.error = "Profile is unavailable. Return to the menu to recover your save."
		return plan
	var carried_capacity := ProfileState.DEFAULT_CARRIED_CAPACITY
	var targets: Dictionary = {}
	for id in profile.loadout.get_equipped_instance_ids():
		var item := profile.inventory.get_item(id)
		var definition := ContentDB.get_item(item.definition_id)
		plan.weight += definition.weight * item.quantity
		if definition is WeaponDefinition:
			var ammo_id: StringName = definition.get_runtime_ammo_definition_id()
			targets[ammo_id] = int(targets.get(ammo_id, 0)) + definition.magazine_capacity * 3
	if targets.is_empty():
		plan.error = "Equip at least one weapon before deployment."
	if plan.weight > carried_capacity:
		plan.error = "Equipment is overweight. Select a lighter loadout."
	var lines: Array[String] = []
	for ammo_id in targets:
		var count := 0
		var definition := ContentDB.get_ammo(ammo_id, false)
		if not definition:
			continue
		for item in profile.inventory.get_items():
			if item.definition_id != ammo_id or count >= targets[ammo_id]:
				continue
			var stack_weight := definition.weight * item.quantity
			if plan.weight + stack_weight > carried_capacity:
				continue
			plan.ammo_ids.append(item.instance_id)
			plan.weight += stack_weight
			count += item.quantity
		lines.append(TranslationServer.translate("%s x%d%s") % [GameLanguage.item_name(definition.display_name), count, TranslationServer.translate(" (EMPTY)") if count == 0 else ""])
	plan.message = TranslationServer.translate("SORTIE  %.1f / %.0f kg\n%s\nExtra warehouse ammunition stays at base.") % [plan.weight, carried_capacity, " / ".join(lines)]
	return plan
