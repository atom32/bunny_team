"""Export Khairul Hidayat's separate textured RPG asset (Blender background)."""
from pathlib import Path
import json
import bpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCE = HERE / "launcher_source"
OUT = ROOT / "assets/weapons/khairul_launcher"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / "rocket_launcher.blend"))
for obj in list(bpy.context.scene.objects):
    if obj.type != "MESH":
        bpy.data.objects.remove(obj, do_unlink=True)

# The source predates node materials. Retain its UVs and original diffuse maps.
for obj in bpy.context.scene.objects:
    mat = bpy.data.materials.new(obj.name.title() + "Textured")
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = .72
    shader.inputs["Metallic"].default_value = .15
    texture = mat.node_tree.nodes.new("ShaderNodeTexImage")
    texture.image = bpy.data.images.load(str(SOURCE / "tex" / (obj.name + "_diffuse.png")), check_existing=True)
    texture.image.pack()
    mat.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)

# Source -X points forward. A 1.3 m assembled launcher, rear grip as anchor.
factor = 1.30 / (3.324518 + 3.913368)
def position(x, y, z):
    return [y * factor, z * factor + .041, (x - .86) * factor - .066]

for obj in list(bpy.context.scene.objects):
    points = [obj.matrix_world @ v.co for v in obj.data.vertices]
    obj.matrix_world.identity()
    for v, p in zip(obj.data.vertices, points):
        g = position(*p)
        v.co = (g[0], -g[2], g[1])
    obj.data.update()
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=str(OUT / "rocket_launcher.glb"), export_format="GLB", use_selection=True, export_animations=False)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(HERE / "rocket_launcher_master.blend"))
markers = {
    "Muzzle": position(-3.94, 0, 0),
    "PrimaryGrip": [.028, -.0704, -.066],
    "SupportGrip": position(.025, -.14, -.74),
    "ReloadGrip": position(-1.4, -.12, .0),
}
scene = '''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/weapons/weapon_visual.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/weapons/khairul_launcher/rocket_launcher.glb" id="2"]

[node name="RocketLauncher" type="Node3D"]
script = ExtResource("1")
hand_pose = &"Rocket"
authored_grips = true
pose_offset = Vector3(0.08, 0.24, 0)

[node name="Art" type="Node3D" parent="."]

[node name="Model" parent="Art" instance=ExtResource("2")]
scale = Vector3(2.272727, 2.272727, 2.272727)

'''
for name, point in markers.items():
    scene += f'[node name="{name}" type="Marker3D" parent="."]\nposition = Vector3({", ".join(f"{v/.44:.6f}" for v in point)})\n\n'
(ROOT / "scenes/weapons/rocket_launcher.tscn").write_text(scene.rstrip() + "\n")
(HERE / "launcher_manifest.json").write_text(json.dumps({"length_m": 1.30, "markers_m": markers}, indent=2))
print("LAUNCHER_EXPORTED")
