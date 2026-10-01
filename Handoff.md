# Bunny Team — Current Project Handoff

## Current checkpoint — First Mission, Streets, bilingual UI and spatial warehouse (2026-10-01)

- Godot 4.7.2 / Forward+, normal entry `scenes/presentation/slice/boot.tscn`. This checkpoint collects the improvements since `41c4db5`; the older sections below retain historical context.
- [First Mission](docs/FIRST_MISSION.md) is an authored tutorial sortie with investigation, alarm reinforcements, optional extra salvage, timed extraction and a single permanent Workshop upgrade: 1 Salvage Core → AR damage 20 to 22. Manual AR-primary/SMG-secondary loadouts can deploy. The 8–10 minute target still needs a newcomer timing pass.
- [Armor](docs/ARMOR_TRADEOFF.md) now trades mobility for actual protection: light 10% reduction / 3 kg, heavy 40% / 8 kg. HUD and equipment readouts use runtime calculations.
- After the first mission, [Streets](docs/STREETS_DISTRICT.md) provides six randomized spawn candidates, two assigned exits, randomized investigation, four enterable interiors and indoor/outdoor loot. Camera orientation stays fixed; occluders fade. Six combat-active automated routes have passed; this is not human difficulty validation.
- Seven weapons and the scarf-free imported Bunny remain playable. The production AR uses the MCO pack M4 and calibrated hand IK. The [master-shot study](docs/bunny_master/README.md) is not a final visual standard; MCO pose samples are not a replacement for gameplay locomotion.
- English / Simplified Chinese can switch live; new launches default to Chinese until a preference is saved. Font and translations are bundled. Fullscreen, window resolution and F11 are available. The compact battle HUD and tutorial preserve the central view.
- Hanger warehouse has item footprints, model thumbnails, native mouse drag/drop, R rotation, sorting, selected-item details and persistent cell positions. Drag equipment icons to unequip or swap slots; names retain dropdown selection. Grid rows grow for recovered items; no finite-slot capacity or nested containers are implemented.
- Existing P0 pause, recovery, atomic save and ammunition conservation remain. Death/abandonment preserve pre-sortie warehouse equipment; Continue restores base state, not an interrupted battle.
- Narrative chapters/Bosses remain design documents. Original-source/asset notices remain in [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md). Model/material fidelity, manual first play and target-platform performance remain open.
- This checkpoint verification: **43/43 scene tests**, **5/5 actual quit paths**, Main and a graphical warehouse probe pass. Cold import has zero errors and two known source-FBX UTF-8 metadata warnings; Main retains its known ObjectDB exit warning. Evidence: [checkpoint report](docs/checkpoint_2026-10-01/README.md).
- Validation tooling now expects the current 43 test scenes. Recent targeted evidence is in `docs/stash/`, `docs/localization/`, `docs/hud_layout/` and `docs/streets/`. Use isolated saves for all checks.
- The discussion about separating base presentation from a dedicated warehouse screen is a proposed next UI change; it is not implemented in this checkpoint.

## Historical working tree — P0 recovery / shared rendering / modern arsenal (2026-09-30)

