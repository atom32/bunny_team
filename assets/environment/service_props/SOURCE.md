# Phase 4A service props

Three project-authored static assemblies from the existing Kenney Space Station Kit
subset, not a new downloaded pack. Original source: https://kenney.nl/assets/space-station-kit
Author: Kenney. Existing provenance and original archive hash:
`../kenney_space_station_kit/SOURCE.md`. Existing package notice copied to `LICENSE.txt`.
No new commercial/public-release license investigation was performed in Phase 4A.

Inputs: container-flat, container-tall, computer-system, wall-switch, pipe, pipe-bend.
Original GLBs and PNG remain byte-unchanged. Exact input and output SHA-256 values:
`art_source/visual_coverage_4a/existing_prop_metrics.json` and `prop_exports.json`.

Master files: `art_source/visual_coverage_4a/{supply_stack,service_cabinet,pipe_rack}.blend`.
Blender 5.2.2 LTS; metric, unit scale 1; Z-up → glTF Y-up (`export_yup=true`).
Floor-centered origin; identity static mesh roots; front Blender -Y → glTF +Z.
Only approved meshes exported: no rig, animation, light, camera or collision.

|Asset|Triangles|Materials|Surfaces|Width/depth/height (m)|GLB bytes|
|---|---:|---:|---:|---|---:|
|supply_stack|372|3|6|1.60 / 1.35 / 1.30|47,660|
|service_cabinet|290|4|10|1.05 / 0.82 / 1.55|44,028|
|pipe_rack|408|4|19|1.60 / 0.74 / 2.10|62,736|

Each embeds the unchanged 512×512 palette PNG (7,440 bytes). No fake ORM or texture
resizing. Principled/simple materials, roughness .8–.82, low metallic/specular.
Godot also extracts each embedded image as `<asset>_colormap.png`; those three identical
PNGs and their import recipes are retained so importer references remain reproducible.
Blender preview's texture multiplier does not survive this exporter as baseColorFactor;
therefore use the presentation wrappers, not bare GLBs, for the approved appearance.
`service_prop_materials.gd` applies the recorded (.26,.30,.32) tint only to colormap
materials. No universal palette shader or player/lighting override.

Wrappers: `scenes/presentation/service_props/`. Maintenance cluster reuses all three
in the normal Hanger background and Field Office exterior. No gameplay responsibilities.
These decorations are **not cover** and must not be placed where collision is expected.
The service cabinet is scenery, NOT the interactive Terminal.

Rebuild with Blender `--background --python art_source/visual_coverage_4a/build_service_props.py`.
The one-off script reproduces these fixed assemblies only; it is not an asset factory.
Verification/evidence: `docs/ART_ASSET_COVERAGE.md` and
`art_source/visual_coverage_4a/final_validation.json`.
