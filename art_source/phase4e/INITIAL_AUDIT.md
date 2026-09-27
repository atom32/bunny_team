# Phase 4E — KITE-07 dependency audit: BLOCKED

2026-09-27. Branch `main`, HEAD `c43264935d2e14b55a87837104ea87aabe3ba639`;
runtime baseline `a40b765`. Godot 4.7.2. Existing WIP retained.
**No production code, existing test, scene, character, weapon or asset was changed.**
Only read-only audit material was added in this folder. No commit / no push in Phase 4E.
The earlier user-authorized push already published c432649; this phase does not undo that.

## Blocking contract conflict

The request simultaneously requires removal of all legacy humanoid skeleton dependencies,
unchanged existing tests, and 33/33. The current production-enemy smoke checks require the
very implementation being removed, not just the gameplay behavior:

- `tests/acceptance_smoke.gd:311–340` obtains the first enemy from the real Battle scene.
- Lines 318–322 require `EnemyVRMModel`, a real character skeleton with >=90 bones,
  Retarget / ForwardAxisRetarget, an active AnimationTree, and the shared rifle combat rig.
- Lines 324–335 demand humanoid foot-animation direction samples.
- Lines 338–339 demand right/left hand-to-rifle IK errors under 2 cm.
- `tests/visual_enemy_acceptance.gd:71` directly drives `enemy.humanoid_visual.update_visual()`.
- The separate historical debug-page checks (`acceptance_smoke.gd:484–494`) also exercise the
  old humanoid fixture. They are distinct from the production enemy assertions above.

Removing the rig cannot satisfy those unchanged production assertions. Keeping it for tests,
adding fake model/bones/IK responses, conditionally instantiating it in test runs, or suppressing
the failure would violate the requested scope/intent. **Stopped before implementing a replacement.**
This is a test-contract incompatibility, not a finding that AI must be rewritten or that
the firing math is fundamentally inseparable from the character skeleton.

## Actual dependency trace

```text
EnemyDefinition.scene → scenes/enemies/enemy.tscn
  → EnemyController._build_visual()
    → HumanoidRetargetVisual (typed property + instantiated class)
      → preload AvatarSample_A + idle/walk/run FBX + assault_rifle.tscn
      → animation source skeleton / VRM skeleton / Retarget / AnimationTree / IK
      → EnemyCombatRig / FireReload / WeaponMount / EnemyAssaultRifle / Muzzle
        → get_muzzle_position(), get_muzzle_direction()
          → EnemyController._telegraph_shot(): actual hitscan origin/direction
          → KITE-07 Gun.global_transform: visual follower only
```

Specific source locations:

| Responsibility | Current implementation | Removal implications |
|---|---|---|
| Construction / type coupling | `enemy_controller.gd:24,158–173`; `humanoid_retarget_visual.gd:4–10,124–170` | Remove actual instantiation and class/resource dependency from the KITE production path; subclassing the old class would retain its preloads. |
| Animation / weapon pose / recoil | `humanoid_retarget_visual.gd:62–80,99–109`; `character_combat_rig.gd:108–173,183–186` | Separate only the enemy weapon pose math; do not edit shared Player rig or animation assets. |
| Actual firing | `enemy_controller.gd:229–266` | Preserve 0.38 s telegraph, locked aim point, cooldown RNG, ray mask/exclusion/length, damage packet, shot order and lifecycle guard. Existing enemy attack is **hitscan**, not a flying projectile. Do not add a projectile/speed model. |
| Gun / muzzle hierarchy | `character_combat_rig.gd:65–77,228–246`; `scenes/weapons/assault_rifle.tscn` | Existing Muzzle is a Marker3D below an ordinary transform node, **not a BoneAttachment child**. Rifle marker `(0,0.04,-1.48)` and mount scale `0.44` participate in the current output. Native marker must preserve resulting world transforms. |
| KITE visual attachment | `enemy_drone_presentation.gd:21–35,52–67` | Asset is parented under the legacy visual, then visible bore follows legacy Muzzle every frame. No native Muzzle Marker3D currently exists in the KITE asset. |
| Hit | `enemy_controller.gd:190–209` | Mesh overlay plus body_visual scale/rotation tween. Keep target semantics and transform response; these parent transforms can affect firing pose, so equivalence must include hit response. No skeleton is logically needed for the hit overlay. |
| Death | `enemy_controller.gd:269–278`; drone adapter `71–97` | Existing six-body RagdollProxy is built without sampling character bones. Adapter reskins its existing bodies and uses `drone_visual` metadata to avoid repeat selection. Preserve physics, RNG, signals, cleanup; migrate only visual ownership. |
| Lookup / groups | `enemies` group, typed controller property, `find_child("Gun")`, death `get_node()` part map | Do not change enemy group or spawn definitions. Discovery hits in Player/debug/tests are classified separately, not permission to change them. |

