# Phase 3C — semantic dependency inventory

Classification: A gameplay preserve; B presentation contract/implementation; C legacy
asset test assumption; D accidental presentation coupling. Repeated declarations and
queries are grouped below; semantic_search.json retains exact file/line hits. Generic
world node queries, LockerHandle substring matches, backpack item tags and input handler
names are not evidence of legacy character dependency. Nothing below authorizes refactoring.

| Dependency / source | Layer | Gameplay required? | Presentation required? | Migration action |
|---|---|---|---|---|
| PlayerController/Player scene, health, damage, movement, input, death | A | Yes | Actor host only | Preserve exact actor/script |
| ProfileRuntime, ProfileState inventory/loadout, ItemInstance IDs, SortieSession ID | A | Yes | No | Preserve schema/content and lifecycle |
| player preload avatar_sample_a.glb | B | No | Yes | Two-choice factory in isolated copy; legacy default |
| player J_Bip_* aliases and Skin bind-name duplication | B | No | Legacy compatibility | Unity already Character1_*; no destructive rename/rebind |
| player Skeleton3D lookup / shared bone profile / RetargetModifier3D | B | No | Yes | Keep shared humanoid source; existing adapter consumes target |
| Body/CombatAvatarModel/CharacterRetarget/CharacterAnimationPlayer/AnimationTree | B | No identity | Yes | Preserve actual semantic roots, not dummy nodes |
| Unity idle/walk/run/slide FBX, Take001 extraction/path rewriting | B | State semantics yes; file no | Yes | Existing source remains; no clip/state-machine edits |
| Idle/Walk/Run/Dodge state names, .12/.06 blend and manual advance | A+B | Existing state behavior | Yes | Preserve; only poses/materials vary |
| UpperBodyState/reload_duration/.is_reloading() | A+B | Fire gate consumes state | Yes | Inherited unchanged; must not add cinematic blocking reload |
| CharacterCombatRig Character1 arm/forearm/hand/spine/head names | B | No bone identity | Yes | Existing source names present on derivative; hand data adapter |
| ForwardAxisRetargetModifier Character1_LeftFoot probe / forward correction | B | No | Yes | Preserve retarget and existing tests |
| Chest/ShoulderL/ShoulderR/Backpack/HipL/HipR/HandL/HandR sockets | B | Equipment slot selection yes | Yes | Semantic names retained; only Chest/Backpack frame correction |
| HandR and ShoulderR attachments on Spine2 (not actual hand bone) | B | No | Existing socket contract | Do not redefine as anatomy; adapter owns actual hand targets |
| PrimaryGrip/SupportGrip/ReloadGrip/Muzzle in 3 weapon wrappers | B (+ A muzzle read) | Muzzle affects AR shot origin | Yes | No marker/definition edits; see muzzle boundary analysis |
| EquipmentDefinition.socket_name and scene | A+B | Definition/owned IDs yes | Attachment/mesh yes | Preserve definitions; consume semantic mounts |
| player Wep visibility filter | D | No | Package-specific | Conditional harmless; leave untouched |
| tests acceptance_smoke:142–143 Face mesh/local y > .2 | C | No | Old face integrity | Document unchanged; no fake Face |
| smoke CombatAvatarModel/CharacterRetarget, >=90 bones, IK/axis/hand error | B test contract | No direct gameplay identity | Yes | Remain real implemented nodes and unchanged assertions |
| smoke wording 'VRM' despite generic roots | C wording only | No | Not a runtime format check | Do not rename runtime/test to manufacture PASS |
| Hanger/Result instantiate scenes/player/player.tscn | A+B | Same Player host | Preview | Isolated factory affects common visual boundary, no Hanger fork |
| Hanger fixed camera/target/platform and Result preview position | B | No | Yes | Unchanged fixed human framing, visually checked |
| battle player spawn/configure_sortie and signals | A | Yes | Host | Same actor through sortie; no visual identity ownership |
| battle orthographic size24.5/focus actor+aim+0.85 | B | Aim ray uses camera | Yes | Preserve camera; no mesh-AABB framing dependency |
| Hitbox capsule .36 radius/1.85 height, center .93 | A | Yes | No | Independent of visual bounds; unchanged and probed |
| interaction radius2.6, door/Terminal/extraction/session checks | A | Yes | No | Actor world position, not mesh or bones |
| weapon range, enemy range/detection/navigation, projectile/blast radius | A | Yes | No | Definitions/actor coordinates, not new avatar dimensions |
| BODY_VISUAL_SCALE and Dodge squash/stretch | B | No collider scale | Yes | Unit visual scale, existing transient body-only tween |
| RagdollProxy shoulder/hip joint names and dimensions | B | Physics visual effect | Yes | Separate authored proxy, not imported avatar skin; unchanged |
| HumanoidRetargetVisual old avatar path/bone aliases/animation/palette | B/D enemy only | Enemy shooting reads its muzzle | Yes | Separate implementation, NOT switched by player factory |
| enemy Face/Hair mesh-name palette special cases | D enemy visual | No | Enemy tint | Preserve old enemy; do not falsely claim no runtime Face references |
| EnemyChestPlate/EnemyVisor attached to Spine2/Head | B enemy visual | No | Yes | Out of player scope; unchanged |
| enemy debug page roots/muzzle vectors/inspection camera | B tooling | No | Debug | Unchanged, not a player migration dependency |
| field_office_presentation world mesh/door/cutaway lookups | B world | No character name dependency | Yes | Unchanged; uses route/actor relationship not avatar mesh |
| loadout backpack tags/UI instance selection/warehouse text | A/UI | Yes | UI only | Not skeleton Backpack socket identity; preserve |
| weapon_visual MuzzleFlash/material effects | B | Not shot definition | Yes | Existing wrapper unchanged |
| world get_node/find_child for terminal/door/barrier/collision/threat | A/B world | Yes where interaction/collision | World art | Not legacy character dependency; preserve |
| tests scene/UI/world node queries and camera-size readability checks | A/B tests | Protect existing behavior | Some | Unchanged, both selection suites run |
| art_source probes and tools/phase2b_route_probe | B reference/tools | No production runtime | Evidence | Historical references not production ownership |

