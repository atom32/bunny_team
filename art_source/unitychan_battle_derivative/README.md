# Unity-Chan Battle Costume — production presentation source

> **Current checkpoint (2026-09-27):** Phase 5 `bc4984b`, Godot 4.7.2.
> Player = production Unity-Chan (Phase 3D + Phase 4B fidelity); Enemy = native
> KITE-07, no legacy humanoid dependency (Phase 4E). Phase 5 validation: 33/33,
> two automated graphical routes 64/64 each, cross-process save/load PASS.
> See `Handoff.md` and `docs/DEVELOPMENT_SETUP.md` for current setup/verification.
> The reports below are **historical**, not instructions to repeat old gates or
> replace current assets. Local screenshots, trial scripts and profile copies
> referenced by historical reports may deliberately be absent from Git.

## Portable master / proportion check — 2026-09-27

`battle_master.blend` retains authored poses/material metadata. Four unpacked PNG
references now use the correct sibling-relative `//../unitychan_battle_legacy/...`
path; no pixels, mesh, bones, actions or runtime GLB changed. Geometry/rig/actions
fingerprint before/after: `5b634b02c3fe19b70323717e204bd7d46a65b6f8b593c6de308d11cb1364bf38`.
Evidence: `master_portability.json`; source-to-runtime leg measurements and method:
`docs/CHARACTER_PROPORTION_CHECK.md`. Official source remains immutable.

## Historical Phase 3B record

### Phase 3B — Demo Presentation Candidate — PASS

Current result (2026-09-26): **Unity-Chan Battle Costume is a Demo Presentation Candidate.**
It is **not production-ready**, not installed as the production player, and not commercial
release clearance. © Unity Technologies Japan / UCL; retained license/credit assets apply.
This section records Phase 3B only; later 3D/4B production results supersede it.

## Material correction

Face/skin and hair now use a small derivative Godot material response, while retaining
original base color, source textures and existing scene lighting. Standard specular removal
and built-in toon mode alone did not resolve clipping; direct albedo darkening was rejected
because Field Office shadows became gray/dark. `phase3b/MATERIAL_LOG.md` records the trials.

Accepted response: bounded per-light diffuse irradiance, gain **0.2**, broad smooth normal
ramp with floor **0.25**, ambient/shadow attenuation preserved, specular disabled. No emission,
new lights, exposure changes, camera-dependent effects, fake hair albedo or UTS shade/grade
maps mislabeled as ORM. Three pale materials use this response; two costume materials remain
StandardMaterial3D. This is a limited anime-compatible approximation, not a Unity UTS port.

Face: **PASS** — eyes/features and warm skin tones remain readable rather than a white patch;
not flattened to gray or unshaded. Hair: **PASS** — blond color blocks/highlight detail recover
in Hanger and Field Office. Costume white/cyan accents remain bright by design; no whole-game
recolor or material polishing beyond the requested scope.

Editable source: `battle_master.blend` has named material custom properties
`godot_direct_response_gain`, `godot_diffuse_shadow_floor`, and shader reference. Run
`phase3b/author_material_profile.py` with Blender 5.2.2 to export `material_profile.json`;
existing authored values are preserved. Principled nodes remain the source-color fallback
preview, **not** claimed to reproduce the Godot light shader. The GLB remains byte-identical
geometry/base-material data; the isolated Presentation Adapter applies the runtime shader.

## Equipment / Hanger / Field Office

Equipment: **PASS**. The main occluder was the backpack in front of the chest: Unity-chan's
torso-bone local X/Z oppose the old equipment frame. A one-time local Y 180° correction of
**Chest and Backpack only** rotates their offsets and visual bases. Master custom property
`GodotEquipmentFrameCorrection` exports to `mount_profile.json`. No mesh rebuild, rig edits,
collision, weapon socket, IK target or gameplay semantics changed. Backpack is now behind
the body and torso/arms are readable. Minor hair/pack contact remains acceptable.

Hanger: **PASS**, original production camera/lighting/scale retained. Full body, face/hair,
weapon and equipment reviewed; supplementary front/back/side images are explicitly diagnostic
views, not a replacement production camera. Original shoulder costume and hip accessories
remain attached. Empty optional equipment sockets were not arbitrarily moved.

Field Office: **PASS automated graphics/API, not manual acceptance**. Existing scale/floor
contact/silhouette preserved; Rifle+Rocket and SMG+Rocket normal-AI routes verify movement,
Q switching, firing/reload, Terminal E objective completion, exit, extraction and Result.
The final paired capture run also completed successfully. Extraction is successful while
other mission objectives may remain incomplete; this is not a full-mission-clear claim.
Top-down face details are naturally small; close diagnostics supplement material inspection,
not evidence of a changed production camera.

## Matched visual evidence

Frozen same pose, environment, weapon and production camera; no exposure changes. Probe
asserts unchanged camera/player/body transforms and restores candidate before normal play.

| View | Before | After |
|---|---|---|
| Hanger full body | [Before](phase3b/final_comparison/hanger_before.png) | [After](phase3b/final_comparison/hanger_after.png) |
| Hanger face/hair crop | [Before](phase3b/final_comparison/hanger_before_detail.png) | [After](phase3b/final_comparison/hanger_after_detail.png) |
| Field Office | [Before](phase3b/final_comparison/office_before.png) | [After](phase3b/final_comparison/office_after.png) |

Material-only diagnostic close views: `phase3b/office_material_trials/office_diagnostic_before.png`
and `office_diagnostic_soft_response.png`. Equipment-only pairs: `equipment_before/` and
`equipment_after/` front/back/side. `final_comparison/*_pair.json` records camera/pose data.

## Performance (recorded, not optimized)

- Character: **37,359 triangles / 328 bones / 5 materials / 4 base textures**, unchanged.
- Textures: three 2048² + one 1024²; RGBA8 with full mips estimate **69.33 MiB**. This is not
  a measured character-only allocation and compression may differ.
- Whole Hanger, production 1280×720, RTX 5090, OpenGL Compatibility: **227 median draw calls**,
  129,245 median rendered primitives (includes scene/shadow passes, not character polygon count).
- Three-second warm-up then three-second sampling: **1.06 ms median wall-frame interval**;
  CPU process monitor median **1.704 ms**. These are different measurements, **not GPU timing**,
  target-device performance guarantees or a measured before/after speedup.
- Whole-Hanger renderer accounting: textures ~79.57 MiB; video memory ~98.31 MiB.
  `phase3b/performance.json` and raw samples retain scope and ranges. Earlier short-sample
  startup CPU value is superseded, not used as steady-state performance.

## Regression / integrity

**32/33** unchanged tests. Sole failure: `ACCEPTANCE_SMOKE: avatar keeps its complete authored
face mesh` (legacy Face/name/size assertion). No fake Face node, dimension change or test edit.
PRESENTATION_GAMEPLAY, VISUAL_SLICE_ASSETS, WORLD_TRAVERSAL, weapon switching and RESULT_RETURN
PASS; main headless exit **0**. Known ObjectDB exit warnings remain; not warning-free.

Initial fresh isolated cold import: 0 errors / 0 warnings. Final shader/adapter loads compile
and relevant tests complete without new errors. Initial SMG graphical route timed out during
a concurrent-window probe; original failure kept in `route_SMG_initial_timeout/`. A solo
fresh-profile replay passed without changing route/gameplay code. Focus interference is
consistent with the evidence, not conclusively proven; graphical acceptance now runs serially.

`phase3b/final_integrity.json`: **68/68 official asset/meta hashes unchanged**, all outside-
derivative snapshot files unchanged, scripts/scenes/tests diff empty. Master metadata-only
save/reload preserves geometry, weights, rest skeleton, posed matrices and animation channel
fingerprint. GLB unchanged. No weapon pose reauthoring, bone rename/rebind or state-machine edit.
Gameplay unchanged. Production player unchanged. Official Unity-Chan source unchanged.
Tests not weakened. No fake legacy nodes. No production replacement.

## Git / files / limits

HEAD remains **main @ ec5f18dbe81164f43c1613a8ab678f4e3c51bed9**. Phase3B changes are only:
- `battle_master.blend`: presentation metadata (materials and two equipment frames).
- `phase3b/`: shader/profile/adapter, authoring and isolated probes, logs/screenshots/audits.
- This README.

Existing importer/migration/user WIP outside derivative is preserved, not reverted or
included. Inspected `project.godot` diff only changes feature level 4.6→4.7. Existing import
diffs include mesh dedup/default importer fields and VRAM/normal/roughness detection settings;
these are meaningful source settings, not discarded cache. `phase3b/import_config.diff`
retains evidence. No new importer/project edits by Phase3B. `.godot` remains generated cache.
No Phase3B commit/push performed (not requested in this objective). This is not a clean-clone
migration checkpoint; isolated reproduction still requires the previously documented WIP
migration/source recovery dependencies.

Known accepted issues: imperfect static grips, minor hand/finger/clothing contact, some
bright costume accents, bulky existing gear, and late full-source Rocket Dodge deformation
outside the currently reached gameplay interval. No animation polish or Terminal work.
Next phase may separately decide production promotion; this phase stops at Demo candidate.

Reproduction on this workstation: run `phase3b/stage.py`, then `phase3b/stage_adapter.py`;
run `run_regression.py`, `run_routes.py`, and `run_final_captures.py` sequentially. Do not run
multiple graphical probes concurrently. Keep official recovery and the derivative License
folder intact. `phase3b/completion_audit.json` maps every Phase3B requirement to evidence.

---

# Historical phase reports

# Phase 3A.3 — Final integration validation (2026-09-26)

