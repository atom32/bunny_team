# Development checkout / 环境同步

> 2026-10-15 当前更新：31定义、79测试场景，profile schema8 / checkpoint6；校园第二批已接入。见 [最新实现与验证](CAMPUS_BATCH2_IMPLEMENTATION.md)。下方75等批次数量是历史。

> 2026-10-15：成年男女动作适配、独立受试者外观、主角自然轻盈战斗样式与编辑器审查入口见 [本批制作说明](MODEL_ANIMATION_AUTHORING.md)。剧情仍只开放当前第一批，库存75；下文旧日期与测试数保留阶段历史。

## 当前环境 — 2026-10-14

同步基线 `main @ 68076ae`，Godot **4.7.2**，入口 `scenes/presentation/slice/boot.tscn`，桌面Forward+；`--rendering-method gl_compatibility`为回退。当前profile schema **8**，支持局内挂起恢复，不按下方历史schema 1描述操作当前存档。

Windows已核实Godot与Python路径如下；其他机器替换为自己的实际路径，不依赖作者macOS路径或临时目录。

```powershell
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path .
# 全新仓库外目录，隔离用户档案：
& 'C:\Python314\python.exe' tools/verify_migration.py --godot 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --output '<全新仓库外目录>'
```

当前 runner 已审核对齐 **79 个场景**，为两个 Hideout 长时间测试补足帧预算，断言与错误门禁不变。加 `--route` 可检查 Forward+ 自动路线（Dummy 音频，不作听感验收）。内容检查与物品向导见 [接续制作进度](CONTENT_AUTHORING_PROGRESS.md)。校园真源、YARD和 F6 工作台操作见 [内容工具说明](CONTENT_TOOLS_IMPLEMENTATION.md)；原66/62漂移留在实施前审计中。

`tools/play_campus_batch1.command`是macOS本地入口，依赖ignored `.grimdark-loop/campus_batch1_20261012/project`，干净checkout没有该副本，Windows也不能直接执行。生产入口使用本仓库 `project.godot`。

不复制另一机器的`.godot`或个人存档，不在主工作区用不同引擎版本试错；保留`.gdignore`、license/SOURCE/hash。模型接口见 [asset interface](asset_interface.md)，扩充建议见 [路线图](CONTENT_PIPELINE_ROADMAP.md)。

## 历史环境同步记录（2026-09-27 至 2026-10-01）

以下checkpoint、WIP、schema、渲染器和测试数字仅描述当时，不覆盖上方当前环境。

2026-10-01 checkpoint: First Mission and the single AR upgrade, real armor protection, Streets district, bilingual UI, display settings and spatial warehouse are now included alongside the modern arsenal and Bunny trial. See the current [handoff](../Handoff.md) and [README](../README.md). Validation tooling checks **43** test scenes in an isolated copy. The WIP notices below describe earlier checkpoints.

2026-09-30 current WIP: seven modern weapons, the scarf-free Artoria playable prototype, imported human patrols plus drones, and 37 regression scenes. See [the model trial](ARTORIA_BUNNY_TRIAL.md) and [modern arsenal](MODERN_ARSENAL.md). `tools/verify_migration.py` snapshots current Git-visible WIP and isolates `user://` on macOS/Linux as well as Windows. The checkpoint results below remain historical. These working-tree changes are not yet committed; pulling the current remote alone will not obtain them.

Run `python3 tools/verify_migration.py --godot <godot-executable> --output <new-directory-outside-repo> --route` for cold import, all 37 scenes, five quit subprocess checks, Main and an automated graphical route. The route checks traversal, interaction and extraction; it is not manual playtesting or a complete campaign mission clear. Godot needs only the self-contained Artoria GLB; the original Downloads blend and Blender 5.2.1 are needed only to rebuild that derivative.

