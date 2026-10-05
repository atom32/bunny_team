# Compact Hideout — production integration, 2026-10-05

## Delivered
The approved 6x4m authored imported environment now replaces the exhibition shell in scripts/presentation/slice/hideout.gd. Existing Hanger remains loadout/save owner. No procedural mesh generation for the new room. Legacy presentation lights/world environment are disabled only inside Hideout; standalone Hanger/gameplay are unchanged.

Main/menu camera is inside the compact room. Operations/Workshop/Rest retain existing functional panels and callbacks. New preview instances receive the floor-level standing anchor before idle binding; equipment restores that anchor. Rest uses the sourced Sitting_Idle at a separate imported metal stool. Seat anchor (2.12,0.045,0.9); source pelvis-height transfer is unchanged. Expanded idle test verifies the imported seat, floor anchor, restore/rebind behavior and unchanged profile.

Detail pass: compact field equipment case, connected imported straight pipe/bend segments, modular electrical cable runs/outlets/switch, cold workshop and warm personal alcove, original model/rifle/toolbox/day bed. Kenney external colormap dependency retained. No new ambient audio (existing menu/Hideout music remains); fan/radio ambience is optional future polish, not part of the scene replacement.

## Provenance / protected state
Free public CC0 concrete, Kenney environment subset, Poly Haven 1K glTFs. Notices/exact download URLs/hash files retained under D:/bunny_team/assets/environment/compact_hideout/. New cables: https://polyhaven.com/a/modular_electric_cables, CC0, API MD5 verified; exported selected existing meshes with node-origin normalization only. Character/rifle retain existing project rights, not blanket CC0. Do not purchase resources or alter character assets.
All 27 files in production Artoria Bunny asset folder match pre-edit SHA256. Standing/sitting animation driver is unchanged. Existing WIP was not reset/staged/committed/pushed. Scoped prior hideout/test backup and diff under D:/bunny_team/art_source/hideout_mechanized_trial_20261005/ . Source scene changes are scoped to this new compact environment.

## Evidence
- Base integration: C:/Users/admin/AppData/Local/Temp/bunny_compact_verified_20261005, 79/79 checks / 59 scene tests, cross-process checks and quit probes PASS.
- Cable/details repaired run: C:/Users/admin/AppData/Local/Temp/bunny_compact_final_fixed_20261005, 79/79 PASS, cold0errors/2 known FBX UTF8 warnings. Last pipe bend rotation/position correction was made after this snapshot, so this is NOT the final exact-state gate.
- Current actual Forward+ menu/Overview/equipment/Operations/Workshop/Rest captures and bone-contact diagnostics: D:/bunny_team/art_source/hideout_mechanized_trial_20261005/integration_evidence/. Final capture log reports PASS, no runtime errors/warnings; frames visually inspected. Seated hip y~0.640, toe bone y~0.082 above floor; visually plausible high-heel contact, not exact mesh-level biomechanical certification.
- Final exact-state full gate PASS (79/79 checks, 59 scene tests; current runtime/source asset hashes match its manifest): C:/Users/admin/AppData/Local/Temp/bunny_compact_releasecheck_20261005. Completion audit retained in art_source/hideout_mechanized_trial_20261005/COMPLETION_AUDIT.json.

Known repair history: first baseline cold import saw an accidentally copied root project.godot in the art trial; renamed that newly-created reference file, no warning whitelist relaxation. First detail TSCN had .83 without a leading zero and failed loading; corrected to 0.83, regressions rerun. Do not present the failing runs as passes.

## Future optional polish
More coherent fixture brackets/wall composition, animated fan and sourced ambience, lower-hardware profiling and seated transition blending. No collision/navigation added: Hideout remains existing camera-driven hub, not a newly walkable level. Core game inventory/mission/upgrade/rest contracts are retained.