**Presentation spike: PASS / USABLE for the internal Demo.** Not a production-player
replacement or commercial-release clearance. Static hand poses are manually authored,
not official Unity-Chan weapon animations. This section supersedes earlier phase status;
the historical reports below remain evidence of rejected attempts, not current results.

## Animation × weapon result matrix

| Existing state | Rifle | SMG | Rocket |
|---|---|---|---|
| Idle_Gun | USABLE | USABLE | USABLE |
| Walk | USABLE | USABLE | USABLE |
| Run | USABLE | USABLE | USABLE |
| Run_Shoot | USABLE | USABLE | USABLE |
| Dodge (actual state machine) | USABLE | USABLE | USABLE |
| Reload | USABLE | USABLE* | USABLE* |
| Recoil | USABLE | USABLE | USABLE |
| Hit | USABLE | USABLE | USABLE |

`phase3a3/animation_review.json` contains 24 explicit classifications, measurement
summaries and screenshot paths. Full-resolution stills and strips: `phase3a3/animation/`.
The reviewed captures show coherent weapons, attached limbs/clothing/hair and recovery;
accepted finger/wrist artifacts remain. No new animation clips/state transitions authored.
Run_Shoot includes existing visual recoil triggers, not just the Run clip.

*SMG/Rocket retain existing socket-path reload behavior: ammo/session reload succeeds,
weapon stays visible and stable, but no dedicated hand reload gesture starts. This is not
claimed to be a newly implemented or polished reload animation. Rifle uses the existing
support-to-ReloadGrip trajectory. Real session reload is separately verified in both routes.

Dodge acceptance is specifically the existing playable state: front/rear input-driven
captures in `live_dodge/` and `live_dodge_front/`; observed source play position ends at
0.116667 s, then returns to Idle/unit body scale. Rifle support sliding peaks at 5.323 cm
at entry and settles (P2); primary hand remains attached. Rocket's **full 1.45 s source
clip stress** still has head/launcher overlap around 0.48 s. That playback is not approved
for reuse: the current unmodified state machine never reaches that segment in the probe.
No animation shortening or gameplay timing edits were used to obtain this result.

## Adapter / switching / IK

`presentation_adapter.gd` and `hand_modifier.gd` are isolated presentation subclasses.
They consume `runtime_poses.json` exported from the existing Blender master actions.
Original reload/recoil/has_weapon behavior is retained. No static-pose polishing occurred.
The targeted integration fix was caching the unadapted weapon pose in **parent-local**
space instead of world space. This preserves inherited socket recoil rather than cancelling
it; Rocket recoil target drift fell from ~10.64 cm to ~0.000000207 m. Before/after evidence
is retained. No global weapon transform/definition changed.

`switching.json`: both requested sequences repeated five times, 45 checks, zero failures;
correct pose selected, no cumulative >1 cm position or >.03 rad orientation drift, no stale
reload state. These are Hanger equip presentation API checks, not fictitious three-slot
combat. Real Q switching is tested in valid Rifle+Rocket and SMG+Rocket loadouts. No
catastrophic IK snapping, target-side confusion, persistent inversion or detachment was
observed in reviewed captures. Numeric target convergence alone was not acceptance.

## Hanger / Field Office

Hanger: **USABLE**, normal camera/scale, idle, equipment and weapon switching. Known face/
hair over-brightness and bulky equipment occlusion remain. No new shader/material polish.
Evidence: `switch_Rifle.png`, `switch_SMG.png`, `switch_Rocket.png`, and both route Hanger
screenshots. Equipment remains attached, not artistically final.

Field Office: **PASS automated graphical route, not manual acceptance**. Both loadouts
use normal AI/health/collision and production 1280×720 camera; no teleport/invulnerability.
Existing Hanger deploy → Field Office door → interior → four real Q switches/fire/reload
→ Terminal E (objective COMPLETED asserted) → exit → extraction → Result. Actual project
order is Hanger deploy before Field Office, not a newly invented Terminal sortie system.
`route_Rifle/route_result.json`, `route_SMG/route_result.json`, logs and screenshots prove
these checks. `04b_terminal_interacted.png` and `06_result.png` show completion of Access
Field Terminal. **Extraction successful, mission incomplete**: enemy-elimination/survey
objectives were not completed. No claim of a full mission clear or combat-balance test.
Top-down doorway/prop and explosion occlusion remain the existing presentation limitation;
close rig views provide the hand/arm inspection that this distant camera cannot establish.

## Tests / invariants

- Fresh isolated cold import: exit 0, **0 ERROR / 0 WARNING** (`workspace.json`, import log).
- Existing suites: **32/33**; sole failure is unchanged acceptance_smoke Face mesh/name/size
  assertion. No fake Face node or weakened expected dimensions. This is explicitly allowed
  as the legacy-character integration-gate mismatch, not reported as 33/33.
- PRESENTATION_GAMEPLAY, WORLD_TRAVERSAL, VISUAL_SLICE_ASSETS, weapon_switching and
  RESULT_RETURN: PASS. Main: exit 0. `regression/results.json` includes all exit/error data.
- ObjectDB cleanup warnings remain in some runs; **not warning-free**.
- `final_integrity.json`: 68 official asset/meta hashes unchanged; all source snapshot
  files unchanged; master hash matches exported poses; production scripts/scenes/tests diff
  empty. Master retains 3 poses / 328 bones. Derivative GLB unchanged.
- Gameplay unchanged. Production player unchanged. Official source unchanged.
  Tests not weakened. No fake legacy nodes. No main-project replacement.

## Changed files / Git / reproduction boundary

Phase3A.3 work is `phase3a3/` plus this README: pose exporter/data, two presentation scripts,
isolated staging, animation/switch/live-Dodge/route probes, regression runner, evidence and
audit. Previous isolated master/GLB/license/phase3A–3A2 artifacts are prerequisites, not a
new production integration. Git baseline: main @ c4ca114e732ff8508370928dd5d16e04d838a6a0.

User/editor WIP outside derivative is preserved and excluded from this phase's publishing
scope. `project.godot` feature 4.6→4.7 and importer changes are recorded in
`phase3a3/import_config.diff`, not reverted. This is **not a complete migration checkpoint**.
The tests ran against the recorded migrated WIP snapshot (`source_manifest.json`), not a
clean c4ca114 checkout. A clean clone needs the separately pending migration/source-recovery
work before `stage.py` / master rebuilding can reproduce that snapshot. Do not claim clean-
clone cold-import acceptance from this scoped derivative commit. GLB itself is self-contained;
master source textures require adjacent recovered official_1_1 with matching hashes.

Publishing: scoped derivative commit `003751478c953fbcaabefedc22ab59e85a4d1cb8` pushed to `origin/main`
and remote hash verified (`phase3a3/publish_receipt.json`). No production promotion is
included. Internal Demo usability is accepted, final art quality and full source Dodge
clip reuse are not. Stop here: no Terminal, enemy, material redesign or gameplay expansion.

---

# Historical phase reports (superseded where noted above)

# Phase 3A — Unity-chan Battle Costume Presentation Spike

**Decision: BLOCKED — not approved for default-player replacement.**
Personal demo only; not commercial release clearance. No Unity endorsement.

© Unity Technologies Japan

Unity-chan / UCL — © Unity Technologies Japan/UCL

Full UCL 3.0 documents and logo assets: `License/`. Preserve them with distribution.
No AI image-generation input or training. Future commercial release needs a new audit.

## Artifacts and reproduction

- `battle_master.blend`: Blender 5.2.2 LTS authoring master, relative source-texture
  paths into the adjacent unchanged `unitychan_battle_legacy/official_1_1/` folder.
- `battle_presentation.glb`: self-contained experimental derivative, NOT installed
  under live `assets/`. Its `.import` is a staging template for the isolated test path.
- `build.py`, `build_report.json`, `PREFAB_MAPPING.md`: reproducible mapping/export.
- `validate.py`: fresh external WIP snapshot, one player preload-path substitution,
  cold import, unchanged 33 tests, headless main and optional real graphics probes.
- `evidence/`: test logs, failures, measured grip errors and 1280x720 screenshots.

```powershell
& 'F:/SteamLibrary/steamapps/common/Blender/blender.exe' --background --factory-startup `
  --python-exit-code 1 --python D:/bunny_team/art_source/unitychan_battle_derivative/build.py
python D:/bunny_team/art_source/unitychan_battle_derivative/validate.py `
  --output C:/Users/admin/AppData/Local/Temp/bunny_phase3a_NEW --route
```

Validation is expected to return failure until the blockers below are resolved.
Do not copy the test override into the live project. Entire directory is `.gdignore`d.

## Provenance / source integrity

Official Unity Technologies Japan Battle Costume Humanoid 1.1:
https://unity3d.jp/unity-chan_contents/releaseNote.php?id=TPK-Hmnd-Kohaku_A&lang=en

No downloads or searches in this phase. All 34 official asset hashes and 34 original
meta hashes still match recovery_manifest.json. User handoff contained transcription
errors; verified values are:

- Archive: `12f1365e5e2eb82e2a0e3ddb5d105c690518a8404a1c33fb0027800436096c2c`.
- Main FBX: `146f9846b95ba57a726e74ba3da63dfac8774f34db85e46d09d01e5ac8bb4478`.
- Final GLB: `32e030e3aa4dea44f699bd7ce260a87c6ea9d5f4c0ea4c5eaedd6e823a335e0f`.

Final rebuilt GLB is byte-identical to the tested copy. Original FBX, PSD references,
Unity meta, PNGs, materials and shader are untouched. No skeleton rest reset/rebind.

