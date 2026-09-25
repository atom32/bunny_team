# Bunny Team Engineering Handoff

> **Authoritative status: Gameplay vertical slice complete; Visual Slice 01 integrated, full regression passes; visual quality/manual route acceptance still partial.**
>
> **Last updated:** 2026-09-25, after Visual Slice 01.
>
> Read this document first. Do not restart architecture, re-audit the whole project or repeat the asset search.

## 1. Current Phase / Exact Stop Point

**Visual Slice 01 — Weapon & Field Office Art Upgrade** was the latest authorized task. It superseded the former environment-only spike and explicitly included three weapon models.

Current art status: **Visual Upgrade Partially Complete — Asset Quality Limited**. The selected CC0 low-poly kit is integrated, licensed and working, with new roof/facade/interior dressing and weapon models. This is not a claim of final production art quality. The direct manual Field Office Enter/Exit check remains **NOT VERIFIED**; deterministic non-headless production-input traversal passes.

The playable loop remains:

```text
Hanger -> Loadout -> Deploy -> Outdoor -> Field Office -> Interior / Combat
       -> Terminal / Loot / Threat -> Back Exit -> Extraction / Death
       -> Result -> explicit Commit / Save -> Hanger / Warehouse
```

### Read these first, then stop or continue only within the next user request

- `docs/visual_slice_01/REPORT.md` — final selections, scope, test evidence, exact manual-verification limits.
- `ASSET_AUDIT.md` — current selection/licensing ledger (the earlier inventory is marked as inherited baseline).
- `scenes/areas/field_office_art.tscn` and `scripts/presentation/field_office_presentation.gd`.
- `scenes/weapons/{assault_rifle,smg,rocket_launcher}.tscn` and `scripts/weapons/weapon_visual.gd`.
- `tests/visual_slice_assets_test.gd`, existing `presentation_gameplay_test.gd`.

### Stated next task

No further implementation is authorized automatically after this stop. If asked to continue, first finish **direct WASD manual Field Office acceptance** with the current production camera: approach, open Door, enter, combat, Terminal, Back Exit. Review current screenshots/art quality with the user before further art expansion. Do not redownload packs, tune gameplay or start a second map.

### Completed in the latest pass

- Preserved all pre-existing definition Resources and arena gameplay placements byte-for-byte.
- Integrated 3 CC0 Kenney GLBs via the existing WeaponDefinition.scene mapping; no registry or PlayerController model-path lists.
- Kept AR combat markers; corrected socket-mounted SMG/Rocket display using the existing rig's pose/IK targets while retaining their gameplay muzzle/reload/recoil paths.
- Preserved Idle_Gun and AnimationTree ping-pong; preview begins at a three-quarter angle.
- Added one environment kit, a small authored office prop set, unified palette/materials, roof/canopy/sign/windows and 6 local unshadowed office lights.
- Added a roof cutaway on approach/inside for the current high-angle camera.
- Kept existing Field Office body/shape blocks identical; added no imported collision meshes.
- Dressed the rotating Door, existing cover and destructible Barrier; Barrier decorations disappear with the original visual.
- Added a visual asset regression test; made the two pre-existing interactive visual smoke scripts auto-advance/cleanly finish when headless.
- Captured new actual OpenGL gameplay and presentation images under `docs/visual_slice_01/captures/`.
- Native UI verified Hanger, three Primary weapon models, Warehouse equipped indicators, Deploy and Battle Q switching. Direct movement did not sustain under the UI tool's taps; the attempted native sortie ended in death and was closed without committing/saving. Do not call that a completed manual Field Office route.

## 2. Current Implementation State

### Content and definitions

- `ContentManifest` and `ContentDB` resolve stable IDs to static Godot Resources.
- Implemented definitions include items, equipment, weapons, ammo, enemies, missions, objectives, loot tables, and areas.
- Definitions are immutable configuration. Mutable combat, inventory, mission, and world state lives in runtime objects.
- `AreaDefinition` resolves `prototype_arena` to its authored scene; Area means **where**.
- `MissionDefinition` describes objectives; Mission means **what to do**.
- `EnemyDefinition` describes enemy configuration; `EnemySpawnPoint` determines where an enemy starts.
- `LootTableDefinition` describes what may spawn; `LootSpawnPoint` determines where loot appears.

### Profile, inventory, and persistence

- `ProfileState.inventory` is the persistent Warehouse.
- `LoadoutState` stores stable ItemInstance IDs for Primary, Secondary, Armor, and Backpack.
- `SortieRequest` contains area ID, mission ID, a loadout snapshot, and explicit carried item IDs.
- `SortieSession.inventory` is an isolated carried-inventory snapshot. It never shares mutable ItemInstance objects with the Profile.
- `SortieSession.initial_carried_instance_ids` records exactly what entered the sortie.
- Item stacking, splitting, consuming, capacity, and stable instance IDs are implemented.
- Warehouse capacity is `1000.0`; carried Sortie capacity is `100.0`.
- `ProfileRuntime` upgrades legacy loaded profiles to at least the current Warehouse capacity without changing the save schema.
- `SaveService` remains the only serialization boundary and uses the existing single profile save.

