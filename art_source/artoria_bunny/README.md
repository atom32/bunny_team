# Artoria Bunny Suit prototype derivative

Source supplied by the user: `~/Downloads/ArtoriaLancer_AllVersion_ARP_MustardUI.blend`.
SHA-256: `1fa53fe6e60a54c4243b2a8dc2b656bf2f4d3c3080fc69cbdf05c4495ccda06a`.
The original file is read with Blender automatic execution disabled and is never saved over.

This is an internal prototype visual selected by the user, not an original Neon Bastion character design or an assertion of commercial licensing. No license document accompanied the source file in the inspection. Confirm the model author's terms and underlying character rights before distributing this asset in a release. Existing Unity-Chan sources remain unchanged and supply the current locomotion clips under their recorded terms.

Reproduce with Blender 5.2.1, passing the source file before `--python`:

```sh
Blender --background --factory-startup --disable-autoexec SOURCE.blend --python art_source/artoria_bunny/inspect_runtime.py
Blender --background --factory-startup --disable-autoexec SOURCE.blend --python art_source/artoria_bunny/bake_materials.py
Blender --background --factory-startup --disable-autoexec SOURCE.blend --python art_source/artoria_bunny/export_runtime.py
```

`configure.py` selects the authored Bunny Suit, matching body fit morphs and default hair, and hides the scarf. The bake evaluates source material node graphs in UV space into PBR maps. Refraction/subsurface scattering and anisotropic hair are approximated by portable game materials; this is not a lossless Blender shader conversion. Cornea uses a transparent shell. Baked textures stay here, outside Godot's importer; the shipped GLB embeds its complete texture set.

The exporter preserves the authored body, face and outfit geometry, reduces only hair to 40% of its original triangles, merges source deformation weights onto 52 source-reference joints, keeps four normalized influences per vertex and applies the game’s -Z forward convention. No humanoid mesh is generated. This first playable derivative has no facial animation or cloth/hair simulation. Counts and the full source-to-runtime weight mapping are recorded in `export_report.json`.

`preview.gd` validates the standalone exported model. `tools/artoria_rig_probe.gd` inspects the actual player retargeting and hand IK in an isolated project copy. Passing static export is not proof of runtime animation quality; retain both checks.
