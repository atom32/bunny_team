"""Bake the selected source node graphs to portable PBR maps; never save the source."""
import bpy, json, numpy as np
from pathlib import Path

here = Path(__file__).resolve().parent
exec((here / 'configure.py').read_text())
dest = here / 'textures'
dest.mkdir(parents=True, exist_ok=True)
active = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.visible_get() and not o.hide_render]
mats = sorted({s.material for o in active for s in o.material_slots if s.material}, key=lambda m:m.name)
for obj in bpy.context.scene.objects:
    obj.select_set(False)
bpy.ops.mesh.primitive_plane_add(size=2)
plane = bpy.context.object
plane.name = 'MaterialBakeUVSquare'
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 1
scene.cycles.device = 'CPU'
scene.render.bake.margin = 0
report = {}

def bake_socket(mat, socket, key, size):
    image_name = mat.name + '_' + key
    path = dest / (image_name + '.png')
    if path.exists():
        return bpy.data.images.load(str(path), check_existing=True)
    image = bpy.data.images.new(image_name, size, size, alpha=True)
    image.colorspace_settings.name = 'sRGB' if key == 'base' else 'Non-Color'
    tree = mat.node_tree
    output = next(n for n in tree.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output)
    old_link = output.inputs['Surface'].links[0].from_socket
    emission = tree.nodes.new('ShaderNodeEmission')
    if socket.is_linked:
        tree.links.new(socket.links[0].from_socket, emission.inputs['Color'])
    else:
        value = socket.default_value
        emission.inputs['Color'].default_value = tuple(value) if hasattr(value, '__len__') else (value,value,value,1)
    tree.links.new(emission.outputs[0], output.inputs['Surface'])
    target = tree.nodes.new('ShaderNodeTexImage')
    target.image = image
    tree.nodes.active = target
    plane.data.materials.clear()
    plane.data.materials.append(mat)
    bpy.context.view_layer.objects.active = plane
    plane.select_set(True)
    bpy.ops.object.bake(type='EMIT', use_clear=True, margin=0)
    tree.links.new(old_link, output.inputs['Surface'])
    tree.nodes.remove(target)
    tree.nodes.remove(emission)
    image.filepath_raw = str(path)
    image.file_format = 'PNG'
    image.save()
    print('BAKED', image_name, flush=True)
    return image

for mat in mats:
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    entry = {'maps': {}, 'values': {}}
    # Cornea is a separate transparent shell; preserve it as a clear surface.
    if mat.name == 'Eyes_Cornea':
        report[mat.name] = {'cornea': True}
        continue
    for key, socket_name in [('base','Base Color'), ('roughness','Roughness'), ('metallic','Metallic'), ('alpha','Alpha')]:
        socket = bsdf.inputs[socket_name]
        if not socket.is_linked and key != 'base':
            entry['values'][key] = socket.default_value
            continue
        size = 2048 if key == 'base' and mat.name in ['ArtoriaLancer_Body','ArtoriaLancer_Head','ArtoriaBunny_Suit','ArtoriaBunny_Stockings'] else 1024
        image = bake_socket(mat, socket, key, size)
        entry['maps'][key] = Path(image.filepath_raw).name
    normal = bsdf.inputs['Normal']
    if normal.is_linked and normal.links[0].from_node.type == 'NORMAL_MAP':
        image = bake_socket(mat, normal.links[0].from_node.inputs['Color'], 'normal', 1024)
        entry['maps']['normal'] = Path(image.filepath_raw).name
    # glTF alpha is read from the base texture, not from an unrelated PNG.
    if 'alpha' in entry['maps']:
        base = bpy.data.images.load(str(dest/entry['maps']['base']), check_existing=True)
        alpha = bpy.data.images.load(str(dest/entry['maps']['alpha']), check_existing=True)
        alpha.scale(*base.size)
        pixels = np.empty(len(base.pixels), dtype=np.float32)
        opacity = np.empty(len(alpha.pixels), dtype=np.float32)
        base.pixels.foreach_get(pixels)
        alpha.pixels.foreach_get(opacity)
        pixels[3::4] = opacity[::4]
        base.pixels.foreach_set(pixels)
        base.save()
    report[mat.name] = entry
    (here/'materials.json').write_text(json.dumps(report,indent=2))
print('MATERIAL_BAKE_COMPLETE',len(report),flush=True)
