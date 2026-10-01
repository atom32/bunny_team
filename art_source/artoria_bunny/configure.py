import bpy,json,math
from pathlib import Path
from mathutils import Vector
out=Path(__file__).resolve().parent
scene=bpy.context.scene
# Change only the in-memory inspection scene; preserve the original .blend.
for name in ['ArtoriaLancer Default','ArtoriaLancer Alter','ArtoriaLancer XX','ArtoriaLancer Golden Bikini']:
 c=bpy.data.collections.get(name)
 if c:c.hide_render=True;c.hide_viewport=True
outfit=bpy.data.collections['ArtoriaLancer Bunny Suit']
outfit.hide_render=False;outfit.hide_viewport=False
for obj in outfit.objects:
 obj.hide_render=False;obj.hide_viewport=False;obj.hide_set(False)
 for mod in obj.modifiers:
  if mod.type=='ARMATURE':mod.show_viewport=True
# Use the matching authored body/stocking fit morphs, with the same default hair.
for objname in ['ArtoriaLancer_Body','ArtoriaLancer Bunny Suit - Stockings']:
 obj=bpy.data.objects[objname];keys=obj.data.shape_keys
 if keys.animation_data:
  for driver in keys.animation_data.drivers:driver.mute=True
 for key in keys.key_blocks:
  if key.name in ['Suit_Gloves','Suit','Suit_Leggings','Suit_Bra']:key.value=0
  if key.name in ['BunnySuit_Leotard','BunnySuit_Stockings','BunnySuit_Heels']:key.value=1
bpy.data.objects['ArtoriaLancer Bunny Suit - Scarf'].hide_render=True
bpy.data.objects['ArtoriaLancer Bunny Suit - Scarf'].hide_set(True)

bpy.context.view_layer.update()