- `main @ 41c4db5` plus uncommitted WIP. An earlier requested pull brought in the recent upstream work; this implementation is not committed or pushed.
- Godot 4.7.2 / **Forward+ desktop + 4× MSAA**; shared AgX/environment reflection/SSAO/glow in `scripts/systems/render_profile.gd`. Compatibility launch fallback remains. Normal Boot → Hideout → Hanger → Battle → Result loop remains.
- Seven modern weapons: P9, SMG-9, AR-556, S12, R7, LMG-56 and separately textured RPG. See [arsenal](docs/MODERN_ARSENAL.md).
- Visible player: user-selected **Artoria Bunny Suit with scarf hidden**; imported geometry, baked textures, 157,293 triangles, 52 display joints and 11 meshes. Existing Unity-Chan locomotion remains a hidden driver; original Unity-Chan geometry/textures were not edited. Source blend remains unchanged. This is an internal prototype, not commercial asset clearance.
- Actual enemies now include imported Quaternius SciFi human patrols and KITE drones. Human death keeps authored geometry/animation; player defeat keeps the skinned model with a posed fall. This is not full physical ragdoll animation. No procedural human/NPC mesh was added.
- Current runtime evidence, reproduction and remaining limitations: [model trial](docs/ARTORIA_BUNNY_TRIAL.md). Human package provenance has an inherited Males/Women notice mismatch; it is explicitly recorded, not silently approved.
- P0: strict save validation + atomic temp/backup replacement + explicit corrupt-save recovery; bounded ammo deployment with visible errors; magazine conservation/weight; atomic result commit/save/retry; warehouse overflow recovery; shared Esc/pause/resume/abandon/base/menu/quit flow, including window close and pending enemy-shot timers. Continue starts at the saved base, not a mid-mission checkpoint. See [updated demo audit](docs/DEMO_READINESS_2026-09-28.md).
- Verification: fresh cold import 0/0, **37/37**, **5 actual quit subprocess paths**, and a Forward+ graphical route passing **13 checks**, normal AI, 58 shots / 3 damage / 0 kills, `mission_completed=false`. Main exits 0 without script errors; forced headless `--quit-after` retains the known 2 ObjectDB instances warning. Latest targeted checks passed after the final cleanup. All profiles isolated; no personal-save modification. [Machine report](docs/p0_verification/verification.json), [UI captures](docs/p0_verification/presentation/05_pause_battle.png).
- Forward+ presentation route also exercised menus, deployment, pause, abandonment, return, save failure and corrupt-save recovery on Apple M5. Short 90-frame battle sample: median 16.708 ms, p95 18.217 ms; not a performance certification. Compatibility fallback rendered successfully. Windows rendering and manual first-player acceptance remain unverified. Temporary Artoria geometry/textures were not revised in this pipeline pass.
- [Narrative production package](docs/narrative/README.md): all seventeen requested sections, twelve chapters, eight bosses, eight adult supporting women, six factions, eighteen key scenes, five relationship scenes, five endings and the first chapter's 95 lines. This is original design work; those chapters, NPC cast and boss encounters are not implemented yet.
- Preserve pre-existing importer WIP and local files. No reset/clean/stash, automatic commits or removal of original character assets. The old Unity-Chan source restrictions still protect those original files; the user's new Artoria trial authorization changes the visible player choice.

The sections below are historical. Their player choice, test counts and earlier scope restrictions describe those checkpoints, not this working tree.

## Historical checkpoint — Phase 5 + portable development sync (2026-09-27)

- Branch `main`; runtime baseline **`bc4984b`** (Phase 5), enemy decoupling **`7ddb981`** (Phase 4E).
- **Godot 4.7.2 / GL Compatibility**; normal entry `scenes/presentation/slice/boot.tscn`.
- Flow: **Boot / Opening → Main Menu → Hideout → Mission → Deployment → Urban Arena / Field Office → Combat / Loot → Extraction → Debrief → Hideout**.
- Production Player: Unity-Chan Battle Costume; official geometry/textures and Phase 4B material semantics remain locked. Production Enemy: native KITE-07; **no AvatarSample_A / legacy humanoid skeleton runtime dependency**.
- Phase 5 retained verification: **33/33**, two graphical routes **64/64 each**, cross-process save/load PASS, cold import **0 ERROR / 0 WARNING**, Main exit **0** (known ObjectDB exit warning). See `art_source/phase5/README.md`; these are automated graphical routes, not manual playtesting.
- This sync versions the missing original FBX texture dependencies, 4.7 import configuration, byte-identical legacy-source relocation, recovered official authoring sources, and source/validation records. No gameplay or production character edits.
- Blender master repair is **four relative image paths only**; no geometry/rig/action/material-semantics change. Character leg-length investigation: `docs/CHARACTER_PROPORTION_CHECK.md`.
- This sync's **staged-only clean-copy** rerun: **33/33**, cold import **0/0**, Main **exit 0 / no warnings**; exported official source **68/68** hashes match. Graphical routes/save-load above are retained Phase 5 evidence, not newly rerun.
- New-machine setup and exact clean-index verification: **`docs/DEVELOPMENT_SETUP.md`**. Screenshots, videos, personal saves, cache and unrelated trial scripts are deliberately not part of this sync; local copies remain untouched.
- Internal demo only. This sync does not grant or re-audit release rights. Retain all existing license/source notices; do not use Unity-Chan as AI input.

