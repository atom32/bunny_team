class_name HumanoidEnemyPresentation
extends Node3D
## Artist-authored Quaternius character, skin, pistol and animation clips.
const MODEL_PATH := "res://assets/characters/quaternius_scifi/SciFi.gltf"

var model: Node3D
var animation_player: AnimationPlayer
var pistol: MeshInstance3D
var _aim_point := Vector3.ZERO
var _dead := false
var _shot_remaining := 0.0
var _move_speed := 0.0

func _ready() -> void:
	model = load(MODEL_PATH).instantiate() as Node3D
	model.name = "ImportedPMCPatrol"
	model.rotation.y = PI
	add_child(model)
	animation_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	pistol = model.find_child("Pistol", true, false) as MeshInstance3D
	for clip in ["Idle_Gun_Pointing", "Run_Shoot"]:
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation_player.play("Idle_Gun_Pointing")

func update_visual(aim_point: Vector3, _move_direction: Vector3, speed: float, delta: float) -> void:
	if _dead:
		return
	_aim_point = aim_point
	_move_speed = speed
	_shot_remaining = maxf(0, _shot_remaining - delta)
	var flat := aim_point - global_position
	flat.y = 0
	if flat.length_squared() > .001:
		var desired_yaw := atan2(flat.x, flat.z)
		model.global_rotation.y = lerp_angle(model.global_rotation.y, desired_yaw, 1.0 - exp(-14.0 * delta))
	var clip := "Run_Shoot" if speed > .25 else ("Gun_Shoot" if _shot_remaining > 0 else "Idle_Gun_Pointing")
	if animation_player.current_animation != clip:
		animation_player.play(clip, .12)

func get_muzzle_position() -> Vector3:
	return pistol.to_global(Vector3(-.175, .025, .02))

func get_muzzle_direction() -> Vector3:
	return get_muzzle_position().direction_to(_aim_point)

func fire_recoil() -> void:
	_shot_remaining = .2
	if _move_speed <= .25:
		animation_player.play("Gun_Shoot", .04)

func play_death(_impact: Vector3) -> void:
	_dead = true
	var marker := get_node_or_null("EnemyMarker")
	if marker:
		marker.queue_free()
	animation_player.play("Death", .08)
	get_tree().create_timer(8.0).timeout.connect(queue_free)
