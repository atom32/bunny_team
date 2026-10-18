class_name ContactDefinition
extends RefCounted
## Static presentation ownership only; never part of ProfileState or transactions.
const CONTACTS := {
	"tang_kui": {"id": "tang_kui", "display_name": "唐葵", "title": "地方送水队长 / 居民补给", "description": "转移队退回来了，伤员还在等药。你带回来的补给，我会交到需要的人手里。", "portrait": preload("res://assets/ui/contacts/tang_kui_v1.png"), "shop_id": "resident_supplies", "quest_ids": ["Q02"]},
	"shen_yanshuang": {"id": "shen_yanshuang", "display_name": "沈砚霜", "title": "战术前辈 / 战备供应", "description": "出门前把装备检查一遍。哪条路能撤，先看清楚。别等出了事再找出口。", "portrait": preload("res://assets/ui/contacts/shen_yanshuang_v1.png"), "shop_id": "combat_supplies", "quest_ids": ["Q01", "campus_recorder", "campus_supply"]},
	"su_mi": {"id": "su_mi", "display_name": "苏弥", "title": "维修技师 / 工程支援", "description": "零件先留着，别急着卖。补给、改装缺什么，拿过来看看。", "portrait": preload("res://assets/ui/contacts/su_mi_v1.png"), "shop_id": "workshop", "quest_ids": ["campus_relay", "campus_power"]},
}
const QUEST_OWNERS := {"Q01": "shen_yanshuang", "Q02": "tang_kui", "Q04": "tang_kui", "campus_relay":"su_mi", "campus_recorder":"shen_yanshuang", "campus_power":"su_mi", "campus_supply":"shen_yanshuang"}

static func get_contact(id: String) -> Dictionary:
	return CONTACTS.get(id, {})

static func owns_quest(contact_id: String, quest_id: String) -> bool:
	return quest_id != "Q04" and (contact_id.is_empty() or QUEST_OWNERS.get(quest_id, "") == contact_id)

static func owns_stock(contact_id: String, definition: ItemDefinition) -> bool:
	if contact_id.is_empty(): return true
	if definition.has_tag(&"fitting_kit"): return contact_id == "su_mi"
	var resident := definition is MedicalDefinition or definition.has_tag(&"food") or definition.has_tag(&"drink") or (definition.has_tag(&"backpack") and definition.id != &"equipment.thruster_pack_01")
	if contact_id == "tang_kui": return resident
	if contact_id == "shen_yanshuang": return not resident
	return false # Engineering uses existing barter/fittings, not a new material shop.