**Read this section and current code first. All reports below retain their historical phase context; old “current”, “BLOCKED”, “not production”, rig-dependency and no-push statements do not describe this checkpoint.**

## Historical checkpoint — Phase 4D (2026-09-27)

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

## Current handoff — Phase 3A Presentation Spike (2026-09-25)

**Decision: BLOCKED. Do not switch the default player.** Personal-demo derivative,
not commercial-release clearance. No new character searches, AI or Terminal work.

- New excluded workspace: `art_source/unitychan_battle_derivative/`. Blender master,
  self-contained GLB, prefab mapping, reproducible build/isolated-validation scripts,
  complete UCL 3.0 license/logo bundle and evidence retained. Read its `README.md`.
- Official source + meta fingerprints unchanged. 24 skinned + one static nose
  renderer mapped; separate head retained, bundled melee weapon excluded. Derivative:
  37,359 triangles, 24 meshes, 328 bones, five materials, four base-color images.
- Corrected centimeter/root-transform loss; applied 180-degree presentation heading
  normalization. World-position/rotation checks passed; not full skin/animation parity.
- Fresh isolated derivative import: **0 ERROR / 0 WARNING / exit 0**.
- Isolated replacement: **32/33 tests PASS**. ACCEPTANCE_SMOKE FAIL is old avatar
  `Face` name/height assertion. Tests were NOT weakened. Main exit 0; visual-slice,
  world traversal, presentation gameplay, weapon behavior/switching suites PASS.
- Eight mounts available; AR/SMG sampled grips converge. Strict all-weapon grip probe
  **FAIL: Rocket left-hand offset ~12 cm**. Measurement-only probe's PASS label is
  superseded by `evidence/grip_acceptance.log` (exit 1).
- Real OpenGL 1280x720 production-camera route PASS through Field Office, terminal,
  extraction/Result: normal AI, 60 shots, 3 damage, 0 kills; early extraction, not full
  mission. Automated API/input, NOT manual. Hinge waypoint failure retained; only
  test path changed to door opening center, not gameplay geometry/routes.
- Visual acceptance NOT ACCEPTED: Hanger hair/face overexposed, equipment occlusion;
  cloth/skin behavior, full animation visual review and performance still unverified.
- Live runtime/player/enemy/gameplay/config unchanged, main remains c4ca114; all
  prior WIP preserved. No commit/reset. Phase 2B 33/33 describes the OLD baseline,
  not the new derivative. ObjectDB warnings retained; not warning-free.

Next bounded step: presentation-only Rocket grip calibration + anime material and
skin/animation review, then reviewed model-independent face/adapter acceptance and
complete regression. Do not adopt the derivative based on route PASS alone.

---

## Historical handoff — Battle Costume source recovery (2026-09-25)

User selected **Unity-chan Battle Costume for a personal demo**. This supersedes
candidate shopping and next-Terminal proposals below. No Terminal work.

- **SOURCE RECOVERY PASS; CHARACTER INTEGRATION NOT VERIFIED.** Official Humanoid
  1.1 package downloaded (12,531,513 bytes); main FBX hash exactly matches legacy.
- Recovered 20 original PNGs, six Unity materials, official prefab, both body/head
  FBXs and shader/include evidence in `art_source/unitychan_battle_legacy/official_1_1/`.
- Six Maya authoring PSDs are NOT in the official release. Shipped appearance uses
  PNGs via Unity materials. All assigned-shader declared non-null texture references
  resolve; seven dangling old saved-property references are not used by that shader.
  No fake PSD, texture substitution, FBX/rig/animation rewrite.
