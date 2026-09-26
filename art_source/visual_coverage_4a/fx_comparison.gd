extends SceneTree
var folder := OS.get_environment("BUNNY_EVIDENCE")
func _initialize(): run.call_deferred()
func capture(label: String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run():
 var world := Node3D.new()
 root.add_child(world)
 current_scene = world
 var camera := Camera3D.new()
 camera.position = Vector3(4,4,6)
 world.add_child(camera)
 camera.look_at(Vector3(0,0.5,0)); camera.current=true
 var env := Environment.new()
 env.background_mode=Environment.BG_COLOR; env.background_color=Color("344653")
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color.WHITE; env.ambient_light_energy=0.6
 var we:=WorldEnvironment.new();we.environment=env;world.add_child(we)
 var ground:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(20,0.1,20);ground.mesh=box
 var material:=StandardMaterial3D.new();material.albedo_color=Color("53616b");material.roughness=1;ground.material_override=material;ground.position.y=-0.2;world.add_child(ground)
 var old = load(OS.get_environment("BUNNY_OLD_EFFECTS"))
 var production = load("res://scripts/combat/combat_effects.gd")
 var report := {}
 for mode in ["before","after"]:
  var fx = old if mode=="before" else production
  var group:=Node3D.new();world.add_child(group)
  seed(143)
  fx.explosion(group,Vector3.ZERO,3.0)
  await create_timer(0.16).timeout
  await capture(mode+"_explosion_peak")
  await create_timer(0.16).timeout
  print(mode," child count ",group.get_child_count())
  for n in group.get_children():
   if n.name=="ExplosionSmoke":print("SMOKE ",n.global_position," SCALE ",n.scale," COLOR ",n.material_override.albedo_color)
  await capture(mode+"_explosion_smoke")
  await create_timer(0.5).timeout
  report[mode+"_explosion_cleanup"] = group.get_child_count()==0
  for i in 6:fx.rocket_trail(group,Vector3(-1.4+i*.45,0.7,0))
  await create_timer(0.02).timeout
  for n in group.get_children():
   if n.name=="RocketTrail":print(mode," TRAIL ",n.position," SCALE ",n.scale," COLOR ",n.material_override.albedo_color," SIZE ",n.mesh.get_aabb()," KEEP ",n.material_override.billboard_keep_scale)
  await capture(mode+"_rocket_trail")
  await create_timer(0.045).timeout
  await capture(mode+"_rocket_trail_fade")
  await create_timer(0.4).timeout
  report[mode+"_trail_cleanup"] = group.get_child_count()==0
  group.queue_free()
 var f:=FileAccess.open(folder.path_join("fx_result.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 root.get_node("AudioDirector").shutdown_for_test()
 quit(1 if report.values().has(false) else 0)
