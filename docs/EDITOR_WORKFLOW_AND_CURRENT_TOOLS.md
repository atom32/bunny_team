# 编辑器可见性、近期工具与可复用场景包

> 后续实现已落地：校园静态作者场景、YARD目录、武器工作台与维修室模块。当前用法和验证见 [内容制作工具使用说明](CONTENT_TOOLS_IMPLEMENTATION.md)。下文保留同日**实施前审计/选型**的原始数据，“未安装/未实现”和66场景数字仅属于当时阶段。

2026-10-14，基于当前 `main @ 68076ae`。本稿补充 [内容路线图](CONTENT_PIPELINE_ROADMAP.md)，回应“工具是否过时、地图为何编辑器不可见、还有哪些场景/武器/数据工具”。本轮是审计与选型，**未安装插件、未迁移关卡、未改变战斗或存档**。

## 1. 工具不能只看首次发布时间

上一轮没有给每个候选列近期维护证据，这个不足已补充。选择应看当前版本、具体变更、支持的Godot版本、许可证、完成度和本项目接入成本，不把2023年的首发贴或2026年的商店上架日期直接等同源码维护日期。

本轮读取作者发布页，并将六个候选的源码克隆到仓库外，核对commit、README与plugin.cfg；未执行这些第三方插件。GitHub REST API遭遇403限流，相关失败保留，不捏造API日期；通过Git实际提交与tag补证。完整取样见 [证据JSON](editor_tooling_2026-10-14_evidence.json)。近期变更若只是README，表中明确标为提交而不是核心代码大更新。

## 2. 编辑器里究竟看不到哪些东西？

**是的，当前项目大量内容在 `_ready()` 创建；整个 `scripts/` 目录没有 `@tool`脚本。** 不是Godot无法显示3D，而是场景文件没有保存对应节点，编辑器不运行普通脚本。

### 隔离实例化实测

Godot 4.7.2，使用上轮已核对运行代码一致的隔离副本和全新profile目录。分别统计PackedScene实例化后、尚未入树（代表场景保存结构，不是截图）与加入SceneTree执行 `_ready()` 后的节点/网格。探针退出0，无ERROR/WARNING；这不是Forward+视觉或完整战斗验收。

| 场景 | `_ready()`前节点 / MeshInstance3D | `_ready()`后节点 / MeshInstance3D | 判断 |
| --- | --- | --- | --- |
| `scenes/areas/street_district.tscn` | **1 / 0** | **2901 / 2042** | 校园建筑、湖岸、陈设、资源点和导航主要运行时构建，编辑器打开基本是空根节点 |
| `scenes/battle/urban_arena.tscn` | 2 / 0 | 905 / 754 | 旧城区背景同样运行时生成 |
| `scenes/areas/first_mission.tscn` | 386 / 237 | 1335 / 1032 | 部分可见：门、点位与Office等保存了，嵌套Arena背景仍运行时生成 |
| `scenes/weapons/assault_rifle.tscn` | **17 / 1** | **18 / 2** | 模型与4个Marker3D已保存，编辑器能查看/调整；新增mesh是运行时枪口闪光，不等于整把武器不可见 |
| `scenes/presentation/compact_hideout/environment.tscn` | **232 / 150** | **232 / 150** | 独立基地环境已是可见可摆放的保存场景，当前没有碰撞体 |

网格节点数不等于draw calls、独立模型数或GPU开销；隐藏的枪口mesh也计入类型统计。

### 代码原因与实际影响

- `street_district.tscn`只保存根和脚本；`street_district.gd::_ready()`调用 `CampusLayout.build(self)`、药房/灯光陈设、`_build_points()`与`_build_navigation()`。坐标和房间/出口主要在代码常量里，不是可拖动的编辑器节点。
- `battle.tscn`也不保存当前校园。`battle.gd::_ready()`要求有效SortieSession，再根据area ID载入地图、创建玩家/敌人/相机/HUD；直接F6运行Battle不等于正常部署。
- 玩家角色、rig和装备主要由 `PlayerController._build_character()` / 装备实例化生成，打开 `player.tscn`不等于能查看完整生产持枪状态。
- `hideout.tscn`是运行时组合外壳，但它引用的 `compact_hideout/environment.tscn`本身可编辑。不要把组合外壳不可见概括为所有基地资产不可见。
- 武器`.tres`已有数值、scene、弹药规则，武器`.tscn`已有模型/Muzzle/PrimaryGrip/SupportGrip/ReloadGrip。目前缺的是**生产角色上的姿态/动作/开火联调预览**，不是缺一套新的武器数据底座。

