@tool
class_name HeroineMotionStyle
extends Resource
## Project-authored adaptation for the selected young-adult heroine, not performer demographics.
@export var id: StringName = &"motion.heroine.natural_combat"
@export var target_demographic := "young adult female"
@export var source_note := "UnityChan female-character clips; not age-verified female mocap"
@export var style := "natural, light, combat practical"
@export_range(0.0, 1.0) var hip_lateral_sway := .80
@export_range(0.0, 1.0) var torso_lateral_sway := .85
@export_range(0.0, 1.0) var leg_lateral_sway := .90

func apply(animation: Animation, skeleton: Skeleton3D, clip: StringName) -> void:
	animation.set_meta("motion_style_id", String(id))
	animation.set_meta("target_demographic", target_demographic)
	animation.set_meta("motion_source_note", source_note)
	# Keep sagittal stride/knee flexion and timing. Reduce lateral sway only;
	# production aim/reload modifiers and final palm contact still own the hands.
	if clip not in [&"Idle_Gun", &"Walk", &"Run", &"Run_Shoot"]: return
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D: continue
		var name := animation.track_get_path(track).get_subname(0)
		var lateral := 1.0
		if name == &"Character1_Hips": lateral = hip_lateral_sway
		elif String(name).begins_with("Character1_Spine"): lateral = torso_lateral_sway
		elif name in [&"Character1_LeftUpLeg", &"Character1_RightUpLeg"]: lateral = leg_lateral_sway
		if lateral == 1.0: continue
		var rest := skeleton.get_bone_rest(skeleton.find_bone(name)).basis.get_rotation_quaternion()
		for key in animation.track_get_key_count(track):
			var pose: Quaternion = animation.track_get_key_value(track, key)
			var delta := (rest.inverse() * pose).get_euler()
			delta.y *= lateral
			delta.z *= lateral
			animation.track_set_key_value(track, key, (rest * Quaternion.from_euler(delta)).normalized())
