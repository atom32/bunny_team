import bpy,json,hashlib
from pathlib import Path
D=Path(__file__).resolve().parent; master=D.parent/'battle_master.blend'
bpy.ops.wm.open_mainfile(filepath=str(master))
def fingerprint():
 out={}
 for o in bpy.data.objects:
  if o.type=='ARMATURE':out[o.name]={'rest':[(b.name,b.parent.name if b.parent else None,[list(x) for x in b.matrix_local]) for b in o.data.bones],'poses':[(b.name,[list(x) for x in b.matrix_basis]) for b in o.pose.bones],'props':{k:o[k] for k in o.keys() if k.startswith('Pose_')}}
  if o.type=='MESH':out[o.name]={'vertices':[(list(v.co),[(g.group,g.weight) for g in v.groups]) for v in o.data.vertices],'polygons':[list(f.vertices) for f in o.data.polygons],'groups':[g.name for g in o.vertex_groups],'transform':[list(x) for x in o.matrix_world]}
 actions={}
 for a in bpy.data.actions:
  channels=[]
  for layer in a.layers:
   for strip in layer.strips:
    for slot in a.slots:
     bag=strip.channelbag(slot)
     if bag:
      for fc in bag.fcurves:channels.append([fc.data_path,fc.array_index,[(list(k.co),list(k.handle_left),list(k.handle_right),k.interpolation) for k in fc.keyframe_points]])
  actions[a.name]=channels
 out['actions']=actions
 return hashlib.sha256(json.dumps(out,sort_keys=True).encode()).hexdigest()
before=fingerprint();old=hashlib.sha256(master.read_bytes()).hexdigest();profile={}
for name in ['Battle_face3_main','Battle_Unity2016_C_Skin','Battle_Unity2016_C_Hair_Spow']:
 m=bpy.data.materials[name]
 m['godot_presentation_shader']='phase3b/anime_surface.gdshader'
 if 'godot_direct_response_gain' not in m:m['godot_direct_response_gain']=0.2
 if 'godot_diffuse_shadow_floor' not in m:m['godot_diffuse_shadow_floor']=0.25
 m['godot_material_note']='Source base color and base texture unchanged. Godot stylized light response; Principled preview is fallback, not shader parity.'
 profile[name]={'direct_response_gain':m['godot_direct_response_gain'],'diffuse_shadow_floor':m['godot_diffuse_shadow_floor']}
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
if 'GodotEquipmentFrameCorrection' not in rig:rig['GodotEquipmentFrameCorrection']=json.dumps({'Chest':180.0,'Backpack':180.0})
(D/'mount_profile.json').write_text(rig['GodotEquipmentFrameCorrection'])
assert before==fingerprint()
bpy.ops.wm.save_as_mainfile(filepath=str(master))
bpy.ops.wm.open_mainfile(filepath=str(master));after=fingerprint();assert before==after
(D/'material_profile.json').write_text(json.dumps(profile,indent=2))
(D/'master_material_edit.json').write_text(json.dumps({'before_sha256':old,'after_sha256':hashlib.sha256(master.read_bytes()).hexdigest(),'before_geometry_rig_actions':before,'after_geometry_rig_actions':after,'fingerprint_match':before==after,'change':'three materials custom presentation properties and Chest/Backpack frame metadata only; no PBR nodes, mesh, skin, bones or pose changes','glb':'unchanged, shader applied at presentation boundary'},indent=2))
print('MASTER_MATERIAL_METADATA_SAVED fingerprint unchanged',after)