编辑器工具的能力边界见Godot官方 [在编辑器运行代码](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html)。给整个Battle/Player/地图依赖链直接加 `@tool` 会把autoload、物资随机化、存档/流程、导航和游戏信号带入编辑器；不建议这样修可见性。

## 3. 可见性应先于购买更多模型

建议按下面顺序做，**尚未实现**：

1. **短期只读预览**：在隔离流程导出静态校园审图快照，显示建筑、道路、门/碰撞、出生/出口/任务点和生产相机。清楚标记“派生预览，不能当关卡编辑真源”；不带AI、个人存档或掉落抽签。
2. **正式关卡制作**：把固定环境与作者点位迁入真实 `.tscn`/子场景；只让每局随机选出生、敌人启用、出口条件和任务状态继续运行时配置。这是把关卡变成可编辑真源，不是长期维护一份代码地图加一份不同步的手工图。
3. **拆出场景模块**：宿舍房间/药房/维修站/档案室/湖岸段，分别具有Art、GameplayGeometry、Markers与明确的碰撞/导航规范。装饰插件只能操作Art层，不能随机刷门/出口stable ID。
4. **武器台**：直接加载已有WeaponDefinition.scene；生产角色/俯视镜头、握点Gizmo、受控开火/换弹/切枪/闪避和缩略图在一个独立台中预览。弹药消耗与命中只走现有owner，不新增第二套射击逻辑。

迁移前后检查同一坐标、碰撞层、导航、stable点位ID、世界layout signature与checkpoint兼容性；静态结构变动不能默默让旧局内存档恢复到另一张图。连续重建不重复生成，预览不得交易/结算或写正常profile。

## 4. 更新后的插件 shortlist

表中日期明确区分发布与最近取样提交。所有兼容描述若来自作者，只表示**作者声明**，未在本项目装插件验证；不将README“production-ready”当独立验收。

### 数据管理

