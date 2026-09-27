# Phase 4E — KITE-07 Legacy Skeleton Decoupling

**Status: PASS — authorized presentation/test-contract migration.** 2026-09-27, Godot 4.7.2.
Starting branch `main`, HEAD `c43264935d2e14b55a87837104ea87aabe3ba639`; runtime oracle `a40b765`.
Commit: this report is included in `Phase 4E: decouple KITE-07 from legacy humanoid presentation`.
Resolve its hash with `git log -1 --format=%H --grep="^Phase 4E: decouple KITE-07"`.
**Push: NO.** Unrelated pre-existing WIP and Handoff.md are unchanged and excluded.

The initial blocked audit is preserved verbatim in `INITIAL_AUDIT.md`, with its original
`scene_audit.json`, `scene_probe.gd`, `dependency_search.json` and `scope_verification.json`.
Those files describe the **before** state, not the final state. The subsequent user authorization
allows migration of enemy presentation assertions and their driver interfaces, not Enemy gameplay.

## Old vs new contract

Before: EnemyController -> HumanoidRetargetVisual -> AvatarSample_A / animation source ->
CharacterCombatRig -> FireReload/WeaponMount/EnemyAssaultRifle/Muzzle; KITE Gun followed that marker.
The marker was an ordinary Marker3D, not a bone attachment. IK followed the weapon, not vice versa.

After:

```text
Enemy (unchanged gameplay owner, capsule, NavigationAgent3D)
  EnemyPresentation (KiteEnemyPresentation; unchanged 1.1 host scale / hit target)
    WeaponPresentation
      FireReload (native world-space aim/recoil frame)
        WeaponMount (scale 0.44)
          Muzzle (0, 0.04, -1.48; forward = normalized world -Z)
    KiteSecurityPresentation
      Model (six existing KITE-07 parts; Gun follows this native Muzzle)
    EnemyMarker
```

- No Avatar instance, Skeleton3D, BoneAttachment3D, AnimationTree, Retarget, IK, hidden/disabled
  fallback, or fake old character node exists in the production enemy subtree.
- No reference to HumanoidRetargetVisual, CharacterCombatRig or the humanoid rifle scene remains
  in the native enemy presentation/scene/controller path. Existing shared Player code is untouched.
- `update_visual()`, `get_muzzle_position()`, `get_muzzle_direction()`, `fire_recoil()` implement the
  enemy's actual presentation capabilities without humanoid state APIs.
- Preserve the exact enemy-only weapon-frame math from the old implementation: height 1.13,
  forward offset 0.06, recoil offset 0.045, decay 10, smoothing `1-exp(-24*dt)`, recoil strength
  `clamp(0.065*8,0.35,1)`, close-target fallback and world-space interpolation. No retuned gun placement.
- EnemyController changes are mechanical construction/type/property/method-name glue only.
  Normalizing those identifiers back gives the frozen controller **identically**, including AI,
  targeting, movement, cooldown RNG, 0.38 s telegraph, ray mask/exclusion/length, damage packet,
  collision/navigation, hit/death order and detached-callback guard. See `scope_final.json`.
- Enemy attack is existing **hitscan + tracer**, not a flying projectile. No projectile implementation,
  timing, speed or damage contract was changed or introduced.
- Existing hover/pod stabilization, attack optics and visible bore follow native state. Existing hit
  overlay/tween targets that same visual root. Death still reskins the original six-body RagdollProxy;
  shapes, joints, impulses, RNG, death signal and timer are unchanged.

## Test migration audit

Original complete smoke source is frozen in `oracle/acceptance_smoke.gd.txt`.
The migrated production block was originally lines 315–340. Gameplay assertions outside that block
are retained; real hit/death presentation checks are added at their existing damage/death checks.

| Old assertion | New assertion / coverage |
|---|---|
| `EnemyVRMModel` | Actual production presentation, visible KITE instance and all six authored visual parts exist; body_visual points at this native hit target. |
| >=90 bones | Not applicable. Assert **zero** Skeleton3D/BoneAttachment3D and no legacy model/tree fallback; separate process confirms Avatar never loaded in the production route. |
| Retarget / ForwardAxisRetarget | Not required. Verify actual idle hover plus movement stabilization and settling instead of requiring a humanoid retarget pipeline. |
| active AnimationTree | Not used by KITE. Observe real transform-based idle, movement and recoil responses; no dummy tree. |
| humanoid locomotion / foot-axis samples | Drive the same aim/movement speed through update_visual; observe pod tilt after 36 frames and settling after stopping. |
| shared humanoid rifle rig | Native weapon hierarchy owns a finite Muzzle with unit forward; visible Gun bore tracks firing origin and direction. |
| dual-hand IK <2 cm | Not applicable to a rigid drone. Replace with actual bore-to-Muzzle alignment <1e-5 m, direction alignment, recoil displacement and recovery checks. |
| muzzle-to-aim dot >0.97 | **Unchanged threshold**, now using native presentation getters. |
| existing damage/death gameplay checks | Retained; additionally check real native hit overlay/scale response and six authored drone wreck parts on existing physics bodies. |

