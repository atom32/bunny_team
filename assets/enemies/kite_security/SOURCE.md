# KITE-07 autonomous security platform

Original project-local hard-surface environment/combat robot asset, authored for this task.
No downloaded character/model, branded product replica, AI input, generated character or texture.

- Master: `art_source/phase4c1/enemy_master.blend`, Blender 5.2.2 LTS.
- Reproducible authoring source: `art_source/phase4c1/build_enemy.py` (not a runtime dependency).
- Runtime: `enemy_visual.glb`; six rigid parts, six simple Principled materials, no textures/rig/collision.
- Metric, unit scale 1; Blender Z-up → GLTF Y-up, `export_yup=true`.
- Gun object origin is its bore; presentation reads the existing enemy gameplay Muzzle.
- `07` marking uses Blender's built-in font converted to mesh; no font file redistributed.
- Exact counts and SHA-256: `art_source/phase4c1/export.json`.
- Blender source contains only the approved robot collection; no camera/light exported.
- Project-original asset. Overall game release authorization is **not** granted here.
- In particular, the unchanged hidden AvatarSample_A compatibility driver remains a licensed
  runtime dependency. The drone does not resolve its public-release blocker.
