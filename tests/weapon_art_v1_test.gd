extends Node3D
const PATH := "user://weapon_art_v1_test.json"
const AR := &"weapon.assault_rifle_01"
const FITS := {"quickloader":&"material.quickloader_kit","suppressor":&"material.suppressor_kit","observation_optic":&"material.observation_optic_kit"}
const NODES := {"quickloader":"Quickloader","suppressor":"Suppressor","observation_optic":"ObservationOptic"}
const MARKERS := {"Muzzle":Vector3(0,.09,-.625),"PrimaryGrip":Vector3(.024,0,.065),"SupportGrip":Vector3(-.024,.055,-.24),"ReloadGrip":Vector3(0,-.075,-.10)}
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func stats() -> Array:
	var d:=ContentDB.get_weapon(AR)
	return [d.id,d.weight,d.damage,d.magazine_capacity,d.reload_seconds,d.fire_rate,d.weapon_range,d.armor_penetration,d.structure_damage,d.knockback,d.compatible_ammo_ids]
func verify_visual(weapon: Node3D,fitting: String) -> void:
	check(weapon.has_node("Art/Model/M4"),"Original production model/node path retained")
	for name: String in MARKERS:
		check(weapon.get_node(name).position.is_equal_approx(MARKERS[name]) and weapon.get_node(name).rotation.is_zero_approx(),"Unmoved logical marker: "+name)
	check(weapon.mount_scale==.9 and weapon.pose_offset==Vector3(0,.015,-.10),"Rig mount/pose unchanged")
	for id: String in NODES:
		check(weapon.get_node("FittingVisuals/"+NODES[id]).visible==(id==fitting),"Exactly the owned single utility fitting is rendered: "+id)
	var material:=weapon.get_node("Art/Model/M4").get_surface_override_material(0) as ShaderMaterial
	check(material!=null and material.get_shader_parameter("replace_factory_optic")== (fitting=="observation_optic"),"Factory sight is visually replaced only for installed observation optic")
	check(weapon.find_children("*","CollisionObject3D",true,false).is_empty(),"No cosmetic collision or hitbox added")
