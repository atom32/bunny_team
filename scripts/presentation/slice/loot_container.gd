class_name SliceLootContainer
extends Node3D
## Visual case around already rolled LootPickups. No new loot rolls or collision.
var lid: Node3D
var opened := false
var motion: Tween

func _ready() -> void:
	VisualFactory.box(self, Vector3(1.05,0.6,0.72), Vector3(0,0.3,0), Color("304755"), "Case")
	for x in [-0.42,0.42]:
		VisualFactory.box(self, Vector3(0.08,0.65,0.78), Vector3(x,0.33,0), Color("cda760"), "Band")
	lid = Node3D.new()
	lid.position = Vector3(0,0.65,-0.36)
	add_child(lid)
	VisualFactory.box(lid, Vector3(1.08,0.12,0.76), Vector3(0,0,0.36), Color("587782"), "Lid")
	var lamp := VisualFactory.box(self, Vector3(0.4,0.055,0.025), Vector3(0,0.5,0.38), SliceUI.CYAN, "Latch")
	lamp.material_override = VisualFactory.material(SliceUI.CYAN,0,0.7,SliceUI.CYAN,1.2)
	for pickup in get_parent().get_children():
		if pickup is LootPickup:
			for visual in pickup.get_children():
				if visual is Node3D: visual.hide()
	var tag := SliceUI.sign(self, "SUPPLY CASE", Vector3(0,1.0,0))
	tag.font_size = 26
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func set_open(value: bool) -> void:
	opened = value
	if motion and motion.is_valid(): motion.kill()
	motion = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(lid,"rotation:x",deg_to_rad(-105.0) if value else 0.0,0.32)
	AudioDirector.play_sfx(&"reload",-9)

func contents() -> Array[LootPickup]:
	var result: Array[LootPickup] = []
	for child in get_parent().get_children():
		if child is LootPickup and not child.consumed: result.append(child)
	return result
