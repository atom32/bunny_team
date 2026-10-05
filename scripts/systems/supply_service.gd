class_name SupplyService
extends RefCounted
## Candidate-state transactions. Runtime publishes only after the save succeeds.
const RECIPES := {
	"field_dressing": {"name": "PACK / 2 FIELD DRESSINGS", "inputs": {&"material.fabric": 1}, "output": &"medical.field_dressing", "quantity": 2},
	"rifle_ammo": {"name": "PRESS / 30 RIFLE ROUNDS", "inputs": {&"material.scrap": 2, &"material.propellant": 1}, "output": &"ammo.556_standard", "quantity": 30},
	"smg_ammo": {"name": "PRESS / 45 SMG ROUNDS", "inputs": {&"material.scrap": 1, &"material.propellant": 1}, "output": &"ammo.9mm_standard", "quantity": 45},
	"field_smg": {"name": "BARTER / COMPACT SMG", "inputs": {&"material.electronics": 2, &"material.scrap": 4}, "output": &"weapon.smg_01", "quantity": 1},
	"light_armor": {"name": "BARTER / LIGHT ARMOR", "inputs": {&"material.fabric": 3, &"material.parts": 2}, "output": &"armor.recon_shell_01", "quantity": 1},
	"field_pack": {"name": "BARTER / FIELD PACK", "inputs": {&"material.fabric": 3, &"material.wiring": 1}, "output": &"equipment.field_pack_01", "quantity": 1},
}
const FACILITY_RECIPES := {
	"clinic_medkit": {"name": "CLINIC / ASSEMBLE MEDKIT", "facility": "clinic", "inputs": {&"medical.field_dressing": 2, &"material.fabric": 2}, "output": &"medical.medkit", "quantity": 1},
	"bench_ap": {"name": "BENCH / 30 AP ROUNDS", "facility": "workbench", "inputs": {&"material.scrap": 3, &"material.propellant": 2}, "output": &"ammo.556_ap", "quantity": 30},
}

static func recipes(profile: ProfileState) -> Dictionary:
	var result := RECIPES.duplicate()
	for id in FACILITY_RECIPES:
		if CampaignService.unlocked(profile, FACILITY_RECIPES[id].facility): result[id] = FACILITY_RECIPES[id]
	return result

static func buy_price(definition: ItemDefinition, profile: ProfileState) -> int:
	var discount := CampaignService.unlocked(profile, "supplier") and (definition.has_tag(&"weapon") or definition.has_tag(&"armor") or definition.has_tag(&"backpack"))
	return maxi(1, int(ceil(definition.base_value * .9))) if discount else definition.base_value

static func stock(profile: ProfileState) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for definition in ContentDB.get_items():
		if not (definition.has_tag(&"weapon") or definition.has_tag(&"armor") or definition.has_tag(&"backpack") or definition.has_tag(&"ammo") or definition is MedicalDefinition): continue
		if not profile.first_mission_completed and definition.id in [&"weapon.sniper_01", &"weapon.lmg_01", &"weapon.rocket_launcher_01", &"ammo.556_ap", &"ammo.rocket_standard", &"equipment.thruster_pack_01"]: continue
		result.append(definition)
	return result

static func sell_price(item: ItemInstance) -> int:
	var definition := ContentDB.get_item(item.definition_id, false)
	return maxi(1, int(floor(definition.base_value * .35 * item.durability / 100.0))) if definition else 0

static func count(profile: ProfileState, id: StringName) -> int:
	var total := 0
	for item in profile.inventory.get_items():
		if item.definition_id == id: total += item.quantity
	return total

static func can_claim_relief(profile: ProfileState) -> bool:
	if profile.failed_sorties <= profile.relief_claimed_after or profile.credits >= 300: return false
	for item in profile.inventory.get_items():
		var weapon := ContentDB.get_item(item.definition_id) as WeaponDefinition
		if weapon and count(profile, weapon.get_runtime_ammo_definition_id()) > 0: return false
	return true