## Prefab reconstruction

The earlier recovery counted 24 skinned renderers, but the full prefab also contains
one static MeshRenderer/MeshFilter for the nose. Both are now mapped: 25 renderers,
then exclude only the bundled melee weapon, yielding 24 derivative meshes.
Unity file IDs, not GameObject names alone, identify the correct FBX mesh; some
prefab object names differ from the mesh they actually reference.

- Main body retained with original skin weights and all 328 character bones.
- Separate `head_Def` FBX and static `headNose` follow Character1_Head. Their rigid
  parent relationship is represented as one-bone weights for the GLB, not a new rig.
- Bundled melee weapon and its separate 11-bone rig omitted from the derivative;
  original source remains intact. Existing AR/SMG/Rocket presentation is reused.
- 37,359 triangles; 24 meshes; five used materials; four embedded base-color PNGs;
  328 bones; zero bundled animations. Existing animation sources provide motion.
- Approximate rest dimensions: 0.961 x 0.748 x 1.467 m in Blender XYZ; no rescaling
  to satisfy tests. Godot height approximately 1.467 m. Floor rest minimum -0.001916 m.

## Materials / normalization

Principled approximation only, NOT UTS parity. Base maps remain original resolution
and sRGB; no texture downsampling. Hair uses official base color, not the grayscale
grade map. Roughness 0.8 and metallic 0 are explicit derivative choices. Shade/grade/
specular maps remain source evidence, never mapped as roughness/metallic/ORM. No
emission from the stale inactive weapon material field. Unity shader is not ported.

Metric / unit scale 1; standard Blender Z-up to glTF Y-up export. FBX object-level
centimeter scale initially caused 100x bones after Godot reparented Skeleton3D.
Applying derivative object rotation/scale fixed this, without resetting rest poses.
An observed backward-facing first pass led to an explicit 180-degree heading
normalization; this is not an extra -90-degree coordinate correction.

Normalization checks (before/after applying object transforms, AFTER heading choice):
max bone-position error 2.403e-7 m, bone-rotation error 0 rad, max vertex-position
error 1.308e-7 m. This proves normalization stability, NOT final deformation parity
with Unity. Historical multiple-bind-pose behavior still requires targeted review.

## Existing contracts / isolated test

No production script, scene, weapon definition or config changed. In the isolated
copy only, the player CHARACTER_SCENE preload points to the new GLB. Existing
Character1_* names work without renaming original bones; CombatAvatarModel,
CharacterRetarget and AnimationTree remain intact. Enemy retains old VRM.

All eight mounts exist. Existing conventions retained:
Chest/Backpack/ShoulderR/HandR -> Spine2; ShoulderL -> LeftShoulder;
HipL/HipR -> Hips; HandL -> LeftHand (all Character1_ prefixed).
HandR is historically a fixed torso socket, not an instruction to move it to the
wrist. Existing AR combat mount and weapon markers are unchanged.

Idle_Gun, Walk, Run, Run_Shoot, Dodge are available. Recoil/Reload/Hit remain existing
presentation logic, not new source animation clips. Automated contract tests do not
establish that all garment/hair deformation looks correct at every animation frame.

## Validation results — final isolated derivative

| Gate | Result |
|---|---|
| Fresh cold import | PASS: exit 0, 0 ERROR, 0 WARNING |
| ALL TESTS | **32/33 PASS, one FAIL** |
| ACCEPTANCE_SMOKE | FAIL: old Face-node / >0.2 m face-height assertion |
| MAIN HEADLESS | PASS: exit 0; 2 ObjectDB exit warning |
| VISUAL_SLICE_ASSETS_TEST | PASS |
| WORLD_TRAVERSAL_TEST | PASS |
| PRESENTATION_GAMEPLAY_TEST | PASS |
| Weapon switching / behavior suites | PASS |
| Graphical Field Office route | PASS: entry/interior/terminal/exit/extraction/Result |
| Extra all-weapon grip acceptance | **FAIL: Rocket left hand ~0.120 m** |
| Final visual acceptance | **NOT ACCEPTED** |

The smoke test expects the previous avatar's named `Face` mesh; it was not renamed,
scaled or removed merely to force a PASS. A reviewed model-independent face contract
is needed before accepting a formal replacement. This failure must remain visible.

AR/SMG two-hand errors in the Hanger sample are below 0.000001 m. Rocket right hand
also converges, but left hand misses by approximately 12 cm. Original measurement-only
probe printed PASS for collection; **grip_acceptance.log (exit 1) supersedes that label**.
Raw measurement, strict probe, and both logs retained; no claim all-weapon IK passed.

Real OpenGL 3.3 / RTX 5090, production camera 1280x720; scripted input/API, NOT human
manual testing. Route retained normal AI, damage and collision: 60 shots, 3 damage,
0 kills, terminal completed, early extraction/Result; not full-mission completion.
Screenshots were inspected: Hanger face/hair overexposed, gear obscures torso/face;
interior camera occlusion limits character judgment. Visual/garment acceptance and
before/after performance remain NOT VERIFIED. No 20–30 s video was produced.

## Failed attempts retained, not hidden

- Missing GLB import sidecar caused early preload parse errors in fresh scan.
- Default embedded-image extraction caused four PNG reimport failures. Staging
  template now uses embedded uncompressed textures (mode 3); fresh copy passed 0/0.
  No old .godot cache copied. Compression/VRAM optimization is deferred.
- Old route probe used door hinge x=-17.1, close to wall/capsule overlap, and blocked.
  Test-only waypoints now cross opening center x=-16.0 (door leaf center). Map,
  gameplay routes and collision unchanged; corrected route passed. Failure log retained.
- Initial normalization guard compared scaled basis matrices rather than world
  rotations; corrected to world position/rotation checks. Rigid-nose double-parent
  transform failed the vertex guard and was corrected before export.
- ObjectDB cleanup warnings in several isolated suites are recorded in results.json;
  do not call the full run warning-free or automatically classify all as historical.

## Next bounded work

1. Presentation-only Rocket support-grip/pole/pose calibration; no WeaponDefinition
   semantics, ammo, fire rate, damage, movement or collision changes.
2. Controlled anime material response and orientation/garment deformation review in
   existing production cameras. Do not fix these by changing Hanger/Field Office art.
3. Review the old avatar-specific face assertion, introduce an explicit presentation
   adapter contract, then rerun strict grip checks, all 33 suites and graphical route.
4. Only after those gates pass consider a separately approved default-player switch.

Current main branch remains c4ca114 with prior WIP preserved, no commit or reset.


## Phase 3A.1 — Static diagnostic checkpoint (2026-09-26): BLOCKED

This is **not a completed pose correction** and does not authorize player replacement.
Gate A remains unaccepted. Gates B–F were deliberately not entered. The earlier
“Next bounded work” above is superseded by static grasp authoring first; do not start
with animation, material work, smoke assertion changes, or global weapon transforms.

### Exact changes and reproduction

Only this README and `phase3a1/` diagnostic files were changed in this phase:

- `inspect_weapons.py`: Blender inspection of original three weapon GLBs; applies
  existing wrapper model transforms and the existing 0.44 presentation scale.
  It reads grip markers from the wrappers; wrapper transform constants are a snapshot,
  not a general-purpose importer. Outputs `weapon_geometry.json` / `.log`.
- `poses.json`: explicit `Pose_Rifle`, `Pose_SMG`, `Pose_Rocket` diagnostic configurations.
  Rifle retains the neutral existing preview origin. SMG uses a compact-height candidate;
  Rocket uses a shoulder-side candidate. **The latter two are rejected/unaccepted
  placements, not finished authored poses or an adapter shipped to gameplay.**
- `static_probe.gd` / `run_static.ps1`: instantiate the derivative directly, original
  weapon wrappers and TwoBoneIK3D, with no player, AnimationTree or clip playback.
  Targets come from unchanged PrimaryGrip / SupportGrip; poles are relative to the
  neutral shoulder, not gameplay hardcoded hand targets. No rest-pose or skin rebinding.
- `Pose_Rifle.png`, `Pose_SMG.png`, `Pose_Rocket.png`: actual OpenGL RTX 5090,
  1280x720, identical orthographic 3/4 camera (2.1,1.75,-3.2), size 2.1,
  looking at (0,0.85,-0.06). Diagnostic lighting, **not production camera acceptance**.
- `static_measurements.json`, `static.log`, `scope_verification.json`: current evidence.
- Failed `initial_parse_failure.log` retained. `invalid_post_modifier_measurements.json`
  is **INVALID**: it read restored bones after modifier execution. Corrected sampling
  uses `Skeleton3D.skeleton_updated` while modified poses are available. Those invalid
  distances must not be interpreted as retarget drift.

Run `phase3a1/run_static.ps1 -IsolatedProject <Phase3A-validation-copy>/project`.
The probe uses the prior warm-imported isolated project, NOT a fresh cold import.
Final exit **1** means Gate A blocked, even though evidence collection completed.
There were no ERROR / SCRIPT ERROR lines in the final diagnostic log.
The `.blend`, exported GLB and production runtime were not changed.

### Measurements (meters, modified wrist bone to existing marker)

| Configuration | PrimaryGrip → HandR | SupportGrip → HandL | Muzzle axis error | Static visual |
|---|---:|---:|---:|---|
| Rifle reference | 0.000000148 | 0.000000037 | 0 degrees | NOT ACCEPTED |
| SMG candidate | 0.000000061 | 0.000000098 | 0 degrees | NOT ACCEPTED |
| Rocket rejected candidate | 0.000000084 | 0.000000020 | 0 degrees | FAIL |

