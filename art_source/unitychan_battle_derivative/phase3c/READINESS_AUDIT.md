# Phase 3C readiness audit — IN PROGRESS

## Rollback baseline

`baseline.json` and `git_status_before.txt`: main @ ec5f18d. Production player still
preloads avatar_sample_a.glb; Unity-chan derivative and Phase3B master preserved. No
production edits, reset/discard, commits or push. Phase3B uncommitted WIP remains intact.

Initial semantic search scans 210 project GDScript/scene/resource/shader/config files,
including historical derivative code separately: 379 runtime/test/tool hits and 79
reference hits (`semantic_search.json`). Hits are discovery evidence, not migration
approval. Generic engine node queries are not automatically old-character dependencies.
Binary GLB and source-package metadata are not treated as executable gameplay code.
Full per-dependency classification and the reversible experiment are still pending.

## Confirmed dependencies / initial classification

| Dependency | Layer | Gameplay required? | Presentation required? | Action |
|---|---|---|---|---|
| PlayerController extends CharacterBody3D, health/motion/dodge/input/session fields | A gameplay | Yes | No | Preserve actor/script behavior |
| scenes/player/player.tscn name Player/script | A actor identity contract | Yes | Hosts visual | Preserve; never put gameplay in GLB |
| CHARACTER_SCENE preload avatar_sample_a.glb | B presentation, implementation coupling in controller | No | Yes | Isolated selection boundary, legacy default retained |
| CHARACTER_BONE_RENAMES J_Bip_* → Character1_* | B old-VRM compatibility detail | No | Yes for legacy | Preserve; Unity-chan already uses Character1_*; no rename/rebind needed |
| CHARACTER_ANIMATION_SCENES Unity-Chan idle/walk/run/slide FBX | B animation source | State names yes, FBX path no | Yes | Retain shared source/retarget; do not redesign |
| Skeleton3D find_child + CharacterRetarget reparent/profile | B rig implementation | No | Yes | Existing presentation adapter boundary; validate both choices |
| Body / CombatAvatarModel / EquipmentRoot / WeaponRoot | B semantic visual roots | No identity data | Yes | Preserve existing names; not fake test nodes |
| Chest, ShoulderL/R, Backpack, HipL/R, HandL/R | B semantic mount interface | Equipment uses contract | Yes | Preserve names; variant-specific frames in adapter only |
| Chest/Backpack local frame discrepancy | B variant frame | No | Yes | Existing Phase3B correction, not new migration redesign |
| Wep child visibility filter | D package-specific visual workaround | No | Legacy only | Harmless conditional; no gameplay change required |
| Face mesh name/local AABB in acceptance smoke | C legacy assertion | No | Legacy visual integrity intent | Document, do NOT edit test or add fake Face |
| ProfileState inventory/loadout + ItemInstance IDs | A persistence | Yes | No model dependency | Preserve schema and all content/instance IDs |
| EquipmentDefinition.scene / content IDs | B asset reference + A owned item identity | Content ID yes | Scene yes | Definition content is not serialized avatar identity |

## Exact Face assertion

Legacy assertion: `tests/acceptance_smoke.gd:142-143`, inside
`_test_hanger_and_equipment()`:
`find_child("Face", true, false) as MeshInstance3D`, then `face != null &&
face.mesh.get_aabb().size.y > 0.2`.

Actual protected behavior: the selected original imported avatar retained a substantial,
complete authored face mesh (rather than missing/reduced facial geometry). This is local
mesh-space visual integrity, not character capsule height, hitbox, interaction reach,
movement or identity. The old assertion message emitted via line 46 is NOT its definition;
previous logs pointing at line 46 only identify the generic error-reporting loop.

Current dependency: original asset mesh node named Face, local mesh AABB y threshold .2.
Unity-chan official face topology/node partition differs. No gameplay code has been found
reading this Face node in the initial search. Test remains byte-for-byte unchanged.

Correct long-term abstraction recommendation: retain a legacy-specific asset-integrity
fixture for AvatarSample_A and introduce a separately reviewed presentation validation
contract (complete visible skinned renderers, finite nonzero visual bounds, expected semantic
mounts/animation availability). Use per-asset facial integrity evidence, not a fake common
Face node or an arbitrary universal AABB threshold. No test change in Phase3C.

Migration risk: low for gameplay, medium for visual coverage if the assertion were simply
deleted. Keep the known 32/33 until a deliberate test-contract migration is authorized.

## Important identity / save schema finding

Current `ProfileState` has only persistent warehouse inventory and loadout. `to_dict()` /
`from_dict()` serialize those two fields. SaveService schema 1 wraps the profile dictionary.
ProfileRuntime owns one profile and loads/saves it; SortieSession carries session_id and
copies owned equipment instances into the carried inventory.

