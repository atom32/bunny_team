extends Node3D
## Native-rendered evidence/icons. Run against an isolated profile/project only.
const NAMES := ["medkit","field_dressing","electronics","parts","wiring","fabric","data_drive","experiment_recorder","scrap","propellant","salvage_core","field_ration","energy_bar","canned_beans","bottled_water","citrus_drink"]
var evidence:=OS.get_environment("BUNNY_SUPPLY_EVIDENCE")
var view: SubViewport
var stage: Node3D
var camera: Camera3D
var environment: Environment
var asset: Node3D
func _ready() -> void: run.call_deferred()
func bounds(node: Node3D) -> AABB:
	var result:=AABB();var first:=true
	for child in node.find_children("*","MeshInstance3D",true,false):
		var box: AABB=child.global_transform*child.get_aabb();result=box if first else result.merge(box);first=false
	return result
func capture(path: String) -> void:
	for frame in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(view.get_texture().get_image().save_png(path)==OK)
func product(name: String,icon: bool) -> void:
	if is_instance_valid(asset):asset.queue_free();await get_tree().process_frame
	asset=load("res://scenes/props/supply_art_v1/"+name+".tscn").instantiate();stage.add_child(asset)
	var box:=bounds(asset);var center:=box.get_center()
	camera.position=center+Vector3(1.0,.80,1.9)*maxf(.15,box.size.length());camera.look_at(center)
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for i in 8:
		var p: Vector3=box.get_endpoint(i)-center;var v:=Vector2(p.dot(camera.global_basis.x),p.dot(camera.global_basis.y));low=low.min(v);high=high.max(v)
	view.size=Vector2i(512,512) if icon else Vector2i(1000,1000);view.transparent_bg=icon
	camera.size=maxf(high.y-low.y,high.x-low.x)*1.26
	environment.background_color=Color(0,0,0,0) if icon else Color("242d31")
	await capture("res://assets/ui/stash/supply_art_v1/"+name+".png" if icon else evidence+"/"+name+".png")
func main_capture(name: String) -> void:
	for frame in 12:
		if get_tree().paused and FlowMenu.mode=="pause":FlowMenu.close()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(evidence+"/"+name+".png")==OK)
func run() -> void:
	assert(not evidence.is_empty() and DisplayServer.get_name()!="headless")
	DirAccess.make_dir_recursive_absolute(evidence)
	view=SubViewport.new();view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var panel:=SubViewportContainer.new();panel.size=Vector2(1000,1000);add_child(panel);panel.add_child(view)
	stage=Node3D.new();view.add_child(stage)
	var world:=WorldEnvironment.new();environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("b7c5ca");environment.ambient_light_energy=.75;environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=environment;stage.add_child(world)
	for row in [[Vector3(-40,-35,0),1.7,Color("fff3da")],[Vector3(25,135,0),.8,Color("b8cfdf")]]:
		var light:=DirectionalLight3D.new();light.rotation_degrees=row[0];light.light_energy=row[1];light.light_color=row[2];stage.add_child(light)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.near=.001;camera.far=30;camera.current=true;stage.add_child(camera)
	var icons:=OS.get_environment("BUNNY_SUPPLY_ICONS")=="isolated"
	if icons:
		assert(not ProjectSettings.globalize_path("res://").replace("\\","/").begins_with("D:/bunny_team"));DirAccess.make_dir_recursive_absolute("res://assets/ui/stash/supply_art_v1")
	for name in NAMES:
		await product(name,false)
		if icons:await product(name,true)
	asset.queue_free();asset=null;await get_tree().process_frame
	# Native Godot contact sheet, not composited/retouched raster artwork.
	view.transparent_bg=false;view.size=Vector2i(1600,1100);environment.background_color=Color("242d31")
	for i in NAMES.size():
		var model: Node3D=load("res://scenes/props/supply_art_v1/"+NAMES[i]+".tscn").instantiate();stage.add_child(model)
		var box:=bounds(model);var scale_factor:=.23/maxf(box.size.x,maxf(box.size.y,box.size.z));model.scale=Vector3.ONE*scale_factor
		model.position=Vector3((i%4-1.5)*.42,(1.5-floorf(i/4.0))*.35,0)-box.get_center()*scale_factor
	var label:=Label3D.new();label.font=UIFactory.FONT;label.font_size=28;label.pixel_size=.0015;label.position=Vector3(0,.73,0);label.text="BASTION 07 / FIELD SUPPLIES";label.outline_size=0;stage.add_child(label)
	camera.position=Vector3(1.1,.7,4.0);camera.look_at(Vector3.ZERO);camera.size=1.68
	await capture(evidence+"/collection.png")
	if not icons:
		for child in stage.get_children():
			if child is Node3D and not child is Camera3D and not child is Light3D and not child is WorldEnvironment:child.queue_free()
		await get_tree().process_frame
		for i in 5:
			var pickup:=load("res://scenes/world/loot_pickup.tscn").instantiate() as LootPickup
			pickup.setup(ItemInstance.new(StringName("supply."+["field_ration","energy_bar","canned_beans","bottled_water","citrus_drink"][i])))
			stage.add_child(pickup);pickup.position=Vector3((i-2)*.85,0,0)
			# Close-up art evidence only; production labels retain their original size.
			for child in pickup.get_children():
				if child is Label3D:child.hide()
		camera.position=Vector3(1.5,2.7,5);camera.look_at(Vector3(0,.4,0));camera.size=3.3
		await capture(evidence+"/real_pickups.png")
	panel.hide();view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	if not icons:
		var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
		for id in ["supply.field_ration","supply.energy_bar","supply.canned_beans","supply.bottled_water","supply.citrus_drink","medical.medkit","medical.field_dressing","material.electronics","material.parts","material.wiring","story.experiment_recorder"]:
			assert(profile.inventory.add_item(ItemInstance.new(StringName(id))))
		var hanger: Node3D=load("res://scenes/hanger/hanger.tscn").instantiate();add_child(hanger)
		GameLanguage.set_language("zh_CN",false);await main_capture("warehouse_zh")
		hanger.queue_free();await get_tree().process_frame
		var layer:=CanvasLayer.new();add_child(layer)
		var supply:=SupplyPanel.new();supply.contact_id="tang_kui";supply.position=Vector2(55,40);supply.size=Vector2(1100,800);layer.add_child(supply)
		await main_capture("resident_shop_zh");layer.queue_free()
	panel.queue_free();stage=null;camera=null;view=null;environment=null
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	for frame in 5:await get_tree().process_frame
	print("SUPPLY_ART_PROBE: PASS / actual 16 assets; isolated fixture, not human acceptance");get_tree().quit()