These values measure **wrist origins**, not palms, finger contact, or anatomical grip.
Muzzle error is marker -Z against intended -Z, not ballistic or bore geometry validation.
Both arms are approximately 0.378 m long in the neutral skeleton. All candidate wrist
positions are within this mathematical reach; that is not sufficient for plausible arms.
The old animation-driven Rocket 0.1195 m error remains historical, not “fixed” by this
static diagnostic. No claim of maintained contact during firing or locomotion is made.

### Actual mesh and visual findings

At unchanged wrapper scale, nearest marker-to-mesh distances are:

| Weapon | Primary to nearest surface | Support to nearest surface |
|---|---:|---:|
| Rifle | 0.03114 m | 0.01078 m |
| SMG | 0.01467 m | 0.00371 m |
| Rocket | 0.03765 m | 0.02407 m |

Surface distances are geometry diagnostics, not proof that markers should be moved.
A wrist is not a skin contact point. SMG shares Rifle marker coordinates despite its
shorter mesh; a dedicated palm frame / finger grasp still needs authoring.

Screenshots were inspected. Rifle and SMG wrists reach markers, but fingers/palms do
not establish verified wrap/contact: open fingers and unsupported hand appearance remain.
No current configuration authors the wrist grasp frame or finger closure. Thus even the
numerically passing Rifle reference has not passed this stricter static visual gate.

Rocket is a bulky four-tube launcher, not a slender shoulder tube: its transformed
bounds span approximately 0.340 x 0.463 x 0.665 m. The tested shoulder-side placement
puts the right grip behind the torso (target z=+0.2784 m) and produces an unacceptable
rear-reaching/open-hand posture; the launcher heavily obscures the upper body in this
view. **Reject this placement.** The screenshot is not sufficient to establish exact
skin/weapon triangle intersection; intersection status is NOT VERIFIED for all three.
It is not proof that every presentation-only Rocket solution is impossible.

### Deferred work / concrete blocker

The missing artifact is an anatomically authored per-weapon **palm/wrist orientation
and finger-contact definition** tied to actual handle geometry, plus a believable Rocket
body/shoulder placement. Positional IK alone cannot supply it. No blind bone rotations,
arbitrary per-frame animation offsets, or global grip edits were used to manufacture PASS.
The requested deterministic accepted presentation contract is therefore **unfinished**.

Next: author/inspect these hand frames and contact shapes in the isolated master,
keep markers and original wrappers intact, and rerun this static gate with close-up and
opposite-side views before proceeding. If Rocket cannot satisfy this within the existing
contract, stop for a presentation design decision rather than modifying gameplay.

### Other gates and integrity

- IK: diagnostic TwoBoneIK only; no production IK / retarget change.
- Materials: unchanged; Hanger overbrightness/equipment occlusion NOT FIXED.
- Clothing/deformation: no animation played here; full set NOT VERIFIED.
- Hanger / Field Office / animation screenshots: not regenerated; earlier Phase 3A
  evidence is historical and is not Phase 3A.1 acceptance.
- Full regression: NOT RUN this phase, per Gate A-first order. Previous isolated
  32/33 is historical; `Face` mesh/name/height smoke assumption remains unchanged and
  must remain a visible integration-gate mismatch, not be patched for a green result.
- Official source: all **68 source/meta hashes match** recovery manifest.
- Export GLB unchanged SHA-256:
  `32e030e3aa4dea44f699bd7ce260a87c6ea9d5f4c0ea4c5eaedd6e823a335e0f`.
- Tracked diff under scripts/scenes/tests/project.godot: empty. Existing unrelated WIP
  preserved; gameplay, old production player, enemy, weapons and official source unchanged.
- No gameplay test weakened, no fake legacy node added, no commit made.
- **Ready for main-project replacement: NO.**


## Phase 3A.2 — Hand authoring checkpoint (2026-09-26): BLOCKED

**This phase authored real finger/palm candidates in Blender, but did not pass Gate A.**
No animation, materials phase, Hanger/Field Office integration, full regression or main
player replacement followed. Numerical wrist convergence is not the acceptance criterion.

### Authoritative source and exact changes

`battle_master.blend` now contains three independently authored single-frame pose actions:
`Pose_Rifle`, `Pose_SMG`, `Pose_Rocket`. They are not gameplay animation states/clips.
The neutral rig remains the default view; actions are saved with fake users. Choose the
armature's action in Blender to inspect a pose at frame 1. Hidden `Reference_<weapon>_*`
objects retain the matching source weapon at its authored origin; reveal only that weapon.
These reference objects must **not** be accidentally included in a production character export.

`phase3a2/master_before.blend` preserves the pre-authoring master. Its texture references
are relative to the original master directory, not the backup directory. The authoring
script resolves/reloads active image nodes against that directory before export. Initial
backup-path texture loading failed; corrected final screenshots contain the original textures.
Do not use white-texture intermediate renders as acceptance evidence.

Changed/new files are limited to the derivative master, this README and `phase3a2/`:
- `inspect_hands.py`, `hand_hierarchy.json`, `HAND_HIERARCHY.md`: actual bones/axes.
- `hand_poses.json`: weapon-specific wrist/palm/finger authoring parameters.
- `author_hands.py`: offline Blender authoring and evaluated static evidence exports.
- `authored_measurements.json`: wrist rotations, arm landmarks and frozen hand-bone matrices.
- `Pose_Rifle.glb`, `Pose_SMG.glb`, `Pose_Rocket.glb`: **static evaluated mesh evidence**,
  not skinned runtime replacements. No gameplay animation is baked into these files.
- `capture.gd`, `capture.log`, 15 view PNGs, `Comparison.png`, `comparison.html`.
- `verify_master.py`, `integrity.json/.log`, `scope_verification.json`.
- `grip_sections.py/.log`: launcher geometry cross-section inspection.
- `inspection_probe.gd/.log`, `Pose_*.png`, `static_measurements.json`: inherited position-only
  baseline inspection, NOT final authored hand evidence. Final images use `<weapon>_<view>.png`.
- `unexpected_workspace_*`, `active_godot_processes.json`: concurrent workspace evidence.

The prior `battle_presentation.glb` remains byte-identical and was not replaced. Running
older `build.py` will regenerate the pre-hand-authoring master; do not inadvertently erase
these actions. `author_hands.py` deliberately starts from `master_before.blend` for repeatability;
rerunning it overwrites current candidate actions, so preserve manual Blender edits first.

### Real hand hierarchy

See [full hierarchy](phase3a2/HAND_HIERARCHY.md) and local matrices in `hand_hierarchy.json`.
Each side has:

```
Character1_LeftForeArm / Character1_RightForeArm
  Character1_LeftHand / Character1_RightHand
    HandThumb1 -> HandThumb2 -> HandThumb3 -> HandThumb4
    HandIndex1 -> HandIndex2 -> HandIndex3 -> HandIndex4
    HandMiddle1 -> HandMiddle2 -> HandMiddle3 -> HandMiddle4
    HandRing1 -> HandRing2 -> HandRing3 -> HandRing4
    HandPinky1 -> HandPinky2 -> HandPinky3 -> HandPinky4
```

The abbreviated child names above all retain the full `Character1_Left` / `Character1_Right`
prefix in the actual skeleton. Each Hand controls wrist/palm orientation; there is no
separate palm joint. Each thumb and finger is independently rigged. Segments 1–3 have
skin weights; segment 4 is a zero-weight terminal landmark. The two hands each have 435
vertices influenced by Hand, with individual phalanx weight counts in `integrity.json`.
The geometry supports finger-level posing; it is not a mitten mesh or a rig limitation.

Important: imported bone **tails do not reliably point along the anatomical phalanges**.
Curl axes are derived from joint head-to-child-head vectors, not blindly assumed local X/Y/Z.

### Authoring method

All authoring is offline in Blender 5.2.2 LTS, in metres, with glTF Y-up export.
The primary arm/hand is authored first, then its bone matrices are recorded before the
support hand is solved. No hand-position optimization was used as a visual acceptance test.
Arm placement uses a two-segment geometric construction with a lateral/down elbow plane;
it does not introduce runtime finger IK or modify the existing animation state machine.

A palm frame is defined from wrist→middle-knuckle and index→pinky landmarks. Each weapon
has independent desired palm longitudinal direction and inward palm normal. Wrist rotations
are derived from that frame. Finger chains receive separate thumb/index/middle/ring/pinky
curl triples; index splay allows the trigger finger to differ from the gripping fingers.
The master stores the resulting rotations, not merely a recipe for wrist IK targets.
These remain **candidate sculpted rotations**, not contact-constrained or visually accepted
poses. Finger curl degrees must not be mistaken for proof of skin contact.

Rifle retains both earlier successful wrist locations. Its change is palm orientation,
individual finger curl and index splay. SMG has its own primary orientation and an under-body
support palm rather than a copied Rifle vertical support grip. Rocket is treated as a bulky
four-tube launcher carried in front of the upper body, not forced into a shoulder-tube posture.
Its rear-reaching placement was discarded. Current Rocket elbows/wrists stay front/side;
this fixes that specific anatomical failure, not the entire gripping problem.

### Grip definitions and adapter candidates

Coordinates below are Godot axes, metres, relative to weapon origin **after the existing
0.44 presentation scale**. Original markers/wrappers are untouched. These new wrist offsets
are isolated character-presentation candidates, not new gameplay marker definitions.

