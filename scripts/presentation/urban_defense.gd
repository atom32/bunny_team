extends Node3D
## Skin the eight existing cover blocks, without owning collision or layout.
const BARRIER := preload("res://scenes/presentation/urban_defense/security_barrier.tscn")
var original_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	_build.call_deferred()

func _build() -> void:
	# Parent's procedural geometry is complete before this deferred callback.
	for body in get_parent().get_children():
		if not body is StaticBody3D:
			continue
		var mesh := body.get_node_or_null("Mesh") as MeshInstance3D
		if not mesh or not mesh.mesh is BoxMesh:
			continue
		# The existing size is the cover contract; never change it or add physics.
		if not mesh.mesh.size.is_equal_approx(Vector3(2.8, 0.9, 0.58)):
			continue
		var visual := BARRIER.instantiate() as Node3D
		add_child(visual)
		visual.global_transform = body.global_transform
		visual.position.y -= 0.45
		original_meshes.append(mesh)
		mesh.visible = false

func set_presentation_visible(enabled: bool) -> void:
	# Reversible evidence comparison; no physics/render geometry coupling.
	visible = enabled
	for mesh in original_meshes:
		mesh.visible = not enabled
