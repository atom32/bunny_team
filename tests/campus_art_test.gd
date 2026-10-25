extends Node
## Full-map art structure, real geometry/physics invariants and native buffers.
## Visual acceptance still requires inspecting the captured camera views.
var failures: Array[String]=[]
var checks:=0
var survey: Node3D
var evidence:=OS.get_environment("BUNNY_EVIDENCE")

func check(value: bool, message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)

func frames(count := 8) -> void:
	for i in count:await get_tree().process_frame

func capture(name: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(name+".png"))

func check_water_noise() -> void:
	if DisplayServer.get_name()=="headless":return
	# Exercise the production noise on the GPU, not a CPU approximation.
	var source:=FileAccess.get_file_as_string("res://resources/materials/streets/geographic_water.gdshader")
	var functions:=source.substr(source.find("float hash"),source.find("void vertex")-source.find("float hash"))
	var shader:=Shader.new()
	shader.code="shader_type canvas_item;\n"+functions+"""
void fragment() {
	vec2 p=floor(UV*40.0)-vec2(20.0);
	float a=abs(noise(p+vec2(-0.00001,0.37))-noise(p+vec2(0.00001,0.37)));
	float b=abs(noise(p+vec2(0.37,-0.00001))-noise(p+vec2(0.37,0.00001)));
	COLOR=vec4(max(a,b)>0.001?1.0:0.0,0.0,0.0,1.0);
}
"""
	var viewport:=SubViewport.new();viewport.size=Vector2i(80,80)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var rect:=ColorRect.new();rect.size=Vector2(80,80)
	var material:=ShaderMaterial.new();material.shader=shader;rect.material=material
	viewport.add_child(rect)
	await frames(4)
	await RenderingServer.frame_post_draw
	var picture:=viewport.get_texture().get_image()
	var continuous:=true
	for y in picture.get_height():
		for x in picture.get_width():
			if picture.get_pixel(x,y).r>.5:continuous=false
	check(continuous,"Production GPU water noise is continuous across both axes of all 1,600 sampled lattice cells")
	viewport.queue_free()

