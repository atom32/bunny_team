extends SceneTree
## Run in the user's isolated, imported source project, never the public repo.
## Samples bone transforms only; no source meshes, textures, scripts or events.
const BASE := "res://Assets/CombatGirlsCharacterPack/RifleGirl/"
const CLIPS := {"Idle":"Normal/R_Idle", "Walk":"Aiming/R_AimWalk_F", "Reload":"Aiming/R_Reload"}
const COMBAT12 := {
	"Idle":"Normal/R_Idle", "WalkRelaxed":"Normal/R_Walk", "Run":"Normal/R_Run",
	"AimIdle":"Aiming/R_AimIdle", "Walk":"Aiming/R_AimWalk_F", "WalkBack":"Aiming/R_AimWalk_B",
	"Shoot":"Aiming/R_Shoot", "Reload":"Aiming/R_Reload", "Hit":"Normal/R_Hit_Upper",
	"Dodge":"Normal/R_Evade", "TakeGun":"Normal/R_TakeGun", "PutGun":"Normal/R_PutGun",
}

func _initialize() -> void: _run.call_deferred()

func _transform(t: Transform3D) -> Array:
	var q := t.basis.orthonormalized().get_rotation_quaternion()
	return [t.origin.x,t.origin.y,t.origin.z,q.x,q.y,q.z,q.w]

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var clips:=CLIPS
	if args.size()==4 and args[0]=="--set" and args[1]=="combat12":
		clips=COMBAT12;args=args.slice(2)
	if args.size()!=2 or args[0]!="--output" or FileAccess.file_exists(args[1]):
		push_error("Expected --output <new absolute JSON path>");quit(2);return
	var stage := Node3D.new();root.add_child(stage)
	var reference: Node3D=load(BASE+"Models/Rifle_Full_Body.FBX").instantiate()
	stage.add_child(reference)
	var ref: Skeleton3D=reference.find_children("*","Skeleton3D",true,false)[0]
	var data := {"format":1,"fps":30,"scope":"LOCAL REVIEW ONLY; source permission not inferred", "reference":{},"clips":{}}
	# A single model rest is essential. Each animation FBX has its own posed
	# rest; subtracting that would erase the authored stance at frame zero.
	for i in ref.get_bone_count():
		data.reference[String(ref.get_bone_name(i))]=_transform(ref.global_transform*ref.get_bone_global_rest(i))
	for alias: String in clips:
		var path: String=BASE+"Animations/"+clips[alias]+".fbx"
		var source: Node3D=load(path).instantiate();stage.add_child(source)
		var sk: Skeleton3D=source.find_children("*","Skeleton3D",true,false)[0]
		var player: AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0]
		player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var name: StringName=player.get_animation_list()[0]
		var clip := player.get_animation(name).duplicate(true) as Animation
		for track in range(clip.get_track_count()-1,-1,-1):
			if clip.track_get_type(track) not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]:clip.remove_track(track)
		player.remove_animation_library(&"")
		var safe:=AnimationLibrary.new();safe.add_animation(name,clip);player.add_animation_library(&"",safe)
		var frames:=[]
		for frame in int(ceil(clip.length*30.0))+1:
			var at:=minf(frame/30.0,clip.length)
			player.play(name);player.seek(at,true);player.advance(0)
			var poses:={}
			for i in sk.get_bone_count():
				poses[String(sk.get_bone_name(i))]=_transform(sk.global_transform*sk.get_bone_global_pose(i))
			frames.append({"time":at,"bones":poses})
		data.clips[alias]={"source":path,"source_sha256":FileAccess.get_sha256(path),"source_clip":String(name),"length":clip.length,"frames":frames}
		print("SAMPLED ",alias," ",name," ",frames.size()," frames")
		source.free()
	var f:=FileAccess.open(args[1],FileAccess.WRITE)
	if not f:push_error("Cannot create sample output");quit(2);return
	f.store_string(JSON.stringify(data));f.close()
	stage.free()
	print("RIFLE_MOTION_SAMPLE: PASS; no event tracks executed")
	quit()