Current desktop renderer: **Forward+**, 4× MSAA, AgX/neutral environment reflection, light SSAO and glow. The shared implementation is `scripts/systems/render_profile.gd`. Use `<godot> --path . --rendering-method gl_compatibility` to launch the fallback. `verify_migration.py --route` now verifies Forward+ by default; `--renderer gl_compatibility` selects the fallback route. Windows GPU/drivers still need a real-machine graphics check.

Current saves remain schema 1. A save is written to `.tmp`, verified, then replaces the primary; the previous valid primary is kept as `.bak`. Corrupt profiles open a recovery menu. Explicit recovery copies the broken primary to `.recovery-<timestamp>-<ticks>` before saving a backup/new profile. Never copy personal saves into test snapshots. Continue returns to base with saved inventory/loadout, not an in-progress battle. Saving failures offer retry and explicit in-memory continuation.

2026-09-27. Runtime checkpoint `bc4984b` (Phase 5); this follow-up only synchronizes
required configuration/source/dependency records. Use **Godot 4.7.2**, GL Compatibility.

## Another machine

1. Clone or pull `main`. Before pulling an existing checkout, inspect `git status`;
   preserve its own WIP. Do not copy `.godot` cache or another machine's personal save.
2. From the repository root run (replace `<godot>` with that machine's executable):
   ```text
   <godot> --headless --path . --editor --import
   <godot> --path .
   ```
   Normal entry is `scenes/presentation/slice/boot.tscn`, not the legacy Hanger entry.
3. First launch uses opening/menu; START / CONTINUE enters Hideout. Existing gameplay
   save format is unchanged. Presentation settings use separate `user://presentation.cfg`.
4. Do not remove `assets/140301_unitychanmodel_Celsis/`: the five original TGA files
   and `.import` files fulfill the existing animation FBXs' relative dependencies.
5. The old standalone `unitychan_battle.fbx` plus original sidecar moved byte-for-byte
   to `art_source/unitychan_battle_legacy/`, excluded by `.gdignore`. Do not put it
   back in runtime import scope. This is quarantine, not destruction of original art.
6. Blender **5.2.2 LTS** is only needed for authoring, not running the game. The master
   is `art_source/unitychan_battle_derivative/battle_master.blend`; its four image
   paths resolve relative to the sibling `unitychan_battle_legacy/official_1_1/` tree.
   Do not re-export or regenerate the locked character as a setup step.

## Included / intentionally local

Included: Godot feature level/import configuration, exact required texture sources,
quarantined official source, license/provenance, authoring master, concise historical
migration/readiness records, and reusable dependency/recovery verification tools.
No new gameplay, material shader or model replacement in this sync.
`.gitattributes` prevents line-ending conversion of the 68 immutable official files;
all 68 hashes also match after export from Git, not only in this working directory.

Excluded and preserved locally: unrelated screenshots/recordings, test profile copies,
Blender backup files, trial capture/material scripts, commit receipts, cache and
CRLF-only importer churn. Existing media already in earlier commits is not purged;
there is no history rewrite. Some old report links therefore refer to local-only evidence.

## Verification of portable content

**Result: PASS — fresh import 0 ERROR / 0 WARNING; 33/33; Main exit 0, no warnings in this run.**

See `docs/development_sync_validation.json` for this sync's staged-only snapshot
verification. It exports **the Git index**, not the full working directory, to a new
folder with no `.godot` cache; profiles are isolated. Then cold import, all 33 existing
test scenes and the normal main entry run. Tests/runners/assertions are unchanged.

To repeat manually in a fresh clone:
```text
<godot> --headless --path . --editor --import
<godot> --headless --path . res://tests/acceptance_smoke.tscn --quit-after 1200
<godot> --headless --path . --quit-after 180
```
Run each of the 37 `tests/*.tscn` for the current full regression, not only acceptance_smoke.
`tools/verify_migration.py` includes local WIP in its snapshot, so it does **not** prove
a clean committed checkout. Its optional route retains the Phase 2B route's bounded
scope while exercising the current runtime. Current trial evidence is under
`docs/artoria_bunny_trial/`; `art_source/phase5/` retains earlier checkpoint evidence.
