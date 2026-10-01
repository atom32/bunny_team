import bpy, json
from pathlib import Path

out = Path(__file__).resolve().parent
exec((out / 'configure.py').read_text())
rig = bpy.data.objects['ArtoriaLancer_rig']
active = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.visible_get() and not o.hide_render]
weighted = set()
objects = []
for obj in active:
    weights = {}
    for vertex in obj.data.vertices:
        for group in vertex.groups:
            name = obj.vertex_groups[group.group].name
            if group.weight > 0.00001:
                weights[name] = weights.get(name, 0) + 1
    weighted.update(weights)
    objects.append({'name': obj.name, 'weights': weights,
                    'modifiers': [{'name': m.name, 'type': m.type, 'enabled': m.show_viewport} for m in obj.modifiers],
                    'matrix': [list(row) for row in obj.matrix_world]})
materials = {}
for obj in active:
    for slot in obj.material_slots:
        mat = slot.material
        if not mat or mat.name in materials:
            continue
        def tree_data(tree):
            rows = []
            for n in tree.nodes:
                row = {'name': n.name, 'type': n.type, 'inputs': {}}
                if n.type == 'TEX_IMAGE': row['image'] = n.image.name if n.image else None
                if n.type == 'GROUP': row['group'] = n.node_tree.name
                for socket in n.inputs:
                    if socket.is_linked:
                        row['inputs'][socket.name] = [(l.from_node.name, l.from_socket.name) for l in socket.links]
                    elif hasattr(socket, 'default_value'):
                        val = socket.default_value
                        row['inputs'][socket.name] = list(val) if hasattr(val, '__len__') and not isinstance(val, str) else val
                rows.append(row)
            return rows
        materials[mat.name] = tree_data(mat.node_tree)
bone_data = {}
for name in weighted:
    bone = rig.data.bones.get(name)
    if not bone:
        continue
    bone_data[name] = {'parent': bone.parent.name if bone.parent else None,
                      'ancestors': [b.name for b in bone.parent_recursive],
                      'head': list(bone.head_local), 'tail': list(bone.tail_local),
                      'matrix': [list(row) for row in bone.matrix_local]}
(out/'runtime_inspection.json').write_text(json.dumps({'objects':objects, 'bones':bone_data, 'materials':materials}, indent=2))
print('RUNTIME_INSPECTION', len(active), len(weighted), len(bone_data), flush=True)