`visual_enemy_acceptance.gd` changes only the driver property `humanoid_visual` -> `presentation`.
The historical humanoid **debug fixture** tests are retained and still run; they do not instantiate
as a KITE fallback. No test scene/runner/count/failure handling was removed or changed.
There are still **33 original test scenes**. Smoke has **239 check call sites vs 234 before**;
this count is supplementary, not the rationale for the migration. Behavior checks above are the rationale.

## Firing equivalence — frozen baseline, not new vs new

`contract_probe.gd` instantiates frozen `a40b765` EnemyController (`oracle/legacy_enemy.gd`) alongside
production KITE. The frozen script only removes its global class_name and loosens its died signal
parameter to Node, permitting side-by-side instantiation; its execution logic is untouched.
The original HumanoidRetargetVisual, shared combat rig and rifle marker resource are checked against
frozen Git text in `oracle_manifest.json` / `scope_final.json` (CRLF normalized for text comparison).
Verification-only oracle files live under this folder's `.gdignore`, not in production references.

| Measure | Result |
|---|---:|
| Original Phase 4C.1 sample sequence | **360** |
| Origin max / mean delta | **0 / 0 m** |
| Direction max / mean vector delta | **0 / 0** |
| Acceptance tolerance | **< 0.00001**, unchanged |
| Visible bore max delta to native marker | 0.000000247557 m |
| Additional translation / hit / recoil / variable-delta samples | 120; max origin/direction **0 / 0** |
| Spawn RNG, capsule/nav signatures | Identical |
| Damage/death results, six physics bodies/joints/timer/RNG | Identical |
| Result | **PASS** |

See `contract.json` for all 360 paired samples, checks, max and mean values; `contract.log` for execution.
The extra 120 samples do not replace or average away errors in the original 360.

## Runtime dependency proof / observations

Separate fresh process: `native_scene_probe.gd` / `native_scene_audit.json` / `.log`.
Full production routes also assert Avatar cache absence and zero enemy Skeleton3D.

| Per-enemy observation | Before | After |
|---|---:|---:|
| Total nodes | 70 | 17 |
| Presentation-related nodes (exclude root/capsule/nav) | 67 | 14 |
| Skeleton3D | 2 | 0 |
| Animation-source / avatar bones | 140 + 91 | 0 |
| BoneAttachment3D | 9 | 0 |
| RetargetModifier3D / AnimationTree / TwoBoneIK3D | 1 / 1 / 2 | 0 / 0 / 0 |
| MeshInstance3D | 24 | 7 (six drone parts + marker) |
| AvatarSample_A instantiated / resource cached | YES / YES | NO / NO |

**Legacy AvatarSample_A runtime dependency (KITE-07): NO.**
**Legacy humanoid Skeleton3D runtime dependency (KITE-07): NO.**
Unity-Chan idle animation is already cached by shared Player dependencies before enemy instantiation;
this is not an enemy humanoid instance and is not a reason to edit Player assets. Both observations are
recorded in the native audit. No FPS/memory optimization claim is made from these node counts.

## Verification

- Fresh isolated copy, absent `.godot` cache, full editor import: **0 ERROR / 0 WARNING**, exit 0.
  `cold_import/results.json`, `cold_import/cold_import.log`, `cold_import/source_manifest.json`.
  Source: current working snapshot including preserved existing WIP, **not** a claim about clean HEAD alone.
  Reused existing `tools/verify_migration.py --import-only`; no runner changes.
- **33/33 original test scenes PASS**; `regression/results.json` plus individual logs.
  `run_regression.py` is byte-identical to the existing Phase 4C.1 runner. No suppression/recount.
- Main: **exit 0**, no ERROR/SCRIPT ERROR. Known non-blocking exit warning: **2 ObjectDB instances**.
- Real OpenGL production camera **1280x720**, automated input/API, **not human manual operation**.
  Two complete routes: Hanger -> Sortie -> Field Office enter/Terminal/exit -> Urban Arena combat ->
  extraction -> Result -> Hanger. **42/42 checks each** in `route_Rifle/route_result.json` and `route_SMG/route_result.json`.
  Normal AI/collision/health; no teleport/invulnerability. Movement, telegraph, actual enemy muzzle flash,
  Player hit, enemy hit/death, dodge, Terminal, extraction, same logical profile/session checked.
