class_name ItemPresentation
extends RefCounted
## Cosmetic lookup only. ContentDB and ItemInstance still own all item rules.
const SCENES := {
	&"medical.medkit":"medkit", &"medical.field_dressing":"field_dressing",
	&"material.electronics":"electronics", &"material.parts":"parts",
	&"material.wiring":"wiring", &"material.fabric":"fabric",
	&"material.data_drive":"data_drive", &"story.experiment_recorder":"experiment_recorder",
	&"material.scrap":"scrap", &"material.propellant":"propellant",
	&"loot.salvage_core_01":"salvage_core", &"supply.field_ration":"field_ration",
	&"supply.energy_bar":"energy_bar", &"supply.canned_beans":"canned_beans",
	&"supply.bottled_water":"bottled_water", &"supply.citrus_drink":"citrus_drink",
}
const EXISTING := {
	&"material.market_carrier_frame":"res://scenes/props/supply_art_v1/carrier_frame.tscn",
	&"ammo.556_standard":"res://scenes/weapons/art_pack_v1/ammo_556_box.tscn",
	&"material.quickloader_kit":"res://scenes/weapons/art_pack_v1/quickloader_magazine.tscn",
	&"material.suppressor_kit":"res://scenes/weapons/art_pack_v1/suppressor.tscn",
	&"material.observation_optic_kit":"res://scenes/weapons/art_pack_v1/observation_optic.tscn",
}
static func create(id: StringName) -> Node3D:
	var path: String=EXISTING.get(id,"")
	if SCENES.has(id):path="res://scenes/props/supply_art_v1/"+SCENES[id]+".tscn"
	if path.is_empty():return null
	var model:=load(path).instantiate() as Node3D
	model.name="ItemArt";model.set_meta("presentation_definition_id",String(id));return model
static func bounds(node: Node3D,transform:=Transform3D.IDENTITY) -> AABB:
	var result:=AABB();var first:=true
	for child in node.get_children():
		if not child is Node3D:continue
		var local: Transform3D=transform*child.transform
		var box: AABB=local*child.get_aabb() if child is MeshInstance3D else bounds(child,local)
		if box.size.is_zero_approx():continue
		result=box if first else result.merge(box);first=false
	return result
static func fit_pickup(model: Node3D) -> void:
	var box:=bounds(model);var longest:=maxf(box.size.x,maxf(box.size.y,box.size.z))
	if longest<=0:return
	var factor:=.42/longest
	model.scale=Vector3.ONE*factor
	model.position=Vector3(-box.get_center().x*factor,.14-box.position.y*factor,-box.get_center().z*factor)
