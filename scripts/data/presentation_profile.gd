@tool
class_name PresentationProfile
extends Resource
## Model/animation authoring contract only. Combat and movement stay with the controller.
@export var id: StringName
@export_file("*.glb", "*.gltf", "*.tscn") var model_path := ""
# Lazy loading avoids editor autoload preloads racing a first GLTF import.
var model: PackedScene:
	get: return load(model_path) as PackedScene if ResourceLoader.exists(model_path) else null
@export var animation_library: AnimationLibrary
@export var skeleton_path: NodePath
@export var bone_map: BoneMap
@export var semantic_clips: Dictionary[StringName, StringName] = {}
@export var model_scale := 1.0
@export var forward_yaw := PI
@export var source_url := ""
@export var license_ref := ""
@export var target_demographic := "adult"
@export var motion_origin := ""
@export var motion_style := ""

func validate_profile() -> bool:
	if id.is_empty() or not model or not animation_library or skeleton_path.is_empty() or not is_finite(model_scale) or model_scale <= 0 or not is_finite(forward_yaw): return false
	for semantic in [&"idle", &"walk", &"run", &"attack", &"hit", &"death"]:
		if not semantic_clips.has(semantic) or not animation_library.has_animation(semantic_clips[semantic]): return false
	var review := preload("res://addons/neon_content/asset_review.gd")
	if review.has_scripts(model): return false
	var instance := model.instantiate()
	var skeleton := instance.get_node_or_null(skeleton_path) as Skeleton3D
	var valid := skeleton != null
	if valid:
		for name in animation_library.get_animation_list():
			var clip := animation_library.get_animation(name)
			if not is_finite(clip.length) or clip.length <= 0: valid = false
			for track in clip.get_track_count():
				var path := clip.track_get_path(track)
				if clip.track_get_type(track) not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D] or path.get_subname_count() != 1:
					valid = false
					continue
				if String(path).get_slice(":", 0) != String(skeleton_path) or skeleton.find_bone(path.get_subname(0)) < 0: valid = false
		if bone_map and bone_map.profile:
			for index in bone_map.profile.bone_size:
				var mapped := bone_map.get_skeleton_bone_name(bone_map.profile.get_bone_name(index))
				if not mapped.is_empty() and skeleton.find_bone(mapped) < 0: valid = false
	instance.free()
	return valid
