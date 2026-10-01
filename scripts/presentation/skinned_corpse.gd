extends Node3D
## Keep the authored character and the last evaluated skin pose after defeat.

func capture(source: Skeleton3D, impact: Vector3) -> void:
	var snapshot := source.duplicate() as Skeleton3D
	for node in snapshot.find_children("*", "SkeletonModifier3D", true, false):
		node.get_parent().remove_child(node)
		node.free()
	add_child(snapshot)
	snapshot.global_transform = source.global_transform
	for bone in source.get_bone_count():
		snapshot.set_bone_global_pose(bone, source.get_bone_global_pose(bone))
	var forward := Vector3(impact.x, 0, impact.z).normalized()
	if forward.length_squared() < .01:
		forward = Vector3.BACK
	var fall_axis := Vector3.UP.cross(forward).normalized()
	var fall_basis := Basis(fall_axis, PI * .48) * global_basis
	var target := Transform3D(fall_basis, global_position + forward * .3 + Vector3.UP * .12)
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(self, "global_transform", target, .55)
	get_tree().create_timer(8.0).timeout.connect(queue_free)
