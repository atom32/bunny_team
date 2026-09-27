# RTX 5090 Game Art / Asset Production Pipeline

> **Current checkpoint (2026-09-27):** Phase 5 `bc4984b`, Godot 4.7.2.
> Player = production Unity-Chan (Phase 3D + Phase 4B fidelity); Enemy = native
> KITE-07, no legacy humanoid dependency (Phase 4E). Phase 5 validation: 33/33,
> two automated graphical routes 64/64 each, cross-process save/load PASS.
> See `Handoff.md` and `docs/DEVELOPMENT_SETUP.md` for current setup/verification.
> The reports below are **historical**, not instructions to repeat old gates or
> replace current assets. Local screenshots, trial scripts and profile copies
> referenced by historical reports may deliberately be absent from Git.

## Historical Phase 3A — BLOCKED presentation spike

Experimental master/GLB and full evidence are in
`art_source/unitychan_battle_derivative/README.md` (excluded from runtime).
Original assets unchanged. Final GLB: 37,359 triangles / 24 meshes / 328 bones /
five materials / four embedded images, approx 1.467 m rest height.
Fresh isolated import 0/0; isolated tests 32/33, smoke fails old Face assertion;
main exit 0 and required specialist suites PASS. Strict Rocket left-grip check
FAIL (~12 cm), Hanger material/visual acceptance NOT ACCEPTED. Automated production-
camera route PASS after a test-only door-center waypoint correction. No default
player replacement, Gameplay or scene/config changes; no commercial clearance.
See README for failures, source hashes, mapping, commands and next bounded steps.


## Latest scope — Battle Costume source recovery (2026-09-25)

User chooses Unity-chan Battle Costume for a personal demo, not Terminal.
Official 1.1 source dependencies recovered in the existing excluded art-source
directory; see `art_source/unitychan_battle_legacy/RECOVERY.md`. Source recovery PASS,
Blender image decode PASS (20/20), fresh current-project cold import 0 ERROR/0 WARNING.
Character GLB/adapter/animation/visual acceptance NOT VERIFIED. Preserve prefab
material mappings and separate head; PNG/UTS material references, not the original
FBX's stale Maya PSD paths, define the shipped appearance. No runtime change.
Historical next-Terminal proposals below are superseded by this scope.

日期：2026-09-25。阶段：**调查、迁移验证、生产规范；未开始大规模资产替换**。

## Phase 2B — Migration Gate Closed（最新，优先于下方历史记录）

**Migration PASS（内部开发）；VRM public shooting-demo release BLOCKED。** 用户已明确接受固定脚本/API 的图形路线验收替代本轮真实键鼠 Gate；报告仍标 automated，不标 manual。本轮不开始 Terminal。

### 修复及剩余风险

1. 从官方 UnityChan **1.2.1** 源包取回五张原始 TGA，六个现有动画 FBX 均与该包对应文件逐字节 hash 一致。来源、许可和文件 hash 在 `assets/140301_unitychanmodel_Celsis/SOURCE.md`。保留旧相对路径是为了不修改 FBX，不是新增平行美术体系。
2. 五张 TGA **必须连同 `.import` 设置一起版本化**。第一次隔离试验仅有 TGA：4.7.2 在扫描 active script preload 时早于纹理设置登记，产生 60 ERROR/20 WARNING 和重复 PNG；该失败被保留。第二次全新副本带设置：0/0。没有复制失败生成的 PNG、没有以 warm import 充当 cold PASS。
3. Battle Costume 模型与 sidecar 原样移入 `art_source/unitychan_battle_legacy/` + `.gdignore`。无路径/文件名/UID 的 runtime 引用、无动态目录加载器，Godot resource dependency 检查无入边；注意 `ResourceLoader.get_dependencies(gd)` 本身不枚举 preload，必须结合源码检查。**只隔离该模型**；damaged/win 留原处，其纹理依赖也已补全。
4. Battle 源中的六个 PSD 和两个 bind-pose warnings 仍未修复，类别是 excluded legacy source。当前玩家/敌人的 VRM、动画都不使用它；未对它的 deformation 作可用性担保。重新启用它前必须重新过 Gate。没有 reset/rebind/rename/track edit。
5. 最终实际 WIP 的全新 snapshot 冷导入：**ERROR 0、WARNING 0、exit 0**。四个活跃动画源和 VRM 的骨名/父级/rest/pose/skin binds/动画路径/类型/插值/关键帧指纹前后相同，回归+实际图形路线通过。当前动画行为没有被依赖修复重写。
6. VRM 作者授权的版本冲突保持 **BLOCKED — authorization unresolved**，不阻止内部迁移验收，但不准公开 shooting-demo 包装或 AI 输入。C03/C04 角色替换 DEFERRED。

