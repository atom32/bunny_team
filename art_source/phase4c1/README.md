# Phase 4C.1 — compact autonomous security drone

Baseline `main @ e915d21`; existing WIP preserved in the authoring snapshot.

**Status: PASS — production visible-presentation replacement.** Final automated graphical
routes, cross-process saves, 33/33 regression and fresh cold import have passed. This does not
clear public-release licensing or remove the retained legacy firing dependency described below.

## Contract decision (before asset production)

`EnemyController` owns health, movement, detection, navigation, targeting, cooldown, hitscan,
damage, death signal and lifetime. The old `HumanoidRetargetVisual` owns the animated weapon
rig, but `EnemyController._telegraph_shot()` consumes that rig's Muzzle for actual ray origin
and direction. The current acceptance test also requires its real VRM skeleton, retarget,
AnimationTree, hand IK and six-body death proxy. These are not removed, faked or bypassed.

This phase replaces **visible presentation only**. A scene child hides the legacy meshes and
adds the authored unmanned platform; it reads the original Muzzle without writing it. The
existing humanoid rig remains the actual compatibility driver, not a test-only dummy. On death,
only the meshes of the already-created physics proxy are replaced; physics, random calls,
signals, collision shapes and the original 8-second cleanup remain unchanged.

Consequently **AvatarSample_A remains a runtime dependency and its public-release license
blocker remains unresolved**. This is not a claim of asset-dependency removal or release clearance.
Removing the legacy driver and migrating its implementation-specific tests is a separate phase.

No player, shared character rig, controller, weapon, level generator, Arena, source character,
animation state machine, existing test or save implementation is authorized for modification.

## Asset / integration

**KITE-07**, a project-original compact hover security unit: swept ceramic hull, two shrouded lift
pods, split muzzle brake, optical slit/rangefinder, radiator cassette, intake louvers and unit marking.
Oxide armor / dark carbon mechanisms / warm titanium / small orange-red optics. No downloaded
pack, branded military replica, humanoid generation, character edit, AI input or texture generation.

- `enemy_master.blend` → `assets/enemies/kite_security/enemy_visual.glb` →
  `scenes/presentation/enemies/kite_security.tscn`.
- Blender 5.2.2 LTS, meters, unit scale 1, Z-up → glTF Y-up; no corrective -90-degree runtime hack.
- **11,092 triangles, six rigid mesh parts, six materials, no texture, no bones, no animation clips,
  no collision** in the added model. Existing compatibility rig costs are retained, not eliminated.
- The only changed pre-existing file is `scenes/enemies/enemy.tscn`: one visual-only script child.
- `scripts/presentation/enemy_drone_presentation.gd` waits for the existing controller to finish
  setup, hides legacy rendering, and instantiates the authored wrapper under the existing body visual.
- The Gun object's origin is the visible bore; its world transform reads the existing Muzzle each
  rendered frame. It never moves that marker, alters the ray, or writes to the combat rig.
- Idle: 12 mm visual hover; movement: mild pod stabilization; attack: existing recoil movement and
  telegraph-controlled optics; hit: original hit overlay/VFX; death: original six physics bodies with
  six matching visual parts, original impulses/joints/colliders/RNG and eight-second cleanup.
- A deferred resource load avoids demanding a new GLB during editor autoload parsing, before the
  import queue has run. There is no asset-generation code in the game runtime.

## Validation

See `final_validation.json` for the fail-closed final status and `comparison.html` for reviewed images.
The existing suite is **33/33**, unchanged; additional authoring probes do not change that count.

- `contract.json`: **360 samples** over Idle / Walk / Run, changing aim, yaw and recoil. Old vs new
  gameplay fire-origin error **0 m**, direction-vector error **0**. Visible bore offset is below
  **0.000001 m** (floating-point transform roundoff).
- Collision/navigation records, spawn RNG, applied damage/health/dead state, deferred deletion,
  death RNG, all six rigid-body transforms/masses/velocities/shapes, all five joint paths and cleanup
  timer are equal. The hidden skeleton remains real and evaluated; no fake test nodes are added.
- New clone with no `.godot` cache: **cold import 0 ERROR / 0 WARNING**. Exact new runtime source
  hashes are retained in `cold_import_sources.json`; full snapshot remains outside the repository.