| Weapon | Original PrimaryGrip | Candidate right wrist | Original SupportGrip | Candidate left wrist |
|---|---|---|---|---|
| Rifle | [0.030799999833106995, -0.07039999961853027, -0.06599999964237213] | [0.0308, -0.0704, -0.066] | [-0.026399999856948853, -0.05719999596476555, -0.2287999838590622] | [-0.0264, -0.0572, -0.2288] |
| SMG | [0.030799999833106995, -0.07039999961853027, -0.06599999964237213] | [0.032, -0.052, -0.04] | [-0.026399999856948853, -0.05719999596476555, -0.2287999838590622] | [-0.055, -0.058, -0.225] |
| Rocket | [0.03959999978542328, -0.17599999904632568, -0.06159999966621399] | [0.07, -0.12, -0.1] | [-0.03959999978542328, -0.1671999990940094, -0.3651999831199646] | [-0.11, -0.02, -0.3] |

The original marker is not a palm contact surface. For Rocket the primary candidate is
on the right side of the rear slanted control handle; the support candidate is under the
launcher body, not the lowest/front marker location. The old shoulder placement put the
primary behind the torso, but this does **not** prove the marker is globally semantically
wrong. Current geometry establishes a character-fit/hand-frame mismatch, not an authorized
reason to rewrite PrimaryGrip/SupportGrip. The adapter can represent local contact offsets;
none are integrated or approved yet.

Launcher cross-sections at y=-0.08..-0.12, z=-0.15 have outer side x≈0.0485 m (the opposite
side is mirrored). The approximately 9.7 cm-wide handle section is bulky compared with
this hand. A plausible thumb/finger contact arrangement has not been established around
that section. Do not compensate by stretching fingers or scaling gameplay weapons.

### Visual result — Gate A stays BLOCKED

All three use fixed lighting and the same camera setup. Source weapon colors are visible
because static Blender reference exports use original materials rather than production
palette overrides. No character material tuning was performed.

| Weapon | Authored | Visual decision | Concrete remaining issue |
|---|---|---|---|
| Rifle | Both palm frames and all finger chains | NOT ACCEPTED | Grip silhouette improved, but support fingertips emerge as disconnected-looking patches against the front block; continuous contact/no penetration and trigger placement are not established. |
| SMG | Independent primary frame, cupped support | NOT ACCEPTED | Primary hand remains crowded into the receiver/handle junction; index/thumb contact is obscured and not clearly believable. |
| Rocket | Front/side arms, rear control hand, under-body support | NOT ACCEPTED | No rear-reaching arm now, but primary fingers read as contact with a broad panel rather than convincing wrap; support contact is partly hidden. |

Finger posing: YES for both hands/all three weapons. Weapon axes remain -Z (no orientation
hack or weapon yaw). No face intersection is apparent in the inspected views. Arm/torso
crossing is not apparent at the inspected scale, but precise skin/weapon and hidden arm/body
intersections are **NOT CLEARED**. In particular, suspicious finger/weapon intersections
prevent PASS. No claim is made that Rocket is impossible without gameplay changes.

This is partial authoring progress, not a finished correction. The next art task is contact-
surface refinement (thumb opposition, fingertips staying outside the grip volume, index at
control region), using the saved master and close views; not additional wrist-distance tuning.

### Evidence / reproduction

[Side-by-side gallery](phase3a2/comparison.html), [comparison PNG](phase3a2/Comparison.png).
Columns: Rifle / SMG / Rocket. No debug markers or animation playback.
For each weapon:
- `A_front`: front 3/4, camera (2,1.5,-3).
- `B_weapon`: weapon-side 3/4, camera (3,1.35,-1.5).
- `C_side`: side, camera (3,1.15,0).
- `D_support`: opposite support-side 3/4, camera (-3,1.35,-1.5).
- `E_primary_close`: additional primary-hand close view, camera (3,1.2,-1).

All look at (0,1.02,-0.13), orthographic size 1.1 m except the close view at 0.45 m;
1280x720, OpenGL 3.3 / RTX 5090 / Godot 4.7.2. Diagnostic, not production cameras.
`Comparison.png` joins the three A views without image generation or visual alteration.
`capture.log` exit 0 means evidence collection completed, **not** a pose acceptance PASS.

Rebuild with Blender `--background --python-exit-code 2 --python phase3a2/author_hands.py`.
Use `capture.gd` in the existing isolated validation copy and set `BUNNY_EVIDENCE` to the
absolute phase3a2 directory. It loads exported GLBs directly through GLTFDocument; no
production character import or replacement is needed. Do not run a production import.

### Integrity and separate workspace change

- 328 bones: rest matrices exactly unchanged versus the pre-phase master.
- 24 character meshes: base vertices, topology and all skin weights exactly unchanged.
- Three pose actions saved. Geometry/skin/rest checks PASS; this is not visual acceptance.
- Official recovered source: **68/68 source/meta hashes unchanged**.
- Production character preload, gameplay scripts, scenes and tests were not edited by
  this work. No fake legacy nodes, no test weakening, no main-project replacement.
- No full regression or gameplay animation tests were run, per Gate A ordering.

**Workspace caveat:** a late check detected unrelated changes during this phase:
`project.godot` feature 4.6→4.7, many `.import` rewrites, and the prior legacy FBX deletion
no longer appearing. A separate running Godot GUI process points at D:\bunny_team\project.godot
(PID 47232 at inspection); our captures use the separate temp validation project. The
changes' ownership has not been confirmed. They were preserved, not reverted. Their diff
is retained in `unexpected_workspace_*`; user clarification was requested. Thus do not
claim the entire working tree is unchanged or ready for a clean checkpoint.

**Workspace clarification received:** the user confirmed opening the main-project editor.
Preserve these editor changes. This is no longer an unknown concurrent-writer blocker.
The sampled weapon import diff adds Godot 4.7 importer settings; the full importer diff
has not been accepted as behavior-neutral. Tracked `.import` sidecars are import recipes,
not disposable `.godot/imported` cache. No rollback or deletion is appropriate.

**Current disposition: BLOCKED on hand-contact visual acceptance, not on workspace ownership.**
Gameplay unchanged by this phase; official source unchanged; production character unchanged
by this phase; tests unchanged; no fake legacy nodes; no main-project replacement; no commit.


## Phase 3A.3 — Integration validation in progress (2026-09-26)

User objective: `C:/Users/admin/.codex/attachments/48df3756-118e-4840-8bdb-0970ddef9ec7/goal-objective.md`.
The user accepts Phase 3A.2 static finger/palm imperfections for the internal Demo.
Those P2 issues no longer block this phase. Do not refine the static poses again.

Current work remains isolated. Phase result is **NOT YET DETERMINED**, not PASS/BLOCKED
based on old static acceptance. `phase3a3/progress.json` lists remaining objective gates.

### Current evidence

- `workspace.json`: fresh external WIP snapshot, Godot 4.7.2 cold import exit 0,
  **0 ERROR / 0 WARNING**, 68 official source/meta hashes match. Git main @ c4ca114.
- Production `player_controller.gd` SHA-256 before validation:
  `48a36086c6bdf54f9ade39b97bdfa6910cf887ac816871a9a493c2db04d13b8c`.
- Blender master contains all three pose actions, 328 bones; `master_export.json` records
  the inspected master hash. `export_poses.py` reads actual saved actions, not invented
  runtime finger angles. `runtime_poses.json` is exported authored presentation data.
- `presentation_adapter.gd`: isolated subclass of existing CharacterCombatRig. The staging
  copy substitutes only player asset preload and rig constructor. Base reload/fire/state
  semantics and production files unchanged. Configuration selected by existing weapon scene.
- Adapter preserves base pose interpolation separately to avoid accumulating offsets.
  Blender-authored wrist/finger frames run after existing retarget/arm IK through
  `hand_modifier.gd`. No new runtime finger IK, no animation-state redesign.
- Initial Hanger probe: three weapons load, all eight mounts exist, positional IK targets
  converge. Screenshots retain known bright face/hair and bulky equipment. **This is not
  full Hanger visual acceptance**, nor proof all animation states pass.
- `animation_probe.gd`: 24 combinations captured with real OpenGL. Existing five clips
  are sampled explicitly by seek; Reload/Recoil/Hit invoke existing presentation behavior.
  No gameplay transition edits. `Run_Shoot` is the existing Run-source clip plus recoil.
- `animation_summary.json`: raw maxima and selected pose for each row. All 24 require visual
  review before assigning PASS/USABLE/BLOCKED. Rocket Recoil reaches ~0.1064 m target error;
  must inspect duration/visible detachment rather than dismiss or fail solely by the number.
- Existing socket-only SMG/Rocket `start_reload()` returns false in this fixture. Record
  the lack of a separate reload motion honestly; actual session reload still needs testing.
- Corrected capture log exit 0, no script errors; **2 ObjectDB instances leaked at exit**.
  Initial SceneTree probe typed PlayerController too early and failed autoload compilation;
  repaired by deferred runtime loading. Failed log retained, not an adapter/gameplay fix.
- `comparison.html`: all animation strips/full-size samples; not a green acceptance report.

### Importer diff inspection

Preserved editor changes. `project.godot` diff changes only feature version 4.6→4.7.
Import diffs include new mesh deduplication/naming/texture-map settings and VRM texture
compression, normal-map and roughness metadata; they are **not all disposable cache**.
Fresh copied import succeeds, but that alone does not prove complete visual equivalence.
`import_config.diff` retains the actual inspected changes; no blanket revert was performed.

### Still required before completion/push

