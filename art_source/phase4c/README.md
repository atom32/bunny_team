# Phase 4C — Combat presentation / cover subphase

Baseline: `main @ cc81d3034d364d51f213cb9b5d1128d1564222a6`, Godot 4.7.2.
Scope: **C combat VFX + one D urban-cover asset**. A/B replacements deliberately deferred.
The evidence is scripted real OpenGL 1280×720 input/API validation, **not manual acceptance**.

## Delivered

1. **Security barrier**: one locally authored Blender master → GLB → presentation wrapper.
   - Eight existing arena cover boxes receive an armored shell, separate panels, corner guards,
     fasteners, hazard stripes, top identification bands and SEC stencil.
   - 1,100 triangles, five materials, one mesh, no textures or collision.
   - 2.798 × 0.897 × 0.579 m, inside the original 2.8 × 0.9 × 0.58 m collision bounds.
   - The old visible box is retained but hidden; all static bodies, collision layers/masks,
     shapes, transforms, navigation vertices and polygons remain unchanged.
   - No new placements, occluding clutter, decorative physics, level-generation rewrite or lights.
2. **Gunfire**: crossed directional flash quads replace the opaque ball/box flash; small dissipating
   muzzle smoke reuses Phase 4A SoftSmoke. Existing flash lifetime and lighting branch are retained.
3. **Impacts / death accent**: a camera-facing compact star replaces the solid impact sphere;
   smoke scales with the existing intensity, preserving original sparks and their random calls.
   The existing enemy death calls the same visual function with its existing higher intensity;
   no death hook, HP, death delay or ragdoll change was needed. The independent lifecycle exception
   is described below.
4. **Dodge**: thin low-opacity ring plus two short ground streaks, from the existing dodge callback.
   No body afterimage, body mesh copy, new animation or movement writes.

There is one new analytic VFX shader, no generated character texture, and no AI workflow.
Tracer, enemy telegraph, rocket trail and explosion functions remain byte-equivalent after newline
normalization. Phase 4A smoke/trail/props are retained, not rebuilt.

## Scope decisions

- **A Enemy visual — DEFERRED.** Existing `EnemyController` takes ray origin AND direction from
  `HumanoidRetargetVisual.get_muzzle_position()/get_muzzle_direction()`. Blindly replacing that rig
  with a drone risks changing actual fire. Keeping a hidden old avatar would retain its license
  dependency. A drone needs a separate future visual-boundary/equivalence spike; none was downloaded,
  generated or integrated here. Old enemy and pink prototype ragdoll remain visibly unfinished.
- **B Weapons — PRESERVED.** AR / SMG / Rocket are already distinct licensed models with accepted
  grip/pose adapters. No second weapon pack, new IDs or global transforms were introduced.
- Casing ejection, drone modeling, additional cabinets and large urban decoration sets were omitted
  rather than extending hooks or producing low-value asset volume.

## Locks and ownership

- Player geometry, official textures, material profile, UTS-subset shader, presentation adapter,
  animation and all eight semantic mounts: unchanged.
- Official Unity-Chan package recovery: 68/68 hashes checked against recovery manifest.
- Production GLB equals the original derivative conversion hash.
- Player controller, weapon definitions, weapon scenes, projectile logic,
  collision, routes, objectives, Terminal, extraction, save/load and equipment semantics: unchanged.
- **Procedural character generation: NONE. Character mesh remodeling: NONE.**
- `CombatEffects` is the only edited script that lived in the combat directory; changes are entirely
  visual. Its public signatures, call sites, global RNG consumption and combat timings are unchanged.
- All pre-existing tracked WIP is byte-compared to the initial snapshot. Two existing presentation
  files differ: `scripts/combat/combat_effects.gd` and `scenes/battle/urban_arena.tscn`.
  The only other existing-file changes are the separately authorized enemy lifecycle guard and
  test-only audio shutdown cleanup below.
- No changes to existing tests, no suppressed assertions, no fake legacy nodes.

## Evidence and verification

Open `comparison.html` for curated before/after images and production evidence.

- `arena_contract.json`: all 48 collision/navigation records equal; eight shells, no added physics,
  no bounds overflow. Before/after SHA-256 equal.
- `visual_probe.json`: identical next global random value for five effect families; all short-lived
  effect nodes cleaned up. Controlled fixed camera/light, same seed; tween sample at exactly 20 ms.
- `route_Rifle/` and `route_SMG/`: production Hanger → normal Sortie → Field Office door/interior/
  Terminal → combat/switch/reload → dodge → extraction → Result → Hanger. Normal AI and health.
  These routes validate successful extraction, not completion of all three elimination objectives.
- `combat_Rifle/` and `combat_SMG/`: additional normal-AI road engagements, only scripted movement,
  line-of-sight aiming and firing. Enemy death is observed from the production signal; no teleport,
  invulnerability, changed HP, direct damage call or modified AI. Target must be in the viewport.