- Rifle route: 24 Player shots, 4 enemy deaths, 12 damage taken. SMG: 115 shots, 4 deaths, 18 damage taken.
  AR/SMG + Rocket switching, correct pose, fire and reload checked on the production Player.
- Phase 4C Arena cover wrapper still has all eight decorations/original meshes; Arena source/collision/nav
  hashes unchanged. Player/Unity-Chan material/mesh/texture/source hashes unchanged.
- Cross-process **save -> process exit -> new process -> load**: **5/5 checks twice** in
  `persistence_Rifle/reload.json` and `persistence_SMG/reload.json`. Full gameplay serialization/equipment/
  warehouse, Player capsule and presentation preserved. Source real profile file hash unchanged;
  all write tests use copies in isolated APPDATA. No save-format changes.
- Scope audit: **2257 protected paths unchanged**, only five authorized existing files changed;
  no new unrelated files. Handoff.md, old reports, official source and existing importer WIP preserved.

## Visual inspection

Inspected original Phase 4C.1 and current Hanger screenshots at the same production framing; no observed
Player face/eyes/hair, weapon or equipment regression. Inspected current Office Terminal, Rocket,
actual enemy attack, hit/death and Result frames. KITE silhouette/bore/wreck remain rendered;
this phase authors no new mesh, character material, environment or VFX.

Evidence includes `route_Rifle/01_hanger.png`, `route_Rifle/combat_enemy_fire.png`,
`route_SMG/04_terminal.png`, `route_SMG/switch_0_Rocket.png`,
`route_SMG/combat_enemy_death_3.png`, `route_Rifle/06_result.png`, and both `07_return_hanger.png`.
No artificial showcase camera substituted for these route captures.

## Files / scope

Changed existing files (only):
1. `scripts/presentation/enemy_drone_presentation.gd` — native presentation/firing frame, no humanoid dependency.
2. `scripts/enemies/enemy_controller.gd` — presentation type/construction/getter/update glue only.
3. `scenes/enemies/enemy.tscn` — remove redundant follower child; controller owns native presentation.
4. `tests/acceptance_smoke.gd` — authorized enemy presentation contract migration + hit/death coverage.
5. `tests/visual_enemy_acceptance.gd` — driver property migration only.

Added: this Phase 4E evidence/verification directory (frozen oracle, reports, logs, screenshots, drivers).
Folder-local .gitattributes preserves exact oracle/evidence bytes across Windows checkouts.
Removed files: **NONE**. Existing legacy source assets/debug fixtures remain reference material, not a KITE runtime fallback.
Gameplay semantics / AI / hitscan-projectile behavior / Player / Unity-Chan / Arena / save format modified: **NO**.
Character generation / character remodeling / official source edits: **NONE**.

## Reproduction

Run from `D:/bunny_team`, with the baseline resources/imported project available:

```powershell
$env:BUNNY_EVIDENCE = 'D:/bunny_team/art_source/phase4e'
$env:APPDATA = "$env:TEMP/bunny_phase4e_probe"
& E:/Godot/Godot_v4.7.2-stable_win64_console.exe --path D:/bunny_team --headless --script D:/bunny_team/art_source/phase4e/contract_probe.gd
& E:/Godot/Godot_v4.7.2-stable_win64_console.exe --path D:/bunny_team --headless --script D:/bunny_team/art_source/phase4e/native_scene_probe.gd
python art_source/phase4e/run_regression.py
python art_source/phase4e/run_production_routes.py
python art_source/phase4e/verify_scope.py
```

Graphical runner requires a COPY of an existing real save in `local/original_profile.json` (gitignored);
its workspace.json points at isolated temporary userdata. Scope audit requires that same copy.
Cold import: run existing `tools/verify_migration.py` with `--godot`, `--import-only` and a **new** external output directory.

## Known issues / boundaries / next phase

- Main retains the documented non-blocking ObjectDB exit warning; no unrelated cleanup attempted.
- The route successfully extracts after enemy/Terminal objectives. Existing survey-zone objective is not
  visited by this route, so Result correctly says **MISSION INCOMPLETE**; no all-objectives-completed claim.
- Legacy humanoid debug scenes/assets remain in the repository and are tested as historical fixtures;
  production KITE does not instantiate/load them. Packaging/license audit for a public release remains
  a separate task, not certified by this dependency change.
- Existing uncommitted migration/source/importer WIP is still present and excluded from this commit.
  Cold import evidence describes the exact snapshot in its manifest, not a clean-clone guarantee.
- Next phase: stop here; separate user authorization needed for further art, release packaging or other systems.
