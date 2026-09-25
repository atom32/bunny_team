class_name CombatEffects
extends RefCounted


static func tracer(parent: Node, from: Vector3, to: Vector3, color: Color, width: float = 0.045) -> MeshInstance3D:
	var distance := from.distance_to(to)
	if distance < 0.05:
		return null
	var direction := from.direction_to(to)
	var bolt_length := minf(distance, 1.5)
	var beam := MeshInstance3D.new()
	beam.name = "Tracer"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, width, bolt_length)
	beam.mesh = mesh
	beam.material_override = VisualFactory.material(color, 0.0, 0.15, color, 4.0)
	parent.add_child(beam)
	beam.global_position = from + direction * bolt_length * 0.5
	beam.look_at(to, Vector3.UP)
	var end_position := to - direction * bolt_length * 0.5
	var duration := clampf(distance / 85.0, 0.055, 0.18)
	var tween := beam.create_tween()
	tween.set_parallel(true)
	tween.tween_property(beam, "global_position", end_position, duration)
	tween.tween_property(beam, "scale", Vector3(0.18, 0.18, 1.0), duration)
	tween.chain().tween_callback(beam.queue_free)
	return beam


static func telegraph(parent: Node, from: Vector3, to: Vector3, duration: float = 0.38) -> void:
	var distance := from.distance_to(to)
	if distance < 0.05:
		return
	var beam := MeshInstance3D.new()
	beam.name = "EnemyTelegraph"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.018, 0.018, distance)
	beam.mesh = mesh
	var material := VisualFactory.material(Color("ff294f99"), 0.0, 0.1, Color("ff2448"), 2.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = material
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(beam)
	beam.global_position = (from + to) * 0.5
	beam.look_at(to, Vector3.UP)
	var tween := beam.create_tween()
	tween.tween_property(material, "albedo_color", Color("ff294fff"), duration * 0.72)
	tween.tween_property(material, "albedo_color", Color("ff294f00"), duration * 0.28)
	tween.tween_callback(beam.queue_free)


static func muzzle_flash(
	parent: Node,
	position: Vector3,
	direction: Vector3,
	color: Color,
	intensity: float = 1.0
) -> void:
	var root := Node3D.new()
	root.name = "MuzzleFlash"
	parent.add_child(root)
	root.global_position = position
	root.look_at(position + direction, Vector3.UP)
	var core := VisualFactory.sphere(root, 0.12 * intensity, Vector3.ZERO, color, "Core")
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.material_override = VisualFactory.material(color, 0.0, 0.08, color, 6.0)
	var streak_length := 0.6 * intensity
	var streak := VisualFactory.box(root, Vector3(0.07 * intensity, 0.07 * intensity, streak_length), Vector3(0.0, 0.0, -streak_length * 0.5), color, "Streak")
	streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	streak.material_override = VisualFactory.material(color, 0.0, 0.08, color, 5.0)
	if intensity > 1.2:
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 4.5 * intensity
		light.omni_range = 3.0 * intensity
		root.add_child(light)
	var tween := root.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(root, "scale", Vector3(0.12, 0.12, 0.3), 0.055 + intensity * 0.015)
	tween.tween_callback(root.queue_free)


static func dodge_pulse(parent: Node, position: Vector3, direction: Vector3) -> void:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.46
	ring_mesh.outer_radius = 0.58
	var ring := MeshInstance3D.new()
	ring.name = "DodgePulse"
	ring.mesh = ring_mesh
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := VisualFactory.material(Color("39dce8"), 0.0, 0.15, Color("4af4ff"), 4.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = material
	parent.add_child(ring)
	ring.global_position = position - direction * 0.25
	ring.scale = Vector3(0.65, 0.65, 0.65)
	var faded_color := Color("39dce800")
	var tween := ring.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector3(2.2, 1.0, 2.2), 0.22)
	tween.tween_property(material, "albedo_color", faded_color, 0.22)
	tween.chain().tween_callback(ring.queue_free)


static func rocket_trail(parent: Node, position: Vector3) -> void:
	var trail := VisualFactory.sphere(parent, 0.1, position, Color("ff7a35"), "RocketTrail")
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := VisualFactory.material(Color("ff7a35cc"), 0.0, 0.15, Color("ff461c"), 4.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail.material_override = material
	var tween := trail.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(trail, "scale", Vector3.ONE * 2.8, 0.2)
	tween.tween_property(material, "albedo_color", Color("322d2a00"), 0.2)
	tween.chain().tween_callback(trail.queue_free)


static func hit(parent: Node, position: Vector3, color: Color = Color("68f6ff"), intensity: float = 1.0) -> void:
	var spark := VisualFactory.sphere(parent, 0.13 * intensity, position, color, "HitEffect")
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spark.material_override = VisualFactory.material(color, 0.0, 0.08, color, 6.0)
	var tween := spark.create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector3(3.2, 0.3, 3.2), 0.12 + intensity * 0.035)
	tween.tween_property(spark, "position:y", position.y + 0.3 * intensity, 0.15)
	tween.chain().tween_callback(spark.queue_free)
	for index in range(4):
		var angle := TAU * float(index) / 4.0 + randf_range(-0.25, 0.25)
		var spark_direction := Vector3(cos(angle), randf_range(0.2, 0.65), sin(angle)).normalized()
		var fragment := VisualFactory.box(parent, Vector3(0.035, 0.035, 0.2 * intensity), position, color, "HitSpark")
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fragment.material_override = VisualFactory.material(color, 0.0, 0.08, color, 5.0)
		fragment.look_at(position + spark_direction, Vector3.UP)
		var fragment_tween := fragment.create_tween().set_parallel(true)
		fragment_tween.tween_property(fragment, "position", position + spark_direction * (0.55 + 0.35 * intensity), 0.13)
		fragment_tween.tween_property(fragment, "scale", Vector3(0.1, 0.1, 0.25), 0.13)
		fragment_tween.chain().tween_callback(fragment.queue_free)


static func explosion(parent: Node, position: Vector3, radius: float) -> void:
	var blast := VisualFactory.sphere(parent, 0.45, position, Color("fff0a0"), "Explosion")
	blast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var blast_material := VisualFactory.material(Color("fff0a0"), 0.0, 0.05, Color("ff4b16"), 7.0)
	blast_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blast.material_override = blast_material
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.55
	ring_mesh.outer_radius = 0.72
	var shockwave := MeshInstance3D.new()
	shockwave.name = "ExplosionShockwave"
	shockwave.mesh = ring_mesh
	shockwave.position = position + Vector3.UP * 0.08
	shockwave.scale = Vector3(0.35, 0.35, 0.35)
	shockwave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shock_material := VisualFactory.material(Color("ff793d"), 0.0, 0.08, Color("ff3b16"), 5.0)
	shock_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shockwave.material_override = shock_material
	parent.add_child(shockwave)
	var smoke := VisualFactory.sphere(parent, 0.5, position + Vector3.UP * 0.3, Color("332b2a99"), "ExplosionSmoke")
	var smoke_material := VisualFactory.material(Color("332b2a99"), 0.0, 1.0)
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.material_override = smoke_material
	var light := OmniLight3D.new()
	light.light_color = Color("ff8a3a")
	light.light_energy = 10.0
	light.omni_range = radius * 1.5
	light.position = position
	parent.add_child(light)
	var tween := blast.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(blast, "scale", Vector3.ONE * radius * 1.45, 0.24)
	tween.tween_property(blast_material, "albedo_color", Color("ff6a2400"), 0.24)
	tween.tween_property(shockwave, "scale", Vector3.ONE * radius * 1.65, 0.32)
	tween.tween_property(shock_material, "albedo_color", Color("ff793d00"), 0.32)
	tween.tween_property(smoke, "scale", Vector3.ONE * radius * 0.95, 0.48)
	tween.tween_property(smoke, "position:y", position.y + 1.35, 0.48)
	tween.tween_property(smoke_material, "albedo_color", Color("332b2a00"), 0.48)
	tween.tween_property(light, "light_energy", 0.0, 0.34)
	tween.chain().tween_callback(blast.queue_free)
	tween.chain().tween_callback(shockwave.queue_free)
	tween.chain().tween_callback(smoke.queue_free)
	tween.chain().tween_callback(light.queue_free)
	for index in range(8):
		var angle := TAU * float(index) / 8.0 + randf_range(-0.18, 0.18)
		var fragment_direction := Vector3(cos(angle), randf_range(0.22, 0.65), sin(angle)).normalized()
		var fragment := VisualFactory.box(parent, Vector3(0.07, 0.07, 0.38), position + Vector3.UP * 0.15, Color("ffb347"), "ExplosionSpark")
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fragment.material_override = VisualFactory.material(Color("ffb347"), 0.0, 0.08, Color("ff5a1f"), 5.0)
		fragment.look_at(position + fragment_direction, Vector3.UP)
		var fragment_tween := fragment.create_tween().set_parallel(true)
		fragment_tween.tween_property(fragment, "position", position + fragment_direction * radius * 0.8, 0.24)
		fragment_tween.tween_property(fragment, "scale", Vector3(0.15, 0.15, 0.25), 0.24)
		fragment_tween.chain().tween_callback(fragment.queue_free)