- `persistence_Rifle/` and `persistence_SMG/`: separate-process reload; full profile serialization,
  item identity, loadout, warehouse merge and production Player are checked. Real save is copied
  for validation; its original SHA-256 is rechecked. Private working save copies are not committed.
- `regression/results.json`: the unchanged 33 test scenes plus Main startup/exit.
- `final_validation.json`: final gate results, source/WIP integrity, test warnings and route results.

### Problems caught, not suppressed

The first full regression was **29/33 clean** despite several test scripts printing PASS:
new VFX helpers incorrectly narrowed the existing parent contract from `Node` to `Node3D`.
Fixed only the new presentation helper:
accept the original `Node` contract and use a property tween with an explicitly initialized shader
parameter (required by the headless renderer). No test was changed. Initial logs/results and the
targeted fix verification are preserved in `diagnostics/`.
An intermittent exit resource error was subsequently identified by verbose logs as
`AudioStreamWAV` / `AudioStreamPlaybackWAV` (`impact.wav`), NOT a new VFX material. A capped-FPS
diagnostic did not fix it (2/6 failures). Those errors are retained and are not filtered as PASS.

### Separately authorized enemy lifecycle correction

Final log review caught an existing transition race despite the route checklist being green:
`EnemyController._telegraph_shot()` could resume its 0.38 s timer while the enemy or target was
detached but not yet freed during extraction → Result. `is_instance_valid()` alone did not protect
global-transform / physics-world access. Evidence: `diagnostics/pre_guard_route_Rifle.log` and
the pre-fix source comparison in `blocker.json` (identical to cc81d303).

Work was stopped and the user explicitly authorized **only** a minimal lifecycle protection.
One existing conditional now also checks `is_inside_tree()` for the enemy and target after the
same await. A detached callback takes the already existing cancellation branch. No active-scene
AI, parameters, cooldown, damage, ray direction, spawn, death or extraction rules change.

`lifecycle_probe.gd` deterministically tests active / enemy detached / target detached / both
detached: 16 checks, normal active fire retained and all three detached cases safely canceled.
This is an additional authoring-side regression probe; the existing test-suite count remains 33.
The lifecycle change is committed separately from visual assets and full routes/regression are
rerun after it. It must be disclosed as an authorized code exception, not described as zero enemy
source edits. Initial probe parser diagnostics are retained; the final probe loads the production
scenes at runtime so project autoloads are registered before controller compilation.

### Separately authorized test audio shutdown cleanup

The user separately authorized changing **only `AudioDirector.shutdown_for_test()`**. Normal music,
SFX playback, streams, RNG, bus parameters and existing test assertions remain byte-equivalent.
The final fix retains immediate node release and adds a test-only wall-clock drain of two audio
driver periods (+10 ms), derived from AudioServer's mix timing. This is about 197 ms on this
workstation's headless Dummy driver, not an additional gameplay delay.