Review/classify all 24 animation×weapon combinations; repeated real slot switching in both
requested orders; IK discontinuity/stale state checks; Hanger functional/material usability;
Field Office → Terminal → combat/switching → extraction/Result; unchanged regression suites
with any legacy Face assertion reported separately; final integrity and Git review.
No commit/push yet. Gameplay, production player, official package and tests were not edited
by this phase. No fake legacy nodes or production replacement.


### Phase 3A.3 continuation — parent-space fix and regression (2026-09-26)

Previous goal turn was progress (new adapter and evidence); this turn also produced a
verified targeted fix and new evidence. Objective remains ACTIVE; not a completed gate.

The Rocket recoil defect was traced to `_raw_pose` being cached/restored in world space.
This discarded inherited body/socket recoil displacement on the next frame. The adapter
now caches/restores the **parent-local transform**. Existing recoil strength, tween,
weapon definitions and gameplay paths are unchanged. Before/after sources and raw samples
are retained as `adapter_before_parent_space_fix.gd.txt`,
`animation_before_parent_space_fix.json`, and current `animation/animation_matrix_raw.json`.
Rocket Recoil maximum target error changed from ~0.1064 m to ~0.000000207 m. This was not
static finger refinement or a relaxed test threshold.

The latest probe covers the complete source clips at fixed 60 Hz sample times rather than
only the first 1.2 seconds: Idle 2.95 s, Walk 1.3667 s, Run/Run_Shoot .8667 s, Dodge 1.45 s.
Procedural Reload/Recoil/Hit retain their 1.2 s response observation. Current `animation.log`
exit 0; all 24 rows collected. It is still a clip stress fixture, not live state traversal.

`switch_probe.gd` repeats both requested three-weapon sequences five times: **45 samples
PASS**, correct configuration, no >1 cm accumulated position drift, no >.03 rad orientation
drift, no leaked reload state. Recoil is deliberately left in flight at each switch.
It uses Hanger's equip presentation API: it does NOT invent three runtime weapon slots.
Actual two-slot gameplay is separately checked by the unchanged `weapon_switching_test`.
Switch probe reports 2 ObjectDB exit leaks; not warning-free.

`regression/results.json`: **32/33 existing tests PASS; Main exit 0**. The only failure is
`ACCEPTANCE_SMOKE: avatar keeps its complete authored face mesh` at acceptance_smoke.gd:46.
The Face/name/size assertion was not edited. PRESENTATION_GAMEPLAY, WORLD_TRAVERSAL,
VISUAL_SLICE_ASSETS, weapon switching and result return all pass. Logs include per-test
warnings and exit codes. Passing these does not substitute for graphical route acceptance.

Visual inspection: Rifle and SMG strips show attached weapons and no catastrophic clothing
collapse in sampled frames. Rocket recoil detachment no longer appears in the corrected
samples. However, `side/Rocket_Dodge.png` shows substantial head/launcher overlap at about
one-third of the complete 1.45 s clip. **This is an unresolved stress-clip presentation
failure**, not dismissed as finger-level P2. Actual gameplay's dodge lasts .16 s then
transitions; the next step is to reproduce through the unmodified state machine before
attributing this to a live-route P1. If live, adjust only the Rocket presentation mapping,
not gameplay dodge duration or source animation. The final matrix remains unaccepted.

No active process was abandoned: animation, switching and full regression runs completed.
All new source/evidence remains in derivative (staged copies only outside the repository).
No production character replacement, official edits, test weakening, commit or push.


### Phase 3A.3 continuation — live Dodge and Terminal evidence (2026-09-26)

This section supersedes the earlier unresolved *live Dodge reproduction* question, not the
full-clip stress limitation. `phase3a3/live_dodge_probe.gd` drives the unchanged controller
with input actions and its real AnimationTree. Rear and front-oblique captures are in
`live_dodge/` and `live_dodge_front/`. All three weapons entered Dodge (9 recorded samples,
maximum observed source play position 0.116667 s), exited, and recovered to Idle with body
scale (1,1,1). Front Rocket stills show the head above the launcher and attached arms;
the deep head/launcher overlap at ~0.48 s in the full 1.45 s diagnostic clip is not reached
by this gameplay state. Full-clip reuse remains unsuitable without separate review.

Front Rifle has transient support-hand target error up to 0.05323 m at Dodge entry,
decreasing over subsequent samples; right hand remains attached. Visual review shows
brief sliding rather than weapon detachment or arm inversion: Demo-level P2, not polished.
Rear-view maximum settled error was ~0.00000107 m; front SMG/Rocket were below 0.000001 m.
These measurements supplement, not replace, the reviewed renders. The first uncontrolled
mouse-aim run remains explicitly superseded; no acceptance claim uses that run.

`route_probe.gd` now asserts actual Terminal objective COMPLETED after E, rather than
merely reaching its area. Both rerun loadouts (`route_Rifle`, `route_SMG`) exit 0 with all
checks true: Hanger, normal movement/AI, door, interior, four Q slot switches, weapon-
specific adapter selection, fire and real session reload, Terminal, exit, extraction,
Result. `04b_terminal_interacted.png` records the post-interaction view. Mission completion
is false because this route does not complete every objective; it does prove extraction
and result flow. These are automated graphical/API checks, not human keyboard acceptance.

Hanger screenshot review: character is recognisable, standing at human scale with attached
weapon/equipment. Face/hair remain over-bright and gear obscures parts of the torso. These
remain known Demo presentation limitations; no material or Hanger architecture edits made.

Only derivative probe/evidence/report files changed in this continuation. Gameplay,
production player, official source and existing tests were not edited. No fake nodes,
production replacement, commit or push. Final 24-row classification / integrity audit and
scoped publishing remain pending; the goal is not yet marked complete.


## Phase 3B started — material diagnosis only

See `phase3b/MATERIAL_LOG.md`. Fresh isolated import 0 errors / 0 warnings; original
source and production unchanged. Same-camera single-variable material trials captured.
Specular removal alone did not resolve pale diffuse clipping. Face/hair albedo response
candidates remain **NOT ACCEPTED** pending Field Office/color review; no master/GLB edits
or equipment changes yet. Phase 3B is active, not complete.


### Phase 3B integration checkpoint (not final acceptance)

Material response and Chest/Backpack frame correction are now authored in derivative
master metadata and consumed by the isolated adapter. Mesh/skin/rig/action fingerprint
unchanged. See phase3b/MATERIAL_LOG.md and before/after equipment evidence. Regression
32/33 (known Face), main exit 0; Rifle route passes. Solo SMG replay, final matched
comparisons and warmed performance sampling remain pending. Production remains untouched.


## Phase 3C — Production Replacement Readiness

**Phase 3C — PASS / Production Replacement Ready (technical migration gate).**

The existing Player actor can use Unity-chan through the isolated presentation selector
without changing gameplay semantics. This is NOT a permanent production replacement,
commercial license clearance, or a claim of polished final animation quality. Phase3B
remains **Demo Candidate PASS**. Full-game public-release authorization remains **BLOCKED**
because the unchanged enemy still uses AvatarSample_A. No assets sent to AI.

### 1. Legacy dependency inventory

`phase3c/DEPENDENCY_INVENTORY.md` classifies A gameplay, B presentation, C legacy tests,
D accidental visual coupling; `semantic_search.json` preserves discovery file/line evidence.
Generic world queries and item-tag matches are not old-character dependencies. Supplementary
bounds, groups and metadata search found no serialized avatar identity. Enemy Face/Hair
palette special cases exist and remain untouched; do not confuse them with player gameplay.

### 2. Face assertion

Exact assertion: acceptance_smoke.gd:142–143, Face MeshInstance3D with local mesh AABB y>.2.
It protects legacy facial geometry, not actor collision or identity. Left unchanged; no fake
Face nodes. Recommend a separately reviewed per-asset integrity fixture plus semantic
presentation contract, not deleting the check. Gameplay risk low; losing visual test
coverage would be medium risk. Details in READINESS_AUDIT.md.

### 3. Skeleton

Character1_* humanoid names already match the shared animation/IK source. Old J_Bip alias
compatibility stays in the original visual builder, with no rebind/rest-pose edits. Semantic
Chest/ShoulderL/R/Backpack/HipL/R/HandL/R and CombatAvatarModel/CharacterRetarget remain real
interfaces. Phase3B Chest/Backpack frame correction and authored hands stay in the adapter.

### 4. Animation

Existing hidden animation source, track retargeting, AnimationTree and locomotion/upper-body
states remain unchanged. Actual input-driven Dodge passes both new graphical routes;
regression and paired contract probes cover inherited reload/recoil behavior. Prior accepted
Phase3A3/3B animation limitations are not upgraded into production-polish claims. No new clips,
state transitions or per-frame gameplay offsets were introduced.

### 5. Weapons

AR/SMG/Rocket tested. `contract/comparison.json`: 270 deterministic samples over idle,
recoil, reload and Dodge weight; legacy vs Unity-chan actual gameplay shot origins/directions
have **0 delta**, has_weapon/reloading/state flags exactly equal. Rifle authored origin equals
base origin; socket SMG/Rocket preserve has_weapon=false and original actor-based shot path.
This mixed gameplay/presentation muzzle dependency must remain guarded in future edits.
Weapon definitions, ammo, damage, fire rate, reload timing and switching are untouched.

### 6. Hanger

Same scenes/player/player.tscn preview host, fixed camera/platform and UI. Factory only selects
visual scene/adapter in copied Player script. Start and returned Hanger screenshots show the
selected model and real equipment. No Hanger scene or gameplay architecture edits.

### 7. Field Office

Same Battle Player/session traverses existing door/interior/Terminal and original extraction
route. Camera, capsule, interaction radius and collision unchanged. Real OpenGL 1280x720
captures in phase3c/route_Rifle and route_SMG. No new area or Terminal asset production.