static func prepare(profile: ProfileState, action: String, id: String, quantity := 1) -> Dictionary:
	if not profile or not profile.validate() or quantity < 1 or quantity > 10000:
		return {"error": ERR_INVALID_PARAMETER, "message": "Invalid supply transaction."}
	var candidate := ProfileState.from_dict(profile.to_dict())
	var message := ""
	match action:
		"buy":
			var definition := ContentDB.get_item(StringName(id), false)
			if not definition or definition not in stock(profile): message = "This supply is not available yet."
			elif not definition.stackable and quantity != 1: message = "Purchase equipment one item at a time."
			elif candidate.credits < buy_price(definition, profile) * quantity: message = "Not enough credits. Sell recovered supplies or choose cheaper equipment."
			elif not candidate.inventory.add_item(ItemInstance.new(definition.id, quantity)): message = "Warehouse capacity exceeded."
			else: candidate.credits -= buy_price(definition, profile) * quantity
		"sell":
			var item := candidate.inventory.get_item(id)
			if not item or quantity > item.quantity: message = "This item is no longer in the warehouse."
			elif candidate.loadout.is_equipped(id): message = "Unequip this item before selling it."
			else:
				candidate.credits += sell_price(item) * quantity
				candidate.inventory.consume_item(id, quantity)
				if not candidate.inventory.contains(id): candidate.stash_layout.erase(id)
		"barter":
			var available := recipes(profile)
			if not available.has(id) or quantity != 1: message = "Unknown workshop recipe."
			else:
				var recipe: Dictionary = available[id]
				for material: StringName in recipe.inputs:
					if count(candidate, material) < recipe.inputs[material]: message = "Missing materials. Search containers or choose another recipe."
				if message.is_empty():
					for material: StringName in recipe.inputs:
						var remaining: int = recipe.inputs[material]
						for item in candidate.inventory.get_items():
							if item.definition_id != material or remaining == 0: continue
							var used := mini(item.quantity, remaining)
							candidate.inventory.consume_item(item.instance_id, used)
							if not candidate.inventory.contains(item.instance_id): candidate.stash_layout.erase(item.instance_id)
							remaining -= used
					var definition := ContentDB.get_item(recipe.output)
					if definition.stackable:
						if not candidate.inventory.add_item(ItemInstance.new(recipe.output, recipe.quantity)): message = "Warehouse capacity exceeded."
					else:
						for index in int(recipe.quantity):
							if not candidate.inventory.add_item(ItemInstance.new(recipe.output)): message = "Warehouse capacity exceeded."
		"relief":
			if not can_claim_relief(profile): message = "Emergency kit: after a failed sortie, no weapon with ammunition, and fewer than 300 credits. One kit per failure."
			else:
				var gun := ItemInstance.new(&"weapon.pistol_01")
				if not candidate.inventory.add_item(gun) or not candidate.inventory.add_item(ItemInstance.new(&"ammo.9mm_standard", 45)):
					message = "Warehouse capacity exceeded."
				else:
					candidate.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, gun.instance_id, candidate.inventory)
					candidate.relief_claimed_after = candidate.failed_sorties
		_: message = "Invalid supply transaction."
	if not message.is_empty(): return {"error": ERR_UNAVAILABLE, "message": message}
	if not candidate.validate(): return {"error": ERR_INVALID_DATA, "message": "Invalid supply transaction."}
	return {"error": OK, "message": "SUPPLIES UPDATED / SAVED", "candidate": candidate}

static func transact(action: String, id: String, quantity := 1, path := SaveService.DEFAULT_SAVE_PATH) -> Dictionary:
	if SortieRuntime.get_current_session() or ProfileRuntime.recovery_required or not ProfileRuntime.get_profile().sortie_checkpoint.is_empty():
		return {"error": ERR_BUSY, "message": "Supplies are only available at base."}
	var profile := ProfileRuntime.get_profile()
	var result := prepare(profile, action, id, quantity)
	if result.error != OK: return result
	var error := SaveService.save_profile(result.candidate, path)
	if error != OK: return {"error": error, "message": "Could not save. Credits and items are unchanged."}
	profile.replace_with(result.candidate)
	return result
