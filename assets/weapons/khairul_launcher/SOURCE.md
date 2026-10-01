# Textured RPG launcher

- Author: Khairul Hidayat (khairul169).
- Source: https://opengameart.org/content/low-poly-rocket-launcher
- Download: https://opengameart.org/sites/default/files/rocket_launcher_0.zip
- Retrieved: 2026-09-29.
- Author's public listing offers the model under CC0. The archive's README separately says MIT; both notices are preserved in the source record. This project uses the author's CC0 offer.
- Original Blender model, UV texture PNGs and unmodified README: `art_source/modern_arsenal/launcher_source/`.
- Exact archive and file hashes: `download_manifest.json` in this directory.

Adaptation: convert the original diffuse textures to Principled materials, embed both maps in GLB, orient/scale the assembled RPG to 1.3 m, author hand and muzzle markers, and place it on the existing combat rig. The launcher and rocket meshes/UVs retain the source geometry. The separate projectile, explosion and barrier-damage gameplay remain project code.

```
blender --background --factory-startup --disable-autoexec --python art_source/modern_arsenal/build_launcher.py
```