## Skeleton and animation boundary

Player still builds a hidden shared animation source, retargets onto the selected display
skeleton, and owns the same AnimationTree. Gameplay selects semantic locomotion state;
resource paths live in the controller's visual builder (localized coupling, not a new state
machine). Both implementations can consume those sources. The two isolated substitutions
are sufficient; no gameplay script is copied into GLB. Runtime_poses.json and hand modifier
remain presentation data. The adapter inherits base reload/recoil behavior and does not
change ammo, cooldown, damage, or movement. Static poses are manually authored, not official
weapon animations. Phase3A3/3B accepted visual limits remain, not production animation polish.

## Muzzle boundary (important mixed-layer contract)

PlayerController._try_fire reads CharacterCombatRig.get_muzzle_position when has_weapon
is true; otherwise it uses actor+UP*1.25+aim*.55. Thus muzzle transforms are NOT universally
cosmetic. Current Rifle runtime_poses weapon_origin is exactly (0,1.13,-.06), so adapter
translation relative to base is zero. Parent-local cache restores the unmodified base
pose before each update. SMG/Rocket track_socket_visual deliberately leaves has_weapon
false; their authored visual offsets do not replace gameplay's original actor-based muzzle.
Do not later change this flag, Rifle origin, or reload behavior as an innocuous visual edit.
This is a known existing gameplay/presentation boundary, not a reason to silently refactor.

## Dimensions / Hanger / Field Office

Only Face's local mesh AABB is an old-asset dimension assertion. Gameplay capsule is built
separately; interaction/detection/attack/extraction use actor position and explicit ranges.
Player has no mesh-derived navigation radius. Enemy navigation .45/1.8 and capsule .5/2.0
remain independent and unchanged. Hanger camera (−2.2,2.45,5.25), target (−2.2,1.15,0),
fov39 and platform character y .34 are visual framing choices, not identity or collision.
Battle uses player.tscn, configures the existing session, and follows that actor. Field
Office is part of that same sortie/area, not a second character instance. Terminal uses
InteractionComponent actor/session; no Face/mesh/bone path. Result legitimately instantiates
a new preview Player and commits the existing session, then Hanger makes a new preview.
Process-local node IDs are not expected to survive scene changes or reload.

## Release boundary, separate from technical readiness

Enemy still uses AvatarSample_A and its Face/Hair palette logic. Its unresolved public
shooting-demo authorization is NOT fixed by switching the player. Technical replacement
readiness cannot be advertised as full-game public-release clearance. Unity-chan remains
UCL/personal-demo scope with official provenance/credits; no AI input and no commercial
clearance claim. Do not change enemy as part of this phase.

## Supplemental groups / metadata / bounds search

Current scripts/tests exhaustive text search for get_aabb, mesh sizes, visual bounds,
person_id, add_to_group and set_meta found: player group on PlayerController; enemies
on EnemyController; interactable world objects; equipment_id metadata on actual equipment
instances; no character mesh-name groups or persisted avatar identity. Face is the sole
get_aabb assertion; VisualSliceAssets checks weapon renderable mesh count >1 (not old
character dimensions). Combat/VisualFactory mesh sizes are authored effect geometry.
HumanoidRetargetVisual is created by enemy_controller and enemy_character_debug, confirming
its Face/Hair special cases are enemy-only. Those runtime references must not be erased.
