class_name ContactDefinition
extends RefCounted
## Static presentation ownership only; never part of ProfileState or transactions.
const CONTACTS := {
	"tang_kui": {"id": "tang_kui", "display_name": "唐葵", "title": "地方送水队长 / 居民补给", "description": "澜港居民今晚需要能用的药和物资。你带回来的东西，要真正送到人手里。", "portrait": preload("res://assets/ui/contacts/tang_kui_v1.png"), "shop_id": "resident_supplies", "quest_ids": ["Q02", "Q04"]},
	"shen_yanshuang": {"id": "shen_yanshuang", "display_name": "沈砚霜", "title": "战术前辈 / 战备供应", "description": "先确认通行条件，再决定带什么出门。我提供战备，你把自己安全带回来。", "portrait": preload("res://assets/ui/contacts/shen_yanshuang_v1.png"), "shop_id": "combat_supplies", "quest_ids": ["Q01"]},
	"su_mi": {"id": "su_mi", "display_name": "苏弥", "title": "维修技师 / 工程支援", "description": "材料别急着扔。现有工坊可以交换物资、制作补给和改装装备。", "portrait": preload("res://assets/ui/contacts/su_mi_v1.png"), "shop_id": "workshop", "quest_ids": []},
}
const QUEST_OWNERS := {"Q01": "shen_yanshuang", "Q02": "tang_kui", "Q04": "tang_kui"}

static func get_contact(id: String) -> Dictionary:
	return CONTACTS.get(id, {})

static func owns_quest(contact_id: String, quest_id: String) -> bool:
	return contact_id.is_empty() or QUEST_OWNERS.get(quest_id, "") == contact_id

static func owns_stock(contact_id: String, definition: ItemDefinition) -> bool:
	if contact_id.is_empty(): return true
	var resident := definition is MedicalDefinition or (definition.has_tag(&"backpack") and definition.id != &"equipment.thruster_pack_01")
	if contact_id == "tang_kui": return resident
	if contact_id == "shen_yanshuang": return not resident
	return false # Engineering uses existing barter/fittings, not a new material shop.
