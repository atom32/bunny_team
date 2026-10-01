extends Node
## CPU skin sample taken inside the final modifier signal, before poses restore.
var player: PlayerController
var buckets := {}
var triangles: Array[PackedVector3Array] = []
var capture := false
var summary := {}
const CELL := .05
func _ready() -> void: run.call_deferred()
func run() -> void:
 player=load("res://scenes/player/player.tscn").instantiate();player.preview_mode=true;add_child(player)
 for tick in 4: await get_tree().physics_frame
 player.set_process(false);player.set_physics_process(false)
 player.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
 var hands:=player.character_skeleton.get_node("BunnyGunHands") as SkeletonModifier3D
 hands.modification_processed.connect(func():
  if capture:
   capture=false;sample()
 )
 for tick in 18:
  player.animation_tree.advance(1./60.);player.animation_source_skeleton.advance(1./60.)
  player.combat_rig.update_pose(Vector3(0,1.25,-20),Vector3.FORWARD,0,1./60.,false)
  capture=tick==17
  player.combat_rig.apply_skeleton_ik(1./60.)
  await get_tree().process_frame
 print("HAND_SURFACE_SAMPLE ",JSON.stringify(summary))
 player.queue_free();await get_tree().process_frame;AudioDirector.shutdown_for_test();get_tree().quit()
func key(point: Vector3) -> Vector3i: return Vector3i(floori(point.x/CELL),floori(point.y/CELL),floori(point.z/CELL))
func sample() -> void:
 var weapon:=player.combat_rig.equipped_weapon
 for mesh: MeshInstance3D in weapon.find_children("*","MeshInstance3D",true,false):
  if mesh.name=="MuzzleFlash" or not mesh.mesh: continue
  for surface in mesh.mesh.get_surface_count():
   var arrays:=mesh.mesh.surface_get_arrays(surface)
   var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
   if indices.is_empty():
    for index in verts.size(): indices.append(index)
   for index in range(0,indices.size(),3):
    var triangle:=PackedVector3Array([mesh.global_transform*verts[indices[index]],mesh.global_transform*verts[indices[index+1]],mesh.global_transform*verts[indices[index+2]]])
    var id:=triangles.size();triangles.append(triangle)
    var lower:=key(triangle[0].min(triangle[1]).min(triangle[2]))
    var upper:=key(triangle[0].max(triangle[1]).max(triangle[2]))
    for x in range(lower.x,upper.x+1):
     for y in range(lower.y,upper.y+1):
      for z in range(lower.z,upper.z+1):
       var cell:=Vector3i(x,y,z)
       if not buckets.has(cell): buckets[cell]=[]
       buckets[cell].append(id)
 var sk:=player.character_skeleton
 var rest_error:=0.
 for mesh: MeshInstance3D in sk.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh or not mesh.skin: continue
  var bone_ids: Array[int]=[]
  var skin:=mesh.skin
  for bind in skin.get_bind_count():
   var bone:=sk.find_bone(skin.get_bind_name(bind)) if skin.get_bind_name(bind)!=&"" else skin.get_bind_bone(bind)
   bone_ids.append(bone)
  for surface in mesh.mesh.get_surface_count():
   var arrays:=mesh.mesh.surface_get_arrays(surface)
   var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var joints: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
   var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
   if joints.is_empty(): continue
   var stride:=joints.size()/verts.size()
   for index in verts.size():
    var side:="";var side_weight:=0.;var dominant:="";var top_weight:=0.
    for slot in stride:
     var weight:=weights[index*stride+slot]
     if weight<=0: continue
     var name:=String(sk.get_bone_name(bone_ids[joints[index*stride+slot]]))
     if "RightHand" in name: side="Right";side_weight+=weight
     if "LeftHand" in name: side="Left";side_weight+=weight
     if weight>top_weight: top_weight=weight;dominant=name
    if side_weight<.8: continue
    var world:=Vector3.ZERO;var rest:=Vector3.ZERO
    for slot in stride:
     var weight:=weights[index*stride+slot]
     if weight<=0: continue
     var bind:=joints[index*stride+slot];var bone:=bone_ids[bind]
     world+=(sk.get_bone_global_pose(bone)*skin.get_bind_pose(bind)*verts[index])*weight
     rest+=(sk.get_bone_global_rest(bone)*skin.get_bind_pose(bind)*verts[index])*weight
    world=sk.to_global(world);rest=sk.to_global(rest)
    rest_error=maxf(rest_error,rest.distance_to(mesh.to_global(verts[index])))
    var group:=side+"Palm" if dominant.ends_with("Hand") else dominant.trim_prefix("Character1_")
    var distance:=nearest(world)
    if not summary.has(group): summary[group]={"vertices":0,"within_3mm":0,"within_8mm":0,"nearest_m":1.}
    var result: Dictionary=summary[group]
    result.vertices+=1;result.nearest_m=minf(result.nearest_m,distance)
    if distance<.003: result.within_3mm+=1
    if distance<.008: result.within_8mm+=1
 summary["rest_transform_max_error_m"]=rest_error
 summary["gun_triangles"]=triangles.size()
 var thumb_joints: Array[Vector3]=[]
 for joint in range(1,4): thumb_joints.append(weapon.to_local(sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_RightHandThumb"+str(joint))).origin)))
 summary["right_thumb_joints_weapon_space"]=thumb_joints
func nearest(point: Vector3) -> float:
 var centre:=key(point);var candidates:={}
 for x in range(-1,2):
  for y in range(-1,2):
   for z in range(-1,2):
    for id in buckets.get(centre+Vector3i(x,y,z),[]): candidates[id]=true
 var distance:=1.
 for id in candidates: distance=minf(distance,point.distance_to(closest(point,triangles[id][0],triangles[id][1],triangles[id][2])))
 return distance
func closest(p: Vector3,a: Vector3,b: Vector3,c: Vector3) -> Vector3:
 var ab:=b-a;var ac:=c-a;var ap:=p-a
 var d1:=ab.dot(ap);var d2:=ac.dot(ap)
 if d1<=0 and d2<=0: return a
 var bp:=p-b;var d3:=ab.dot(bp);var d4:=ac.dot(bp)
 if d3>=0 and d4<=d3: return b
 var vc:=d1*d4-d3*d2
 if vc<=0 and d1>=0 and d3<=0: return a+ab*(d1/(d1-d3))
 var cp:=p-c;var d5:=ab.dot(cp);var d6:=ac.dot(cp)
 if d6>=0 and d5<=d6: return c
 var vb:=d5*d2-d1*d6
 if vb<=0 and d2>=0 and d6<=0: return a+ac*(d2/(d2-d6))
 var va:=d3*d6-d5*d4
 if va<=0 and d4-d3>=0 and d5-d6>=0: return b+(c-b)*((d4-d3)/((d4-d3)+(d5-d6)))
 var denominator:=va+vb+vc
 if absf(denominator)<.000000001: return a
 return a+ab*(vb/denominator)+ac*(vc/denominator)
