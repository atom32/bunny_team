# Production integration update — 2026-10-05
The approved environment is now integrated. See D:/bunny_team/scenes/presentation/compact_hideout/INTEGRATION.md for current status and gates. The text below is the historical isolated trial record, not current integration status.

# Compact mechanized Hideout trial — 2026-10-05

## Scope / status
Isolated Godot 4.7 preview, not production integration. Only new files under this directory; parent .gdignore excludes the trial from the game importer. Earlier trial remains unchanged. No purchases, save changes, model edits, commit or push.

## Design implemented
- Fixed 6m x 4m / 24m² floor, compared with previous trial's 8m x 6m / 48m². Same 3m ceiling. 16m² main work area plus 8m² partly hidden rest alcove.
- Real imported modules and prop assets, stored as editable scene instances in project/trial.tscn. author_scene.py places fixed instances offline; no procedural modeling/runtime mesh generation.
- Replaced ordinary Kenney bed, desk, chair, rug/fridge with a worn metal office desk, metal stool, old day bed, military crates and tools. The day bed is intentionally a temporary old furniture choice, not a final military cot.
- Existing rifle on the workbench. Poly Haven toolbox, arm lamp, tool chest and steel-frame shelving.
- Separate industrial wall fixtures for workshop, entrance and rest corner; cooler task/character light and localized warm rest light. SSAO and Forward+ shadows. No fog/post-processing image edits.
- Pipe kit's whole collection initially looked like an asset display; exported original individual modules with Blender and placed a riser/overhead run instead. No geometry edits. The riser/overhead junction still needs a proper sourced bend/support brackets for final detail acceptance.
- Imported Kenney entrance panel/service panel receives isolated material-instance tint, not source/model edits. No character material changes.
- Original current Artoria Bunny GLB copied byte-for-byte, SHA256 A593BC5DD94C266CCC913698CD67C87D4BD60E99036A4AD7B731FE4B86067072. Scale 1. Standing idle uses the same Quaternius baked data/rest-space algorithm with 52 body/finger semantics. Preview-only driver has no gameplay or save dependencies.

## Sources / licenses
Inherited concrete module conversion and 16 furniture GLBs from ../hideout_kitbash_trial_20261004/project. Notices retained there and here; source/archive hashes in earlier trial.
- Axel Kulomaa / AXLplosion Modular Concrete Interior, CC0: https://axel-kulomaa.itch.io/modular-concrete-interior
- Kenney Furniture Kit and Space Station Kit, CC0: https://kenney.nl/assets/furniture-kit and https://kenney.nl/assets/space-station-kit . Existing kit provenance copied into project/kit.
- Poly Haven, CC0 https://polyhaven.com/license : metal_office_desk, metal_stool_01, old_military_crate, industrial_wall_lamp, modular_industrial_pipes_01, vintage_day_bed, desk_lamp_arm_01, metal_toolbox. 1K glTF plus original dependencies. Each public API download MD5 verified, exact URLs/SHA256 in polyhaven_sources.json. Shelf/chest provenance copied to inherited_polyhaven_sources.json. Direct asset pages use https://polyhaven.com/a/<asset_id> . Pipes exported individually, original mesh/UVs preserved; extract_pipes.py and pipes.log retained.
- Rifle reuses existing project modern_arsenal asset; existing notices retained in project/weapons. Do not label the entire project CC0: character and weapon rights follow their existing project provenance. Character/source animation notices remain in production assets and docs.

## Run / inspect
Open project/project.godot in Godot; run trial.tscn. 1 = main, 2 = spatial overview, 3 = rest. Escape exits. This is a visual preview, not a playable hub.
Capture: E:/Godot/Godot_v4.7.2-stable_win64_console.exe --path D:/bunny_team/art_source/hideout_mechanized_trial_20261005/project --rendering-method forward_plus -- --capture
Actual GPU screenshots: main.png, wide.png, rest.png. No image-generation tool or image retouching used.
Current author_scene.py + bounds.log reproduce placements. prepare/revise/polish scripts record one-time development steps, not an idempotent build pipeline; rerun the saved scene or author_scene.py, not all development scripts.

## Verification / remaining work
Final logs verified_import.log / verified_render.log: use these instead of first experimental render, which failed a body mapping assumption. Current GLB uses Character1_* names; corrected mapping records 52 semantics, scale=1. No imported model mesh/material modified.
All three final views must be visually inspected. This checks visible scale/framing only, not detailed seated contact, collision/navigation, shadows on low hardware, resource budgets or Alpha gameplay regression.
No new ambient sound yet. No connection to loadout/mission/rest UI and no production camera switch. No full gameplay tests rerun because production is untouched. Further scene pass should add coherent upright lockers, pipe bends/supports and actual cable routing, improve exposed wall composition, then integrate behind a scoped scene replacement after visual acceptance.
