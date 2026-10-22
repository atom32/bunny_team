extends SceneTree
## Bake the three-clip baseline or combat12 set to the existing driver skeleton.
## Generated motion remains outside the public repository until rights review.
const MAP := {
	"Character1_Hips":"pelvis", "Character1_Spine":"spine_01", "Character1_Spine1":"spine_02", "Character1_Spine2":"spine_03",
	"Character1_Neck":"neck_01", "Character1_Head":"head",
	"Character1_LeftShoulder":"clavicle_l", "Character1_LeftArm":"upperarm_l", "Character1_LeftForeArm":"lowerarm_l", "Character1_LeftHand":"hand_l",
	"Character1_RightShoulder":"clavicle_r", "Character1_RightArm":"upperarm_r", "Character1_RightForeArm":"lowerarm_r", "Character1_RightHand":"hand_r",
	"Character1_LeftUpLeg":"thigh_l", "Character1_LeftLeg":"calf_l", "Character1_LeftFoot":"foot_l", "Character1_LeftToeBase":"ball_l",
	"Character1_RightUpLeg":"thigh_r", "Character1_RightLeg":"calf_r", "Character1_RightFoot":"foot_r", "Character1_RightToeBase":"ball_r",
}

func _initialize() -> void: _run.call_deferred()

func _t(v: Array) -> Transform3D:
	return Transform3D(Basis(Quaternion(v[3],v[4],v[5],v[6])),Vector3(v[0],v[1],v[2]))

