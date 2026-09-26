# Phase 4A — first reusable art batch

Baseline `main @ 955ce1f`; source of truth for scope/results: `docs/ART_ASSET_COVERAGE.md`.
No player/enemy/Terminal/weapon gameplay change, new pack download, AI or license audit.

## Reproduction

1. `inspect_sources.py`: read-only Blender source inspection.
2. `build_service_props.py`: Blender 5.2.2 fixed authoring/export, three `.blend` masters.
3. Import the normal project in Godot 4.7.2; use service-prop wrappers for material tint.
4. `run_fx_comparison.py`: real OpenGL, old/new FX at the same fixed camera/seed.
5. `run_regression.py`: 33 unchanged test scenes + main headless.
6. `run_production_routes.py`: **run alone**, normal OpenGL 1280×720 production cameras,
   automated input/API, isolated APPDATA, copied real profile. Both primary weapons + Rocket;
   Terminal, Dodge, extraction/Result/Hanger and separate-process reload. Not manual testing.
7. `prop_contract.gd`: instantiated wrapper triangles/surfaces/no collision/navigation.
8. `verify_final.py`: read-only scope/hash/budget/test/independent warehouse merge audit.

Scripts use local Godot paths and `workspace.json`; update those paths on another workstation.
Evidence saves are copies; the original production save path/hash is in `save_source.json`.
Do not write validation results into the real profile. No save-schema change.

## Visual evidence

Production-camera comparisons (new visual node hidden/shown while simulation is frozen;
not a different camera, crop or altered gameplay state):

- [Hanger before](route_Rifle/01_hanger_before_props.png) / [after](route_Rifle/01_hanger_after_props.png)
- [Office before](route_Rifle/02_entrance_before_props.png) / [after](route_Rifle/02_entrance_after_props.png)
- [Terminal still works](route_SMG/04b_terminal_interacted.png)
- [Return Hanger](route_SMG/07_return_hanger.png)
- [Trail before](fx/before_rocket_trail.png) / [after](fx/after_rocket_trail.png)
- Explosion peak/fade comparisons and trail fade also under `fx/`.

Smoke is deliberately restrained, not cinematic volumetrics. One 128² opacity texture,
2-triangle camera-facing quad, depth testing retained, no light/emission/RNG/physics added.
Existing 0.2s trail and 0.48s smoke fade/motion stay unchanged. Billboard keep-scale was
required to retain the existing growth tween; early rejected colors were too close to the
background. Final trail is visibly soft; late explosion smoke is intentionally faint and
does not obscure actors. Flash/ring/sparks are unchanged.

## Results and limitations

Final: 33/33, main exit 0, two 32-check graphical routes, two 5-check reloads and independent
warehouse merge PASS. Real AI fires/damages Player; routes do not complete all kill/survey
mission goals (0 enemies defeated), so no mission-completion claim. Combat/damage semantics
remain covered by the unchanged tests.

One earlier route run made concurrently with other renderer work timed out leaving Office
at (-16.027,23.328). Retained in `diagnostic_route_failure/`; cause not established, not
claimed repaired by art. Identical route subsequently passed alone for Rifle and SMG.
No teleport, invulnerability, collision change or gameplay workaround. Props instantiate
with zero collision/navigation nodes; their code cannot block traversal. Run graphics
acceptance alone to avoid focus/load interference, without asserting that caused the timeout.

Known non-blocking 2-instance ObjectDB cleanup warning remains in main and the small prop
probe; final route/FX logs contain no errors/warnings. Initial import log retains three
resource-before-cache errors; warm imports subsequently succeeded. No new fresh cold-import
acceptance is claimed here. Original recovered source passes all 68 manifest hashes.

Only final masters/evidence and useful reproduction scripts are committed. Local `.blend1`
backups, early color trials and temporary debug probes are retained locally, not bundled.
