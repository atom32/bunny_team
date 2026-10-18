extends Node3D
## Isolated visual evidence and icon renderer; never runs in production gameplay.
var evidence:=OS.get_environment("BUNNY_WEAPON_ART_EVIDENCE")
var view: SubViewport
var studio: Node3D
var camera: Camera3D
var environment: Environment
var asset: Node3D
func _ready() -> void: run.call_deferred()
func bounds(node: Node3D) -> AABB:
	var result:=AABB();var first:=true
	for child in node.find_children("*","MeshInstance3D",true,false):
		if not child.is_inside_tree() or not child.is_visible_in_tree():continue
		var box: AABB=child.global_transform*child.get_aabb()
		result=box if first else result.merge(box);first=false
	return result
func capture_view(path: String) -> void:
	for frame in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png(path)==OK)
func product(path: String,filename: String,fitting:="",baseline:=false,top:=false,icon:=false) -> void:
	if is_instance_valid(asset):
		asset.queue_free();asset=null
		await get_tree().process_frame
	asset=load(path).instantiate();studio.add_child(asset)
	await get_tree().process_frame
	if asset.has_method("apply_fitting_presentation"):asset.apply_fitting_presentation(fitting)
	if baseline:
		asset.get_node("Art/Model/M4").set_surface_override_material(0,null)
		asset.get_node("FittingVisuals").hide()
	var box:=bounds(asset);var focus:=box.get_center()
	camera.position=focus+(Vector3(.3,1.4,.4) if top else Vector3(1.3,.32,.32))*maxf(box.size.length(),.15)
	camera.look_at(focus);camera.near=.001;camera.far=30
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for i in 8:
		var point: Vector3=box.get_endpoint(i)-focus
		var p:=Vector2(point.dot(camera.global_basis.x),point.dot(camera.global_basis.y))
		low=low.min(p);high=high.max(p)
	view.size=Vector2i(512,256) if icon else Vector2i(1280,720)
	camera.size=maxf((high.y-low.y)*1.3,(high.x-low.x)*1.3*view.size.y/view.size.x)
	view.transparent_bg=icon;environment.background_color=Color(0,0,0,0) if icon else Color("242e35")
	var output: String="res://assets/ui/stash/weapon_art_v1/"+filename+".png" if icon else evidence+"/"+filename+".png"
	await capture_view(output)
func main_capture(filename: String) -> void:
	for frame in 12:
		# Isolated evidence only: normal focus-loss pause may cover the model.
		if get_tree().paused and FlowMenu.mode=="pause":FlowMenu.close()
		await get_tree().process_frame
	assert(not get_tree().paused)
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(evidence+"/"+filename+".png")==OK)
func run() -> void:
	assert(not evidence.is_empty() and DisplayServer.get_name()!="headless")
	DirAccess.make_dir_recursive_absolute(evidence)
	view=SubViewport.new();view.size=Vector2i(1280,720);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var container:=SubViewportContainer.new();container.size=Vector2(1280,720);add_child(container);container.add_child(view)
	studio=Node3D.new();view.add_child(studio)
	var env:=WorldEnvironment.new();environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("242e35")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("becbd5");environment.ambient_light_energy=.75
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=environment;studio.add_child(env)
	for entry in [[Vector3(-45,-30,0),2.1,Color("fff4df")],[Vector3(30,145,0),1.0,Color("c4dbea")]]:
		var light:=DirectionalLight3D.new();light.rotation_degrees=entry[0];light.light_energy=entry[1];light.light_color=entry[2];studio.add_child(light)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;studio.add_child(camera)
	await product("res://scenes/weapons/assault_rifle.tscn","ar_before","",true)
	for fitting in ["","quickloader","suppressor","observation_optic"]:
		await product("res://scenes/weapons/assault_rifle.tscn","ar_after_"+("standard" if fitting.is_empty() else fitting),fitting)
		await product("res://scenes/weapons/assault_rifle.tscn","ar_top_"+("standard" if fitting.is_empty() else fitting),fitting,false,true)
	for name in ["quickloader_magazine","suppressor","observation_optic","ammo_556_box","ammo_556_round"]:
		await product("res://scenes/weapons/art_pack_v1/"+name+".tscn",name)
	if OS.get_environment("BUNNY_WEAPON_ART_ICONS")=="isolated":
		assert(not ProjectSettings.globalize_path("res://").replace("\\","/").begins_with("D:/bunny_team"))
		DirAccess.make_dir_recursive_absolute("res://assets/ui/stash/weapon_art_v1")
		await product("res://scenes/weapons/assault_rifle.tscn","ar556","",false,false,true)
		for entry in [["quickloader_magazine","quickloader"],["suppressor","suppressor"],["observation_optic","observation_optic"]]:
			await product("res://scenes/weapons/art_pack_v1/"+entry[0]+".tscn",entry[1],"",false,false,true)
	container.hide();view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	var gun_id:=profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	profile.inventory.add_item(ItemInstance.new(&"material.observation_optic_kit"))
	var kit: ItemInstance
	for item in profile.inventory.get_items():
		if item.definition_id==&"material.observation_optic_kit":kit=item
	assert(WeaponFitting.install_kit(gun_id,kit.instance_id,"user://weapon_art_probe.json").error==OK)
	var hanger: Node3D=load("res://scenes/hanger/hanger.tscn").instantiate();add_child(hanger)
	await main_capture("real_hanger_optic")
	hanger.queue_free();await get_tree().process_frame
	var bench: WeaponWorkbench=load("res://scenes/tools/weapon_workbench.tscn").instantiate();add_child(bench)
	bench.actor.equip_weapon_instance(profile.inventory.get_item(gun_id));bench.set_camera(1);bench.set_markers(false);bench.set_process(false);bench.get_node("Camera").size=2.5
	for frame in 24:bench.advance_preview(1.0/60.0)
	await main_capture("real_preview_optic")
	bench.reload_preview()
	for frame in 30:bench.advance_preview(1.0/60.0)
	await main_capture("real_preview_reload")
	bench.queue_free();await get_tree().process_frame

	assert(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon","user://weapon_art_probe.json").error==OK)
	var battle: Node3D=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	await main_capture("real_battle_optic")
	battle.queue_free();container.queue_free();asset=null;studio=null;camera=null;view=null;environment=null
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	for frame in 5:await get_tree().process_frame
	await get_tree().create_timer(.4).timeout
	print("WEAPON_ART_V1_PROBE: PASS / actual material/accessory/preview captures; not human acceptance")
	get_tree().quit()