func _frame(right: Vector3,up: Vector3) -> Basis:
	var y:=up.normalized();var x:=(right-y*right.dot(y)).normalized()
	return Basis(x,y,x.cross(y)).orthonormalized()

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=4 or args[0]!="--samples" or args[2]!="--output" or FileAccess.file_exists(args[3]):
		push_error("Expected --samples <JSON> --output <new .tres>");quit(2);return
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	assert(data.format==1 and data.fps==30 and data.clips.size() in [3,12])
	var stage:=Node3D.new();root.add_child(stage)
	var model: Node3D=load("res://assets/characters/unitychan_battle/animations/idle.fbx").instantiate();stage.add_child(model)
	var sk: Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
	var rest:=[]
	for i in sk.get_bone_count():rest.append(sk.global_transform*sk.get_bone_global_rest(i))
	var ref: Dictionary=data.reference
	var src_frame:=_frame(_t(ref.upperarm_r).origin-_t(ref.upperarm_l).origin,_t(ref.head).origin-_t(ref.pelvis).origin)
	var dst_frame:=_frame(rest[sk.find_bone("Character1_RightArm")].origin-rest[sk.find_bone("Character1_LeftArm")].origin,rest[sk.find_bone("Character1_Head")].origin-rest[sk.find_bone("Character1_Hips")].origin)
	var correction:=dst_frame*src_frame.inverse()
	var src_leg:=_t(ref.pelvis).origin.y-_t(ref.foot_l).origin.y
	var dst_leg: float=rest[sk.find_bone("Character1_Hips")].origin.y-rest[sk.find_bone("Character1_LeftFoot")].origin.y
	var arm_scale: float=rest[sk.find_bone("Character1_LeftArm")].origin.distance_to(rest[sk.find_bone("Character1_LeftHand")].origin)/_t(ref.upperarm_l).origin.distance_to(_t(ref.hand_l).origin)
	var mapping:=MAP.duplicate()
	for side in ["Left","Right"]:
		for finger in ["Thumb","Index","Middle","Ring","Pinky"]:
			for joint in range(1,4):
				mapping["Character1_"+side+"Hand"+finger+str(joint)]=(finger.to_lower()+"_0"+str(joint)+("_l" if side=="Left" else "_r"))
	var library:=AnimationLibrary.new()
	var report:={"mapped_bones":mapping.size(),"mapped_body_bones":MAP.size(),"mapped_finger_bones":30,"target_bones":sk.get_bone_count(),"source_sample_sha256":FileAccess.get_sha256(args[1]),"leg_scale":dst_leg/src_leg,"arm_scale":arm_scale,"clips":{},"scope":"Local trial only, no distribution permission asserted"}
	for alias: String in data.clips:
		var input: Dictionary=data.clips[alias]
		var clip:=Animation.new();clip.length=input.length
		clip.loop_mode=Animation.LOOP_LINEAR if alias in ["Idle","Walk","WalkBack","WalkRelaxed","Run","AimIdle"] else Animation.LOOP_NONE
		clip.set_meta("source_clip",input.source_clip);clip.set_meta("source_sha256",input.source_sha256)
		clip.set_meta("source_license","UNVERIFIED LOCAL REVIEW ONLY")
		var first: Dictionary=input.frames[0].bones
		var final: Dictionary=input.frames[-1].bones
		if first.has("root") and final.has("root"):
			var root_delta:=_t(final.root).origin-_t(first.root).origin;root_delta.y=0
			clip.set_meta("driver_nominal_speed",root_delta.length()*dst_leg/src_leg/clip.length)
		var tracks:={};var last:={}
		for name: String in mapping:
			assert(sk.find_bone(name)>=0 and ref.has(mapping[name]))
			var track:=clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(track,NodePath(".:"+name));tracks[name]=track
		var hip_track:=clip.add_track(Animation.TYPE_POSITION_3D);clip.track_set_path(hip_track,NodePath(".:Character1_Hips"))
		var left_path:=PackedVector3Array();var first_left:=Vector3.ZERO
		var right_path:=PackedVector3Array();var right_rotations: Array[Quaternion]=[]
		var anchor: Dictionary=input.frames[-1 if alias=="TakeGun" else 0].bones
		clip.set_meta("driver_vertical_anchor",(_t(anchor.pelvis).origin.y-_t(ref.pelvis).origin.y)*dst_leg/src_leg)
		var anchor_position:=_t(anchor.hand_r).origin-_t(anchor.pelvis).origin
		var anchor_basis:=_t(anchor.hand_r).basis
		for frame: Dictionary in input.frames:
			var global_rotations:=[]
			for i in sk.get_bone_count():
				var name:=String(sk.get_bone_name(i))
				if mapping.has(name):
					var source: String=mapping[name]
					var delta:=_t(frame.bones[source]).basis*_t(ref[source]).basis.inverse()
					global_rotations.append(correction*delta*correction.inverse()*rest[i].basis)
				else:
					var parent:=sk.get_bone_parent(i)
					global_rotations.append(sk.global_basis*sk.get_bone_rest(i).basis if parent<0 else global_rotations[parent]*sk.get_bone_rest(i).basis)
			for name: String in mapping:
				var i:=sk.find_bone(name);var parent:=sk.get_bone_parent(i)
				var local: Basis=sk.global_basis.inverse()*global_rotations[i] if parent<0 else global_rotations[parent].inverse()*global_rotations[i]
				var q:=local.orthonormalized().get_rotation_quaternion()
				if last.has(name) and q.dot(last[name])<0:q=-q
				last[name]=q;clip.rotation_track_insert_key(tracks[name],frame.time,q)
			var hip:=sk.find_bone("Character1_Hips");var parent:=sk.get_bone_parent(hip)
			var dy:=(_t(frame.bones.pelvis).origin.y-_t(ref.pelvis).origin.y)*dst_leg/src_leg
			var parent_basis: Basis=rest[parent].basis if parent>=0 else sk.global_basis
			clip.position_track_insert_key(hip_track,frame.time,sk.get_bone_rest(hip).origin+parent_basis.inverse()*Vector3.UP*dy)
			var relative:=src_frame.inverse()*(_t(frame.bones.hand_l).origin-_t(frame.bones.hand_r).origin)*arm_scale
			if left_path.is_empty():first_left=relative
			left_path.append(relative-first_left)
			var right:=src_frame.inverse()*((_t(frame.bones.hand_r).origin-_t(frame.bones.pelvis).origin)-anchor_position)*arm_scale
			right_path.append(right)
			var turn:=src_frame.inverse()*_t(frame.bones.hand_r).basis*anchor_basis.inverse()*src_frame
			right_rotations.append(turn.orthonormalized().get_rotation_quaternion())
		clip.set_meta("left_reload_delta",left_path)
		clip.set_meta("right_weapon_delta",right_path)
		clip.set_meta("right_weapon_rotation",right_rotations)
		library.add_animation(alias,clip)
		report.clips[alias]={"source":input.source_clip,"length":clip.length,"tracks":clip.get_track_count(),"samples":input.frames.size()}
	assert(ResourceSaver.save(library,args[3])==OK)
	report["library_sha256"]=FileAccess.get_sha256(args[3])
	var f:=FileAccess.open(args[3]+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	stage.free();root.get_node("AudioDirector").shutdown_for_test()
	print("RIFLE_TRIAL_BAKE: PASS / ",mapping.size()," mapped body/finger bones / ",data.clips.size()," clips")
	quit()