### Sortie lifecycle

```text
ProfileState
  -> SortieRequest
  -> SortieSession
  -> SortieOutcome
  -> SortieOutcomeService.commit_outcome()
  -> ProfileState
  -> SaveService
```

- `ACTIVE -> COMPLETED` occurs only through Extraction.
- `ACTIVE -> FAILED` occurs through player death.
- `ABANDONED` retains its existing no-recovery behavior.
- A successful Outcome merges the recovered carried inventory into the Warehouse using `initial_carried_instance_ids`.
- Failed and abandoned Outcomes do not modify the Warehouse.
- Outcome commit is idempotent.
- Mission completion and successful Extraction are separate facts. A player may extract with an incomplete mission.

### Weapons, ammo, and combat

- Primary and Secondary slots contain real ItemInstances and independent `WeaponRuntimeState` objects.
- Assault Rifle, SMG, and Rocket Launcher use the same production combat boundary.
- Magazine state is Sortie runtime state. Reserve ammo is carried inventory.
- Reload consumes only matching ammo definitions from the active Sortie inventory.
- Successful Extraction materializes remaining magazine ammo into carried inventory once before Outcome creation.
- Failed sorties do not materialize runtime magazine ammo and do not change the Warehouse.
- Combat delivery is:

```text
WeaponAction
  -> DamagePacket
  -> target.receive_damage(packet)
  -> target-side Armor / Health / Structure resolution
```

- Weapons do not inspect Basic/Heavy enemy identity or directly mutate target HP.
- Basic and Heavy enemies use the same controller and scene with different `EnemyDefinition` values.
- Cover is static and indestructible and blocks hitscan through physics collision.
- `DestructibleWorldObject` consumes only `structure_damage`; destruction disables its collision and visuals.
- Rocket explosion uses the same DamagePacket receiver path as hitscan/projectile combat.

### Missions, threat, loot, and world

- Objective runtime supports `ELIMINATE`, `INTERACT`, and `REACH`.
- Objective state belongs to `SortieSession`; UI reads it but does not calculate it.
- The authored Terminal records its interaction objective and is connected at the Area composition level to the local `ThreatEvent`.
- Threat is sortie-local: `NORMAL -> ALERT`, once, only while ACTIVE.
- Threat reinforcement reuses authored inactive `EnemySpawnPoint` nodes and `EnemySpawnService`; it does not create a global director or wave system.
- Generated loot becomes a real ItemInstance, enters only Sortie inventory, and reaches the Warehouse only after successful Outcome commit.
- Door, Cover, Barrier, objectives, extraction, loot, enemies, and threat are authored Area content and are freed with the Area.

### Hanger and presentation

- Hanger can configure Primary, Secondary, Armor, and Backpack, including `NONE` where valid.
- The Warehouse summary groups Weapons, Ammo, Equipment, and Salvage, and shows used/max capacity, quantity, weight, and equipped tags.
- Equipment changes refresh both UI and the character preview.
- Hanger uses the existing VRM character with the current idle animation through an active `AnimationTree`.
- `prototype_field_office.tscn` is a visually dressed traversable authored interior with floor, walls, roof framing, collision, front Door, interior Cover/Barrier, Terminal, loot, enemies, and a rear exit.
- The Field Office now uses a scoped low-poly CC0 visual slice; it is not a final map. See the current report for art-quality and manual-acceptance limits.

## 3. Important Architecture Decisions and Invariants

These are hard boundaries unless a future task explicitly changes them.

1. `ProfileState` owns persistent long-term state and the Warehouse.
2. `SortieSession` owns temporary carried inventory, weapon runtime, objective runtime, combat statistics, and threat state.
3. Profile and Sortie inventories use distinct InventoryState and ItemInstance objects.
4. Battle, Player, LootPickup, Door, objectives, enemies, ExtractionPoint, Result UI, and Area scenes never directly modify Profile.
5. Only `SortieOutcomeService.commit_outcome()` may formally apply sortie recovery to Profile.
6. `COMPLETED` means successful Extraction, not necessarily mission completion.
7. `FAILED` and `ABANDONED` do not mutate the Warehouse.
8. `GameState` is scene switching only. Do not put gameplay or persistence state in it.
9. `SaveService` is the sole persistence/serialization boundary. Do not add another profile or Outcome save.
10. Persisted data uses stable definition/instance IDs. Do not persist Nodes, NodePaths, scenes, or runtime Resources.
11. Magazine ammo belongs to Sortie runtime; reserve ammo belongs to Sortie carried inventory.
12. Definition Resources are static. Runtime state must not mutate definitions.
13. Weapons create DamagePackets; receivers decide how to consume them.
14. Area scenes own authored placement and local composition. They do not own Profile, Outcome, or Save behavior.
15. Mission, Area, Loot, Enemy, and world-interaction concerns remain separate:

```text
AreaDefinition    = WHERE
MissionDefinition = WHAT TO DO
EnemyDefinition   = WHAT ENEMY
EnemySpawnPoint   = WHERE ENEMY STARTS
LootTable         = WHAT LOOT MAY APPEAR
LootSpawnPoint    = WHERE LOOT APPEARS
SortieSession     = WHAT HAPPENED THIS SORTIE
```

## 4. Assets / Presentation Boundaries

- Kenney Space Station Kit 1.0: `assets/environment/kenney_space_station_kit/`, 16 selected GLBs; CC0.
- Kenney Blaster Kit 2.1: `assets/weapons/kenney_blaster_kit/`, only blaster-e / blaster-g / blaster-o; CC0.
- Each directory contains LICENSE.txt and SOURCE.md with original URLs and ZIP SHA-256.
- Existing VRM and Unity-Chan license materials are retained; no new character/animation source.
- Both palettes are 512 px. 19 GLBs total, 337,612 source mesh bytes. AR/SMG/Rocket: 802/618/664 triangles.
- Visual art owns no profile/session state. Window panels are sealed; wall collision remains fully solid.
- `track_socket_visual()` in CharacterCombatRig reuses existing targets but leaves `equipped_weapon` null and `has_weapon()` false for legacy socket weapons. Do not casually change this distinction: PlayerController still uses it for the original muzzle/reload/recoil behavior.
- Production Battle camera and GL Compatibility are unchanged. Alternate cameras/paused AI exist only in capture fixtures.
- Warehouse UI remains the existing inspection/configuration MVP; no stash redesign.

## 5. Validation Baseline

```text
All test scenes: 33/33 PASS (31 assertion suites + 2 scripted visual smoke flows)
ACCEPTANCE_SMOKE: PASS
PRESENTATION_GAMEPLAY_TEST: PASS
RESULT_RETURN_TEST: PASS
WORLD_TRAVERSAL_TEST: PASS
VISUAL_SLICE_ASSETS_TEST: PASS
Main headless: exit code 0
```

Inspect both exit code and log text (ERROR, SCRIPT ERROR, ': FAIL'). Do not match the word FAILURE in the successful SORTIE_FAILURE_TEST name. The two headless visual smoke passes are not image assertions or manual tests.

Main forced exit has an ObjectDB warning identifying the playing AudioStreamWAV/AudioStreamPlaybackWAV Music stream, no ERROR. The prior `4 resources still in use` errors from the two interactive visual test scenes were eliminated by completing/cleaning those headless runs. Audio lifecycle was not redesigned.

Run each test with Godot 4.6.3:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/xudawei/bunny_team res://tests/acceptance_smoke.tscn --quit-after 1200
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/xudawei/bunny_team --quit-after 180
```

Optional non-headless capture env vars: `PRESENTATION_CAPTURE_DIR`, `RESULT_CAPTURE_DIR`, `VISUAL_SLICE_CAPTURE_DIR`. Tests that persist state must use temporary save paths. The native UI review did not commit or save to user://profile.json.

## 6. Manual Status / Known Limits

- Hanger: VERIFIED (actual native UI).
- AR: VERIFIED (Hanger selection/held model; non-headless gameplay close-up).
- SMG: VERIFIED (Hanger selection/held model; non-headless gameplay close-up).
- Rocket: VERIFIED (Hanger model, Battle Q switch; non-headless gameplay close-up).
- Field Office Enter/Exit: NOT VERIFIED manually; the actual-window scripted production route passes and has screenshots.
- The low-poly sci-fi kit is a visual improvement, not a final production map/art set. The launcher uses a stylized four-tube model with unchanged single-projectile gameplay. Lighting/VRM material integration still needs an art-quality judgment; no bulk assets should be added to disguise this limitation.
- Git is initialized on `main` with `origin` set to `https://github.com/atom32/bunny_team.git`. Godot's generated `.godot/` cache, OS metadata and local credentials are excluded from version control. A pre-change local snapshot was retained at `/tmp/bunny_visual01/baseline` for this session; do not treat temporary files as durable project storage.

## 7. Do Not Do Yet

Do not add maps, open world, procedural generation, streaming, chunks, HLOD, large cities, multiplayer, networking, new combat/weapon/AI frameworks, balance changes, new weapons/ammo/enemies/objectives/loot, global EventBus/ECS, economy/trader/currency/crafting/insurance, grid stash/drag-and-drop/sorting/filtering/search, second saves, schemas or persistent Outcome logs.

Do not change the Outdoor -> Field Office -> Interior -> Combat -> Back Exit route or collision nodes to accommodate decorative art. Do not change renderer, add heavy GI/ray tracing, large textures or many shadowed lights. Preserve existing runtime/data ownership boundaries above.

The next work must start from these selected assets and evidence, not from a fresh design or whole-project audit.