- Blender 5.2.2: 20/20 PNG decode PASS, main FBX import PASS; 39,241 triangles,
  character 328 bones + weapon 11 bones. Not prefab/runtime or animation acceptance.
- Fresh isolated 4.7.2 current-project import: **0 ERROR / 0 WARNING / exit 0**.
  Source remains under `.gdignore`; this is not Battle Costume runtime acceptance.
- Existing 33/33 and graphical route PASS are Phase 2B evidence, not rerun this step.
  Runtime assets, Gameplay, player/enemy presentation and project config unchanged.
- `main @ c4ca114` preserved with all prior WIP; no commit/push/reset.
- Evidence: `art_source/unitychan_battle_legacy/RECOVERY.md`, `recovery_manifest.json`,
  `blender_source_probe.json`, and `docs/art_pipeline_validation.log`.

Next: isolated Blender prefab/material reconstruction, then deformation/retarget
verification and player-only presentation adapter. Main FBX alone does not reproduce
the separate-head prefab. Bind-pose behavior still needs verification. Existing
VRM release restriction remains in effect.

---

## Historical handoff — Phase 2B — Migration Gate Closed (2026-09-25)

**MIGRATION GATE: PASS for continued internal development on Godot 4.7.2. PUBLIC SHOOTING-DEMO RELEASE: BLOCKED — VRM authorization unresolved.** No Terminal selection/production was started. Stop here.

### Accepted gate standard and evidence

- User explicitly authorized **automated graphical input/API route acceptance instead of the original manual-keyboard gate**. It is NOT human/manual input. The current acceptance standard, not the older manual requirement below, governs this checkpoint.
- Actual working-tree snapshot → entirely fresh `.godot` → Godot 4.7.2 cold import: **0 ERROR / 0 WARNING / exit 0**. A separate fresh repair candidate also passed 0/0. No cached `.godot` was copied.
- Real dependencies repaired: official UnityChan 1.2.1 archive contains all six existing animation FBXs with **identical SHA-256** and all five missing TGA files. Only those original TGAs and their Godot `.import` settings were added, at the unchanged FBXs' expected path. No FBX/rig/animation/material rewrite or substitute texture.
- Unused Battle Costume FBX and original sidecar moved intact to `art_source/unitychan_battle_legacy/`, excluded by `.gdignore`. Filename/path/UID reference searches plus resource dependency checks found no runtime reference. The six missing PSD references and two bind-pose warnings remain in that preserved legacy source; no rest-pose reset was performed.
- Live idle/walk/run/slide + VRM bone hierarchy/rest/pose, skin binds and animation track/key fingerprints match before/after exactly. **150 runtime source files** used by the regression copy match the checkout. Character presentation, movement, combat and routes unchanged.
- After fix: **ALL TESTS 33/33 PASS**, ACCEPTANCE_SMOKE PASS, MAIN HEADLESS exit 0, VISUAL_SLICE_ASSETS_TEST PASS, WORLD_TRAVERSAL_TEST PASS, PRESENTATION_GAMEPLAY_TEST PASS, RESULT_RETURN_TEST PASS. No runtime ERROR/SCRIPT ERROR. MAIN and sortie_outcome_test each reported a **KNOWN NON-BLOCKING EXIT WARNING: 2 ObjectDB instances**; not warning-free.
- OpenGL 3.3 / RTX 5090, 1280×720 production camera: Hanger → movement → door E → entrance → interior → Terminal → exit → original outdoor route → extraction → Result **automated PASS**. Normal AI/health/collision retained. Terminal objective 1/1; early extraction successful, mission otherwise incomplete (0 kills; 9 damage taken). This is not full-mission completion or a manual-combat skill test.
- First scripted route attempt hit the entrance jamb due to a diagonal waypoint; only the test path was corrected to cross the doorway before turning. Production collision/map/code were NOT altered. Failed attempt evidence retained.

### Git and reproducibility

