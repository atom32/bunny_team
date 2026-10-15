@tool
extends EditorNode3DGizmoPlugin

func _init() -> void:
	create_material("muzzle", Color("ff6b63"))
	create_material("grips", Color("54dfd4"))

func _get_gizmo_name() -> String:
	return "Neon Weapon Mounts"

func _has_gizmo(node: Node3D) -> bool:
	return node.has_node("Muzzle") and node.has_node("PrimaryGrip") and node.has_node("SupportGrip")

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var node := gizmo.get_node_3d()
	var muzzle := node.get_node("Muzzle") as Marker3D
	var start := muzzle.position
	gizmo.add_lines(PackedVector3Array([start, start + muzzle.transform.basis * Vector3.FORWARD * .7]), get_material("muzzle", gizmo))
	var primary := node.get_node("PrimaryGrip") as Marker3D
	var support := node.get_node("SupportGrip") as Marker3D
	var lines := PackedVector3Array([primary.position, support.position])
	if node.has_node("ReloadGrip"):
		lines.append(support.position)
		lines.append(node.get_node("ReloadGrip").position)
	gizmo.add_lines(lines, get_material("grips", gizmo))
