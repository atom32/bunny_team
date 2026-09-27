# Art Asset Inventory / 当前资产质量审计

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


## Latest update — Battle Costume selected, sources recovered (2026-09-25)

For the personal demo, user selected Unity-chan Battle Costume. Official 1.1 body
and separate-head FBXs, 20 PNGs, six materials and prefab recovered under the
existing `.gdignore` source directory. Main FBX matches the legacy bytes exactly.
Blender read-only main-source inspection: 39,241 triangles, 24 meshes, seven FBX
materials, 328 character + 11 weapon bones, zero actions. These are not final
runtime totals. Texture decode 20/20 PASS; old authoring PSDs still not supplied.
See `art_source/unitychan_battle_legacy/RECOVERY.md` for material GUID evidence.
The live player/enemy still use the old VRM; no replacement or new visual acceptance.
UCL 3.0 retained; no AI input. Terminal deferred, source recovery only.

审计日期：2026-09-25。基线：`c4ca114e732ff8508370928dd5d16e04d838a6a0`。本次仅盘点，未替换资产。

## Phase 2B — migration dependency closure（最新）

- Cold import **PASS 0 ERROR / 0 WARNING**：只恢复五张官方原始 TGA + Godot import settings，约 15 MiB；没有生成假图、改角色外观、改 FBX 或动画。来源是 UnityChan 1.2.1，六个本地动画 FBX 与官方包 SHA-256 一致。
- `unitychan_battle.fbx` 与原 `.import` 已原样移动至 `art_source/unitychan_battle_legacy/` 并 `.gdignore`；许可仍在原 character/license 目录。两个 bind-pose 警告属于该排除源，不影响当前使用的 VRM/动画；不代表该旧模型蒙皮已修好。其他六个动画文件（包括未用 damaged/win）保留原位，依赖已完整。
- 四个活跃 FBX + VRM 骨架/rest/skin/动画指纹完全一致，33/33 回归通过。玩家、敌人、武器、装备插槽、IK、CharacterRetarget、AnimationTree、碰撞、地图和美术均未修改。
- 用户批准自动化图形路线替代本轮手工 Gate：入门/Terminal/退出/撤离/Result PASS，有 1280×720 生产摄影机证据。不是人工操作，不是完整任务通关。
- VRM public shooting-demo use：**BLOCKED — authorization unresolved**，允许内部技术验证的 checkpoint 不授予公开许可。C03 Import PASS，骨名/动画/mount contract 仍不能直接兼容，替换 DEFERRED；没有继续制作 adapter。
- Terminal、Hanger、Rocket、UI、VFX 与外景没有新增/替换资产。新 texture 是 migration dependency，不是一次 character presentation upgrade。以下 Phase 2/Phase 1 状态仅为历史。

## Historical Phase 2 增量审计

- 已授权 4.7.2，冷导入仍 FAIL 72 ERROR/38 WARNING；问题逐文件拆分见 ART_PIPELINE。不要整体降级 Unity-Chan 动画目录：idle/walk/run/slide 是活跃依赖；battle 模型及 damaged/win 仅为未发现代码引用的 legacy 候选。未清理/删除源文件。
- 当前 VRM 文件可追溯到 VRMMetalKit 的相同 Git blob；作者官方 Hub 当前允许 violent/commercial use，与内嵌限制冲突，发布授权仍 BLOCKED，而非已经认定作者一律禁止战斗。证据和 hash 见候选 README。
- **C03 导入 PASS、直接替换不通过**：Godot 4.7.2 能实例化 PackedScene，1 个 Skeleton3D/62 骨，源文件有 24 animations。骨名为 Root/Hips/Chest/Shoulder.L/Wrist.L 等，不匹配 Character1_*；当前 VRM rename map 也不匹配这组名称，CharacterRetarget 的同名 profile 不能直接复用。
- 八插槽解剖映射候选：Chest/Backpack→Chest，ShoulderL→Shoulder.L，ShoulderR→Chest（保留当前固定战斗姿势约定），HipL/HipR→Hips，HandL→Wrist.L，HandR→Chest（当前本来固定在 Spine2，不可擅自改成右腕）。只是映射假设，offset、轴、比例、IK 及动画均未签收。
- 保留 CombatAvatarModel/AnimationTree/移动/武器/IK 的端到端兼容性：**NOT VERIFIED**。理论可走 presentation-only bone adapter，但当前不是 drop-in；没有实施重命名或重做 rig。如果需要修改 movement/combat，停止该方案。C04 只有产品级候选，未声称导入成功。
- **来源纠正**：C03 本地 LICENSE.txt 写 Ultimate Modular Males，而下方 Phase 1 记录引用 Women。CC0 文本存在不代表已核对准确包版本；修正为“具体包身份待核对”，不得以旧候选条目批准替换。
- Terminal 仍为原有程序几何；本轮未选型/集成。不扩大到 Hanger、Rocket、VFX、UI 或户外。Manual route、before/after、20–30s footage 和性能数据均 NOT VERIFIED。