func _ready() -> void: run.call_deferred()
func run() -> void:
	if "--read" in OS.get_cmdline_user_args():
		var loaded:=SaveService.load_profile(PATH,false)
		check(loaded!=null,"Fresh process reads the real saved profile")
		if loaded:
			var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://weapon_art_v1_expected.json"))
			for id: String in expected:
				check(loaded.inventory.get_item(id).fitting==expected[id],"Fresh process preserves exact existing fitting string and weapon instance")
				var weapon:=load("res://scenes/weapons/assault_rifle.tscn").instantiate() as Node3D;add_child(weapon)
				weapon.apply_fitting_presentation(expected[id]);verify_visual(weapon,expected[id]);weapon.queue_free()
		await finish();return
	var before_stats:=stats()
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapons/mocap_m4/checksums.json")):
		check(FileAccess.get_sha256("res://assets/weapons/mocap_m4/"+row.file)==row.sha256,"Original supplied M4/texture bytes untouched: "+row.file)
	var reference: Node3D=load("res://assets/weapons/mocap_m4/M4_Rifle_01.fbx").instantiate()
	var art: Node3D=load("res://scenes/weapons/assault_rifle.tscn").instantiate();add_child(art)
	check(reference.get_node("M4").mesh==art.get_node("Art/Model/M4").mesh,"Base rifle still uses original mesh/UV/topology, not a primitive replacement")
	verify_visual(art,"")
	art.apply_fitting_presentation("observation_optic")
	var other: Node3D=load("res://scenes/weapons/assault_rifle.tscn").instantiate();add_child(other);verify_visual(other,"")
	check(not other.get_node("Art/Model/M4").get_surface_override_material(0).get_shader_parameter("replace_factory_optic"),"Optic shader state cannot leak to another owned rifle")
	art.queue_free();other.queue_free();reference.free();await get_tree().process_frame
	for path in ["ammo_556_box","ammo_556_round"]:
		var model: Node3D=load("res://scenes/weapons/art_pack_v1/"+path+".tscn").instantiate();add_child(model)
		check(model.get_meta("presentation_definition_id")=="ammo.556_standard" and model.find_children("*","CollisionObject3D",true,false).is_empty(),"Ammo is a display of existing ID only, no new entity/collision")
		model.queue_free()
	SortieRuntime.clear_session();var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	var expected: Dictionary={}
	for fitting: String in FITS:
		var gun:=ItemInstance.new(AR);check(profile.inventory.add_item(gun),"Own a separate finite fixture rifle")
		var kit:=ItemInstance.new(FITS[fitting]);profile.inventory.add_item(kit)
		check(WeaponFitting.install_kit(gun.instance_id,kit.instance_id,PATH).error==OK and not profile.inventory.contains(kit.instance_id),"Existing installation consumes the actual kit: "+fitting)
		profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY,gun.instance_id,profile.inventory)
		var hanger: Node3D=load("res://scenes/hanger/hanger.tscn").instantiate();add_child(hanger)
		verify_visual(hanger.preview_character.equipped_weapon_visual,fitting)
		hanger.queue_free();await get_tree().process_frame
		check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH).error==OK,"Deploy through existing ownership/packing service")
		var battle: Node3D=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		battle.player.set_physics_process(false)
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		verify_visual(battle.player.equipped_weapon_visual,fitting)
		var count: int=battle.player.get_magazine_ammo()
		check(battle.player._try_fire() and battle.player.get_magazine_ammo()==count-1,"Real firing still spends exactly one round")
		var reserve: int=battle.player.get_reserve_ammo()
		check(battle.player.reload_weapon() and battle.player.get_reserve_ammo()==reserve-1,"Real reload consumes the exact missing round")
		check(is_equal_approx(battle.player.get_reload_remaining(),1.6*WeaponFitting.OPTIONS[fitting].reload),"Existing fitting reload timing unchanged")
		check(battle.player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY) and battle.player.switch_weapon(LoadoutState.SLOT_WEAPON_PRIMARY),"Real switch away/back remains available")
		verify_visual(battle.player.equipped_weapon_visual,fitting)
		check(SortieRuntime.save_checkpoint()==OK,"Suspend actual world with fitted weapon and reload in progress")
		battle.queue_free();SortieRuntime.clear_session();await get_tree().process_frame
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"Load and resume existing checkpoint contract")
		profile=ProfileRuntime.get_profile()
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		verify_visual(battle.player.equipped_weapon_visual,fitting)
		check(battle.session.complete_extraction() and SortieRuntime.finalize_sortie(PATH)==OK,"Existing extraction returns exact fitted gun")
		battle.queue_free();await get_tree().process_frame
		expected[gun.instance_id]=fitting
	check(stats()==before_stats,"All shared weapon stats and ammunition compatibility unchanged")
	var raw:=ProfileState.create_new().to_dict();raw.erase("campus_chapter")
	for item in raw.inventory.items:item.erase("fitting")
	var file:=FileAccess.open("user://weapon_art_legacy.json",FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":7,"profile":raw}));file.close()
	var legacy:=SaveService.load_profile("user://weapon_art_legacy.json",false)
	check(legacy!=null and legacy.validate(),"Old schema/no-fitting profile migrates normally without new possessions")
	var gun_id: String=expected.keys()[0]
	var before:=profile.to_dict()
	check(WeaponFitting.install(gun_id,"", "user://missing_art_dir/profile.json").error!=OK and profile.to_dict()==before,"Failed removal save never publishes cosmetic/equipment state")
	check(WeaponFitting.install(gun_id,"",PATH).error==OK,"Existing free removal still works")
	var hanger: Node3D=load("res://scenes/hanger/hanger.tscn").instantiate();profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY,gun_id,profile.inventory);add_child(hanger);verify_visual(hanger.preview_character.equipped_weapon_visual,"");hanger.queue_free()
	# Restore this fixture fitting with a real additional kit, preserving three
	# distinct installed strings for the separate-process reader.
	var kit:=ItemInstance.new(FITS[expected[gun_id]]);profile.inventory.add_item(kit)
	check(WeaponFitting.install_kit(gun_id,kit.instance_id,PATH).error==OK,"Reinstall through real kit flow")
	file=FileAccess.open("user://weapon_art_v1_expected.json",FileAccess.WRITE);file.store_string(JSON.stringify(expected));file.close()
	check(SaveService.SCHEMA_VERSION==8 and SortieCheckpoint.VERSION==6,"No profile/checkpoint schema bump")
	await finish()
func finish() -> void:
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	for frame in 4:await get_tree().process_frame
	print("WEAPON_ART_V1_TEST: ","PASS" if failures.is_empty() else "FAIL"," (",checks," checks)")
	get_tree().quit(0 if failures.is_empty() else 1)