### 8. Save/load

Schema1 contains inventory/loadout, not Person ID, avatar path, independent progression or
currency fields. No invented identity schema. Legacy process writes a normal save; Unity-chan
process loads it, runs sortie, returns through production Result UI signal, commits/saves;
another process reloads and matches full data. `identity_verification.json` independently
reconstructs warehouse = uncarried + recovered items and validates owned IDs/loadout/schema.
Ammo legitimately decreases. Scene changes recreate preview Nodes; logical profile/session
identity—not process-local Node ID across restarts—is the correct invariant.

### 9. Isolated switch result

`phase3c/stage.py` creates an external fresh snapshot. `presentation_switch.gd` defaults to
legacy; BUNNY_PRESENTATION=unitychan opts in. Exactly two expressions in copied PlayerController
change: character scene instantiation and rig constructor. No gameplay scripts inside GLB.
Fresh import exit0, 0 ERROR/0 WARNING. Default legacy33/33; opt-in32/33 (Face only); MAIN0 both.
Existing tests byte-for-byte unchanged. Known ObjectDB exit warnings remain in regression
logs; not claimed warning-free. Original production player/asset stay recoverable.

### 10. Full route

Both Rifle/Rocket and SMG/Rocket routes pass all32 checks: existing save → Hanger → deploy →
Office door/interior → Terminal COMPLETE → movement/switch/fire/reload → actual Dodge → exit →
extraction → Result → Hanger. Normal AI/collision/health, no teleport or invulnerability.
Rifle route60 shots/15 damage; SMG103 shots/18 damage. Both extracted without completing all
mission objectives (0 enemies defeated); do not claim full mission completion. Automated
input/API graphical acceptance, NOT manual keyboard acceptance. Post-result restart PASS.

### 11. Remaining blockers / boundaries

No blocking dependency found for this player-only technical migration. Public shooting-demo
release remains BLOCKED by unchanged enemy AvatarSample_A license; Unity-chan personal-demo
UCL provenance/credit obligations also remain. Legacy Face assertion still fails32/33 as
explicitly allowed by this phase. Imported/source migration WIP is not a clean-clone committed
checkpoint. Known accepted visual rough edges remain. Do not silently replace enemy or tests.

### 12. Recommended next step and Git

Review this readiness result, then separately authorize a narrow production-player switch
and an explicit test-contract migration. Do not combine with Terminal, enemy or other art.
No replacement, commit or push performed in Phase3C.

HEAD: main @ ec5f18dbe81164f43c1613a8ab678f4e3c51bed9.
Working tree: pre-existing Phase3B/import/migration WIP retained. Phase3C changed this README
and added phase3c scripts/reports/logs/screenshots only. Production character modified: NO;
Gameplay modified: NO; official source modified: NO; experiment isolated: YES.
`final_integrity.json`: source snapshot drift empty; all68 official hashes match; master,
GLB and production character/script match Phase3C baseline; isolated Player is exactly the
two substitutions. `completion_audit.json` covers objective sections1–21.

## Phase 3D — Production Player Presentation Switch

**Technical production migration: PASS**
**Public release authorization: NOT ASSESSED**
**Enemy AvatarSample_A licensing: BLOCKED**

Normal production Player now preloads the validated battle_presentation.glb and instantiates
scripts/presentation/unitychan/presentation_adapter.gd. These are the only two Player code
changes. Gameplay ownership, collision, identity, save schema, weapon definitions and enemy
are unchanged. No environment switch/demo scene needed. Old avatar remains for rollback.
Existing CombatAvatarModel/Body/UpperBodyAim plus eight semantic mounts form the presentation
contract; no fake CharacterPresentation/Face nodes or renamed gameplay concepts added.

### Test-contract migration (separate from production reference changes)

Old Face mesh-name/AABB assertion replaced by adapter visual integrity contract: all24
skinned meshes, all37359 triangles, authored head3474 triangles with finite nonzero bounds.
Mesh-specific knowledge stays inside the adapter, not generic Player tests. Eight semantic
mounts now explicitly checked; animation/IK/equipment tests retained. Old VRM wording updated,
no unrelated tests changed. This protects complete geometry rather than merely checking a
node exists. Runtime adapter data preserves the validated manually authored poses.

### Validation

- Production regression33/33; ACCEPTANCE_SMOKE PASS, MAIN exit0. Relevant Presentation,
  WorldTraversal, VisualSlice, ResultReturn, save/load and weapon suites all pass.
- Production vs legacy270 deterministic weapon samples: origin/direction delta0, reload and
  state flags identical. WeaponDefinition/weapon logic untouched.
- Normal production Hanger/Field Office graphical routes, Rifle/Rocket and SMG/Rocket:
  all32 checks each PASS including actual Dodge, Terminal, extraction, Result→Hanger.
  Production cameras1280x720; automated input/API, not manual. Mission objectives not all
  completed; extraction/result—not full mission completion—is the verified outcome.
- Real existing production profile copied byte-for-byte for safe validation (source/hash in
  save_provenance.json). Both routes load that data, commit/save, then restart another process
  and reload. Full profile/owned IDs/loadout match; independent warehouse merge check passes.
  Original user save hash remains unchanged. Schema has no Person ID; none invented.
- Animation contract24 weapon/state combinations PASS through the existing AnimationTree:
  Idle/Walk/Run/Run+Shoot/Recoil/Reload/Hit/Dodge. Finite bones/integrity checked; captures in
  phase3d/animation. Accepted prior minor sliding/intersection remains, no pose redesign.
- Official68 source/meta hashes unchanged; runtime GLB equals derivative; old avatar unchanged.
- Initial adapter integrity-helper parse errors were corrected with explicit Array/AABB types;
  retained initial logs. No real gameplay failure workaround. Known ObjectDB exit warnings
  remain in some tests; not claimed warning-free.

### Rollback / files / Git

Rollback not triggered: no acceptance criterion failed after helper compilation correction.
Old asset remains untouched. A rollback would restore only Player's two presentation reference
expressions and their matching test contract; do not discard other WIP.

Production changes: scripts/player/player_controller.gd (two references);
scripts/presentation/unitychan/ (validated adapters + integrity query);
assets/characters/unitychan_battle/battle_presentation.glb(.import) and presentation/ data.
Test migration: tests/acceptance_smoke.gd only. Evidence/report: phase3d/ and this section.
No Terminal/enemy/official source changes. Existing Phase3B/3C/import/migration WIP excluded
from the dedicated commit. No push. Commit identity is recorded in phase3d/commit_receipt.json
and the final response (receipt written after commit, avoiding self-referential commit hash).


## Phase 4B — Unity-Chan Visual Fidelity Recovery

2026-09-26. **PASS — source-faithful geometry retained; active material semantics recovered.**
This is a bounded visual recovery, not a redesign or a claim of pixel-identical Unity UTS rendering.
Start: main @ 10e9d822b2f9c67c7d61bc5885dee9002b746f0b (Phase 4A), containing Phase 3D 955ce1f.
Existing migration/import/authoring WIP was snapshotted and preserved, not reset or committed.

### Source verification / objective geometry comparison

- Official package source/meta: **68/68 hashes match** recovery_manifest.json.
- Production and derivative GLB still equal the original build_report.json conversion SHA-256:
  `32e030e3aa4dea44f699bd7ce260a87c6ea9d5f4c0ea4c5eaedd6e823a335e0f`.
- Blender master byte hash unchanged from this phase's starting WIP. No save/re-export was made.
- Read-only Blender 5.2.2 imports compare official main FBX + separate head FBX against runtime GLB.
  Comparison accounts for the already documented 180-degree heading normalization and cm→m/object
  transform baking. Index IDs and bone palette IDs are not semantic identities: compare triangle
  corners and named influences, not raw ordinal arrays.

| Mesh | Official vertices → GLB | Triangle index count, both | Maximum position delta (m) | UV delta | Maximum normal angle |
|---|---:|---:|---:|---:|---:|
| head_Def | 2014 → 2370 | 10422 | 1.22e-7 | 0 | 0.652° |
| headNose | 26 → 64 | 144 | 2.39e-7 | 0 | 0.020° |
| eyeBall | 202 → 322 | 1080 | 3.62e-7 | 7.46e-9 | 0.028° |
| eyeHighLightShape | 120 → 120 | 648 | 3.62e-7 | 7.46e-9 | 0.020° |

**Face geometry: IDENTICAL in shape/topology within conversion floating-point tolerance; not
byte-identical vertex buffers.** Export splits UV/normal seams, accounting for increased vertex
counts. Oriented position/UV triangle multisets match after 2e-6 m corner matching; zero unmatched
corners. A naive rounded-coordinate hash differs at rounding boundaries; that diagnostic is retained,
not concealed. All 18 head morphs plus Basis match within 1.22e-7 m. No facial feature moved.
Head/nose/eye weight deltas by semantic bone name are zero. Full named palettes and accessor/index
counts are in geometry_comparison.json and material_verification.json.

Four hair meshes also match topology/UV/positions (largest delta 5.97e-7 m). Existing import-normal
differences reach 0.890°; hairFront's existing named-weight conversion delta reaches 0.000614.
These are pre-existing conversion differences, not Phase 4B edits or proof of literal buffer identity.

Tangents: production GLB contains no TANGENT accessor. Godot's existing import generates tangents.
The read-only Blender MikkTSpace diagnostic can differ up to 180°/sign at degenerate or ambiguous
position/UV corner matches; it is NOT an authored tangent equality certificate. No active original
character material enables a normal map or tangent-based high-color highlight. These derived-tangent
diagnostics are therefore not a reason to reshape/re-export the face. No normal/tangent correction
was necessary or performed. Re-audit tangents if normal mapping is ever enabled.