func _ready() -> void:
	await get_tree().process_frame
	var before:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	await check_water_noise()
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	add_child(survey)
	await frames()
	var world: Node3D=survey.get_node("WeijinGeographicWorld")
	var geo: CampusGeodata=survey.geo
	var stats: Dictionary=world.get_meta("build_stats")
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/geography/weijin/PHYSICS_BASELINE.json"))
	check(FileAccess.get_sha256(CampusGeodata.PATH)==baseline.data_sha256,"Source geography did not change during the art pass")
	check(SortieCheckpoint.layout_signature(world)==baseline.layout_sha256,"All geographic collision matches the independently rebuilt pre-art baseline")
	check(world.find_children("*","CollisionShape3D",true,false).size()==baseline.collision_shapes,"No decorative props become unintended cover or blockers")
	var layers_ok:=true
	for body: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		if body.collision_layer!=4 or body.collision_mask!=0:layers_ok=false
	check(layers_ok,"All retained geographic bodies keep their original world collision layer/mask")
	var helper:=preload("res://scripts/world/geography/campus_builder.gd").new()
	helper.unit_box=BoxMesh.new();helper.unit_box.size=Vector3.ONE
	helper.materials.fixture=StandardMaterial3D.new()
	helper._box(Vector3(.4,.3,10),Vector3.ZERO,"fixture",PI*.5)
	var box_mesh: ArrayMesh=helper.batches.values()[0].tool.commit()
	check(absf(box_mesh.get_aabb().size.x-10)<.001 and absf(box_mesh.get_aabb().size.z-.4)<.001,"Rotated trim scales in local axes rather than stretching across the campus")
	helper.batches.clear()
	helper._beam(Vector3.ZERO,Vector3(8,0,6),.12,"fixture")
	var beam_mesh: ArrayMesh=helper.batches.values()[0].tool.commit()
	var beam_ok:=true
	for vertex: Vector3 in beam_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var along:=vertex.dot(Vector3(.8,0,.6))
		# A rotated square section may have an AABB sqrt(2) times its width.
		var radial:=vertex-Vector3(.8,0,.6)*along
		if along<-.001 or along>10.001 or radial.length()>.085:beam_ok=false
	check(beam_ok,"Oblique branches/hardware preserve actual axial length and square cross-section")
	var road:=PackedVector2Array([Vector2(-1,-5),Vector2(1,-5),Vector2(1,5),Vector2(-1,5)])
	helper.carriageways=[{"poly":road,"rect":Rect2(-1,-5,2,10)}]
	var paving:=PackedVector2Array([Vector2(-3,-.5),Vector2(3,-.5),Vector2(3,.5),Vector2(-3,.5)])
	var paving_ok:=true
	var paving_area:=0.0
	for piece: PackedVector2Array in helper._clip_carriageway(paving):
		if Geometry2D.is_point_in_polygon(Vector2.ZERO,piece):paving_ok=false
		var area:=0.0
		for i in piece.size():area+=piece[i].cross(piece[(i+1)%piece.size()])
		paving_area+=absf(area)*.5
	check(paving_ok and absf(paving_area-4)<.001,"Crossing footways are geometrically clipped from carriageways, not coplanar z-fighting overlays")
	check(world.get_meta("art_revision")==2,"Static scene contains the new art, not an unbaked builder")
	check(stats.window_modules>40000 and stats.closed_facade_entries>200,"Architectural detailing covers the campus, not a few hero corners")
	check(stats.pitched_roofs+stats.flat_roofs==467,"Every retained building has a complete roof treatment")
	check(stats.landmark_facades==4,"Main hall, library, activity centre and pool have authored entrances")
	check(stats.foliage_variants==4 and stats.foliage_near_cutoff_m==160,"Detailed branch/leaf variants have a separate far LOD")
	check(stats.garden_shrubs>100,"Mapped garden areas have a restrained understory layer")
	check(stats.street_lamps>100 and stats.lakeside_benches>25 and stats.parked_bicycles>30 and stats.road_drains>200,"Campus-wide use and road infrastructure exist")
	check(stats.get("lake_wayfinding_signs",0)==4,"Each real lake has an in-world source-named wayfinding sign")
	var records: Array=world.get_meta("roof_art_records")
	var by_id: Dictionary={}
	for record: Dictionary in records:by_id[record.osm_id]=record
	check(by_id.size()==467,"Roof art has one traceable record per source footprint")
	for entry: Dictionary in geo.data.buildings:
		var shape: String=entry.tags.get("roof:shape","")
		if shape in ["flat","gabled","hipped"]:
			check(by_id[entry.osm_id].shape==shape and by_id[entry.osm_id].source==shape,"Explicit source roof shape preserved: "+String(entry.osm_id))
	var bad_trees:=0
	var mapped:=0
	for record: Dictionary in world.get_meta("tree_art_placements"):
		if record.mapped:mapped+=1;continue
		var p: Vector2=record.point
		if geo.is_building(p,3.9) or geo.is_water(p,2.9) or geo.road_blocks(p,1.25) or geo.sports_blocks(p,1.25):bad_trees+=1
	check(mapped==2,"Two source-mapped trees remain distinguishable from inferred planting")
	check(bad_trees==0,"No inferred tree trunks are in buildings, lakes, sports surfaces or road crossings")
	var bad_shrubs:=0
	for p: Vector2 in world.get_meta("shrub_art_placements"):
		if geo.is_building(p,1.4) or geo.road_blocks(p,1.1) or geo.sports_blocks(p,1.1):bad_shrubs+=1
	check(bad_shrubs==0,"Understory is kept out of paved circulation and sport grounds")
	var bad_props:=0
	for record: Dictionary in world.get_meta("art_placements"):
		if record.kind=="drain":continue # Drains intentionally sit within the road edge.
		var p: Vector2=record.point
		if geo.is_water(p,.4) or geo.is_building(p,.4) or geo.road_blocks(p,.35) or geo.sports_blocks(p,.35):bad_props+=1
	check(bad_props==0,"Street furniture is not scattered into circulation, water or building shells")
	var window_count:=0
	var near_count:=0
	var far_count:=0
	var native_buffers_ok:=true
	var leaf_geometry_ok:=true
	var branch_geometry_ok:=true
	for node: MultiMeshInstance3D in world.find_children("*","MultiMeshInstance3D",true,false):
		if String(node.name).begins_with("ArchitecturalWindows"):window_count+=node.multimesh.instance_count
		if String(node.name).begins_with("IllustrativeDetailedTrees"):
			near_count+=node.multimesh.instance_count
			var colors: PackedColorArray=node.multimesh.mesh.surface_get_arrays(1)[Mesh.ARRAY_COLOR]
			if colors.size()<10000:leaf_geometry_ok=false
			var branch_vertices: PackedVector3Array=node.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			if branch_vertices.size()<500:branch_geometry_ok=false
		if String(node.name).begins_with("IllustrativeTreeLOD"):far_count+=node.multimesh.instance_count
		if DisplayServer.get_name()!="headless" and node.multimesh.buffer.is_empty():native_buffers_ok=false
	check(window_count==stats.window_modules,"Baked window buffers match the full-map instance count")
	check(near_count==stats.illustrative_and_mapped_trees and near_count==far_count,"Every tree has matching near and far geometry")
	check(leaf_geometry_ok,"Near foliage contains the existing game's individually colored leaf geometry, not sphere proxies")
	check(branch_geometry_ok,"Every near tree retains its full trunk, limbs and twigs, including auto-renamed source nodes")
	if DisplayServer.get_name()!="headless":check(native_buffers_ok,"Real renderer loads all baked MultiMesh buffers")
	var samples:=0
	var error:=0.0
	for i in 150:
		var p:=Vector2(sin(i*2.399963)*640,cos(i*1.731)*410)
		if not geo.safe_walk_point(p) or geo.is_water(p,15):continue
		var point:=geo.at3(p)
		var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*2,point-Vector3.UP*2,4)
		var hit:=survey.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or not String(hit.collider.name).begins_with("ground"):continue
		error=maxf(error,absf(float(hit.position.y)-geo.mesh_height_at(p)))
		samples+=1
	check(samples>=25 and error<.005,"Draped paths and gardens follow the real collision triangles, not intersecting planar overlays")
	var toggle: Button=survey.screen.get_node("ToggleSceneDetails")
	check(get_viewport().get_visible_rect().encloses(toggle.get_global_rect()),"Scene/Tab control fits the actual viewport")
	var key:=InputEventKey.new();key.physical_keycode=KEY_TAB;key.pressed=true
	get_viewport().push_input(key)
	await frames()
	check(not survey.details_visible and not survey.screen.get_node("GeographicInspector").visible,"Real Tab input collapses the GIS inspector")
	survey.toggle_walking()
	await frames(45)
	await capture("walk_east_gate")
	check(survey.actor.is_on_floor(),"Actor still enters on the actual terrain after visual dressing")
	# Explicit near-building fixture, not a claimed traversal to this location.
	survey.actor.position=geo.at3(Vector2(333,77),.1)
	survey.actor.velocity=Vector3.ZERO
	await frames(25)
	survey.focus=survey.actor.position+Vector3.UP
	survey.target_focus=survey.focus
	var actor_before: Vector3=survey.actor.position
	survey._update_camera(0)
	var query:=PhysicsRayQueryParameters3D.create(survey.actor.position+Vector3.UP*1.15,survey.camera.position,4)
	query.exclude=[survey.actor.get_rid()]
	var hit:=survey.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.is_empty() or not String(hit.collider.name).begins_with("Building_"),"Near-building walk camera keeps the actual player visible")
	check(survey.yaw==0 and survey.actor.position.distance_to(actor_before)<.001,"Camera steepening does not rotate movement heading or move the actor")
	await capture("walk_north_hall_fixture")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==before,"Art inspection and camera fixtures preserve the entire Profile")
	print("CAMPUS ART TEST: ",checks," checks / ",failures.size()," failures; terrain samples=",samples," max_error=",error)
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("art_validation.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"stats":stats,"terrain_samples":samples,"terrain_max_error_m":error,"physics_signature":SortieCheckpoint.layout_signature(world),"native":DisplayServer.get_name()!="headless"},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)