- Main: exit **0**, existing two-instance ObjectDB exit warning remains. No runtime ERROR accepted.
- Both Rifle and SMG routes run Hanger → normal Sortie / Urban Arena → Field Office / Terminal →
  enemy encounter / attack / hits / deaths → extraction → Result → Hanger. Each also verifies Rocket,
  switching/reload and dodge. **39 checks per route**, normal health/AI, no teleport or direct damage.
- Each route has an independent process restart and five save-load checks. Warehouse merge is
  independently compared against the outcome. The live user save is hash-checked and never written.
- Both routes verify all eight Phase 4C cover shells remain; Arena files, collider/navigation layout,
  player geometry/materials/shader/adapter, weapon definitions, controller and existing tests are
  byte-identical to the start-of-phase snapshot. Official Unity-Chan: **68/68 source hashes equal**.

### Visual review

Real Godot OpenGL screenshots, not Blender beauty renders. Controlled front/side/rear and
near/medium/far views make the hull, gun direction, twin pods and optics readable. At the production
top-down distance the paired pods and red/ivory blocks distinguish the drone from the slim cyan
player; vents/stencils intentionally become secondary details. The short existing flash/impact does
not permanently cover the unit. Death leaves mechanical pieces, not pink humanoid cubes.

`route_Rifle/` and `route_SMG/` use the unmodified production camera, **1280×720** viewport. The
controlled fixture uses alternative cameras and scripted states only for asset inspection; those
captures are **not** used as proof of normal AI. Production route checks use real AI and input/API.
Neither route is claimed as manual keyboard/mouse acceptance or completion of all mission goals.

### Diagnostic failures kept separate

- Initial isolated probe referenced EnemyController before autoload registration: fixed by loading
  the production script at runtime in the probe, not changing the controller.
- Initial death-proxy inspection assumed an automatically named CollisionShape3D; corrected the
  probe to inspect the actual typed child. All final logs are also checked, not just JSON booleans.
- Initial new-GLB preload caused an editor import-order error. Presentation loading was deferred;
  a genuinely fresh independent cold import proves resolution, not a warm-cache retry.
- First route's cover assertion assumed all eight runtime-instantiated nodes kept identical names.
  It now checks the actual eight children and eight retained original meshes on the existing wrapper.
  A resized window also reduced capture resolution; the probe now fixes the **test viewport**, not
  project configuration or camera, to 1280×720. These initial logs are preserved in `diagnostics/`.
- A deferred screenshot observer briefly held a freed muzzle-flash node. The **probe only** now
  resolves the instance ID at observation time. Production effects and lifecycle code were not changed.

## Reproduction / file boundaries

1. Blender background: `--python art_source/phase4c1/build_enemy.py`.
2. Godot editor import; the `.import` sidecar travels with the runtime GLB.
3. With `BUNNY_EVIDENCE` pointing here, run Godot headless `--script .../contract_probe.gd`;
   run `visual_probe.gd` with OpenGL at 1280×720 for controlled screenshots.
4. Put a COPY of a real game save at `local/original_profile.json`, then
   `python art_source/phase4c1/run_production_routes.py`.
5. `python art_source/phase4c1/run_regression.py` and `python art_source/phase4c1/verify_final.py`.

`local/`, working profile copies and Blender backup files are ignored. Source/evidence has
`.gdignore`. No source script or Blender master is a runtime generation dependency.

Files added: the one master/export source, runtime GLB/import/provenance, presentation wrapper,
presentation script, comparison gallery and validation evidence. Existing file changed: only the
enemy scene's presentation child. Unrelated WIP, previous reports, player and Arena remain untouched.

Commit: `Phase 4C.1: replace enemy visual presentation`. Final hash is in the task result.
Push: **NO**.

## Known limits / release boundary

- **Visual replacement only.** AvatarSample_A and the legacy rifle/skeleton still load, hidden, to
  preserve actual current firing behavior and the unchanged implementation-coupled tests.
- **Public release authorization remains BLOCKED** for that retained asset. Do not market this as
  a license-cleared dependency replacement. The new drone asset does not grant licenses to old assets.
- The enemy debug page remains the legacy rig diagnostic; production enemy scenes display KITE-07.
- No low-end hardware certification, new AI, new weapons, Arena work or player changes.
- **Player character modified: NO. Official Unity-Chan source modified: NO. Enemy gameplay
  modified: NO. Arena gameplay modified: NO.** Procedural hard-surface drone authoring: YES,
  explicitly in scope; procedural human/player character generation or remodeling: NONE.