### Head, nose and eye assembly

Original prefab mapping was re-read, including material/texture GUIDs and FBX file IDs. The selected
head is head_Def from the separate head FBX; nose is the original headNose. Both use face3_main,
as do eyeBall and eyeHighLightShape. There is no missing separate eye-albedo asset to invent.
The prefab's head/nose rest-world assembly is identity within ~1.8e-7 m. The established derivative
encodes their rigid Character1_Head attachment with equivalent one-bone weight 1.0. Eye meshes retain
their original named skin influences. Original geometry relationship, scale, UVs, winding and morph
positions pass comparison. No new parent/scale/rotation/binding correction was indicated or applied.

### Root cause / material reconstruction

The old production shader used only base color, a generic softened diffuse response and double-sided
culling for face/hair/skin; body/accessories remained generic PBR. It omitted the original shade-color
and shading-grade maps. This produced smooth sculpt-like facial/hair shadows, pale flat irises and
different highlights, despite the original geometry being intact. Lighting-only neutral comparisons
did not restore the missing authored bands. The production light response also differed from UTS.

All five character materials now use the same small source-specific UTS subset. `inspect_materials.py`
verifies **60 source/profile checks** for original PNG hashes, colors, thresholds and active semantics.
No texture was painted, generated, resized, recompressed or replaced.

| Runtime material / surface | Base source | Shade source | Grade source | Parameters |
|---|---|---|---|---|
| face3_main / head, nose, eyes | face3_main.png | face3_main_sub.png + face3_main_Shd2.png | face3_main_spow.png | steps .5/.51; white multipliers |
| Hair_Spow / all hair | **no base texture**, original constant (.93725497,.8313726,.6784314) | original first shade (.53333336,.4901961,.48235297) | Hair_Spow.png | first step .5 |
| Skin | skin.png | Skin_Shd.png | skin_spow.png | first step .5 |
| Body / clothes, horns | Body.png | Body_Shd.png | Body_spow.png | first step .65 |
| Add / accessories | Add.png | Add_Shd.png | Add_Spow.png | first step .65 |

Filenames above omit common `kohaku_A_` prefix. All sample UV0, original scale 1 / offset 0.
Original PNG import metadata marks these maps sRGB, including grade; grade R selects a shading band,
**not** albedo/roughness/metallic/ORM/normal data. Original active five materials are opaque, back-culled,
depth-writing, normal-map disabled, HighColor power 0, rim/MatCap/GI 0, active emissive map default black.
Serialized stale _MainTex/_EmissionMap references do not occur in the active shader closure.
No invented metallic/specular/emission maps. Original sixth Unity2016_Wep belongs to the excluded
bundled melee weapon; existing AR/SMG/Rocket and equipped gameplay gear materials were not changed.

Shader implements half-Lambert × grade × original system-shadow factor; original two shade masks,
colors and thresholds; opaque back culling. No vertex function, mesh displacement, procedural facial
detail, PBR highlights or new eye geometry. The eyes now use their original shared face shade maps,
recovering the authored iris color separation. Hair uses original constant colors, not a fake albedo.

### Color management / lighting isolation / explicit limitations

The neutral scene uses a fixed white directional light (energy 1), gray background, fixed cameras,
linear tone mapper and identical pose. It captures old production, source-equation subset, and final
game-adapted material separately. `source_semantics` means **our rendering of the recovered equations**,
NOT an independent official Unity screenshot. Exact authoring scene lighting/project color-space is
not shipped. Three genuine 128px package previews were extracted from the already verified local
archive, with hashes recorded; their resolution is insufficient for pixel-parity face certification.
No Unity installation or unrelated download was performed.

The new shader initially exposed an sRGB/light-space mismatch: a .5 custom DIFFUSE_LIGHT swatch became
.7373, whereas .5 ALBEDO/StandardMaterial swatches became .502. The final shader explicitly converts
painted sRGB colors into linear light output on Compatibility; original texture bytes remain intact.
Do not confuse this rejected trial with proof that the old shader had that same specific gamma bug.

Another rejected trial looked correct with one neutral light but clipped face/hair white in Hanger.
Isolation showed the separate shadowed directional/local-light passes adding after tone mapping;
max(DIFFUSE_LIGHT, ...) inside one pass cannot cap their final sum. The final game adaptation uses
the existing directional key for these five character paints and normalizes excessive key energy.
It deliberately does **not** reproduce UTS ForwardAdd/local accent response. Local scene/equipment
lighting, WorldEnvironment, exposure, cameras and all Phase 4A decoration/VFX remain unchanged.
Hanger and Field Office both already have the required directional key. A future local-light-only
scene needs a separate presentation review; this is not a universal toon shader framework.

Full UTS outline extrusion, engine GI/fog parity and Forward+/Mobile fidelity are not claimed. No
outline geometry was generated. This phase verifies the source-faithful active painted/shade subset
and visible improvement, not identical output from two different renderers.

### Visual / runtime acceptance

- Neutral frontal / 3/4 / side: inspected; original facial silhouette, nose and hairline retained;
  authored cel bands, iris shading and hair colors restored; no floating/recessed eye assembly or
  glossy PBR face highlight introduced. Hanger before/after no longer clips hair/skin to pure white.
- Normal Hanger and Field Office cameras remain 1280×720. Additional close-ups are explicitly
  diagnostic. Cameras sample the final head skin at Skeleton3D.skeleton_updated (after modifiers),
  not the temporarily restored pre-modifier pose. No head yaw/pitch is altered to fake the view.
  Neutral frontal/3-4/side captures remain the fixed reference. Production top-down face is only a few pixels, not a
  substitute for that inspection. Same-pose A/B records store camera/player/body matrices.
- Existing AnimationTree: **24 weapon/state combinations PASS** (AR/SMG/Rocket × Idle, Walk, Run,
  Run+Shoot, Recoil, Reload, Hit, Dodge), finite skeletons and complete visual integrity. Prior accepted
  pose/finger rough edges remain; no pose, retarget, IK or animation-state edits.
- Two real-OpenGL normal production routes: **32/32 checks each PASS**, Hanger → Office door/interior
  → Terminal interaction → fire/switch/reload/dodge → original route → extraction → Result → Hanger.
  Normal enemy AI, collision, damage and cameras; no teleport/invulnerability. These are automated
  input/API runs, not manual keyboard acceptance. They verify extraction, not all mission objectives.
- Real existing save copied for isolation; production return/commit/save followed by another-process
  reload: **5/5 checks each PASS**. Full state/owned equipment IDs/loadout preserved, independent
  warehouse merge checks pass. Original user's save hash unchanged; no save schema edits.
- **33/33 existing tests PASS**, including ACCEPTANCE_SMOKE, PRESENTATION_GAMEPLAY_TEST,
  VISUAL_SLICE_ASSETS_TEST and WORLD_TRAVERSAL_TEST. MAIN exit 0. No ERROR / SCRIPT ERROR in final
  runs. Known non-blocking 2-ObjectDB exit warnings remain in some runs; not claimed warning-free.

Evidence: [comparison gallery](phase4b/comparison.html), [final audit](phase4b/final_validation.json),
geometry_comparison.json, material_verification.json, color_probe.json, controlled/, hanger/,
route_Rifle/, route_SMG/, animation/, regression/. Rejected lighting/gamma trials are labeled and
retained. All screenshots are engine renders, not edited/generated character imagery.

### Changes / integrity / Git

Runtime changes only:
1. assets/characters/unitychan_battle/presentation/anime_surface.gdshader — source-specific painted/shade subset.
2. assets/characters/unitychan_battle/presentation/material_profile.json — five original material bindings.
3. scripts/presentation/unitychan/presentation_adapter.gd — deserialize texture/Color parameters only.

Documentation: this section. Analysis/evidence: phase4b/. No Player/gameplay/test/weapon/animation/
collision/route/save/environment/enemy/Terminal changes. No Phase 4A reversal. All tracked starting
file hashes outside these three runtime files and this README remain unchanged, including existing WIP.
Runtime and source textures/meshes remain byte-identical. No fake legacy nodes or weakened tests.

Character geometry modified: **NO**
Character face generated: **NO**
Character textures generated: **NO**
Official source modified: **NO**
Procedural character generation: **NONE**
Character mesh remodeling: **NONE**

Technical visual recovery: PASS. Public release authorization: NOT ASSESSED. Enemy AvatarSample_A
licensing: still BLOCKED. Retain © Unity Technologies Japan/UCL provenance/license/credits; no AI input.
Dedicated Phase 4B commit only; no push. Commit hash is recorded in phase4b/commit_receipt.json and
the final reply after commit (avoids a self-referential hash). Original WIP and real save copies are
excluded from staging. The pre-existing workspace is still not an entirely committed clean-clone baseline.

Reproduction (existing tools, no dependency installation): set BUNNY_PHASE4B to this phase4b folder;
run Blender --background --factory-startup --python compare_geometry.py; python inspect_materials.py;
run Godot --path D:/bunny_team --rendering-method gl_compatibility --resolution 1280x720 --script
material_probe.gd / hanger_probe.gd with isolated APPDATA; then run run_production_routes.py,
run_animation.py and run_regression.py **serially**. workspace.json supplies project/temp-output paths;
route validation needs a safe byte-copy of the existing real save in persistence/original_profile.json.
Finally run verify_final.py. Read-only audits never save Blender/FBX/GLB/PNG art assets.
