extends SceneTree
func _initialize():
    run.call_deferred()
func run():
    var source = load("res://probe_free/source.glb").instantiate()
    root.add_child(source)
    var sk: Skeleton3D = source.find_children("*","Skeleton3D",true,false)[0]
    var player: AnimationPlayer = source.find_children("*","AnimationPlayer",true,false)[0]
    player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var names := {"hips":"pelvis","spine":"spine_01","chest":"spine_02","upperChest":"spine_03","neck":"neck_01","head":"Head"}
    for side in ["left","right"]:
        var suffix := "_l" if side == "left" else "_r"
        for entry in {"Shoulder":"clavicle","UpperArm":"upperarm","LowerArm":"lowerarm","Hand":"hand","UpperLeg":"thigh","LowerLeg":"calf","Foot":"foot","Toes":"ball"}:
            names[side+entry] = {"Shoulder":"clavicle","UpperArm":"upperarm","LowerArm":"lowerarm","Hand":"hand","UpperLeg":"thigh","LowerLeg":"calf","Foot":"foot","Toes":"ball"}[entry]+suffix
        for finger in ["Index","Middle","Pinky","Ring","Thumb"]:
            for n in range(1,4): names[side+finger+str(n)] = finger.to_lower()+"_0"+str(n)+suffix
    var output := {}
    var hip := sk.find_bone("pelvis")
    var rest_y := sk.get_bone_global_rest(hip).origin.y
    var leg_height := rest_y-sk.get_bone_global_rest(sk.find_bone("foot_l")).origin.y
    for clip in ["Idle","Sitting_Idle"]:
        var duration := player.get_animation(clip).length
        var frames := []
        var height := []
        for frame in range(int(ceil(duration*30))+1):
            player.play(clip)
            player.seek(minf(frame/30.0,duration),true)
            player.advance(0)
            var rotations := {}
            for semantic in names:
                var id := sk.find_bone(names[semantic])
                var delta := sk.get_bone_global_pose(id).basis.orthonormalized()*sk.get_bone_global_rest(id).basis.orthonormalized().inverse()
                var q := delta.get_rotation_quaternion()
                rotations[semantic] = [q.x,q.y,q.z,q.w]
            frames.append(rotations)
            height.append((sk.get_bone_global_pose(hip).origin.y-rest_y)/leg_height)
        output[clip] = {"duration":duration,"fps":30,"frames":frames,"height":height}
        print("BAKE ",clip," frames=",frames.size()," bones=",names.size())
    var file := FileAccess.open(OS.get_environment("BUNNY_BAKE"),FileAccess.WRITE)
    file.store_string(JSON.stringify(output))
    root.get_node("AudioDirector").shutdown_for_test()
    quit()
