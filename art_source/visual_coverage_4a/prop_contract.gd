extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var cluster = load("res://scenes/presentation/service_props/maintenance_cluster.tscn").instantiate()
 root.add_child(cluster)
 await process_frame
 var triangles := 0
 var surfaces := 0
 for mesh in cluster.find_children("*", "MeshInstance3D", true, false):
  for i in mesh.mesh.get_surface_count():
   surfaces += 1
   triangles += mesh.mesh.surface_get_array_index_len(i) / 3
 var checks := {
  "no_collision_bodies":cluster.find_children("*", "CollisionObject3D", true, false).is_empty(),
  "no_navigation_regions":cluster.find_children("*", "NavigationRegion3D", true, false).is_empty(),
  "triangles_1070":triangles == 1070,
  "surfaces_35":surfaces == 35,
  "three_reusable_props":cluster.get_child_count() == 4
 }
 var report := {"checks":checks,"triangles":triangles,"surfaces":surfaces,"label_count":1}
 var f:=FileAccess.open(OS.get_environment("BUNNY_PROP_REPORT"),FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"  "));f.close()
 print(JSON.stringify(report))
 cluster.queue_free()
 root.get_node("AudioDirector").shutdown_for_test()
 await process_frame
 quit(1 if checks.values().has(false) else 0)
