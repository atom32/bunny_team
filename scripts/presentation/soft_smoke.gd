class_name SoftSmoke
extends RefCounted
## Reusable visual quad only. No physics, damage, timing or global RNG consumption.
const MATERIAL := preload("res://resources/vfx/soft_smoke.tres")
static func create(parent: Node, position: Vector3, radius: float, color: Color, label: String) -> MeshInstance3D:
 var puff := MeshInstance3D.new()
 puff.name = label
 puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var quad := QuadMesh.new()
 quad.size = Vector2.ONE * radius * 2.0
 puff.mesh = quad
 var material := MATERIAL.duplicate() as StandardMaterial3D
 material.albedo_color = color
 puff.material_override = material
 parent.add_child(puff)
 puff.position = position
 return puff
