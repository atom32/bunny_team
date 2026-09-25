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

Publishing status is recorded after the scoped commit/push; no production promotion is
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