| 候选 | 近期证据、版本与许可 | 对本项目的用法与取舍 |
| --- | --- | --- |
| **[YARD](https://github.com/elliotfontaine/yard-godot)** | [v1.3.1发布](https://github.com/elliotfontaine/yard-godot/releases/tag/v1.3.1)，2026-10-08；实际tag `a496be3`及plugin.cfg=1.3.1核对。MIT；[商店](https://store.godotengine.org/asset/elliotfontaine/yard-yet-another-resource-database/)标4.4–4.8.x、当前unstable | **优先隔离试用**：现有Resource表格、目录扫描、引用ID下拉。先只用编辑能力，ContentDB保留；YARD缺省string ID取文件basename，与本项目 `weapon.assault_rifle_01`等definition.id不是天然同一ID，必须显式同步/校验，不能直接迁移存档。 |
| **[Godot DataTables](https://github.com/yulrun/godot-data-tables-addon)** | 1.0.0，README/官网声明Godot4.7+；实际最近提交2026-07-14 `1f9240d`（README更新）；MIT | **有明确批量配置需求时试点**：类型化schema、数组/资源引用、row handle下拉、CSV/JSON。更接近新的数据表真源，不是单纯编辑现有`.tres`；先一张非存档权威配置表或单向导出适配，不再维护两套武器定义。 |
| **[GoSheets](https://github.com/marcel-b-roodt/GoSheets)** | plugin.cfg=0.1.2，实际2026-09-09 `3c966cb`修复不当script.new导致引擎崩溃；GPLv3；README仍Stage2 | **观察/独立试用，不列默认生产选项**。新但资源生命周期、关系查找、CSV/JSON等仍列后续阶段；不能把路线图当已完成功能。许可证与分发边界需单独核对，不与MIT候选混称。 |
| [Edit Resources as Table](https://godotengine.org/asset-library/asset/1479) | 官方库2.17.4、提交日期2026-01-27，MIT，Godot4分支；本轮Git克隆失败，未核对该分支最新commit | **保留备选，不再只凭旧首发贴优先推荐**。不是完全停留2022年的工具；直接改`.tres`的接入成本仍低。与YARD二选一验证，不同时铺三种表格系统。 |

### 场景/关卡制作

| 候选 | 近期证据 | 本项目决策 |
| --- | --- | --- |
| **[Godot Asset Placer](https://github.com/levinzonr/godot-asset-placer)** | 1.6.0，实际2026-08-25 `1dbf9fd`；[发布页](https://github.com/levinzonr/godot-asset-placer/releases/tag/1.6.0)新增brush模式；MIT；商店当前标unstable | 首选摆放/资产库候选；只安装其 `addons/asset_placer`，源码demo带Terrain3D目录不代表要把整个仓库addons搬进项目。它不能把空的运行时校园自动变成编辑关卡，需要先落地静态场景层。 |
| **[Scene Builder](https://github.com/sci-comp/scene-builder)** | README Godot4.4+；实际最近提交2026-07-26 `6d1cff9`（README贡献者更新），plugin.cfg仍0.0；MIT | 可替代Asset Placer：场景资产浏览、点位摆放、Path3D围栏与批量操作。维护日期不能单独证明版本成熟；先在新模块场景试用，注意它的配置/集合机制。 |
| [Cyclops Level Builder](https://github.com/blackears/cyclopsLevelBuilder) / [func_godot](https://github.com/func-godot/func_godot_plugin) | 官网仓库分别是编辑器白盒关卡工具 / Quake.map工作流；本轮未取样commit日期，不列入“2026已验证维护”名单 | 前者用于新室内白盒；后者适合明确选择TrenchBroom工作流。均不是内容包，不为校园现有固定布局引入另一套建图工具链。 |

同名注意：Roman Levinzon的免费MIT **Godot Asset Placer** 与CookieBadger的收费 **AssetPlacer** 是不同产品。后者 [2026-05-13发布1.5.0](https://cookiebadger.itch.io/assetplacer)，仅列付费备选，本轮未购买。

### 武器与战斗制作

| 候选 | 证据与功能 | 对当前项目的用途 |
| --- | --- | --- |
| **[Godot Simple FPS Weapon System](https://github.com/Jeh3no/Godot-simple-FPS-weapon-system)** | 实际最近提交2026-06-22 `a7bd56c`（捐赠说明）；作者声明4.4–4.7；源码MIT。Resource武器、hitscan/projectile、独立开火/装填/弹药组件、移动靶射击场 | **优先拆解射击场/调参结构**，不替换斜俯视controller。其输入动作、第一人称viewmodel/共享弹药与物理层约定和本项目不同；视频专有声音/素材不在下载里，不当完整军械包。 |
| [COBRA FPS Feelkit](https://github.com/WynnSystems907/COBRA-FPS-Feelkit) / [Godot FPS Template](https://github.com/DelaiDan/godot-fps-template) | 作者目标分别Godot4.5.x与4.5+；第一人称gunfeel/Resource射击模板。本轮未核commit日期，不声称最新维护或已适配4.7.2 | **独立参考而非整体集成**。借鉴recoil/弹道/射击场；不能因此再启动另一套库存/伤害/存档owner。 |
| **[Gun & Shooting VFX / Muzzlux](https://gennai.itch.io/gun-shooting-vfx-godot-4)** | 2026-10-12新发1.0；作者声明测过4.7.2，包含编辑器预览与demo；收费、定制许可禁止单独重分发；有免费impact sample | **观察/先看免费样例**，不能因为刚发布便称成熟。若采用只接表现，使用既有命中结果（如fire_at/impact），不让它另做raycast伤害。作者性能/零错误数字不是本项目实测，不购买或把受限原包提交公共仓库。 |
| [GodotGAS](https://github.com/yulrun/godot-gas) | 作者描述Godot4.6+的数据驱动技能/属性/标签/效果系统；本轮未完整核许可、commit或接入 | 只有真需要蓄力技能、状态效果、复杂属性组合时再评估。它不是武器握点/换弹编辑器；当前项目已有DamagePacket/医疗/装备修正，暂不迁移战斗基础。 |

**武器开发的关键组合：现有WeaponDefinition + 一个数据表编辑器 + 独立射击/持枪预览台。** 不是安装一个FPS框架就自动获得本项目的持枪动画、负重、携行损失和挂起恢复。

## 5. 可复用场景包：必须分“模型包”和“真正Godot场景”

| 包 | 是否有真实Godot场景/预制模块 | 当前适合程度与限制 |
| --- | --- | --- |
| **[Analog Memory — 80s Retro Rooms](https://store.godotengine.org/asset/emace-art/analog-memory-80s-retro-rooms/)** | 作者列5间已布置/打光demo、118组合prefab，Godot4.7.1 Forward+；商店2026-10-07更新、当前免费/unstable | **最值得先审图的现成室内包**：宿舍/生活空间/维修角落。但80年代美术需筛掉时代不符道具；定制EmacEArt许可允许游戏使用、禁止原始素材独立重分发，不能直接把下载包推入公开Git仓库。不是任务/导航完整关卡。 |
| **[Kominka Modular Home Lite](https://store.godotengine.org/asset/rice-studio-lab/kominka-modular-home-pack-lite/)** | 24资产、现成Godot场景/碰撞/示例；2026-09-14更新；Lite全部MIT，Full另有商业条款 | 免费且真有scene，但日式老屋主题不匹配当前校园，作为模块化包装参考/后续居民区候选。作者只证macOS Compatibility，包括4.7.2；Windows/Forward+未证，商店unstable。 |
| **[Quaternius Downtown City MegaKit](https://quaternius.com/packs/downtowncitymegakit.html)** | 2026-05发布；7示例建筑，**Source版本**有Godot项目、材质/碰撞，作者列Godot4.5 | 新近且适合城区外围；CC0。免费Standard是部分模型，不能默认含完整Godot项目；Source有成本，未购买。美式建筑风格与校园需融合；不是可直接玩搜打撤的新地图。 |
| [Quaternius Modular Sci-Fi MegaKit](https://store.godotengine.org/asset/quaternius/modular-sci-fi-megakit/) | **Source**提供Godot工程、shader与碰撞；官方商店明确免费Standard **没有Godot project** | 可用于实验区内部，但偏科幻，按剧情需要少量选件；不以“商店免费”宣称拿到整套预制工程。原包2024，静态模块年龄不等于失效。 |
| [Kenney City Kit Industrial](https://kenney.nl/assets/city-kit-industrial) / [Modular Buildings](https://kenney.nl/assets/modular-buildings) | 官方模型包、CC0；前者v2.0有新能源道具，1.0在2025发布；后者v2.1重做 | 低成本白盒/维修区布景；**不是已确认含原生.tscn的场景包**，需项目包装碰撞/原点/材质与prefab。不能把100模型等同100可玩房间。 |

上表免费、版本、许可与兼容是本次一手页面取样，并非下载核包或本机实际验收；没有下载安装这些场景包。场景自带灯光/WorldEnvironment应与当前RenderProfile统一，不将demo后处理叠加进整个游戏。

### 本仓库已有可复用场景，不必全部外购

- `scenes/presentation/compact_hideout/environment.tscn`：静态导入的6×4m室内模块，可直接编辑；目前是相机基地，没有现成战斗碰撞/导航。
- `scenes/areas/field_office_art.tscn` + `prototype_field_office.tscn`：已有室内美术/游戏几何分层，适合拆出药房/维修模块的结构参考。
- `scenes/world/door.tscn`、`cover_obstacle.tscn`、`extraction_point.tscn`、`enemy_spawn_point.tscn`、`loot_spawn_point.tscn`、`objective_reach_zone.tscn`：已有玩法prefab，保留脚本/组/ID/碰撞层。新美术场景尽量接这些，而不是复制外包的另一套交互系统。
- `scenes/weapons/*.tscn`：已有七类武器包装与握点。新增武器流程应从这些合格模板起步，不从裸GLB/整套第一人称demo起步。

## 6. 调整后的下一步

建议首批：**校园编辑器可见性/静态模块化 → YARD只编辑试用（DataTables对比备选）→ 现有角色武器预览台 → 一个真实室内场景包小样**。这是新选择顺序，覆盖上一稿“先表格/摆放/动画”未体现关卡可见性的排序。

采用门禁：固定源码tag/hash；在隔离工程启用，确认4.7.2冷导入/编辑器日志；加载当前武器/弹药继承Resource并保存重开；检查definition.id与registry ID、引用、Undo/Redo和Git diff；新增模块走真实导航/感知/出口/挂起恢复；自定义许可不把原始包提交公开仓库。移除插件后游戏仍以现有定义与场景运行。

本轮结论不是“新插件已装好”。实测了可见性结构，查证了维护/版本与场景包范围，更新选型；没有把读取第三方README当成兼容性或质量认证。