### 路线 checklist（自动化图形验收；非人工）

| 项目 | 结果 |
|---|---|
| Hanger launches / entrance visible | PASS / PASS |
| Player movement / door interaction | PASS / PASS |
| Enter Field Office / interior traversal | PASS / PASS |
| Terminal area reachable / exit Field Office | PASS / PASS |
| Return to original route | PASS |
| Combat still works | PASS：生产开火事件、正常敌人 AI 与受伤；击杀/伤害规则另外由回归验证 |
| Extraction / Result | PASS / PASS；合法提前撤离，非全部任务目标完成 |

Godot OpenGL 3.3、RTX 5090、生产 camera 1280×720，六张成功阶段截图；初次 waypoint 错误的失败截图也保留。未 teleport、暂停敌人、设置无敌、改碰撞或换摄影机。最终 120 次 weapon_fired signal、受伤 9、击杀 0；Result 显示 Terminal 1/1，其余目标未完成。不要将此证据描述成完整战斗通关。

### 自动测试与复现

改动后的隔离副本：**33/33 PASS**（含全部要求的专项测试），MAIN exit 0；无 ERROR/SCRIPT ERROR。仅 MAIN、sortie_outcome_test 出现 2-instance ObjectDB 退出 warning，记录为 KNOWN NON-BLOCKING EXIT WARNING，不宣称 warning-free。既有 4.7.2 测试在修复前没有重复；本次完整回归发生在实际 migration fix 之后。

```powershell
# --output 必须是仓库外全新的目录；脚本包含当前 modified + untracked WIP。
python D:/bunny_team/tools/verify_migration.py `
  --godot E:/Godot/Godot_v4.7.2-stable_win64_console.exe `
  --output C:/Users/admin/AppData/Local/Temp/bunny_migration_new_run --route
# 只验证首次冷导入用 --import-only；不要同时传 --route。
python D:/bunny_team/tools/audit_migration_dependencies.py --output C:/Users/admin/AppData/Local/Temp/bunny_dependencies.json
```

输出：独立 project / APPDATA / LOCALAPPDATA、source_manifest.json、results.json、每测试日志、可选 captures/route_result.json + PNG。不会修改原仓库或用户存档；首次导入失败立即停止。图形路线使用 Input.parse_input_event 和生产 Deploy 按钮信号，不调用电脑控制工具。所有发布限制仍适用。

固化证据 `docs/phase2b/` 已 `.gdignore`；日志详见 `docs/art_pipeline_validation.log`。该 checkpoint 尚未 commit，分支/HEAD 仍 main/c4ca114；必须保留新增 TGA/.import 和移动后的 legacy 文件，不能只迁移旧 HEAD。**本轮到此停止，P1 Terminal 不开始。**

## Historical Phase 2 — Gate 判定（已由 Phase 2B 更新）

用户已明确授权统一到 **4.7.2**，不再获取 4.6.3。版本选择 PASS；迁移整体 **FAIL / 尚未验收**。保持 `project.godot` 的 4.6 feature 字段，不把 feature 字段当实际运行版本。Phase 2 范围只允许一个 Terminal/Cabinet；下文旧的多模型预算仅属未来规划。

### 冷导入真实依赖分类

新建无 `.godot` 缓存的 HEAD archive，用本机 4.7.2 `--headless --editor --import`，再次出现 **72 ERROR / 38 WARNING**（exit 0 不代表 PASS）。另以 `FBXDocument.append_from_file` 逐文件定位：

| 来源 | ERROR / WARNING | 分类与行动 |
|---|---|---|
| animations/idle、walk、run、slide.fbx | 每件 10 / 5 | **live production animation dependency**。每件引用五张缺失旧 TGA；对应 mesh 在角色代码中隐藏，但骨架/Take 001 仍是当前动画来源。缺图不是运行时崩溃，却是真实且未修复的 source dependency failure，不能忽略整个目录 |
| animations/damaged、win.fbx | 每件 10 / 5 | 源资源历史残留候选；在已跟踪 gd/tscn/tres 中没有找到这两个路径引用。未据此删除；后续降级 reference 需保留源和许可、再全量导入/运行验证 |
| unitychan_battle.fbx | 12 / 8 | 六张缺失 Maya PSD（12 ERROR + 6 skip warnings），另有两个 bind-pose warnings。未发现当前 gd/tscn/tres 引用，是 legacy/reference 候选，不是当前可见 VRM |