Root cause evidence: after a long frame, a SceneTreeTimer(0.2) expired with **0–1 ms wall time**
in the resource probe, while the Dummy audio driver mixes roughly every 93 ms. `stop()` submits
asynchronous audio work; the engine may still hold WAV/playback references at immediate exit.
This matches the separation between stop requests, audio mixing and main-thread cleanup in the
[Godot audio player implementation](https://github.com/godotengine/godot/blob/master/scene/audio/audio_stream_player_internal.cpp)
and [AudioServer implementation](https://github.com/godotengine/godot/blob/master/servers/audio/audio_server.cpp).
These upstream references explain the mechanism; local logs, not upstream version assumptions,
are the acceptance evidence for this workstation's 4.7.2 binary.

Rejected attempts are retained in `diagnostics/`: queue_free alone (8/8 exit errors), audio lock
alone (4/8), and capped frame rate (2/6). None is in the final code. No log filtering or retry-until-
green was used. `run_audio_shutdown.py` runs a fixed 20 unchanged world-interaction tests plus
five new resource probes. The probes exercise music + all 20 SFX players, verify released playback
resources with weak references, empty owner references, idempotence and harmless late callbacks.
**25/25 PASS**, no ERROR or warning; the main suite remains the same 33 tests.

The initial performance sample was unstable (VSync / frame-monitor sampling). Kept as
`performance_initial.json`, NOT used to claim a performance improvement. Final `performance.json`
uses an ABBA repeat, VSync off only in the probe, 60 warm-up + 120 measured frames per state,
same frozen production camera/scene. The measured interval is not GPU time or live combat FPS.
Memory is Godot's allocation monitor, not whole-board VRAM; both assets are loaded in both states.

Blender reports unused startup grease-pencil brush paths while saving the master. These are not
used/exported: the runtime GLB contains only the one static mesh and five listed materials, with
no image/brush dependency. The build log is retained; this is not described as warning-free.

## Reproduction

1. `Blender --background --python art_source/phase4c/build_barrier.py`
2. Godot `--headless --path D:/bunny_team --editor --import`
3. `python art_source/phase4c/run_probes.py`
   Also run Godot headless `--script art_source/phase4c/lifecycle_probe.gd` with `BUNNY_EVIDENCE`
   set to this directory for the separately authorized lifecycle regression.
4. `python art_source/phase4c/run_combat_lanes.py`
5. `python art_source/phase4c/run_production_routes.py`
6. `python art_source/phase4c/run_regression.py`
7. `python art_source/phase4c/run_audio_shutdown.py`
8. `python art_source/phase4c/verify_final.py`

`workspace.json` records this workstation's paths. Route runners require an existing-save COPY at
`local/original_profile.json`; never supply the user's live save as a writable test path. Run the
graphical jobs serially. `local/` is excluded from Git; `.gdignore` excludes all source/evidence from
Godot runtime import. Masters are not runtime dependencies.

## Files / assets

New runtime files: `assets/environment/urban_defense/` (one GLB + provenance),
`scenes/presentation/urban_defense/security_barrier.tscn`, `scripts/presentation/urban_defense.gd`,
`scripts/presentation/combat_accents.gd`, `resources/vfx/combat_flash.gdshader` and Godot sidecars.

New authoring/evidence: this directory (one `.blend`, deterministic source, export metrics,
validation probes, logs, screenshots and reports). No parallel character hierarchy.

Edited existing files: the arena scene's new presentation child, `CombatEffects` visual
construction, the separately authorized enemy lifecycle conditional, and the separately authorized
test audio shutdown drain. Handoff / inventory / previous derivative README contain unrelated WIP, so this
self-contained checkpoint report does not overwrite those documents.

## Release / remaining limitations

- Internal-demo presentation subphase only; **not commercial-release clearance**.
- Enemy AvatarSample_A license remains **PUBLIC RELEASE BLOCKED**; it was not modified or replaced.
- Existing prototype enemy/ragdoll, UI, city buildings and weapon meshes remain as before.
- No broad weak-hardware benchmark, new enemy candidate, new weapon visual or final-city art claim.
- Automated screenshots and review are not claimed to be human keyboard/mouse acceptance.
- Commit records only this subphase; existing importer/configuration/WIP changes are not bundled.
- Push: **NO**.

## Final checkpoint — 2026-09-26

**PASS — bounded C+D presentation subphase.** This is not completion of A/B enemy/weapon replacement.

| Gate | Result |
| --- | --- |
| Existing regression suite | **33/33 PASS**, all exits 0, no ERROR / SCRIPT ERROR |
| Main headless launch/exit | **0**, no ERROR; known two-instance ObjectDB exit warning remains |
| Hanger / Field Office / Terminal / Sortie | PASS, production camera and normal scene paths |
| AR / SMG / Rocket / reload / dodge | PASS, original weapon definitions and gameplay untouched |
| Extraction → Result → Hanger | PASS, both Rifle and SMG routes (32 checks each) |
| Cross-process save/load | PASS, two independent restarts; user's actual save hash unchanged |
| Normal-AI enemy interaction/death | PASS, additional Rifle and SMG road engagements |
| Authorized pending-shot lifecycle guard | **16/16 PASS**; active shots still fire |
| Authorized test-only audio cleanup | **25/25 processes PASS**, no errors or warnings |
| Arena collision/navigation | **48/48 records identical**, eight visual-only wrappers |
| Official Unity-Chan source | **68/68 hashes identical** |
| Player geometry/textures/materials/adapter | **UNCHANGED**, no procedural character work |
| Pre-existing WIP and existing test files | **UNCHANGED** relative to start-of-phase snapshot |

The older arena-only probe also retains the known two-instance ObjectDB exit warning. These
warnings are recorded, not filtered or described as a warning-free project. Failed diagnostic
experiments remain in their separate historical directory; they are not final acceptance runs.

Production 1280×720 static ABBA render measurement (not combat FPS): mean wall-frame interval
**0.828 / 0.828 ms before → 0.857 / 0.854 ms after**; draw calls **854 → 870**; submitted primitives
**86,951 → 88,479**. Godot video allocation **320,085,000 bytes** in both states with both asset
versions resident. This is a small measured static cost, not proof for low-end hardware.

One Blender master / one runtime GLB / one wrapper / one shader / two presentation helper scripts
were added. Existing runtime edits are exactly four files: two visual integration files and the two
explicitly authorized cleanup exceptions. No Terminal, enemy visual, player, weapon, level generator,
gameplay parameter, save schema, official source or Phase 4A asset was modified.

Commits are separated into enemy lifecycle protection (`d69b56c`), test audio cleanup (`ea16447`), and
**`Phase 4C: expand combat visual assets`**. No push. The final commit ID is reported with the task
result; this report does not attempt to embed its own self-referential commit hash.
