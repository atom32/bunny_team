extends Node3D
## WeaponDefinition.scene owns model selection and authored attachment markers.
@export var hand_pose: StringName = &""
@export var authored_grips := false
@export var pose_offset := Vector3.ZERO
@export var mount_scale := 0.44
@export var reload_offset := Vector3.ZERO
@export var support_thumb_contact := Vector3.ZERO
@export var primary_thumb_contact := Vector3.ZERO
@export var support_finger_contacts := PackedVector3Array()
var muzzle: Marker3D
var muzzle_flash: MeshInstance3D

func _ready() -> void:
	muzzle = $Muzzle
	muzzle_flash = VisualFactory.sphere(muzzle, 0.13, Vector3.ZERO, Color("fff3a8"), "MuzzleFlash")
	muzzle_flash.material_override = VisualFactory.material(Color("fff3a8"), 0.0, 0.1, Color("ffb72d"), 5.0)
	muzzle_flash.visible = false

func get_muzzle_position() -> Vector3:
	return muzzle.global_position if muzzle else global_position

func flash() -> void:
	if not muzzle_flash:
		return
	muzzle_flash.visible = true
	muzzle_flash.scale = Vector3.ONE
	var tween := create_tween()
	tween.tween_property(muzzle_flash, "scale", Vector3(0.15, 0.15, 0.15), 0.055)
	tween.tween_callback(func() -> void: muzzle_flash.visible = false)