- Branch `main`, HEAD still `c4ca114e732ff8508370928dd5d16e04d838a6a0`, same origin. Original Phase 1/2 documentation WIP preserved. No reset, discard, commit or push.
- Worktree changes: migration dependency restoration + legacy relocation + validation tools/evidence/documentation. Git shows deletion at the old FBX path and an untracked destination until staged; this is a byte-identical move, not destruction. Carry all untracked files if migrating this checkpoint; cloning HEAD alone does not include this fix.
- Fixed scripts: `tools/verify_migration.py` (fresh WIP snapshot/import/regression/optional graphical route), `tools/audit_migration_dependencies.py` (read-only material/source trace), `tools/phase2b_route_probe.gd` (normal-AI graphics route).
- Durable evidence: `docs/phase2b/validation.json`, `dependency_trace.json`, `route_result.json`, `captures/`; the directory has `.gdignore` so screenshots are not game resources. Full diagnostic details/reproduction fingerprints appended to `docs/art_pipeline_validation.log`.
- Original official archive and intermediate failures retained outside Git at `C:\Users\admin\AppData\Local\Temp\bunny_phase2b_20260925_214246`. Only ~15 MiB of original dependency textures added to runtime source; no asset-pack dump or AI work.

### Release boundary / next phase

VRM author/model/FAQ pages were checked again. Their current permissions differ from the fixture metadata; the exact old-file authorization/version is still unresolved. Keep the model intact and **blocked for public shooting-demo use**, do not remove metadata or use it as AI input. This documented restriction does not block this internal migration checkpoint. C03 replacement remains DEFERRED.

Next separately authorized phase: exactly **one Terminal vertical slice**. This session ends at the migration checkpoint; do not proceed automatically.

---

## Historical handoff — Phase 2 Gate checkpoint (2026-09-25)

**Result: BLOCKED before Terminal production; Definition of Done NOT achieved.** This section supersedes the Phase 1 proposals below. Latest user authorization: use **Godot 4.7.2**, with other platforms to be unified by the user. Engine selection is settled; migration acceptance is not. Do not obtain 4.6.3 or call 4.7.2 merely an unauthorized temporary version. `project.godot` remains at its compatible 4.6 feature level; no rendering/configuration change was needed for this audit.

- Git: `main`, HEAD `c4ca114e732ff8508370928dd5d16e04d838a6a0`, origin `https://github.com/atom32/bunny_team.git`. Start-of-Phase-2 WIP was the Phase 1 Handoff edit and four untracked documentation paths listed in the validation log. Preserved. This phase changes Documentation only; no Gameplay, imports, rigs, runtime assets, commits, resets or package downloads.
- Fresh 4.7.2 cold import of a new HEAD archive: **FAIL — 72 ERROR / 38 WARNING**, process exit 0. Reproduced independently of the old cache. Six animation FBXs each contribute 10 missing-texture errors/5 warnings; `unitychan_battle.fbx` contributes 12 errors/8 warnings, including both multiple-bind-pose warnings. Details and safe next choices: `docs/ART_PIPELINE.md`, Phase 2 section.
- Unity-Chan dependency cleanup: **DEFERRED**, not cosmetically silenced. Idle/walk/run/slide remain live animation/skeleton dependencies even though their meshes are hidden. Entire-directory ignore/deletion would break runtime. No replacement textures or rest-pose edits.
- VRM release/license: **BLOCKED**, with new evidence rather than a blanket claim that the author forbids combat. Official AvatarSample_A page currently allows violent use. The repository binary exactly matches the VRMMetalKit fixture, but retains OnlyAuthor/Disallow metadata; applicability of current author terms to this particular distributed version is unresolved. See `docs/art_candidates/README.md` for URLs, hashes, permissions and limitations. No public footage or AI input approved.
- C03 bounded compatibility probe: existing glTF loads as PackedScene with one 62-bone skeleton; direct replacement is **not compatible** with current Character1_* bone contract. Eight sockets have anatomical counterparts but no tested adapter/IK/AnimationTree acceptance. Local LICENSE says **Ultimate Modular Males**, conflicting with Phase 1's Women pack attribution; exact pack identity must be reconciled. No character replacement made; C04 not downloaded.
- Fresh runtime verification: **ALL TESTS 33/33 PASS**, including ACCEPTANCE_SMOKE, RESULT_RETURN_TEST, PRESENTATION_GAMEPLAY_TEST, VISUAL_SLICE_ASSETS_TEST, WORLD_TRAVERSAL_TEST. MAIN HEADLESS exit 0; no runtime ERROR/SCRIPT ERROR. Two-instance ObjectDB exit warnings remain in main and two suites; not warning-free.
- Manual Field Office Enter/Exit, Terminal reachable, original route/result: **NOT VERIFIED**. Migration failed first, so no claim of manual acceptance and no Terminal selection/integration. Entrance/Terminal/Character visual acceptance, before/after performance, four new screenshots and 20–30s footage: **NOT VERIFIED / not produced**.
- Raw evidence: `C:\Users\admin\AppData\Local\Temp\bunny_phase2_20260925_211817`; durable results, commands, hashes and diagnostic output appended to `docs/art_pipeline_validation.log`.

