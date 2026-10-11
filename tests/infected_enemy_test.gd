extends Node3D
var failures: Array[String] = []
var checks := 0
var player: PlayerController
var enemy: EnemyController

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func sync() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func _ready() -> void:
	await get_tree().process_frame
	var definition := ContentDB.get_enemy_definition(&"campus_infected")
	check(definition != null and definition.validate_definition(), "registered infected content")
	var floor_body := StaticBody3D.new(); floor_body.collision_layer = 4
	var floor_shape := CollisionShape3D.new(); var floor_box := BoxShape3D.new(); floor_box.size = Vector3(30,.4,30)
	floor_shape.shape = floor_box; floor_body.position.y = -.2; floor_body.add_child(floor_shape); add_child(floor_body)
	player = PlayerController.new()
	add_child(player)
	player.set_physics_process(false); player.set_process(false)
	enemy = EnemySpawnService.spawn(definition, Transform3D.IDENTITY, self)
	enemy.set_physics_process(false)
	await sync()
	enemy.target = player
	check(not enemy.presentation.pistol.visible and enemy.presentation.animation_player.current_animation == "Idle", "unarmed idle presentation")
	enemy.awareness.state = EnemyAwareness.State.COMBAT
	enemy.awareness.last_known = Vector3(0,0,-8)
	check(enemy._movement_goal(.1) == Vector3(0,0,-8), "chases contact rather than holding ranged distance")
	player.position = Vector3(0,0,-1.3)
	await sync()
	var before := player.health
	enemy._telegraph_shot()
	check(enemy._is_telegraphing and enemy.presentation.animation_player.current_animation == "Punch_Left", "visible melee windup")
	await get_tree().create_timer(.45).timeout
	check(player.health < before, "nearby visible target receives melee damage")
	before = player.health
	enemy._telegraph_shot()
	player.position = Vector3(0,0,-5)
	await sync()
	await get_tree().create_timer(.45).timeout
	check(player.health == before, "escaping windup avoids damage")
	player.position = Vector3(0,0,-1.3)
	await sync()
	enemy._telegraph_shot()
	var wall := StaticBody3D.new(); wall.collision_layer = 4
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(3,3,.1)
	shape.shape = box; wall.add_child(shape); wall.position = Vector3(0,1,-.65); add_child(wall)
	await sync()
	await get_tree().create_timer(.45).timeout
	check(player.health == before, "wall prevents melee damage")
	wall.free()
	enemy.awareness.state = EnemyAwareness.State.PATROL
	enemy.set_physics_process(true)
	enemy.hear_noise(Vector3(6,0,0), &"gunfire")
	enemy.set_physics_process(false)
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE and enemy.awareness.last_known == Vector3(6,0,0), "noise investigates event origin")
	player.position = Vector3(0,0,-7)
	enemy.awareness = EnemyAwareness.new()
	enemy.ensure_awareness()
	var start := enemy.position
	enemy.set_physics_process(true)
	await get_tree().create_timer(2.0).timeout
	enemy.set_physics_process(false)
	check(enemy.awareness.state == EnemyAwareness.State.COMBAT and enemy.position.distance_to(start) > 2, "live infected actually pursues through physics/navigation")
	enemy.take_damage(1000)
	await get_tree().process_frame
	check(not is_instance_valid(enemy), "death removes controller without retaining an attacking actor")
	player.free()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	for failure in failures: push_error(failure)
	print("INFECTED_ENEMY_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
