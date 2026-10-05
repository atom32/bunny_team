extends SceneTree
var hub
var actor
var adapter
var source: Node3D
var sk: Skeleton3D
var target: Skeleton3D
var anim: AnimationPlayer
var mapping := {}
var rest := {}
var ticks := 0
var active := false
var clips := ["Sitting_Idle", "Sitting_Talking"]
var chosen := []
var contacts := []
func _initialize():
    process_frame.connect(tick)
    run.call_deferred()
func run():
    root.get_node("ProfileRuntime").new_profile()
    hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
    root.add_child(hub)
    await process_frame
    await process_frame
    actor = hub.hanger.preview_character
    adapter = hub.relaxed_preview
    adapter.set_process(false)
    hub.set_process(false)
    hub.hide()
    hub.ui.hide()
    for c in hub.find_children("*", "CanvasLayer", true, false): c.hide()
    actor.reparent(root)
    actor.position = Vector3(0.8,0,0)
    actor.body_visual.rotation.y = PI
    target = actor.character_skeleton
    source = load("res://probe_free/source.glb").instantiate()
    root.add_child(source)
    source.position.x = -0.8
    sk = source.find_children("*", "Skeleton3D", true, false)[0]
    anim = source.find_children("*", "AnimationPlayer", true, false)[0]
    anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    print("SOURCE_BONES ",sk.get_bone_count()," CLIPS ",anim.get_animation_list())
    var names := {"hips":"pelvis","spine":"spine_01","chest":"spine_02","upperChest":"spine_03","neck":"neck_01","head":"Head"}
    for side in ["left","right"]:
        var suffix := "_l" if side == "left" else "_r"
        for entry in {"Shoulder":"clavicle","UpperArm":"upperarm","LowerArm":"lowerarm","Hand":"hand","UpperLeg":"thigh","LowerLeg":"calf","Foot":"foot","Toes":"ball"}:
            names[side+entry] = {"Shoulder":"clavicle","UpperArm":"upperarm","LowerArm":"lowerarm","Hand":"hand","UpperLeg":"thigh","LowerLeg":"calf","Foot":"foot","Toes":"ball"}[entry]+suffix
    for index in adapter.semantics:
        var semantic = adapter.semantics[index]
        var source_id := sk.find_bone(names[semantic])
        assert(source_id >= 0)
        mapping[index] = source_id
        rest[source_id] = sk.get_bone_global_rest(source_id).basis.orthonormalized()
    for clip in clips:
        for name in anim.get_animation_list():
            if str(name) == clip: chosen.append(name)
    assert(chosen.size() == 2)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(0.11,0.14,0.18)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color.WHITE
    env.environment.ambient_light_energy = 0.7
    root.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35,-30,0)
    light.light_energy = 0.8
    root.add_child(light)
    var camera := Camera3D.new()
    root.add_child(camera)
    camera.position = Vector3(0,1.4,5.2)
    camera.look_at(Vector3(0,1,0))
    camera.fov = 36
    camera.make_current()
    var overlay := CanvasLayer.new()
    root.add_child(overlay)
    var label := Label.new()
    overlay.add_child(label)
    label.position = Vector2(35,30)
    label.name = "Caption"
    label.add_theme_font_size_override("font_size",24)
    label.text = "FREE PIPELINE PROBE | Source (left) / Current character (right)"
    for x in [-0.8, 0.8]:
        var seat := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.55,0.06,0.55)
        seat.mesh = box
        seat.position = Vector3(x,0.47,0)
        root.add_child(seat)
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(4,3)
    floor.mesh = plane
    root.add_child(floor)
    print("TARGET_BONES ", target.get_bone_count())
    for i in target.get_bone_count(): print("TARGET_BONE ",i," ",target.get_bone_name(i))
    active = true
func tick():
    if paused and root.get_node("FlowMenu").mode == "pause": root.get_node("FlowMenu").close()
    if not active: return
    ticks += 1
    var clip = chosen[mini((ticks-1)/240,1)]
    anim.play(clip)
    anim.seek(fmod(float((ticks-1)%240)/60.0,anim.get_animation(clip).length),true)
    anim.advance(0)
    var globals: Array[Basis] = []
    var forward := Basis(Vector3.UP,PI)
    for index in target.get_bone_count():
        var parent := target.get_bone_parent(index)
        var desired: Basis = adapter.references[index]
        if mapping.has(index):
            var id: int = mapping[index]
            var delta: Basis = sk.get_bone_global_pose(id).basis.orthonormalized() * rest[id].inverse()
            desired = forward * delta * forward.inverse() * adapter.references[index]
        elif parent >= 0:
            desired = globals[parent] * adapter.references[parent].inverse() * adapter.references[index]
        globals.append(desired)
        var local: Basis = desired if parent < 0 else globals[parent].inverse() * desired
        assert(local.is_finite())
        target.set_bone_pose_rotation(index,local.get_rotation_quaternion())
        assert(target.get_bone_pose_scale(index).is_equal_approx(Vector3.ONE))
    if ticks in [120,360]:
        var report := {"clip":str(clip),"frame":ticks,"source_pelvis":source.to_global(sk.get_bone_global_pose(sk.find_bone("pelvis")).origin),"target_pelvis":target.to_global(target.get_bone_global_pose(target.find_bone("Character1_Hips")).origin)}
        for side in ["Left","Right"]:
            for part in ["Foot","ToeBase"]:
                report[side+part] = target.to_global(target.get_bone_global_pose(target.find_bone("Character1_"+side+part)).origin)
        contacts.append(report)
        print("CONTACT_BASELINE ", report)
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("probe_%s.png" % ticks))
    if ticks >= 480:
        print("FREE_ANIMATION_PROBE: clips=2 frames=480 mapped_bones=",mapping.size()," finite_rotations=PASS no_bone_scale=PASS")
        root.get_node("AudioDirector").shutdown_for_test()
        var output := FileAccess.open(OS.get_environment("BUNNY_EVIDENCE").path_join("contacts.json"),FileAccess.WRITE)
        output.store_string(JSON.stringify(contacts,"  "))
        quit()