依据：Handoff、Visual Slice 01 REPORT、实际场景/脚本/Resource、GLB JSON 与 PNG 文件头、历史截图。历史截图已检查 `office_interior.png`、`hanger_assault_rifle.png`、`03_inside_field_office.png`；不是本机新拍截图或新手工验收。

## 1. 结论与优先级

已经够用：Field Office 模块壳体、现有三把 Kenney 武器的可读轮廓、角色/装备接口、可运行的动画与路线。不要为了换来源而全部推倒。

当前主要差距：角色授权未闭环；玩家/敌人共用同一外形；角色亮度与环境不协调；Hanger、户外和部分交互物仍是明显方块/圆环；UI 和 VFX 是功能呈现；入口没有足够独特的美术焦点。更多高面数模型不能单独解决这些问题。

| 优先级 | 项目 | 判断 / 行动 | 候选编号 |
|---|---|---|---|
| P0 发布门禁 | 当前 VRM 玩家及敌人 | 内嵌限制与射击 Demo 用途冲突待澄清；先取得明确授权或选替代角色，不能宣布可发布 | C03、C04 |
| P0 生产门禁 | Unity-Chan FBX 冷导入 | 缺失原始 TGA/PSD 引用，4.7.2 冷导入有 ERROR；独立修复导入依赖，不用运行测试 PASS 掩盖 | C05 可作为长期动画替代，不是即时修复 |
| P0 视觉 | 户外大方块背景、Hanger 方块墙/舞台 | 截图里一眼可见 blockout；本轮只规划入口镜头范围和未来 Hanger，不重做地图 | C01、C09 |
| P0 视觉 | Terminal、loot/extraction/threat 圆环与亮块 | 缺少物件身份；优先 Terminal 外壳，保留提示/触发逻辑 | C02、C09 |
| P0 视觉 | 玩家/敌人外形相同、程序化胸甲/背包 | 区分敌我轮廓；角色替换必须单独验证重定向，不能借机新增机器人敌人逻辑 | C03、C04；C02 仅外形研究 |
| P1 | 入口 canopy、sign、柜体、接待台 | Blender 统一比例/倒角/材质；保留已经有效的模块 | C01、C02、C09 |
| P1 | 角色过亮、材质与环境脱节 | 先校正材质/灯光参考；不是改渲染器或强加全局 outline | C03、C04；既有材质 |
| P1 | 枪口闪光、命中、爆炸、烟雾 | 现有几何效果可读但临时；保持事件与伤害计算分离 | C10；C14 否决比较 |
| P1 | Rocket 四管外形 vs 单发行为 | 优先现模型 Blender 简化为匹配的轮廓；找不到合适单管候选就不替换 | C07、C08，型号仍待核实 |
| P1 | UI 层级/背景/装备图形 | 保留 Warehouse/Result 信息与按钮行为，仅主题适配 | C11 |
| P1 | floor / painted metal 表面 | 少量低频粗糙度与边缘层次，禁止写实噪声压倒轮廓 | C12、C13、C15 |
| P2 | lockers、racks、pipes、vents、ceiling lights、warning stripes | 入口切片先最多选 2–3 件，其余延后 | C01、C02、C09 |
| P2 | reload/locomotion 衔接、壳体弹出 | 既有动作可用但仍为重定向/插值；先测握持，再引入动作 | C05 |
| P3 | drones、turrets、NPC、雨、全城、全套枪械 | 只保留检索方向，不新增 gameplay、不大批下载 | C02、C06、C08 |

