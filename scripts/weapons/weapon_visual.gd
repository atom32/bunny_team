extends Node3D
## WeaponDefinition.scene owns model selection and authored attachment markers.
@export var factory_optic_mesh: NodePath
@export var fitting_visual_root: NodePath
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

func apply_fitting_presentation(fitting: String) -> void:
	# Cosmetic children only. Never move Muzzle/grips or change ItemInstance data.
	if fitting_visual_root.is_empty():return
	if not factory_optic_mesh.is_empty():
		var model:=get_node(factory_optic_mesh) as MeshInstance3D
		var material:=model.get_surface_override_material(0).duplicate() as ShaderMaterial
		material.set_shader_parameter("replace_factory_optic",fitting=="observation_optic")
		model.set_surface_override_material(0,material)
	var root:=get_node(fitting_visual_root)
	for entry in [["Quickloader","quickloader"],["Suppressor","suppressor"],["ObservationOptic","observation_optic"]]:
		(root.get_node(entry[0]) as Node3D).visible=fitting==entry[1]

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
