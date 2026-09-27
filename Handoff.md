# Bunny Team — Current Project Handoff

## Current checkpoint — Phase 4D (2026-09-27)

- 项目：**Neon Bastion / Bunny Team**，日系科幻机娘俯视角撤离射击游戏；`D:\bunny_team`。
- **运行内容基线：`main @ a40b765`**（完整 SHA：`a40b7658f9fe282697ce6887a76d59ea2d64b94b`）。
- Godot **4.7.2**；当前本机配置为 GL Compatibility，入口 `scenes/hanger/hanger.tscn`。
- **Internal Demo checkpoint / Not pushed**。Phase 4D 只追加文档提交，最终 HEAD 请用 `git log` 确认；运行内容基线不变。
- **可完整跑通、可录制展示的内部 Demo；不是内容完整版本，也不是公开发行版本。**
- 工作区有意保留历史 WIP。验证描述的是本机含 WIP 的工作区，**不保证仅 checkout 此 SHA 就能复现全部本地证据或迁移状态**。

## PLAYER CHARACTER HARD RULE

> Do not procedurally generate, reshape, sculpt, remodel, AI-edit,
> or regenerate Unity-Chan character geometry or character textures.
>
> Official source is immutable.
>
> Current visual issues must be solved at presentation/material/lighting
> level unless explicitly authorized otherwise.

玩家 geometry、贴图、官方包均锁定；不要把 Unity-Chan 送入 AI workflow。
保留 `Chest / ShoulderL / ShoulderR / Backpack / HipL / HipR / HandL / HandR`。
不要为敌人或环境问题修改玩家。Phase 4D 不修改任何材质、灯光、模型或运行代码。

## Current gameplay flow / ownership

```text
Hanger → Sortie → Field Office / Terminal → Urban Arena combat
       → Extraction → Result → Hanger
```

Field Office 是 Sortie 的 Urban Arena 内部区域，不是新增的独立关卡切换。
Player/Enemy controller 继续拥有 gameplay，视觉 asset/adapter 不拥有游戏状态。
Person/逻辑身份、WeaponDefinition、weapon IDs、伤害、射速、弹药、换弹、移动、闪避、
碰撞、AI、导航、spawn、交互、撤离、经济、Warehouse / Save / Result contract 均保持原有语义。
存档 schema 1 保留 owned-item IDs / loadout / inventory；**没有独立 Person ID 字段，不要补造**。
艺术扩展未重设计 gameplay；历史独立授权修复仅包括离场射击回调保护 `d69b56c`
和测试退出音频清理 `ea16447`，不能据此扩大后续 gameplay 改动范围。

## Current visual state

| 模块 | 当前实现与边界 |
|---|---|
| Player | **Unity-Chan Battle Costume 已是 production player**（`955ce1f`）；Face / Eyes / Hair 材质语义已恢复（`cc81d30`）。官方 source 68/68 hashes unchanged；无程序化人物生成、无人物 mesh remodeling。不是 Unity UTS 像素级复刻声明。 |
| Weapons | AR / SMG / Rocket；原有握持/挂载、切换、换弹和射击已验证，没有新增 weapon ID 或 gameplay。 |
| Enemy | **KITE-07 已是 production enemy presentation**（`a40b765`）；仅替换可见模型，旧 AvatarSample_A 及 humanoid firing rig **仍实际加载并参与运行**，不是 enemy system fully migrated。 |
| Environment | Hanger / Field Office 服务道具、装饰；Urban Arena 八处既有 cover 的视觉外壳。没有重写布局、碰撞或导航。 |
| VFX | muzzle flash、hit、smoke、rocket trail、dodge、death 已有覆盖；不等于全套最终品质。 |

当前事实以本页 + 当前代码 + 对应最新阶段证据为准。
历史报告中的 “BLOCKED / 尚未替换玩家 / 32/33” 是当时阶段状态，不能覆盖 Phase 3D/4B/4C.1 结果。

## Verification state — retained evidence, not rerun in Phase 4D

最新完整验证来源：[Phase 4C.1 报告](art_source/phase4c1/README.md)、
[最终验证](art_source/phase4c1/final_validation.json)、[原测试结果](art_source/phase4c1/regression/results.json)。

| 项目 | 最近已完成的结果 |
|---|---|
| Tests | **33/33**；Phase 4C.1 未改原测试，Phase 4D 也不修改测试 |
| Fresh cold import | **0 ERROR / 0 WARNING**，独立新副本，不复用旧缓存 |
| Main exit | **0**；仍有已知 **2 ObjectDB instances leaked at exit** 警告，不声称 warning-free |
| Graphical routes | **两条 PASS**，Rifle+Rocket / SMG+Rocket，各 39 项检查；包含敌人交战、死亡、撤离和返回 |
| Cross-process save/load | **PASS**，各路线独立重启后五项检查；仓库合并/装备身份保持，使用真实存档副本 |
| Enemy fire comparison | **360 samples PASS**；origin / direction 差值为 0，同时检查碰撞、导航、死亡物理与 RNG |
| Unity-Chan official source | **68/68 hashes unchanged** |

证据在 `art_source/phase4c1/`；本阶段只读核对内容、路径、代码引用和 Git 范围，**不重新冒领一次回归 PASS**。