P0 的视觉优先级与发布/生产门禁分开：授权问题不意味着模型低质量；程序化也不必然低质量，只替换实际破坏展示的部分。

## 2. Character / Enemy / Animation

### 当前 VRM（发布状态：未批准）

- 文件：`assets/characters/vrm_avatar/avatar_sample_a.glb`；作者内嵌为 **pixiv VRoid Project**，title 为 `AvatarSample_A`。精确原始下载 URL/CC BY 版本未在当前文件内闭环。
- 实测：**29,542 triangles**（GLB 三角形 primitive index/3 总和，不等于每帧渲染成本）、15 材质、3 个 skin，每个引用 91 joints；并非 273 个不同人体骨骼。
- 27 张外置 PNG，尺寸包括 8²、256²、512²、512×1024、1024×512、1024²、1024×256、2048²；GLB 也有 27 个嵌入 image 项。未在本阶段去重。
- 当前玩家与 `HumanoidRetargetVisual` 敌人均 preload 此 GLB。不能把敌人记录为“方块机器人”。玩家 `BODY_VISUAL_SCALE = Vector3.ONE`；本项目模型朝 -Z。
- 当前许可说明 `LICENSE-MODELS.md` 是上游通用 fixture 文档，不足以覆盖实际模型。
- **实际 GLB 元数据**：`licenseName: CC_BY`、`commercialUssageName: Allow`、`allowedUserName: OnlyAuthor`、`violentUssageName: Disallow`、`sexualUssageName: Disallow`。不能只取其中 Allow / CC_BY 就放行。参见 [VRM 官方字段定义](https://github.com/vrm-c/vrm-specification/blob/master/specification/0.0/schema/vrm.meta.schema.json)。
- 处理：保留现有文件和证据，不擅删；暂停将其列为可公开射击 Demo / 商业素材，也不送入 AI。取得作者明确适用许可，或从 C03/C04 做独立角色 Presentation spike。

### Unity-Chan

- `assets/characters/unitychan_battle/`：Battle Costume FBX、textures、animations、UCL 3.0 中英 PDF 和 logo。
- 角色 mesh 不是当前玩家可见模型。`idle.fbx` 提供隐藏 source rig，原文档记录 140 bones；本轮未重新量 FBX 骨数。原 Battle Costume 328 bones 同为历史记录。
- 玩家实际使用：Idle_Gun←idle、Walk←walk、Run/Run_Shoot←run、Dodge←slide；damaged、win 文件在库，非当前玩家动作表条目。敌人复用 idle/walk/run。
- `RetargetModifier3D` + `AnimationLibrary` + `AnimationTree`；Idle_Gun ping-pong、去掉 bind-pose lead-in；AR 通过上身瞄准/TwoBoneIK。reload/recoil/dodge/hit 中仍有程序插值表现，不能宣传为完整专用动作组。
- 来源/署名沿用 `THIRD_PARTY_ASSETS.md`；UCL 3.0 不是 CC0。企业用途署名 `© Unity Technologies Japan/UCL`，保留完整许可，正式发布再次核对条件。[官方指南](https://unity3d.jp/unity-chan_contents/guideline.php?lang=en) 明确限制角色作为 AI 图像生成训练或输入；项目规范对该组文件及其角色截图统一禁用 AI 输入，动画包条款也须按来源核验。
- 冷导入风险：多个 FBX 仍引用原作者工作目录里的 TGA/PSD。Windows 4.7.2 新缓存导入有错误；运行通过不代表依赖完整。

### 在库替代参考

`assets/characters/quaternius_scifi/SciFi.gltf`：Quaternius Ultimate Modular Women / SciFi，CC0（本地 LICENSE + 官方 C03）。实测 **8,038 triangles、62 joints、24 animations、9 materials**，buffer 为嵌入数据。不是当前运行角色；不能未经重定向/比例测试直接覆盖 VRM。

### 挂点契约（替换时必须保留）

`Chest / ShoulderL / ShoulderR / Backpack / HipL / HipR / HandL / HandR`。

实际实现并非全部同名手骨：HandR 与 ShoulderR 当前在 `Character1_Spine2` 上加固定姿态；HandL 在 LeftHand；Chest/Backpack 在 Spine2；Hip 在 Hips。换 rig 必须通过 Presentation 映射适配，不通过改移动/射击/碰撞规则补偿。保持 `CombatAvatarModel`、`CharacterRetarget`、AnimationTree 等当前测试契约。

## 3. Weapons

源目录：`assets/weapons/kenney_blaster_kit/`；三个 GLB、一张 `Textures/colormap.png`（512²）、LICENSE、SOURCE、导入旁车。均 Kenney [Blaster Kit 2.1](https://kenney.nl/assets/blaster-kit)，**CC0 1.0，商业/修改/再分发可，署名非强制但保留**；源 ZIP SHA-256 已在 SOURCE 中。均无 skin，不要求武器自身 rig；握持依赖角色 rig 和 wrapper markers。

| 定义 / wrapper | 源模型 | 实测 triangles | Model 局部 scale | Model 局部 offset | 挂载 |
|---|---|---:|---|---|---|
| AR / assault_rifle.tscn | blaster-e.glb | 802 | (1.18,1.18,1.18) | (0.053,0.03,-1.48) | HandR 定义，uses_combat_rig=true |
| SMG / smg.tscn | blaster-g.glb | 618 | (1.5,1.5,1.5) | (0,0,-0.46) | HandR socket，uses_combat_rig=false |
| Rocket / rocket_launcher.tscn | blaster-o.glb | 664 | (3.15,3.15,3.15) | (0,0,-0.866) | ShoulderR socket，uses_combat_rig=false |

以上是 wrapper 内的模型变换，不是世界空间大小。三个 Model rotation 均 0；在本项目适配后朝 -Z，不能把 glTF 任意模型都假定为 -Z。原 GLB 仍未修改。

| wrapper 本地 Marker | AR | SMG | Rocket |
|---|---|---|---|
| Muzzle | (0,.04,-1.48) | (0,.02,-.98) | (0,0,-1.48) |
| PrimaryGrip | (.07,-.16,-.15) | 同 AR | (.09,-.4,-.14) |
| SupportGrip | (-.06,-.13,-.52) | 同 AR | (-.09,-.38,-.83) |
| ReloadGrip | (-.04,-.24,-.37) | 同 AR | 同 AR |

Godot 链路：`WeaponDefinition` 继承 `EquipmentDefinition.scene/socket_name` → 既有 `.tscn` wrapper → `Art/Model` imported GLB → `model_palette.gd` + `weapon_palette.tres`。`weapon_visual.gd` 保留现有特效行为。换 Art 子节点而非改 ContentDB/PlayerController 的模型路径表。

SMG/Rocket 的 `track_socket_visual()` 只复用 pose/IK targets；`has_weapon()` 仍为 false，不能为了外观变更把它切换到 AR 战斗路径。当前 AR/SMG 足够继续验证；Rocket 外观语义是 P1，不允许把弹药/伤害改成四连发迁就模型。

## 4. Environment

### 已集成外部模型

`assets/environment/kenney_space_station_kit/`：Kenney [Space Station Kit 1.0](https://kenney.nl/assets/space-station-kit)，CC0 1.0，商业可、署名可选、允许源素材再分发；LICENSE/SOURCE/ZIP 哈希在库。16 GLB、512² palette、无 skin，每个 1 源材质。

| 文件（省略 .glb） | triangles（本次源文件实测） | 用途 |
|---|---:|---|
| wall / wall-detail / wall-window | 44 / 120 / 104 | 墙、细节、封闭窗框 |
| floor / floor-detail | 12 / 44 | 地板模块 |
| door-double-closed | 52 | 既有旋转门的视觉层 |
| table / chair | 104 / 62 | 接待家具 |
| computer-screen / computer-system / display-wall | 198 / 176 / 86 | 办公/墙屏 |
| container-flat / container-tall | 116 / 116 | 储物 |
| wall-switch | 18 | 开关面板 |
| pipe / pipe-bend | 20 / 48 | 管路 |

环境+武器共 19 GLB，历史记录源网格 337,612 bytes。wrapper 与 Godot import 不计入此大小。

### 本地 authored / procedural

- `scenes/areas/field_office_art.tscn`：BoxMesh 等构成 roof/fascia/ribs、canopy、门槛、sign、封闭玻璃、locker、file shelf/binders、bin、desk lamp、papers、keyboard、luminaires；这些不是外部高质量制作模型，但已形成统一布局。
- `prototype_field_office.tscn`：12×14m floor、3.6m wall 高度、已有 StaticBody/BoxShape；OfficeArt 是视觉子层。门洞/窗户不能由美术导入器自行重建物理。
- `field_office_presentation.gd`：装饰门、counter、cover/barrier；屋顶在接近/室内 cutaway；Barrier 装饰跟随原 Mesh 可见性。door 源模型缩放 (3.66,3.43,2.4)，随原 DoorLeaf 旋转，非新滑动门。
- 原有 6 盏局部不投影灯，继续复用 Environment/sun；不添加 HDRI/GI，也不切换 GL Compatibility。
- `office_palette / office_floor / weapon_palette` 共用 `slice_palette.gdshader`：去饱和+青色映射、roughness=.74、metallic=.12、cull_disabled；office brightness .62、floor .19、weapon .7。**它是 palette shader，不是已有 outline 系统，也不适合直接覆盖新 PBR 模型。**
- 本地 StandardMaterial family：metal、wall、roof、floor、stripe、lamp、teal 等；现玻璃为视觉封闭面，不代表透明可穿越窗。

### 其他场景

- `scenes/hanger/hanger.tscn` 仅挂脚本；墙/梁/地台/光环由 `scripts/hanger/hanger.gd` 构造，整体仍 programmer art。UI 可用但不是成品主题。
- `scripts/battle/urban_arena.gd`：地面道路、城市块、街道道具、边界是程序几何。当前不是需要重写的关卡系统；只在后续授权的画面范围做视觉覆盖。
- Terminal、loot、extraction、reach/threat 的提示几何在 `scripts/world/`；保留交互可读性与原节点，不把静态家具误当成有交互的 Terminal。

## 5. Presentation 临时项清单

| 类别 | 当前实现 | 后续策略 |
|---|---|---|
| placeholder | 外围 blockout、Hanger、Terminal 外壳、敌我同模型 | 保留行为，按 P0/P1 局部替换 |
| programmer art | 装备胸甲/背包、空间标志/圆环、UI 默认控件 | 接口不变，仅替换 Art/Theme |
| procedural geometry | 城市、roof/canopy、cover 装饰、部分小家具 | 已好用的保留；Blender 加工优先于再写生成器 |
| temporary texture/material | flat colors/palette、缺少受控 dirt/roughness variation | palette 自身不是垃圾；只补 1–2 材质，不堆 4K/8K |
| temporary VFX | `combat_effects.gd` 的 tracer/telegraph/muzzle/dodge/trail/hit/explosion 网格与 tween；敌人 overlay hit flash | C10 小粒子 atlas + Godot Presentation 适配；时序不改伤害 |
| temporary animation | reload/recoil/hit/dodge 插值、重定向与通用 locomotion | 单独验证脚滑、穿模和握持；没有专门 shell-ejection 成品资产 |
| temporary UI | HUD/Hanger/Result Label/Panel/OptionButton 等 | 保留任务/仓库/结果数据归属；主题不是新 UI 功能 |
| audio（补充） | 14 WAV，`tools/generate_audio_assets.sh` 合成 | 可运行的临时声效/BGM；本阶段不重生成 |

## 6. 文档差异与边界

`docs/asset_interface.md` 的“Unity-Chan 为可见模型、枪在背上、CombatAndroidModel”已过时；`ASSET_AUDIT.md` 前半部“没有外部武器/模块包”也是历史段落。当前以本盘点、运行代码、Handoff 和 Visual Slice 报告为准；本次不扩散修改这些历史文档。

本次没有下载新包、没有删除旧资产、没有运行 AI 生成、没有 Gameplay 变更。候选、许可门禁、工序和测试见 `docs/art_candidates/README.md` 与 `docs/ART_PIPELINE.md`。
