extends Node3D
## Presentation only. All bodies, shapes and interaction scripts stay authored in Area.
const DOOR_MODEL := preload("res://assets/environment/kenney_space_station_kit/door-double-closed.glb")
const PALETTE := preload("res://resources/materials/office_palette.tres")
var _player: Node3D

func _ready() -> void:
	call_deferred("_dress_existing_fixtures")

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return
	var local_player := to_local(_player.global_position)
	# The current high-angle camera needs a cutaway on approach and while inside.
	$OfficeArt/RoofShell.visible = not (absf(local_player.x) < 8.0 and absf(local_player.z) < 11.0)

func _dress_existing_fixtures() -> void:
	var lane := get_parent()
	# Existing courtyard collision sits within this room; dress it as a service counter.
	var environment := lane.get_parent().get_parent().get_node_or_null("Environment")
	if environment:
		var counter := environment.find_child("CourtyardCover", true, false) as StaticBody3D
		if counter:
			for part in counter.get_children():
				if part is MeshInstance3D:
					part.material_override = VisualFactory.material(Color("374c4b"), 0.25, 0.7)
			VisualFactory.box(counter, Vector3(4.05, 0.08, 0.75), Vector3(0, 0.45, 0), Color("536461"), "Countertop")
	var door := lane.get_node_or_null("SouthAccessDoor/DoorLeaf/DoorBody/DoorMesh") as MeshInstance3D
	if door:
		door.mesh = null
		var art := DOOR_MODEL.instantiate() as Node3D
		art.position = Vector3(0, -1.2, 0)
		art.scale = Vector3(3.66, 3.43, 2.4)
		door.add_child(art)
		for mesh in art.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = PALETTE
	for cover_name in ["InteriorEntryCover", "InteriorFlankCover"]:
		var cover := lane.get_node_or_null(cover_name + "/CoverMesh") as MeshInstance3D
		if cover:
			_dress_barrier(cover, Vector3(2.8, 1.5, 0.7), false)
	var barrier := lane.get_node_or_null("DestructibleBarrier/BarrierMesh") as MeshInstance3D
	if barrier:
		_dress_barrier(barrier, Vector3(3.0, 2.0, 0.55), true)

func _dress_barrier(mesh: MeshInstance3D, dimensions: Vector3, destructible: bool) -> void:
	mesh.material_override = VisualFactory.material(Color("334748"), 0.3, 0.8)
	# Children inherit BarrierMesh.visible, so destruction removes the entire visual.
	for side in [-1.0, 1.0]:
		var panel := VisualFactory.box(mesh, Vector3(dimensions.x - 0.18, dimensions.y - 0.22, 0.035), Vector3(0, 0, side * (dimensions.z * 0.5 + 0.018)), Color("637270"), "InsetPanel")
		for x in [-0.4, 0.4]:
			VisualFactory.box(panel, Vector3(0.06, dimensions.y - 0.32, 0.05), Vector3(dimensions.x * x, 0, 0), Color("26383b"), "Brace")
		VisualFactory.box(panel, Vector3(dimensions.x - 0.3, 0.09, 0.055), Vector3(0, dimensions.y * 0.28, 0), Color("a5743c") if destructible else Color("2f6968"), "IdentificationBand")
	VisualFactory.box(mesh, Vector3(dimensions.x + 0.04, 0.08, dimensions.z + 0.04), Vector3(0, dimensions.y * 0.5, 0), Color("243538"), "Cap")
