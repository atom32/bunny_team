extends Node3D
## Real motor/input check. No sortie progress or inventory is manufactured.
var failures: Array[String]=[]
var measures:=[]
var actor: PlayerController

func check(ok: bool,message: String) -> void:
	if not ok:failures.append(message);push_error(message)

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	var floor:=StaticBody3D.new();floor.collision_layer=2
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(100,.2,100)
	collision.shape=box;collision.position.y=-.1;floor.add_child(collision);add_child(floor)
	actor=load("res://scenes/player/player.tscn").instantiate();add_child(actor)
	for i in 5:await get_tree().physics_frame
	for strength in [.35,.65,1.0]:
		Input.action_press("move_right",strength)
		var amount:=Input.get_vector("move_left","move_right","move_forward","move_back").length()
		check(amount>0,"configured deadzone admits the measured partial input")
		for i in 60:await get_tree().physics_frame
		var expected:=actor.get_movement_speed()*amount
		measures.append({"raw_strength":strength,"effective_strength":amount,"expected_speed":expected,"actual_speed":Vector2(actor.velocity.x,actor.velocity.z).length()})
		check(absf(Vector2(actor.velocity.x,actor.velocity.z).length()-expected)<.03,"motor preserves input magnitude: "+str(measures[-1]))
		Input.action_release("move_right")
		for i in 30:await get_tree().physics_frame
		check(Vector2(actor.velocity.x,actor.velocity.z).length()<.001,"released stick stops normally")
	Input.action_press("move_right");Input.action_press("move_forward")
	for i in 60:await get_tree().physics_frame
	check(absf(Vector2(actor.velocity.x,actor.velocity.z).length()-actor.get_movement_speed())<.03,"full diagonal input remains capped at original speed")
	Input.action_release("move_right");Input.action_release("move_forward")
	var out:=OS.get_environment("BUNNY_EVIDENCE")
	if not out.is_empty():
		var f:=FileAccess.open(out.path_join("analog_movement.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"measures":measures,"failures":failures},"\t"));f.close()
	actor.queue_free();await get_tree().process_frame;AudioDirector.shutdown_for_test()
	print("ANALOG_MOVEMENT_TEST: %s measures=%s"%["PASS" if failures.is_empty() else "FAIL",measures])
	get_tree().quit(0 if failures.is_empty() else 1)