### Next checkpoint, in order

1. Close cold import on 4.7.2: recover the exact lawful original image dependencies OR prove a geometry-free animation-source derivative preserves every bone/rest/track/key and PackedScene contract. Do not simply switch animation FBXs to AnimationLibrary: current code expects PackedScene + Skeleton3D + Take 001. Keep original sources and licenses archived; quarantine only verified unused references, not the live animation directory.
2. Reconcile the VRM metadata/version with author permission (or separately approve a small presentation-only character adapter spike). Do not rewrite embedded licensing metadata as a substitute for permission.
3. Complete actual-window keyboard/mouse route acceptance, then select **exactly ONE** Terminal/Cabinet, comparing processed C09 with C02 and C01 only if superior. The old 3–5-model proposal below is superseded. No Hanger/weapon/UI/environment expansion.
4. Blender master → GLB → presentation wrapper without collision/interaction changes → full regressions → production-camera 1280×720 performance/screenshots/video/manual acceptance. No AI workflow needed unless a real supporting-art gap is identified.

---

## Historical handoff — RTX 5090 Art Pipeline Audit (2026-09-25)

**Latest authorized phase: migration validation + sustainable art production planning, not Gameplay implementation or bulk asset replacement.** This section supersedes the old "stated next task" below. The Visual Slice 01 implementation and historical acceptance evidence remain intact.

### Read next

- `docs/ART_PIPELINE.md` — workstation facts, production gates, Blender normalization, rollout order, Windows test commands and acceptance limits.
- `docs/ART_ASSET_INVENTORY.md` — measured inventory, current presentation contracts, P0/P1 priorities and licensing blockers.
- `docs/art_candidates/README.md` — 16 individually documented source entries: 2 already integrated, 12 candidates, 2 rejected for style/scope. No new packages downloaded or approved for integration.
- `docs/art_pipeline_validation.log` — consolidated fresh test/tool evidence, including cold-import errors rather than a false clean-migration claim.
- `docs/visual_slice_01/REPORT.md` — historical visual implementation/manual evidence, unchanged.

### Workstation / Git

- Project is already on the RTX 5090 machine at `D:\bunny_team`.
- Initial tree **clean** (no modified or untracked files); branch `main`; HEAD `c4ca114e732ff8508370928dd5d16e04d838a6a0`; origin `https://github.com/atom32/bunny_team.git`; remote main checked and matches HEAD. Clean baseline can be cloned/checked out directly. This phase leaves only its documentation edits uncommitted; no reset/discard/commit/push was performed.
- Installed Godot: `E:\Godot\Godot_v4.7.2-stable_win64_console.exe`, **4.7.2**, not the historical **4.6.3**. All importing/testing occurred in a temporary git-archive copy, not the production working tree. No engine upgrade was applied to project configuration.
- Blender: `F:\SteamLibrary\steamapps\common\Blender\blender.exe`, **5.2.2 LTS**. Existing CC0 AR → Blender → GLB → separate Godot test import/instantiate passed; 802 triangles and Blender world bounds preserved. No production asset replaced.
- RTX 5090, driver 616.92, CUDA driver UMD 13.4; ComfyUI Python 3.13.11 / Torch 2.13.0+cu130 completed a CUDA tensor calculation. System Python 3.14.2, Node 24.12.0, Git 2.52.0; Python/Node are not game runtime dependencies.
- MiniMax H3 and WAI Anima weights/nodes/workflows exist under `D:\ComfyUI-aki-v3.2\ComfyUI` (0.33.2). Full model inference/API workflow has **not** been validated. `anima-preview.safetensors.part` is incomplete and is not counted as a working model. No installs, model downloads or AI generation performed.