There is **no Person class, Person ID, player-avatar path, player model name, persistent
health/progression/economy field** in the inspected current profile schema. Do not invent
a Person ID or silently expand the save format to satisfy the wording of this task.
Migration must prove preservation of the existing logical profile and owned item IDs,
loadout, quantities, carried/warehouse transitions and committed result. It cannot claim
verification of a nonexistent Person-ID field. A live Player instance remains the same
actor through the sortie; Hanger/Result scene changes legitimately create different Node
instances. Cross-process identity must be checked from serialized gameplay data, not
Godot process-local object instance IDs.

## Remaining work

- Finish grouped classification of all search hits, bounds/collision/camera/animation/
  weapon and scene ownership, including enemy references (do not change enemy).
- Build fresh isolated copy with reversible legacy/unitychan visual selection; production
  file stays unchanged. Use existing presentation adapters rather than new architecture.
- Test existing save through Hanger, normal route including actual Dodge, Result→Hanger,
  save and a separate process reload. Compare full gameplay serialization and owned IDs.
- Run relevant unchanged regression and verify default legacy rollback works.
- Final README section and readiness decision only after this new evidence exists.

## Reversible switch evidence (current checkpoint)

Fresh Phase3C snapshot uses exactly two presentation-only expression substitutions in
its copied PlayerController: model instantiation factory and combat-rig factory.
`presentation_switch.gd` defaults to the original legacy model/rig; only environment
`BUNNY_PRESENTATION=unitychan` selects the derivative. No identity, save selection,
gameplay scripts in GLB, or production file edits. See `isolated_changes.json`.
Fresh import: exit 0, 0 ERROR, 0 WARNING; 68 official hashes unchanged.

Full unchanged tests with default legacy: **33/33**, MAIN exit 0.
Same snapshot with Unity-chan selection: **32/33**, MAIN exit 0; only failure remains
exact Face assertion. All Presentation/World/Visual/Result suites pass. ObjectDB exit
warnings are retained in individual logs, not called warning-free.

Separate processes: legacy process saved a normal schema-1 profile through SaveService;
Unity-chan process loaded it through ProfileRuntime and matched the entire serialized
inventory/loadout. Hanger selected the correct presentation; gameplay capsule remains
radius .36, height 1.85. This proves pre-sortie save compatibility ONLY, not the required
post-extraction restart yet. `persistence/seed.json`, `verify_before.json`.
The first standalone harness eagerly referenced PlayerController's class before autoload
compilation and failed; fixed harness to compare its script resource path instead. Initial
failure retained as seed_initial_harness_compile_failure.log; no production fix needed.

Still pending: full semantic classification, route including real Dodge, Result return,
post-result state snapshot and separate-process reload. NOT Production Replacement Ready.

## Full Rifle/Rocket route + post-extraction restart evidence

`route_Rifle/route_result.json`: all 32 checks true; renderer OpenGL at 1280x720.
Loads an existing schema-1 save authored by the legacy process, then Hanger DEPLOY,
Field Office door/interior/Terminal completed, four weapon switches and actual reload,
input-driven Space Dodge with live dodge timer + displacement, exit/original route,
extraction COMPLETED, Result, production return signal, commit/save, Hanger. No teleport,
invulnerability, enemy removal or gameplay state forcing. Same Player node/session through
sortie and same ProfileRuntime profile object across scene return. Result session ID matches.
60 shots, 15 damage received, 0 enemies defeated; overall mission false (not all objectives),
but extraction/result succeeded. This is automated graphical/API evidence, not manual.

`persistence/reload.json`: separate new process reloads post-result save, compares full
profile and restores Unity-chan under the explicit presentation selection. A default legacy
process would still intentionally select legacy; presentation is not serialized identity.
`identity_verification.json`: independent Python warehouse merge equals uncarried items plus
recovered outcome, equipment instance IDs/loadout preserved, schema 1 unchanged, save equals
committed profile and reloaded profile. Ammo quantities legitimately change with combat.

`07_return_hanger.png` visually reviewed: Unity-chan and equipped Rifle/backpack remain on
production Hanger platform; HUD warehouse/loadout populated. No camera/material edits.
Remaining: semantic dependency classification completion; final evidence/integrity audit.
No production replacement, commit or push. Do not infer readiness solely from this route.

## Dependency classification checkpoint

DEPENDENCY_INVENTORY.md now groups discovered semantic dependencies into A/B/C/D, with
source ownership, dimension, camera, animation, mount, muzzle and release-boundary analysis.
Important correction to initial search wording: there IS a runtime Face/Hair mesh-name
special case in HumanoidRetargetVisual._apply_enemy_palette (enemy only). No player
Gameplay Face dependency found; enemy is untouched. Therefore full-game public-release
license remains blocked independently of player technical migration readiness.

A mixed-layer dependency deserves explicit parity proof before final approval: AR shot
origin is consumed from the presentation rig. Current Rifle authored origin offset is zero;
SMG/Rocket preserve has_weapon=false and original actor-based shot origin. Do not change
these semantics casually. Next: paired legacy/Unity-chan muzzle/reload contract probe and
SMG through the reversible selector; then final integrity/requirement audit. No new
architectural blocker established, no production code edits.
