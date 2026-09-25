extends Area3D

var direction := Vector3.FORWARD
var speed := 17.0
var damage := 75.0
var armor_penetration := 0.0
var structure_damage := 0.0
var blast_radius := 4.2
var knockback := 12.0
var shooter: CollisionObject3D
var source_weapon: StringName
var traveled := 0.0
var max_distance := 30.0
var _trail_cooldown := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 6
	var shape := SphereShape3D.new()
	shape.radius = 0.19
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	var body := VisualFactory.cylinder(self, 0.14, 0.62, Vector3.ZERO, Color("ded9bd"), "Rocket")
	body.rotation_degrees.x = 90.0
	var glow := VisualFactory.sphere(self, 0.17, Vector3(0.0, 0.0, 0.38), Color("ff7a26"), "MotorGlow")
	glow.material_override = VisualFactory.material(Color("ffb13b"), 0.0, 0.1, Color("ff4a14"), 5.0)
	var light := OmniLight3D.new()
	light.name = "RocketLight"
	light.light_color = Color("ff6a2b")
	light.light_energy = 4.0
	light.omni_range = 3.5
	add_child(light)


func setup(owner_body: CollisionObject3D, aim_direction: Vector3, weapon: WeaponDefinition) -> void:
	shooter = owner_body
	direction = aim_direction.normalized()
	speed = weapon.projectile_speed
	damage = weapon.damage
	armor_penetration = weapon.armor_penetration
	structure_damage = weapon.structure_damage
	blast_radius = weapon.blast_radius
	knockback = weapon.knockback
	source_weapon = weapon.id
	max_distance = weapon.weapon_range
	look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	var old_position := global_position
	_trail_cooldown -= delta
	if _trail_cooldown <= 0.0:
		CombatEffects.rocket_trail(get_parent(), old_position)
		_trail_cooldown = 0.045
	var travel := speed * delta
	var new_position := old_position + direction * travel
	var query := PhysicsRayQueryParameters3D.create(old_position, new_position, collision_mask)
	if shooter:
		query.exclude = [shooter.get_rid()]
	var hit_result := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit_result.is_empty():
		global_position = hit_result.position
		_explode()
		return
	global_position = new_position
	traveled += travel
	if traveled >= max_distance:
		_explode()


func _explode() -> void:
	set_physics_process(false)
	AudioDirector.play_sfx(&"explosion", 0.0, 0.025)
	var sphere := SphereShape3D.new()
	sphere.radius = blast_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = 6
	var hits := get_world_3d().direct_space_state.intersect_shape(query, 32)
	var damaged: Dictionary = {}
	for result in hits:
		var target := result.collider as Node
		if not target or damaged.has(target):
			continue
		damaged[target] = true
		if target.has_method("receive_damage"):
			var offset: Vector3 = target.global_position - global_position
			var falloff := clampf(1.0 - offset.length() / (blast_radius * 1.3), 0.35, 1.0)
			var hit_normal := offset.normalized()
			var packet := DamagePacket.new(
				damage * falloff,
				armor_penetration,
				structure_damage * falloff,
				shooter,
				source_weapon,
				&"player",
				target.global_position,
				hit_normal,
				hit_normal * knockback
			)
			target.receive_damage(packet)
	CombatEffects.explosion(get_parent(), global_position, blast_radius)
	queue_free()