### New blockers (do not conceal behind test PASS)

1. **Cold import is NOT CLEAN:** Windows Godot 4.7.2 import exited 0 but logged **72 ERROR / 38 WARNING** lines, including missing original Unity-Chan TGA/PSD texture paths. Runtime suites subsequently pass; this does not clear the import gate. Diagnose with a pinned Godot version and repair import dependencies separately, without empty substitute textures or Gameplay changes.
2. **Current player AND enemy VRM licensing is not cleared for a shooting Demo:** actual `avatar_sample_a.glb` metadata contains `allowedUserName=OnlyAuthor`, `violentUssageName=Disallow`, alongside `licenseName=CC_BY` and `commercialUssageName=Allow`. The generic bundled model-license notes are insufficient to resolve this. Obtain explicit applicable permission or choose a cleared replacement (C03/C04 are investigation candidates), before public gameplay/promotion. Do not feed this model or Unity-Chan assets/screenshots into AI.
3. **Manual Field Office Enter/Exit remains NOT VERIFIED.** Hanger/AR/SMG/Rocket VERIFIED are inherited previous-machine observations, not fresh 5090 manual verification. Full AI inference and actual 5090 GL rendering/manual acceptance are still pending.

### Fresh validation, exact scope

- Windows **Godot 4.7.2** isolated copy: **ALL TESTS 33/33 PASS**, RESULT_RETURN_TEST PASS, PRESENTATION_GAMEPLAY_TEST PASS, WORLD_TRAVERSAL_TEST PASS, ACCEPTANCE_SMOKE PASS, VISUAL_SLICE_ASSETS_TEST PASS; all runtime test exit codes 0 and no ERROR / SCRIPT ERROR / `: FAIL`.
- MAIN HEADLESS: exit 0, no ERROR, **2 ObjectDB instances warning** at forced exit. Do not describe as warning-free.
- 31 assertion suites + 2 scripted visual smoke flows; not automated image approval or direct manual input acceptance.
- Historical Godot 4.6.3 33/33 baseline is preserved, **not rerun on this machine**. Cold import errors above are a separate failed migration gate.
- Test profile data was isolated with per-process APPDATA/LOCALAPPDATA under the audit temporary directory. Original user saves, runtime code, Resource definitions, scenes and source assets were not modified.

### Next authorized proposal (requires an implementation task)

1. Resolve engine version/cold import; finish existing direct keyboard/mouse route acceptance. Resolve VRM release permissions separately before public output.
2. First vertical art slice: **Field Office entrance + briefing/terminal nook**; keep layout, collisions, camera, roof cutaway and route intact. Existing Kenney modules are a baseline, not an instruction to make a pack showcase.
3. Choose one licensed terminal/storage asset (C02 versus reworking existing C09), normalize in Blender, export GLB, adapt only Presentation, then full regressions and actual-camera comparison. Limit first slice to 3–5 models, 2 material sets and a small atlas, not an entire library.
4. Character/animation replacement, Hanger, Rocket silhouette and UI are later separate slices. No new drone/turret/weapon gameplay. Existing A → adapted B → optional AI C priority is mandatory; AI must not replace source/licensing/quality evaluation.

**Stop point:** planning delivered; workstation has the core production capability but migration/release readiness is conditional. No art integration, Gameplay changes, source-code edits or large downloads were made in this phase.

---

## Historical handoff — Visual Slice 01 (retained evidence)

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