`dependency_search.json` contains lexical discovery with exact paths/line numbers. A keyword hit
does not itself prove a dependency. No additional `$...`, `%...`, exported NodePath or metadata-based
gameplay dependency on the old humanoid bones was found in the inspected production chain;
the direct typed property and weapon marker are the significant links.

## Read-only runtime confirmation

`scene_probe.gd` instantiates the **unchanged** production enemy in an isolated headless process,
disables physics for structural inspection, then frees it. It is not a combat/route or native-muzzle test.
APPDATA/LOCALAPPDATA redirected outside the real profile; exit **0**, no ERROR/WARNING in `scene_audit.log`.
Result: `scene_audit.json`.

- **Legacy AvatarSample_A runtime dependency: YES.** Scene path resolves to the real GLB,
  resource is cached, and its model is instantiated but hidden.
- Enemy subtree: **70 nodes**, **2 Skeleton3D** (140 animation-source bones + 91 VRM bones),
  **9 BoneAttachment3D**, **1 RetargetModifier3D**, **1 AnimationTree**, **2 TwoBoneIK3D**.
- Actual gun marker:
  `Enemy/EnemyCharacterVisual/EnemyCombatRig/FireReload/WeaponMount/EnemyAssaultRifle/Muzzle`.
- KITE asset path: `Enemy/EnemyCharacterVisual/KiteSecurityPresentation`;
  **0 native Marker3D** in that asset subtree.
- These are baseline counts, not an optimization result. Memory/FPS reductions were not measured.

## Smallest required change, pending test-contract authorization

1. Author an enemy-only native presentation with its own `WeaponPresentation/Muzzle`. Preserve
   the current `FireReload` pose filtering/aim/recoil math and marker world output, without
   importing HumanoidRetargetVisual, AvatarSample_A, skeletons, AnimationTree or a hidden fallback.
   Source inspection shows the pose calculation uses host transform + aim + recoil, while
   humanoid IK follows the weapon; no AI redesign is indicated. Numerical equivalence is **not yet proven**.
2. Change only enemy presentation construction/type/getter/update/recoil glue. Keep AI, attack
   decision, timing, damage, hitscan, movement, collision, spawn, hit/death gameplay unchanged.
   Reparent KITE visuals/hit targets to the native host; keep six-body death behavior.
3. **Requires an explicit exception to “do not modify tests”:** migrate the production-enemy
   implementation-specific portion of `acceptance_smoke.gd` and the driver reference in
   `visual_enemy_acceptance.gd` to a real native presentation contract. Keep 33 test scenes,
   all gameplay assertions, and independent historical rig/debug coverage if still desired.
   Replacement checks must assert actual KITE asset, finite native Muzzle, absence of legacy
   skeleton/resource dependency in production, aim consistency, recoil/hit/death and cleanup.
   Do not merely delete old checks or add fake legacy nodes. This audit does not authorize edits.
4. Keep legacy oracle in **external validation only**, not shipped fallback. The original
   Phase 4C.1 probe builds both sides from the same live EnemyController script; after migration
   that would no longer be an independent old baseline. Freeze the a40b765 implementation for
   comparison and keep the same 360 input samples and `< 0.00001` origin/direction tolerances.
   Report max/mean origin and direction deltas, and extend to relevant hit/rotation boundaries.
5. Only after removing the contract blocker, rerun fresh import, Main, all 33 tests, graphical
   enemy combat/extraction routes, Player/Arena checks and cross-process save/load. Re-audit
   AvatarSample_A **production** resource references separately from old diagnostic fixtures.

## Verification status for Phase 4E

| Gate | Result |
|---|---|
| Dependency/source and runtime subtree audit | Completed; current dependency confirmed |
| Native muzzle implementation | **NOT STARTED — BLOCKED** |
| Legacy dependency removed | **NO** |
| New 360-sample old-vs-native comparison | **NOT RUN**; no candidate; max/mean deltas N/A |
| Cold import / Main / 33 tests / graphical routes / save-load after migration | **NOT RUN**; no migration performed |
| Prior Phase 4C.1 results | Historical baseline only: 33/33, fresh import 0/0, Main0, two routes and 360 samples; not a Phase 4E PASS |
| Player / Unity-Chan / official source / Enemy gameplay / Arena / tests / existing WIP | Unchanged; verified against start-of-audit file hashes |
| Commit / push | None / NO |

No geometry or material work, new enemy type, UI/environment expansion, performance cleanup,
Gameplay rewrite, fake legacy node or test weakening was performed.
