extends Node
@onready var root := get_tree().root
func _ready(): run.call_deferred()
func run():
 if "--chinese" in OS.get_cmdline_user_args(): GameLanguage.set_language("zh_CN",false)
 root.size=Vector2i(1600,1000)
 var profile=root.get_node('ProfileRuntime').new_profile()
 var plan=DeploymentPlan.build(profile)
 var session=root.get_node('SortieRuntime').start_sortie(profile.create_sortie_request(&'street_district',&'streets_recon',plan.ammo_ids),profile)
 print('SESSION ',session)
 var battle=load('res://scenes/battle/battle.tscn').instantiate();battle.loot_seed=907
 root.add_child(battle);get_tree().current_scene=battle;battle.result_transition_enabled=false
 battle.player.set_physics_process(false)
 for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
 for frame in 8: await get_tree().physics_frame
 print('SPAWN ',battle.area_root.selected_spawn,' EXITS ',battle.area_root.active_exit_names,' LOOT ',battle.area_root.loot_points.size())
 var map=battle.area_root.get_node('StreetNavigation').get_navigation_map()
 var region_rid: RID = battle.area_root.get_node("StreetNavigation").get_rid()
 for tick in 60:
  if NavigationServer3D.region_get_iteration_id(region_rid)>0: break
  await get_tree().create_timer(.05).timeout
 await get_tree().create_timer(.25).timeout
 NavigationServer3D.map_force_update(map)
 print("NAV ACTIVE ",NavigationServer3D.map_is_active(map)," iteration ",NavigationServer3D.region_get_iteration_id(region_rid)," closest ",NavigationServer3D.map_get_closest_point(map,battle.player.global_position))
 print('MAP ',map,' regions ',NavigationServer3D.map_get_regions(map),' polys ',battle.area_root.get_node('StreetNavigation').navigation_mesh.get_polygon_count())
 var nav=NavigationServer3D.map_get_path(map,battle.player.global_position,battle.area_root.get_node('StreetTerminal').global_position,true)
 print('NAV TO TERMINAL ',nav.size(),' end ',nav[-1] if not nav.is_empty() else Vector3.ZERO)
 var basis=battle.camera.global_basis
 for frame in 30:
  battle.player.global_position=Vector3(-20,.1,-20)+Vector3.RIGHT*frame*.1
  battle.player.aim_direction=Vector3.LEFT if frame%2 else Vector3.FORWARD
  battle._process(1./60.)
 print('CAMERA_BASIS_UNCHANGED ',basis.is_equal_approx(battle.camera.global_basis))
 battle.set_process(false)
 battle.hud.hide()
 battle.area_root.route_map.hide()
 for shot in ['overview','street','interior','pharmacy','lobby','workshop','vehicle','facade','tree']:
  battle.camera.size=130 if shot=='overview' else 25
  if shot in ['vehicle','facade','tree']:
   battle._camera_occlusion._exit_tree()
   battle._camera_occlusion.faded.clear()
   var focus: Vector3 = Vector3(42,.7,-14) if shot=='vehicle' else (Vector3(16,2.3,13) if shot=='tree' else Vector3(-9,4,34))
   battle.camera.size=8 if shot in ['vehicle','tree'] else 18
   battle.camera.global_position=focus+(Vector3(5,4,6) if shot=='vehicle' else (Vector3(8,12,-10) if shot=='tree' else Vector3(15,12,18)))
   battle.camera.look_at(focus)
  elif shot in ['overview','street']:
   battle.camera.global_position=Vector3(0,95,60) if shot=='overview' else Vector3(0,18,30)
   battle.camera.look_at(Vector3.ZERO if shot=='overview' else Vector3(0,0,16))
  else:
   var room: Vector3 = battle.area_root.ROOMS[['interior','pharmacy','lobby','workshop'].find(shot)]
   battle.camera.global_position=room+Vector3(0,18,16)
   battle.camera.look_at(room)
   battle.player.global_position=room+Vector3(0,.1,0)
   for frame in 20: battle._camera_occlusion.update_occlusion(battle.camera,battle.player,.05)
  for frame in 5: await get_tree().process_frame
  if DisplayServer.get_name()!='headless':
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png('/tmp/streets_'+shot+'.png')
 battle.hud.show()
 battle.area_root.route_map.show()
 battle.area_root.route_map.expanded=true
 for frame in 5: await get_tree().process_frame
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('/tmp/streets_route_map.png')
 battle.queue_free();await get_tree().process_frame
 root.get_node('AudioDirector').shutdown_for_test()
 get_tree().quit()
