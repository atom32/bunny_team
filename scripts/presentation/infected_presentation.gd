extends HumanoidEnemyPresentation
var profile: PresentationProfile
var legacy_mode := false

func _ready() -> void:
	if profile:
		_build_subject()
		return
	_build_legacy()

func _build_legacy() -> void:
	legacy_mode = true
	super._ready()
	pistol.hide()
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if mesh != pistol:
			for surface in mesh.mesh.get_surface_count():
				var source = mesh.get_active_material(surface)
				if source is StandardMaterial3D:
					var stained := source.duplicate() as StandardMaterial3D
					stained.albedo_color *= Color(.65,.78,.58)
					stained.roughness = .95
					mesh.set_surface_override_material(surface, stained)
	for clip in ["Idle", "Walk", "Run"]:
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation_player.play("Idle")
	model.rotation.x = .12

func _build_subject() -> void:
	legacy_mode = false
	model = profile.model.instantiate() as Node3D
	model.name = "ImportedContainmentSubject"
	model.rotation.y = profile.forward_yaw
	model.scale = Vector3.ONE * profile.model_scale
	add_child(model)
	animation_player = AnimationPlayer.new()
	model.add_child(animation_player)
	animation_player.add_animation_library("", profile.animation_library)
	animation_player.play(profile.semantic_clips[&"idle"])
	pistol = null
	var skeleton := model.get_node(profile.skeleton_path) as Skeleton3D
	var badge := BoneAttachment3D.new(); badge.name = "SubjectIdentity"; badge.bone_name = "spine_03"
	skeleton.add_child(badge)
	var label := Label3D.new(); label.text = "L-02 / 017"; label.font_size = 22; label.pixel_size = .0018
	label.position = Vector3(0, .05, .08); label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("172532"); badge.add_child(label)

func use_legacy_model() -> void:
	# Old suspended sorties retain their exact old skin/rig and sampled pose.
	if legacy_mode: return
	model.free()
	_build_legacy()

func play_hit() -> void:
	if not _dead and not legacy_mode and _shot_remaining <= 0:
		animation_player.play(profile.semantic_clips[&"hit"], .06)

func get_muzzle_position() -> Vector3:
	# Generic presentation/checkpoint API: this unarmed actor exposes a strike
	# origin, not a gun muzzle. Its controller never invokes the ranged pipeline.
	if legacy_mode: return super.get_muzzle_position()
	var skeleton := model.get_node(profile.skeleton_path) as Skeleton3D
	return skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).origin)

func update_visual(aim_point: Vector3, _move_direction: Vector3, speed: float, delta: float) -> void:
	if _dead: return
	_aim_point = aim_point
	_move_speed = speed
	_shot_remaining = maxf(0, _shot_remaining - delta)
	if not legacy_mode and animation_player.current_animation == String(profile.semantic_clips[&"hit"]) and animation_player.current_animation_position < animation_player.current_animation_length - .02 and _shot_remaining <= 0: return
	var semantic := &"attack" if _shot_remaining > 0 else (&"run" if speed > 1.5 else (&"walk" if speed > .25 else &"idle"))
	var clip: StringName = {&"attack":&"Punch_Left",&"run":&"Run",&"walk":&"Walk",&"idle":&"Idle"}[semantic] if legacy_mode else profile.semantic_clips[semantic]
	if animation_player.current_animation != clip: animation_player.play(clip, .15)

func fire_recoil() -> void:
	# Presentation duration only: controller damage windup/cooldown stay unchanged.
	_shot_remaining = .65 if legacy_mode else animation_player.get_animation(profile.semantic_clips[&"attack"]).length
	animation_player.play("Punch_Left" if legacy_mode else profile.semantic_clips[&"attack"], .08)

func play_death(impact: Vector3) -> void:
	if legacy_mode:
		super.play_death(impact)
		return
	_dead = true
	var marker := get_node_or_null("EnemyMarker")
	if marker: marker.queue_free()
	animation_player.play(profile.semantic_clips[&"death"], .08)
	get_tree().create_timer(8.0).timeout.connect(queue_free)
