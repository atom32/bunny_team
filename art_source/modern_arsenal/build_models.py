"""Blender authoring/export for six modern firearms, from Quaternius CC0 sources.
Run with Blender --background --factory-startup --disable-autoexec --python <this file>.
Weapon GLBs are in meters; Godot wrappers compensate the existing 0.44 rig scale.
"""
from pathlib import Path
import json
import math
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUTPUT = ROOT / "assets/weapons/modern_arsenal"
OUTPUT.mkdir(parents=True, exist_ok=True)
CONFIG = {
    "assault_rifle": ("AssaultRifle_1", .88, .12, -.15, .95, .10, .60),
    "smg": ("SubmachineGun_1", .62, .05, -.20, 1.05, .10, .72),
    "pistol": ("Pistol_1", .25, .04, -.10, .04, -.20, .60),
    "shotgun": ("Shotgun_1", .93, .10, -.17, 1.08, .0, .25),
    "sniper": ("SniperRifle_1", 1.08, .12, -.30, 1.22, -.10, .10),
    "lmg": ("AssaultRifle_1", 1.02, .12, -.15, 1.10, .20, .60),
}


def material(name, color, metal=0.0, roughness=.55):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metal
    shader.inputs["Roughness"].default_value = roughness
    return mat


def box(name, location, size, mat, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("MachinedEdges", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.materials.append(mat)
    return obj


def cylinder_between(name, start, end, radius, mat):
    start, end = Vector(start), Vector(end)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=(end-start).length, location=(start+end)*.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = (end-start).to_track_quat("Z", "Y").to_euler()
    obj.data.materials.append(mat)
    return obj


records = []
for key, config in CONFIG.items():
    source, length, grip_x, grip_z, support_x, support_z, bore_z = config
    bpy.ops.wm.open_mainfile(filepath=str(HERE / "sources" / (source + ".blend")))
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)
    steel = material("ParkerizedSteel", (.075, .085, .095), .7, .39)
    polymer = material("GraphitePolymer", (.035, .042, .049), .0, .72)
    tan = material("FieldPolymer", (.24, .205, .145), .0, .74)
    edge = material("SteelEdges", (.16, .175, .19), .8, .3)
    glass = material("OpticGlass", (.018, .055, .065), .45, .14)
    for obj in bpy.context.scene.objects:
        for slot in obj.material_slots:
            old_name = slot.material.name.lower() if slot.material else ""
            slot.material = glass if "glass" in old_name else (tan if any(n in old_name for n in ["wood", "green"]) else (edge if "lightmetal" in old_name else (polymer if "black" in old_name else steel)))
    if key in {"assault_rifle", "smg", "lmg"}:
        # The selected base variants have no shoulder stock; author a telescopic stock.
        cylinder_between("StockTube", (-1.05, 0, .40), (.0, 0, .40), .08, steel)
        box("StockCheek", (-.82, 0, .38), (.65, .25, .27), tan if key == "assault_rifle" else polymer)
        box("StockButt", (-1.13, 0, .27), (.16, .30, .65), polymer)
        box("StockBrace", (-.61, 0, .18), (.50, .12, .10), steel)
    if key == "lmg":
        box("AmmunitionBox", (.96, 0, -.35), (.88, .65, .83), tan)
        box("BoxLatch", (.98, -.34, -.12), (.22, .045, .12), steel, .01)
        cylinder_between("HeavyBarrel", (2.70, 0, bore_z), (3.80, 0, bore_z), .085, steel)
        cylinder_between("MuzzleBrake", (3.70, 0, bore_z), (3.95, 0, bore_z), .12, polymer)
        for side in [-1, 1]:
            cylinder_between("FoldedBipod", (3.15, side*.12, bore_z-.10), (2.0, side*.26, bore_z-.28), .032, steel)
            box("BipodFoot", (2.0, side*.26, bore_z-.28), (.12, .12, .05), polymer, .01)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    points = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    minimum = min(v.x for v in points)
    maximum = max(v.x for v in points)
    factor = length / (maximum-minimum)
    offset_y = -.0704 - grip_z * factor

    def godot_position(x, y, z):
        return [y * factor, z * factor + offset_y, -(x-grip_x) * factor - .066]

    # Bake source +X forward / +Z up into Blender +Y forward / +Z up.
    # glTF's Y-up export then gives Godot -Z forward / +Y up.
    for obj in meshes:
        coords = [obj.matrix_world @ v.co for v in obj.data.vertices]
        obj.matrix_world.identity()
        for vertex, coord in zip(obj.data.vertices, coords):
            g = godot_position(*coord)
            vertex.co = (g[0], -g[2], g[1])
        obj.data.update()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    model = bpy.context.object
    model.name = key.title().replace("_", "") + "Model"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT / (key + ".glb")), export_format="GLB", use_selection=True, export_animations=False, export_yup=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE / (key + "_master.blend")))
    primary = [.0308, -.0704, -.066]
    support = godot_position(support_x, -.14, support_z)
    if key == "pistol":
        support = [-.020, -.083, -.075]
    muzzle = godot_position(maximum, 0, bore_z)
    reload_grip = [0, -.17, -.14] if key != "pistol" else [0, -.16, -.066]
    markers = {"Muzzle": muzzle, "PrimaryGrip": primary, "SupportGrip": support, "ReloadGrip": reload_grip}
    scene = '[gd_scene load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://scripts/weapons/weapon_visual.gd" id="1"]\n'
    scene += f'[ext_resource type="PackedScene" path="res://assets/weapons/modern_arsenal/{key}.glb" id="2"]\n\n'
    scene += f'[node name="{key.title().replace("_", "")}" type="Node3D"]\nscript = ExtResource("1")\nhand_pose = &"Rifle"\nauthored_grips = true\n\n'
    scene += '[node name="Art" type="Node3D" parent="."]\n\n[node name="Model" parent="Art" instance=ExtResource("2")]\nscale = Vector3(2.272727, 2.272727, 2.272727)\n\n'
    for name, point in markers.items():
        values = ", ".join(f"{v/.44:.6f}" for v in point)
        scene += f'[node name="{name}" type="Marker3D" parent="."]\nposition = Vector3({values})\n\n'
    (ROOT / "scenes/weapons" / (key + ".tscn")).write_text(scene.rstrip() + "\n")
    model.data.calc_loop_triangles()
    records.append({"weapon": key, "source": source + ".blend", "length_m": length, "triangles": len(model.data.loop_triangles), "surfaces": len(set(p.material_index for p in model.data.polygons)), "markers_m": markers})
(HERE / "model_manifest.json").write_text(json.dumps(records, indent=2))
print("MODERN_ARSENAL_EXPORTED", json.dumps(records))