TGA 文件名：`FO_SKIN1.tga`、`face_00.tga`、`eyeline_00.tga`、`eye_iris_L_00.tga`、`eye_iris_R_00.tga`。PSD 文件名及全部原路径保留于 validation log；不要把旁边名字相似的 PNG 当成经过验证的替代。

`J_1_R_mantleSide_R`、`J_1_R_midFrillSide_R` 的 multiple bind poses 只在独立导入 battle 模型时复现，不在六个动画 FBX 中。分类为 **historical source artifact / 当前运行不依赖的 importer warning**；不等于已验收其蒙皮。不得 reset rest pose 或修改 rig 来消警告。若未来使用该模型，必须单独检查 deformation。

检查了 [Godot 官方 FBX importer](https://github.com/godotengine/godot/blob/4.6-stable/modules/fbx/fbx_document.cpp) 和 [scene importer](https://github.com/godotengine/godot/blob/4.6-stable/editor/import/3d/resource_importer_scene.cpp)：AnimationLibrary 路径支持 discard meshes/materials，但项目目前需要 PackedScene。该源码用于理解机制，**不是当前 4.7.2 可安全改变导入设置的证明**。没有直接将 importer 切为 AnimationLibrary，没有清空纹理引用，也没有引入空白材质。下一步可选：取得准确且合法的原始依赖，或在隔离副本制作仅骨架/动画的派生 PackedScene，并逐骨骼名称/父级/rest、逐轨道/关键帧比对，再做回归及动画人工检查；未经这些验证不推广到生产。

### 发布与执行 checkpoint

- VRM 当前作者页允许 violent use，但当前二进制内嵌 Disallow，确切适用版本仍待澄清：**BLOCKED**。完整权利记录在候选 README。内部技术诊断不授予公开发布许可；不送入 AI。
- C03 有界探针仅证明导入/骨名可读，未替换角色；C04 未下载。没有修改 movement/combat 来适配。
- 4.7.2 新副本的 33 个运行测试均 PASS，无 ERROR；MAIN exit 0。main、ammo_carried_foundation、sortie_outcome 各有一个“2 ObjectDB instances”退出 warning，未当作无警告验收。
- 手工路线 **NOT VERIFIED**；Terminal 制作/集成 **NOT STARTED**；视觉/性能/录屏验收 **NOT VERIFIED**。按 gate 顺序停在迁移/授权，不跳过它们完成“美术成绩”。
- 证据目录 `C:\Users\admin\AppData\Local\Temp\bunny_phase2_20260925_211817`；长存档见 `docs/art_pipeline_validation.log`。测试用独立 APPDATA/LOCALAPPDATA，没有覆盖用户存档。

## 1. 环境结论

**5090 已具备主力开发/Blender 资产加工能力，但迁移验收尚未完全闭环。** 缺口不是算力或缺少软件：是 Godot 版本与冷导入错误、AI 端到端验证、角色发布许可和直接手工路线验收。不能用“已安装”代替“已验证”。

| 项目 | 本机实际证据 | 判定 |
|---|---|---|
| 项目 | `D:\bunny_team` | 已迁至 Windows 路径；不再使用 README 里的 macOS 命令 |
| Git | 2.52.0.windows.1；branch `main` | 起始 modified=0、untracked=0 |
| HEAD | `c4ca114e732ff8508370928dd5d16e04d838a6a0` | `git ls-remote origin refs/heads/main` 同值 |
| remote | `https://github.com/atom32/bunny_team.git` | 只读访问成功，本次未 push/commit |
| Godot | `E:\Godot\Godot_v4.7.2-stable_win64_console.exe`；4.7.2.stable.official.ed1daf0bf | 可执行；历史基线是 **4.6.3**，未找到匹配版，不冒称相同版本复验 |
| 项目配置 | Godot 4.6 feature、GL Compatibility、1280×720、main=`hanger.tscn` | 未修改，未切换 Vulkan/GI |
| Blender | `F:\SteamLibrary\steamapps\common\Blender\blender.exe`；5.2.2 LTS，d13f752e3b9c | CLI、GLB 往返和 Godot 再导入通过 |
| GPU | RTX 5090，32607 MiB，driver 616.92，nvidia-smi 正常 | CUDA tensor 实算通过；不是大型模型满负载测试 |
| CUDA | driver 报 UMD 13.4；Comfy PyTorch 用 CUDA 13.0 | driver 能力≠安装完整 Toolkit；nvcc 不在 PATH，不影响已有 Torch runtime |
| Python | PATH `C:\Python314\python.exe` 3.14.2 | 本轮文件审计 stdlib 用它；项目运行不依赖它 |
| AI Python | `D:\ComfyUI-aki-v3.2\python\python.exe` 3.13.11；Torch 2.13.0+cu130 | cuda available=True，GPU 正确，4 元素求和=4.0；仅有 pynvml deprecation warning，未安装修补依赖 |
| Node | `E:\node.js\node.exe` 24.12.0 | 可执行；项目无 package.json / Node 构建步骤 |
| 项目依赖 | 未找到 requirements/pyproject/csproj/npm manifest | Godot 原生 GDScript；不要为了美术建立不必要的 Node/Python 框架 |
| 音频生成 | 现有 shell 脚本依赖 Bash/FFmpeg，默认 macOS 路径 | 现有 WAV 已在库，正常运行不需重新生成；本轮未验证 FFmpeg |

### AI 工具：已定位，但尚未完成推理验收

根目录 `D:\ComfyUI-aki-v3.2\ComfyUI`，源码版本文件 **0.33.2**，本轮未启动服务、未加载几十 GB 模型、未生成图片/视频。检查时常见 8188/7860 未监听；8000 的监听不据此认定为 ComfyUI。无当前会话可调用的 MiniMax/Anima 专用连接器，后续可以通过本地 ComfyUI API。

- MiniMax H3：`models/diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors` 与 ref2va 权重各约 20.97 GB；配有 Qwen3VL text encoder、video/audio VAE、若干 H3 nodes 和工作流 `user/default/workflows/video_minimax_h3_i2v.json`、`video_minimax_h3_r2v.json`。
- Anima：`waiANIMA_v10Base10.safetensors` 约 4.18 GB；`AnimaBasicV8.json` 引用该权重、`waiANIMA_v10Base10_txt.safetensors` 和 `qwenImage_qwenImageVAE.safetensors`，三项均找到；有 Advanced workflow/辅助节点。
- `anima-preview.safetensors.part` 是部分文件，**不算完整模型**；不能因为它存在就声明模型可用。现有 WAI 权重是另一可检查选项。
- 本地 Civitai metadata 有商业使用标志，但不是权利链完备证明；本轮未联网验证确切 base/checkpoint/LoRA 的完整条款。AI 输出用于成品前须分别核验模型、衍生权重、输入图与输出使用条件。
- 未证明：custom-node 全部能加载、workflow 可通过 `/prompt`、采样不 OOM、输出可用于游戏。本机硬件/张量验证不能替代这些步骤。

后续最小 AI 验收：使用现有启动器和隔离输出目录 → 记录实际端口 → 读取 `/system_stats`、`/object_info`、`/queue` → 对照工作流 node types 和 model refs → 确认没有其他运行任务 → 将批准的 UI 工作流导出为 **API 格式**（不能直接把 UI JSON 作为 `/prompt`）→ 一张自有/CC0 输入的 512px 原创标牌/材质样图 → 记录 prompt_id、history 成功、seed、模型 hash、工作流、耗时/峰值显存、输出 hash → 人工检查。H3 只在确需动态概念/镜头预演时测试短片；**不假定它能产出可用 3D 或骨骼动画**。失败先报告缺失，不自动 pip upgrade / 下载模型。

## 2. 迁移方法与保护

起始工作区 clean，远端 HEAD 匹配，**可直接 clone/checkout 此提交**；当前已在目标机器，无需再复制一份常驻仓库。本轮修改后仅文档 dirty，移至其他机器前提交这些文档或显式带上 diff/untracked 文件，不能只迁 HEAD 丢失本阶段交付。

若未来存在未提交改动：先列 modified/untracked/HEAD；优先在原机做用户确认的 WIP commit + push，或保存 patch + 单独归档 untracked；不 reset/discard，不覆盖存档。Git bundle 可作离线备份，但不自动包含工作区文件。

迁移清单：源文件、`.import` 导入配置、`.uid`、许可证随 Git；不搬 `.godot` 缓存、绝对机器路径、密钥。大权重/第三方原包留资产库，不放游戏仓库。`user://` 存档不在 Git，若需迁旧存档另行备份迁入，不由测试覆盖。

本次使用 `git archive HEAD` 到临时副本：
`C:\Users\admin\AppData\Local\Temp\bunny_art_audit_20260925_201927\project`。
测试进程 APPDATA/LOCALAPPDATA 指向该审计目录内的 userdata/localdata，避免污染正常用户 profile；主仓库从未用新版 editor 重写导入配置。

**环境放行顺序**：
1. 在独立副本使用与历史一致的 4.6.3 复验，或明确批准 4.7.2 为新基线；本阶段没有默默升级项目。
2. 修复 FBX 缺失贴图依赖并做全新缓存导入。先区分 animation-only source 与可见角色，选择合法纹理映射/animation-only 导出；不下载不明旧 PSD，不造空图掩盖错误。同时检查 `J_1_R_mantleSide_R` / `J_1_R_midFrillSide_R` 的 multiple-bind-pose warnings，不能盲目重设 rest pose。与资产替换分 commit。
3. 重跑全套 + 本机实际 OpenGL 画面 + 直接键鼠路线。通过后才称迁移完成。

## 3. 搜索到集成的门禁

```text
Brief / 当前画面问题
  → Search（A：已有高质量合法资产）
  → License（逐资产、逐版本，记录证据）
  → Blender（B：70% 合适优先加工；归一化/清理/材质/枢轴）
  → AI（C：只补经比较后仍缺失的部分；可跳过）
  → Blender 复核/导出（AI 产物不得绕过此关）
  → Godot Presentation wrapper
  → Test + 生产相机画面 + 手工验收
  → Integrated / 有证据可回滚
```

| 关口 | 输入与输出 | 放行人/标准 |
|---|---|---|
| Brief | 一张现状图、需要解决的具体问题、用途、优先级 | 项目负责人确认范围；不是“把所有东西做高级” |
| Search | 每需求最多 2–3 个有效对照；候选池字段见 README | 比较 silhouette/风格/加工量/授权/成本；差不多则保留现有 |
| License | 作者原始 URL、许可版本/文本、日期、商业/署名/再分发/AI-input、原包 SHA-256 | 有疑点维持 candidate；Free 不放行；禁止不明版权/政治徽记 |
| Blender | source 不改、可编辑 master、GLB、尺度/面数/材质检查 | 技术检查通过，视觉负责人 A/B 签收 |
| AI | 合法输入+模型条款+可重现工作流 | 不用当前 VRM、Unity-Chan 或未知截图作输入；输出须人工清理 |
| Godot | Art 子节点/材质替换，不接管游戏状态 | 无新物理/触发器/资源定义数值变化 |
| Test | 自动结果、实际镜头对照、手工清单 | 任一 FAIL/ERROR 不集成；人工签收后 integrated |

当前候选池：C01/C02 环境、C03/C04 角色、C05 动作、C08/C16 枪械、C10 VFX、C11 UI、C12/C13/C15 材质；C06/C14 为风格/范围否决。条目与许可逐项见 `docs/art_candidates/README.md`。只有已集成的 C07/C09 为 integrated；没有将网页质量承诺当成本地质量测量。

## 4. Blender = Asset Normalization / Authoring Layer

### 坐标、尺度、pivot

- 工作单位 Metric，Unit Scale=1；**1 Godot unit = 1m**，先用 1m 参考尺和既有门洞/角色检验。
- Blender Z-up，glTF Y-up 导出转换交给 exporter；`export_yup=True`。不要再额外套一遍 -90° 纠正。
- **本项目 controller/weapon forward=-Z**；Godot/glTF 通用面向资产的约定常为 +Z，见 [Godot 官方坐标说明](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html)。导入每个新来源都必须检查朝向，不能泛化成“所有 GLB 都 -Z”。
- 新静态模型在 master 中规范 rotation/scale，导出 root 尽量 identity；对已有 rig 不盲目 Apply Pose/变换，不破坏 bind matrices。weapon 的 origin/grip 与既有 wrapper 对齐；环境以地面接触点/模块网格角为 pivot，门装饰沿既有铰链。
- 新 master 若以 grip 为原点，wrapper 可以保留适配偏移。**不要为获得 identity 把旧 Muzzle/Grip 的坐标改掉**。Godot marker 是战斗/IK 接口，不是可以随模型任意移动的装饰。

### 清理与材质

1. 保留原文件；选定一件模型开始，不在所有模型上批量 destructive apply。
2. 清掉重复/退化面、确认 normals/tangents、必要的 triangulation；对不影响轮廓的隐藏面减量；不盲目焊接 UV seam 或删刚体分件。
3. UV、材质槽和贴图路径完整。不要导出依赖本机外部盘的纹理路径；GLB 内嵌或随资产显式打包。
4. 用 Principled/PBR 可兼容子集；程序纹理/复杂 Blender nodes 要 bake，不能指望 GLB 自动带 Cycles 材质。
5. BaseColor/emission 按 sRGB；roughness/metal/normal 作为非颜色数据；Normal 用 OpenGL 约定，确认绿通道和 tangent；如用 ORM，约定 R=AO/G=roughness/B=metal，导入后核对。
6. 不将 palette shader 套到任意 PBR UV；保留 palette 与 PBR 两种明确路径，用相同明度/粗糙度基准统一风格。既有 shader 无 outline，不在此阶段加新 toon 框架。
7. LOD 只在测量表明有必要时做，先保 silhouette；rigged LOD 必须核对 skin weights。不建 HLOD/streaming 系统。

### 轻量试制预算（新提案，非现项目硬性能保证）

| 类别 | 首轮目标 |
|---|---|
| 小 props | 0.2k–3k triangles；通常 1 材质 |
| hero terminal / 单把 weapon | 1k–8k triangles；1–2 材质 |
| character | 约 10k–30k triangles，具体取决于画面；现有 VRM 为 29.5k |
| textures | 先 512/1K；hero 必要时 2K，暂不引入 4K/8K |
| 首个入口切片新增 | 最多 3–5 个模型、2 套材质、1 小 atlas；不同时替换整楼 |

记录实际 draw calls/material surfaces/VRAM/帧时间，再调整预算。5090 是制作机，不是降低成品性能纪律的理由。

### GLB 导出与工程归属

- Export Selected Objects/批准 collection；不带 camera/light/测试物体；保留需要的 UV/normals/materials；静态 props 不带无关 animations，rigged 只导出需要的 clips/skin。
- 显式 GLB 作为交换格式；不依赖 Godot 隐式 `.blend` 导入对每个开发者安装 Blender 的要求。现有 FBX 不在本轮批量转换。
- 包含 collision suffix（如 -col）/PhysicsBody/Area3D 的第三方场景不得直接塞进关卡；装饰导入不生成碰撞。最终实例检查没有多余 body/trigger/navigation region。
- 推荐按需建立而非现在造空目录：外部资产暂存 `D:\bunny_art_staging\<asset_id>\`；合法可分发的 master 放项目 `art_source/<asset_id>/` 并由 `.gdignore` 排除 Godot 扫描；runtime GLB 放现有 `assets/<category>/<source>/`；wrapper 在现有 scenes/presentation 边界。受限源包不能进入公共 Git。
- 每个真实集成资产只保留 `SOURCE.md` + 许可 + master/导出 + 必要贴图；SOURCE 记录源 URL/包版本/hash、加工者/日期、Blender 版本/设置、原尺寸/最终尺寸、面数/材质/贴图、wrapper、测试证据。候选阶段只记文档，不为每条创建素材目录。
- 大二进制是否用 LFS 另按仓库策略决定；本阶段不擅改 `.gitattributes`，不把模型权重和整个原包提交 Git。

### 已做的工序 rehearsal

使用现有 CC0 `blaster-e.glb`，Blender 5.2.2 factory-startup headless 导入 → GLB/Y-up 导出 → 清空临时场景重导入：802 triangles 保持，Blender 世界包围盒各轴误差 <1e-5。再到独立最小 Godot 4.7.2 项目导入/实例化，`mesh.get_faces()/3=802`，PASS。

这证明一条最小 **existing source → Blender → GLB → Godot** 通路可执行，不代表 rig、材质像素一致或新模型已合格。所有试制文件在临时目录，未替换仓库 AR、未保存到生产 scene。

## 5. Gameplay / Presentation 边界

默认只替换 `Art/Model`、视觉材质/Theme、装饰 GLB；依然通过 `WeaponDefinition.scene`。保留 Muzzle、PrimaryGrip、SupportGrip、ReloadGrip；AR vs legacy socket 的 `has_weapon()` 分流不变。

不改 damage/fire_rate/ammo、movement/collision、extraction/route、warehouse/person identity、expedition/economy、save/load、Outcome/result/commit；不让粒子驱动伤害。Area 内的 Door/Terminal/loot/objective placement 保持，封闭窗不会因视觉透明变成射击孔。Barrier 装饰必须随原可见性销毁。

如果未来发现必须改 Gameplay，实施前写清 **WHY / WHAT / RISK / TEST** 并取得范围确认；本阶段没有该类修改。角色重定向适配即使叫 Presentation，也必须单独审查 controller 触点和现有测试契约，不能让整个替换变成隐式重构。

## 6. Art Upgrade Roadmap / 第一完整切片

**选择：Field Office entrance + briefing/terminal nook。** 不选择同时重做 Hanger+角色+三武器：那会把 rig、UI、许可和材质迁移揉成一件高风险工作。

视觉语言：低饱和蓝灰/军用灰绿大面、受控青色设备灯、少量琥珀警戒色；非发光墙/地板明暗清晰、武器与角色轮廓可读。对比同一生产 camera/lighting，而非靠特写掩盖平时不可读。用尺度、roughness、低频 weathering、原创编号/标志和构图统一来源，不以全 Kenney 或全 Quaternius 为目标。

### 实施顺序

0. **基础门禁**：确定 Godot 版本、清理 FBX 冷导入错误；VRM 许可列为独立发布阻断。先完成当前场景的直接键鼠路线，记录遗留问题，不借美术隐藏 bug。
1. **A/B 选型**：在库 C09 加工方案 vs C02 terminal/storage；C01 只在门框/背墙明显更好时用。不新建地图、不新增 briefing gameplay。
2. **一件归一化资产**：首件 terminal 外壳或入口柜体，完成 source/license/master/GLB/Godot 全链和全套回归。作为后续可复制样板，而不是生成十几种模型。
3. **构图/表面**：保留大部分墙件，整理 canopy/sign/局部顶板；最多一种 1K 地面材质（C12 或 C15），原创清晰标号，控制角色周边亮度。道具贴边，不占西侧战斗/行走通道。
4. **表现补足**：有必要才从 C10 做一组 muzzle/impact；不是装饰终端切片的强制前置。AI 如需加入，只制作权利明确的虚构标牌/概念，不直接生成碰撞、动作或游戏逻辑。
5. **闭环测试**：自动回归、实际 GL 画面、直接键鼠 Enter/Exit（正常 AI）。角色许可未解决可做内部环境审图，但不能对外发布带受限角色的 gameplay。
6. **下一批**：独立角色/敌人 Presentation spike（C03/C04 + C05），再 Hanger、Rocket silhouette、UI theme；P2 管道/设备架最后；P3 无人机/炮塔/新地图继续冻结。

### Definition of Done（下一阶段目标，本次未实现）

- 同一生产相机 1280×720 截图能读出入口、目的地、敌我和掩体；入口主题有独特编号/标志，不像单纯 kit 展示；不依赖另调摄影机才好看。
- 展示一张入口图、一张 briefing/terminal 室内图、20–30 秒正常 AI gameplay（不是自动截图夹具）；无穿模、z-fighting、错误法线/透明排序；灯光不洗白角色。
- 直接 WASD/mouse：接近 → E 开门 → 进入 → 战斗/掩体 → Terminal → Back Exit → 原 extraction/result 路径；门、切屋顶、Barrier、窗封闭均正确。
- 自动门禁全绿，冷导入无 ERROR，GPU 画面检查通过，署名/许可清单签收；存档只使用测试 profile，不覆盖正常档。
- 使用相同分辨率/路线记录改前后 frame time、draw calls、VRAM；若明显退化先减透明叠层/材质/灯而非更换 renderer。只有这些证据齐全才把切片称为可 Demo 展示。

## 7. 本轮测试与验收事实

| 检查 | 历史 4.6.3 | 本轮 Windows 4.7.2 临时副本 |
|---|---|---|
| ALL TESTS | 33/33 PASS | **33/33 PASS**，所有退出码 0、marker 存在、运行日志无 ERROR/SCRIPT ERROR/: FAIL |
| RESULT_RETURN_TEST | PASS | PASS |
| PRESENTATION_GAMEPLAY_TEST | PASS | PASS |
| WORLD_TRAVERSAL_TEST | PASS | PASS |
| ACCEPTANCE_SMOKE | PASS | PASS（已含在 33 内） |
| VISUAL_SLICE_ASSETS_TEST | PASS | PASS |
| MAIN HEADLESS | exit 0 | exit 0；2 ObjectDB instances warning，未称零警告 |
| 全新缓存 import | 旧报告未作为独立冷导入门禁记录 | **NOT CLEAN**：exit 0，但 72 ERROR / 38 WARNING（含缺失 FBX TGA/PSD），不能放行 |
| Hanger、AR、SMG、Rocket 直接手工 | VERIFIED | 本轮未重验，沿用历史状态而非新机 VERIFIED |
| Field Office Enter/Exit 直接键鼠 | NOT VERIFIED | 仍 NOT VERIFIED；自动路线通过不代替手工 |
| Blender→GLB→Godot rehearsal | 未记录 | PASS，802 triangles |
| 完整 AI workflow / 本机实际 GL 画面 | 未在本阶段验证 | 未验证 |

33 项包含 31 个 assertion suites 与 2 个 scripted visual smoke；后者不是图像断言或人工验收。`docs/art_pipeline_validation.log` 保存本轮 34 个运行日志/退出码/marker、冷导入去重错误与原日志 hash、Blender 结果。完整临时原日志位于审计目录，临时目录不是长期资产库；关键结论已写入版本化文档。

新资产集成后最低：ALL TESTS + ACCEPTANCE_SMOKE + MAIN HEADLESS；武器加 PRESENTATION_GAMEPLAY_TEST；任何 Field Office/navigation/door/collision 触点加 WORLD_TRAVERSAL_TEST，OfficeArt 加 VISUAL_SLICE_ASSETS_TEST。即便全套已含专项，也要在报告中单独列结果。FAIL/ERROR 立即停集成，不能因为“纯视觉”忽略。

### Windows 复验方式

先复制/归档到隔离项目，不在主工作区用不同版本导入器试错。以下 `$Project/$Evidence` 使用独立的本轮临时副本；重验历史版时仅将 `$Godot` 指向已核实的 4.6.3 executable。

```powershell
$Godot = 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$Project = 'C:\Users\admin\AppData\Local\Temp\bunny_art_audit_20260925_201927\project'
$Evidence = Join-Path $env:TEMP ('bunny_recheck_' + (Get-Date -Format yyyyMMdd_HHmmss))
New-Item -ItemType Directory $Evidence | Out-Null
$env:APPDATA = Join-Path $Evidence 'userdata'
$env:LOCALAPPDATA = Join-Path $Evidence 'localdata'
New-Item -ItemType Directory $env:APPDATA,$env:LOCALAPPDATA | Out-Null
& $Godot --headless --path $Project --editor --import *> "$Evidence\import.log"
$ImportExit = $LASTEXITCODE
if ($ImportExit -ne 0 -or (Select-String -Path "$Evidence\import.log" -Pattern 'ERROR|SCRIPT ERROR|:\s*FAIL\b')) {
    throw 'Cold-import gate failed; inspect log before integration.'
}
$Scenes = @(Get-ChildItem "$Project\tests\*.tscn" | Sort-Object Name)
if ($Scenes.Count -ne 33) { throw 'Test inventory changed: review expected count.' }
foreach ($Scene in $Scenes) {
    $Log = Join-Path $Evidence ($Scene.BaseName + '.log')
    & $Godot --headless --path $Project ("res://tests/" + $Scene.Name) --quit-after 1200 *> $Log
    $Exit = $LASTEXITCODE
    $Text = Get-Content $Log -Raw
    if ($Exit -ne 0 -or $Text -match 'ERROR|SCRIPT ERROR|:\s*FAIL\b' -or $Text -notmatch ': PASS') {
        throw "Test failed or did not finish: $($Scene.Name)"
    }
}
& $Godot --headless --path $Project --quit-after 180 *> "$Evidence\main.log"
if ($LASTEXITCODE -ne 0 -or (Select-String -Path "$Evidence\main.log" -Pattern 'ERROR|SCRIPT ERROR|:\s*FAIL\b')) {
    throw 'MAIN HEADLESS failed'
}
```

在新 PowerShell 进程运行，避免改动交互 shell 的 APPDATA。本轮审计即使冷导入有错误仍继续了运行测试以区分问题，但**不是集成放行**；上述未来集成门禁会更早停止。检查成功 marker 防止 `--quit-after` 超时退出假 PASS；不要将 `SORTIE_FAILURE_TEST` 名称匹配成失败。外层 runner 本轮另有每进程 180 秒超时。下一次正式执行也应有外层超时，防止挂起。

## 8. 本阶段交付边界

只新增本流程、资产 inventory、一个合并候选清单与一个合并验证日志，更新 Handoff；无源代码/场景/定义/原资产/项目配置改动，无下载新资产包、无安装依赖、无 Git reset/discard/commit/push。迁移不是用几万个文件和新工具堆起来，而是下一件资产能按同一门禁重现、回滚和验收。
