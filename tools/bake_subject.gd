extends Node
const CLIPS := {"Idle":"Idle_Loop","Walk":"Walk_Loop","Run":"Jog_Fwd_Loop","Punch_Left":"Punch_Jab","Hit_Chest":"Hit_Chest","Death":"Death01","Interact":"Interact"}
func _ready() -> void: _run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var options := {}
	for index in range(0, args.size(), 2):
		assert(index + 1 < args.size(), "Every option needs a value")
		options[args[index]] = args[index + 1]
	for option in ["--source", "--target", "--output", "--demographic", "--profile-id", "--report"]:
		assert(options.has(option), "Missing option: " + option)
	var output: String = options["--output"]
	assert(output.begins_with("res://"), "Output must be a project resource directory")
	for filename in ["campus_subject_animations.tres","campus_subject_bone_map.tres","campus_subject_profile.tres"]:
		assert(not FileAccess.file_exists(output + "/" + filename), "Never overwrite reviewed resources")
	assert(FileAccess.get_sha256(options["--source"]) == "69591853d817488edaa8fd9bf8fc1d821eaeaf789f8627b3cd23b41c4ed67997", "Unexpected UAL1 source revision")
	var document:=GLTFDocument.new(); var state:=GLTFState.new()
	assert(document.append_from_file(options["--source"],state)==OK)
	var source:=document.generate_scene(state);add_child(source)
	var src:Skeleton3D=source.find_children("*","Skeleton3D",true,false)[0]
	var player:AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var model:Node3D=load(options["--target"]).instantiate();add_child(model)
	var target:Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
	var target_path:=String(model.get_path_to(target))
	var src_hip:=src.find_bone("pelvis");var dst_hip:=target.find_bone("pelvis")
	var src_height:=src.get_bone_global_rest(src_hip).origin.y-src.get_bone_global_rest(src.find_bone("foot_l")).origin.y
	var dst_height:=target.get_bone_global_rest(dst_hip).origin.y-target.get_bone_global_rest(target.find_bone("foot_l")).origin.y
	var library:=AnimationLibrary.new();var report:={"clips":{},"bones":target.get_bone_count(),"skeleton_path":target_path,"source_leg_height":src_height,"target_leg_height":dst_height}
	for alias:String in CLIPS:
		var clip:Animation=player.get_animation(CLIPS[alias]);assert(clip)
		var animation:=Animation.new();animation.length=clip.length
		animation.loop_mode=Animation.LOOP_LINEAR if alias in ["Idle","Walk","Run"] else Animation.LOOP_NONE
		animation.set_meta("source_clip",CLIPS[alias]);animation.set_meta("source_license","CC0-1.0")
		animation.set_meta("root_policy","In-place horizontal root; source vertical pelvis scaled by rest leg height")
		var position_track:=animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(position_track,NodePath(target_path+":pelvis"))
		var tracks:=[];var last:=[]
		for i in target.get_bone_count():
			assert(src.find_bone(target.get_bone_name(i))>=0)
			var track:=animation.add_track(Animation.TYPE_ROTATION_3D);animation.track_set_path(track,NodePath(target_path+":"+String(target.get_bone_name(i))))
			tracks.append(track);last.append(Quaternion.IDENTITY)
		var samples:=int(ceil(clip.length*30))+1
		for frame in samples:
			var at:=minf(frame/30.0,clip.length)
			player.play(CLIPS[alias]);player.seek(at,true);player.advance(0)
			var global_rotations:=[]
			for i in target.get_bone_count():
				var src_index:=src.find_bone(target.get_bone_name(i))
				var delta:=src.get_bone_global_pose(src_index).basis.orthonormalized()*src.get_bone_global_rest(src_index).basis.orthonormalized().inverse()
				global_rotations.append(delta*target.get_bone_global_rest(i).basis.orthonormalized())
			for i in target.get_bone_count():
				var parent:=target.get_bone_parent(i)
				var local:Basis=global_rotations[i] if parent<0 else global_rotations[parent].inverse()*global_rotations[i]
				var q:=local.orthonormalized().get_rotation_quaternion()
				if frame>0 and q.dot(last[i])<0:q=-q
				last[i]=q;animation.rotation_track_insert_key(tracks[i],at,q)
			var displacement:=Vector3(0,(src.get_bone_global_pose(src_hip).origin.y-src.get_bone_global_rest(src_hip).origin.y)*dst_height/src_height,0)
			var parent:=target.get_bone_parent(dst_hip)
			var local_delta:Vector3=displacement if parent<0 else target.get_bone_global_rest(parent).basis.inverse()*displacement
			animation.position_track_insert_key(position_track,at,target.get_bone_rest(dst_hip).origin+local_delta)
		library.add_animation(alias,animation);report.clips[alias]={"source":CLIPS[alias],"duration":clip.length,"samples":samples}
	var dir := output;DirAccess.make_dir_recursive_absolute(dir)
	assert(ResourceSaver.save(library,dir+"/campus_subject_animations.tres")==OK)
	var map:=BoneMap.new();map.profile=SkeletonProfileHumanoid.new()
	var names:={"Root":"root","Hips":"pelvis","Spine":"spine_01","Chest":"spine_02","UpperChest":"spine_03","Neck":"neck_01","Head":"Head"}
	for side in ["Left","Right"]:
		var suffix:="_l" if side=="Left" else "_r"
		for part in {"Shoulder":"clavicle","UpperArm":"upperarm","LowerArm":"lowerarm","Hand":"hand","UpperLeg":"thigh","LowerLeg":"calf","Foot":"foot","Toes":"ball"}:
			names[side+part]={"Shoulder":"clavicle","UpperArm":"upperarm","LowerArm":"lowerarm","Hand":"hand","UpperLeg":"thigh","LowerLeg":"calf","Foot":"foot","Toes":"ball"}[part]+suffix
		for finger in ["Index","Middle","Ring","Little","Thumb"]:
			var source_name:String="pinky" if finger=="Little" else finger.to_lower()
			var joints:=["Metacarpal","Proximal","Distal"] if finger=="Thumb" else ["Proximal","Intermediate","Distal"]
			for i in 3:names[side+finger+joints[i]]=source_name+"_0"+str(i+1)+suffix
	for semantic:String in names:map.set_skeleton_bone_name(semantic,names[semantic])
	assert(ResourceSaver.save(map,dir+"/campus_subject_bone_map.tres")==OK)
	var profile:=PresentationProfile.new();profile.id=StringName(options["--profile-id"])
	profile.model_path=options["--target"]
	profile.animation_library=library;profile.animation_library.take_over_path(output+"/campus_subject_animations.tres")
	profile.skeleton_path=NodePath(target_path);profile.bone_map=map;profile.bone_map.take_over_path(output+"/campus_subject_bone_map.tres")
	profile.semantic_clips={&"idle":&"Idle",&"walk":&"Walk",&"run":&"Run",&"attack":&"Punch_Left",&"hit":&"Hit_Chest",&"death":&"Death",&"interact":&"Interact"}
	profile.source_url="https://quaternius.itch.io/universal-base-characters + https://quaternius.itch.io/universal-animation-library"
	profile.target_demographic=options["--demographic"]
	profile.motion_origin="UAL1 universal/unisex authored clips; global-rest rotation retarget, target leg-height pelvis scaling"
	profile.motion_style="natural neutral / in-place adult reference"
	profile.license_ref=String(options["--target"]).get_base_dir()+"/LICENSE.txt; res://assets/animations/quaternius_hideout/LICENSE.txt"
	assert(ResourceSaver.save(profile,dir+"/campus_subject_profile.tres")==OK)
	var file:=FileAccess.open(options["--report"],FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("SUBJECT_ANIMATION_BAKE: PASS ",target.get_bone_count()," bones / ",CLIPS.size()," clips")
	source.queue_free();model.queue_free();await get_tree().process_frame
	AudioDirector.shutdown_for_test();get_tree().quit()