[2026-09-27 Playthrough](art_source/phase4c1/local/playthrough_20260927/index.html)：
约 **52 秒 / 1280×720 / 60 FPS / 游戏原声**；录制记录 `recording.json` 确认代码和正式存档未改。
录像在 ignored `local/` 下，只存在于本机，不随 Git checkout 提供。
**自动化输入/API 验证 ≠ 人工试玩体验评测；成功录制撤离流程 ≠ 已验证全部任务目标。**

## Known technical debt / release boundary

1. **Enemy legacy dependency（下一阶段首要问题）**：AvatarSample_A visual 与旧步枪已隐藏，
   但真实 humanoid skeleton / AnimationTree / IK 仍求值。`EnemyController` 从旧 rig 读取
   muzzle origin/direction；新无人机只跟随它。死亡沿用原六刚体，替换可见碎片而非死亡逻辑。
   依赖和运行开销尚未清理，旧资源 public-release authorization blocker 仍未解除。
   敌人 debug 页面仍是旧 rig 诊断，不代表正常生产场景没有切换。
2. **Visual coverage**：城市大面积环境与 UI 仍有原型感；部分战斗反馈可 polish；
   Terminal 专项美术切片未完成。不要据此立即开始大规模 asset expansion。
3. **Performance**：low-end PC、持续 FPS、内存与加载时间均未完成验收；
   **720p60 录像成功不能作为性能认证**。
4. **Release / licensing**：目前不是发行验收；Unity-Chan 为 UCL，不是 CC0，保留 credit/license/source，
   商业发行需另审。AvatarSample_A 历史授权阻塞仍在；不阻止有边界的内部 Demo 工作，
   但不能把内部验收描述为 public-release-ready。
5. **Workspace / documentation**：历史 `.import`、`project.godot`、迁移资源、Blender master、
   报告等 WIP 有意保留。禁止 reset / clean / stash / 自动整理 / 删除 / 顺手提交。
   本页历史区的原有未提交段落也保留为 WIP；本次只提交新 current 区、历史区封装及阶段索引。
   旧报告目录中也有本地未提交文件，见索引的持久化标记；不要假设所有证据已入库。

## Next-step roadmap — not authorization to start implementation

```text
Phase 4D  Checkpoint / Handoff consolidation（本轮仅文档）
    ↓
Phase 4E  KITE-07 legacy skeleton decoupling
    ↓
Phase 4F  Fixed Demo Route presentation polish
    ↓
Phase 4G  Performance / release audit
```

**Phase 4E 目标**：单独解除 KITE-07 对 AvatarSample_A / legacy humanoid skeleton 的运行时依赖。
先审计真实 fire chain，而不是删除隐藏节点后让测试“看起来绿”：

- 保持 enemy gameplay、firing behavior、projectile/hitscan origin 和 direction、attack timing、hit/death、spawn/碰撞/导航。
- 保持并扩展原 **360-sample 行为对照**；在等价证据成立后移除不必要的旧视觉/骨架依赖。
- 当前部分敌人测试绑定真实旧 VRM/骨架/IK；必须先识别行为契约与实现假设，
  需要契约迁移时单独明确范围，不能删断言、加假节点或降低标准来掩盖变化。
- 重跑完整 33 项回归、Main、fresh import、graphical combat/extraction routes、跨进程 save/load。
- 不改玩家、武器语义、Terminal、Arena 或 AI 参数；严重契约冲突时 STOP，报告而非补 gameplay hack。

入口：[EnemyController](scripts/enemies/enemy_controller.gd)、
[旧视觉/rig](scripts/characters/humanoid_retarget_visual.gd)、
[CharacterCombatRig](scripts/player/character_combat_rig.gd)、
[无人机 adapter](scripts/presentation/enemy_drone_presentation.gd)、
[对照 probe](art_source/phase4c1/contract_probe.gd)。本轮 **不开始 Phase 4E**。

## Phase report index

[完整阶段索引与证据可用性](docs/PHASE_INDEX.md)：
3A → 3A.1 → 3A.2 → 3A.3 → 3B → 3C → 3D → 4A → 4B → 4C → 4C.1 → 4D。
索引只引用实际存在的报告；明确区分历史失败、后续通过、已提交记录与本地 WIP。

## For next Codex session

1. 绑定 `PROJECT_ROOT=D:\bunny_team`，先读 **`Handoff.md`**，不要假设历史 conversation 存在。
2. 执行 `git status`、`git log --oneline -10`，核对 HEAD、分支与 WIP；不要从旧 commit 猜当前状态。
3. 阅读 `docs/PHASE_INDEX.md` 和对应 phase report；Phase 4E 首先读 `art_source/phase4c1/README.md`、
   `final_validation.json` 与上面的实际 fire chain。先确认验证新鲜度，旧 PASS 不自动覆盖新改动。
4. 保留历史 WIP，不提交无关文件、不 push；未授权不扩大范围。测试/录制只用存档副本。
5. 本轮 4D 到此停止；下一轮获得明确任务后再做 4E。下方内容仅历史记录，不是当前指令。

---

<details>
<summary>Historical handoff notes — superseded; retained verbatim, including local WIP</summary>


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

</details>
