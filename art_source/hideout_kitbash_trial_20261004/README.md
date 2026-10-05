# Hideout kitbash trial — 2026-10-04

## Scope
An isolated Godot 4.7 project, excluded from the main project's importer by the parent `.gdignore`. No production scenes, gameplay, saves, character assets, or existing WIP were changed. Not integrated into the game. No purchases, commits, or pushes.

## Assets and provenance
- Axel Kulomaa / AXLplosion, Modular Concrete Interior: https://axel-kulomaa.itch.io/modular-concrete-interior
  Archive downloaded from the author's OpenGameArt upload: https://opengameart.org/sites/default/files/modular_concrete_interior.zip
  Package readme licenses assets and included textures as CC0 and credits texturehaven.com / cc0textures.com. Original readme retained under source and project/concrete/LICENSE.txt.
  Actual formats: Blender + FBX, not native glTF. `convert_modules.py` exports 7 existing modules as GLB without changing geometry/UVs. Repairs stale texture paths using the included 2K maps. Other author's modules and demo room remain untouched.
- Kenney Furniture Kit: https://kenney.nl/assets/furniture-kit
  Package version notice says 2.0, unlike the webpage's older update list. CC0 notice retained. 16 original GLBs copied byte-for-byte into the trial. Their metre scale is small; 2x uniform placement scaling used for bed/desk/chair, not mesh edits.
- Poly Haven: https://polyhaven.com/a/steel_frame_shelves_01 and https://polyhaven.com/a/metal_tool_chest
  CC0: https://polyhaven.com/license . Original 1K glTF packages and dependencies downloaded through the public API. Each download checked against API MD5. Exact URLs and SHA256 in polyhaven_sources.json.
  Shelf import is 21.405m tall; explicit 0.1 uniform node scale gives 2.1405m. Tool chest is 0.652m tall; node scale 1.6 gives 1.043m.

## Scene
`project/trial.tscn`: fixed, editable node placements of imported models. 8m x 6m room, 3m ceiling, partial wall partition/doorway, workbench/stock corner and warm bed corner. `author_scene.py` writes these authored instance placements offline; there is no runtime mesh generation or procedural modeling. `placements.json` records positions/scales/rotations. `capture.gd` only controls cameras and captures two screenshots, then exits.

Reproduce:
1. Blender --background --python convert_modules.py
2. Godot --headless --path project --editor --import
3. Godot --headless --path project --script res://inspect.gd  (bounds.log)
4. Python author_scene.py
5. Godot --headless --path project --editor --import
6. Godot --path project --rendering-method forward_plus

Final actual Godot Forward+ captures: overview.png, rest.png. Logs: final_import.log and render_forward.log. Runtime exit 0. Both images visually inspected. Initial import was intentionally before trial.tscn creation and reported missing main scene; final import after creation must be used for acceptance. A first export attempt hit excluded Blender collections; exporter now links existing meshes into an export-only scene.

## Findings / limits
- Concrete shell and Poly Haven industrial props are suitable for the basement direction.
- Kenney furniture is visibly more stylized than the concrete/tool chest. This is a resource-fit test, not final art acceptance. Recommend replacing the bed/desk/chair with a coherent worn/industrial furniture set before production integration rather than hiding the mismatch with lighting.
- Workshop/rest warm-cool split, lower ceiling and doorway occlusion read more like a small occupied space than the old exhibition bays, but walls still need sourced pipes, clutter and working light fixtures.
- No current character inserted yet; standing/seated contact, camera framing with character, gameplay access, collisions/navigation, performance on lower hardware and full regression tests are NOT certified here.
- Imported wall/floor modules are thin/single-surface. Production collision and shadow/light-leak validation are required. The trial is visual-only.
- New files are confined to this trial directory. Rollback means removing only this newly-created trial, never restoring old production files or cleaning the dirty tree.
