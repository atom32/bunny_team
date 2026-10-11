extends HumanoidEnemyPresentation

func _ready() -> void:
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

func update_visual(aim_point: Vector3, _move_direction: Vector3, speed: float, delta: float) -> void:
	if _dead: return
	_aim_point = aim_point
	_move_speed = speed
	_shot_remaining = maxf(0, _shot_remaining - delta)
	var clip := "Punch_Left" if _shot_remaining > 0 else ("Run" if speed > 1.5 else ("Walk" if speed > .25 else "Idle"))
	if animation_player.current_animation != clip: animation_player.play(clip, .15)

func fire_recoil() -> void:
	_shot_remaining = .65
	animation_player.play("Punch_Left", .08)
