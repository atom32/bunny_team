extends EnemyController

const STRIKE_HALF_ANGLE := PI / 4.0
var _strike_warning: MeshInstance3D

func _movement_goal(_delta: float) -> Vector3:
	# Brake during the committed punch instead of sliding after the target.
	if _is_telegraphing: return global_position
	return awareness.destination(patrol_radius) if awareness.state != EnemyAwareness.State.COMBAT else awareness.last_known

func _face_direction(direction: Vector3, delta: float) -> void:
	super._face_direction(_shot_aim_point - global_position if _is_telegraphing else direction, delta)

func _strike_direction() -> Vector3:
	var direction := _shot_aim_point - global_position
	direction.y = 0
	return direction.normalized() if direction.length_squared() > .001 else -global_basis.z

func _in_strike_arc(point: Vector3) -> bool:
	var gap := point - global_position
	gap.y = 0
	return gap.length_squared() < .001 or _strike_direction().dot(gap.normalized()) >= cos(STRIKE_HALF_ANGLE)

func _create_presentation() -> Node3D:
	var visual := preload("res://scripts/presentation/infected_presentation.gd").new()
	visual.profile = presentation_profile
	return visual

func receive_damage(packet: DamagePacket) -> float:
	var applied := super.receive_damage(packet)
	if applied > 0 and not is_dead: presentation.play_hit()
	return applied

func _build_visual() -> void:
	super._build_visual()
	presentation.get_node("EnemyMarker").material_override = VisualFactory.material(Color("9fba68"), 0, .1, Color("9fba68"), 1.2)
	_strike_warning = MeshInstance3D.new()
	_strike_warning.name = "MeleeWindup"
	_strike_warning.mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(1.0, .49, .18, .48)
	_strike_warning.material_override = material
	_strike_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_strike_warning)
	_strike_warning.top_level = true
	_strike_warning.hide()

func _update_presentation(delta: float, aim_point: Vector3, locomotion_speed: float) -> void:
	super._update_presentation(delta, aim_point, locomotion_speed)
	_refresh_strike_warning()

func _refresh_strike_warning() -> void:
	# Derived from the existing saved aim/timer, not a second attack or save field.
	# No hidden-actor warning, and each edge is clipped to cover and player sight.
	if not is_instance_valid(_strike_warning): return
	_strike_warning.visible = _is_telegraphing and not is_dead and PlayerVisibility.enemy_observed(self, self)
	if not _strike_warning.visible: return
	_strike_warning.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * .06)
	var mesh := _strike_warning.mesh as ImmediateMesh
	mesh.clear_surfaces()
	var direction := _strike_direction()
	var edges: Array[Vector3] = []
	for index in 13:
		var edge := direction.rotated(Vector3.UP, lerpf(-STRIKE_HALF_ANGLE, STRIKE_HALF_ANGLE, index / 12.0)) * attack_range
		var from := global_position + Vector3.UP
		var ray := PhysicsRayQueryParameters3D.create(from, from + edge, 4)
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty(): edge *= maxf(0, from.distance_to(hit.position) - .05) / attack_range
		edges.append(edge)
	var vertices := PackedVector3Array()
	for index in 12:
		if not PlayerVisibility.point_visible(self, _strike_warning.global_position + edges[index]) or not PlayerVisibility.point_visible(self, _strike_warning.global_position + edges[index + 1]): continue
		vertices.append(Vector3.ZERO)
		vertices.append(edges[index])
		vertices.append(edges[index + 1])
	if vertices.is_empty(): return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices: mesh.surface_add_vertex(vertex)
	mesh.surface_end()

func _update_awareness_indicator() -> void:
	awareness_indicator.text = "!" if _engaged else ("?" if awareness.state in [EnemyAwareness.State.INVESTIGATE, EnemyAwareness.State.SEARCH] else "")
	awareness_indicator.modulate = Color("c7d580")

func _telegraph_shot() -> void:
	if _is_telegraphing or is_dead or not is_instance_valid(target): return
	_is_telegraphing = true
	_shot_cooldown = attack_cooldown_min
	_shot_aim_point = target.global_position + Vector3.UP
	presentation.fire_recoil()
	_finish_telegraphed_shot(0.38)

func _finish_telegraphed_shot(remaining: float) -> void:
	_shot_timer = get_tree().create_timer(remaining, false)
	_refresh_strike_warning()
	await _shot_timer.timeout
	_shot_timer = null
	# The committed sector is avoidable sideways too; sight/range/walls still apply.
	if is_inside_tree() and can_process() and not is_dead and can_see_target() and global_position.distance_to(target.global_position) <= attack_range and _in_strike_arc(target.global_position):
		target.receive_damage(DamagePacket.new(attack_damage, 0, 0, self, &"enemy.infected_melee", &"enemy", target.global_position, Vector3.UP, global_position.direction_to(target.global_position) * 0.3))
	_is_telegraphing = false
	_shot_aim_point = Vector3.ZERO
	_refresh_strike_warning()
