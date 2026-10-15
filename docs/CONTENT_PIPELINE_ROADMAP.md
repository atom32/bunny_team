# 内容扩充与开发工具路线图

> 2026-10-15落地汇总：作者场景/YARD、物品向导/只读检查、成年男女动作审查、主角自然轻盈战斗适配、3件实物套件及校园3–6任务均已接入，详见 [最新批次](CAMPUS_BATCH2_IMPLEMENTATION.md)。以下选型优先级保留为实施前调研，不重复把已完成项列为下一步。

> 2026-10-15最新动作/模型制作入口：[独立审查台、成年男女适配与主角自然战斗样式](MODEL_ANIMATION_AUTHORING.md)。本页旧库存与未实现事项保留为阶段历史，不覆盖新批次状态。

> 后续实现已落地：校园静态作者场景、YARD目录、武器工作台与维修室模块。当前用法和验证见 [内容制作工具使用说明](CONTENT_TOOLS_IMPLEMENTATION.md)。下文保留同日**实施前审计/选型**的原始数据，“未安装/未实现”和66场景数字仅属于当时阶段。

调研日期：2026-10-14。依据同步后的 `main @ 68076ae`；以下工具选择与优先级是针对本项目的工程判断，不是已安装、已集成或已通过兼容性测试的声明。现状与本轮验证见 [项目审计](PROJECT_STATUS_2026-10-14.md)。

**后续补充优先阅读：[编辑器可见性、近期工具与场景包](EDITOR_WORKFLOW_AND_CURRENT_TOOLS.md)。** 已实测校园`.tscn`入树前1节点/0网格，运行后2901节点/2042网格；补入YARD/DataTables/GoSheets的近期源码与发布证据，区分现成Godot场景与裸模型包。下方初版候选保留供比较；最新排序先解决校园静态场景可编辑，再试数据表与武器预览，不仅凭首发年份判断工具是否过时。

## 1. 结论：做内容生产工具，不换游戏底座

**现在应该做轻量工具来帮助导入物品、角色、敌人和动画，但不该先做一个万能编辑器。** 游戏已具备数据 Resource、内容注册、装备实例、交易、撤离结算与跨进程恢复。替换为另一套 RPG/背包/任务框架会增加迁移成本，且未直接增加可玩内容。

当前真正需要打通的是：

```text
来源与许可 → 导入预检 → 生产镜头预览 → 现有 Resource 定义
         → 显式注册与引用检查 → 小批次实际游戏验收 → 回归与存档验证
```

模型多样性 ≠ 玩法多样性。优先让一件物品改变携行/交易/任务取舍，让一种敌人改变交战方式，让一个事件改变路线；新外观和动画为这些变化服务。校园第二批任务应沿 [当前六项委托稿](narrative/DEVELOPMENT_STATUS_AND_TASK_STORY.md)推进，不恢复旧物流核验故事。

## 2. 已有基础与重复劳动

| 领域 | 可复用代码/资产 | 当前瓶颈 |
| --- | --- | --- |
| 物品与装备 | `scripts/data/*_definition.gd`、`resources/content/content_manifest.tres`、`ContentDB` | 手工创建 `.tres`、注册、图标与多处文本；新增定义不代表已在商店/掉落/制作中可获得 |
| 图标 | `tools/stash_icons.gd` / `.tscn`，从装备场景渲染缩略图 | 仅处理有场景的装备；文件名取 ID 第二段，扩展命名空间后可能覆盖同名图标；需要增量和冲突检查 |
| 玩家模型 | `player_controller.gd`、Artoria `pose_adapter.gd` / `hand_modifier.gd` | 模型、骨骼重命名、动作源、挂点和专用接触校验仍与当前角色耦合；不能任意换 GLB |
| 敌人 | `EnemyDefinition`、`enemy_controller.gd`、`infected_controller.gd`、三种已注册定义 | 数值可配置；PMC 模型/动作名固定，感染者复用 PMC 皮肤与拳击动作；外观和行为需分别配置 |
| 动画 | `bake_mco_clips.gd`、`bake_hideout_transitions.gd`、Quaternius Hideout JSON 与重定向 | 烘焙、骨骼映射、动作命名、循环和 root policy 尚无统一可视化检查；Hideout动作不是通用战斗动作库 |
| 任务与内容 | `MissionDefinition` / `ObjectiveDefinition`、`NarrativeSlice`、`CampaignService` | 出击目标已有 Resource，剧情和基地成长仍有固定代码；新任务的世界交互、结算、UI、存档不能只靠填表 |
| 场景与验收 | `campus_layout.gd`、已有探针与 `verify_migration.py` | 美术摆放和游戏语义需联动；验证脚本固定数量已落后于实际测试库存 |

## 3. 网上工具筛选：买/用现成的，还是自建？

只使用作者仓库、官网或 Godot 官方资料。版本与许可是本次页面核对，不保证未来不变。正式采用应固定 release/tag/commit，记录依赖与许可证，并在 **Godot 4.7.2 / Windows** 隔离副本实测；编辑器工具优先于运行时框架。

| 候选与一手来源 | 能解决什么 | 本项目决策与成本 |
| --- | --- | --- |
| [Edit Resources as Table](https://github.com/don-tnowe/godot-resources-as-sheets-plugin)，[Godot 库条目](https://godotengine.org/asset-library/asset/1479) | Godot 4 的 Resource 表格编辑、CSV、批量数值编辑与 Undo/Redo；MIT | **优先隔离试用**。直接编辑当前 `.tres`，不替换 ContentDB；测试自定义继承类型、数组/资源引用、保存后重开与 Git diff。用它代替自建完整表格编辑器。 |
| [Godot Asset Placer](https://github.com/levinzonr/godot-asset-placer) | 3D资产集合、缩略图、网格吸附、旋转/缩放与撤销；MIT | **优先试用美术布景**。只放装饰包装场景；门、掩体、目标、出生点和出口必须保留游戏语义与稳定 ID。不能自动生成合格关卡。 |
| [Quaternius UAL 1](https://quaternius.com/packs/universalanimationlibrary.html) / [UAL 2](https://quaternius.com/packs/universalanimationlibrary2.html) | 人形动作与 Godot 导出版本，官网标 CC0，分 Standard/扩展版本 | **最高优先资源源**。项目已使用 UAL1 的部分 Hideout动作；先核对免费 Standard 实际含哪些动作，别把完整包宣传数量当免费数量。新增受击、死亡、近战/交互动作逐个审查，不宣称存在已验收抱臂/换弹动作。 |
| [Quaternius Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html) | 同系列人形底模，官网标 CC0 | **敌人独立外观试点**；优先一个受试者候选，与现有 PMC 区分。骨骼与风格仍须实测；不自动替换当前主角，不将角色基模当完整感染者成品。 |
| [Kenney Survival Kit](https://kenney.nl/assets/survival-kit) | 免费 CC0 3D生存道具 | **补物品世界外观与地点用途**。选择少量与医疗/维修/营地需求相符的资产；保留包内许可和来源，不整包堆入 runtime。 |
| [Poly Haven](https://polyhaven.com/license) | CC0 模型、材质、HDRI；许可页区分资产与网站内容 | **继续现有环境路线**。优先低分辨率贴图和必要道具；控制材质、透明层、灯光与draw calls。资产 CC0不等于网页/商标也可随意重分发。 |
| [Dialogue Manager 4](https://github.com/nathanhoad/godot_dialogue_manager) | Godot 4.6+ 的无状态分支对白编辑/运行，MIT，含翻译文档 | **开始批量对白时再试用**。仅接管文本和分支显示；任务奖励/物资消耗/结算仍由当前服务负责，不能从对白脚本直接改钱包。先一个联系人短对话，测试中英与恢复。 |
| [LimboAI](https://github.com/limbonaut/limboai) | Godot 4行为树、层级状态机、黑板、调试器；有 GDExtension/模块版本 | **暂不迁移现有感知/战术AI**。以后 Boss/小队行为明显复杂再独立实验。需选匹配Godot版本的二进制，设计状态保存；源码MIT，demo美术为CC BY 4.0，不能混同。 |
| [Pandora](https://github.com/bitbrain/pandora) | RPG数据编辑器与运行时单例；MIT | **借鉴编辑体验，不做数据底座迁移**。作者仍标 Alpha / not production-ready；会与当前 Resource/ContentDB、稳定ID和存档约束重叠。 |
| [Expresso Inventory System](https://github.com/expressobits/inventory-system) | 物品资源、格子库存、制作与掉落示例；MIT；当前 main 为C++插件 | **参考示例，不替换仓库**。现有实例所有权、死亡损失、精确携行与原子保存已投入使用，重新集成收益有限。 |
| [ProtonScatter](https://github.com/HungryProton/scatter) | 按区域/路径规则散布道具，Godot4插件MIT；GitHub为镜像 | **仅环境细节可选**。产出固定可审查摆放，不随机堵住路线；demo纹理另有条款，不整包继承MIT结论。 |
| [Material Maker](https://github.com/RodZill4/material-maker) | 基于Godot的程序材质/3D绘制外部工具，仓库默认MIT | **按需使用，不集成运行时**。制作共享环境材质并烘焙贴图；社区素材单独核许可。当前角色材质不属于本轮重做范围。 |
| [Terrain3D](https://github.com/TokisanGames/Terrain3D) | MIT、GDExtension地形编辑/植被工具 | **低优先**。压缩校园/城市室内主要缺玩法与布景，不缺大地形；有野外地图明确需求再评估性能、碰撞与导航。 |
| [Godot 官方 demos](https://github.com/godotengine/godot-demo-projects) / [TPS demo](https://github.com/godotengine/tps-demo) | 动画、导航、3D射击与灯光参考项目 | **选小示例学习，不搬整套射击框架**。demos应选对应稳定版本分支；TPS的第三人称控制不等于斜俯视搜打撤；复用美术另查具体LICENSE。 |

**初版首批为Resource表格、资产摆放、Quaternius动作；补充调研后先处理校园静态层可见性，再试YARD/表格与武器台。** Asset Placer不能给空的runtime场景自动补出可编辑关卡。近期维护/unstable状态和备选比较见 [补充报告](EDITOR_WORKFLOW_AND_CURRENT_TOOLS.md)。不一次安装全部插件，保留当前真实场景/进程验证。

## 4. 自建工具的最小边界

建议统一入口 `Content Workbench`，由若干小命令/预览页组成。先做只读检查与独立预览，验证有效后才包成 EditorPlugin。以下名称、字段和目录均为**规划，尚未实现**。

### P0：内容检查器 + 物品创建向导

- 从现有定义生成只读目录：ID、类型、图标、引用、获取渠道、中英文本、许可状态；同时报告未注册定义与死引用。
- 创建时选择现有模板（材料/医疗/弹药/装备/武器），自动提议新ID；克隆资源必须新ID，不能共享可变实例状态。
- 校验跨类型重复ID、重量/栈上限/占格、弹药兼容、资源缺失、商店与loot引用、来源/许可。不要简单复制数值生成几十个无用物品。
- 生成 `.tres`、图标候选与 manifest **变更预览**；显示新增、修改、冲突，用户确认才发布。已有合法资产不能被导入顺手覆盖。
- 复用 `ResourceSaver` 与当前 Resource 类型；`.tres` 是唯一内容定义真源。可用CSV作单向批量输入，但不要让CSV、JSON、Pandora和`.tres`成为四套相互冲突的真源。
- `ContentDB` 已有部分运行时检查，但不是完备的离线lint；检查器必须汇总错误、非零退出，不能只读日志警告。

### P1：模型与动画审查台（实际生产镜头）

- 静态道具：尺度、原点、朝向、材质/贴图缺失、AABB、mesh/材质数量；不自动焊接/减面/改蒙皮。
- 武器：`Muzzle`、`PrimaryGrip`、`SupportGrip`、`ReloadGrip`可视化，装备挂点预览，开火/换弹/切枪/闪避；复用缩略图脚本但修正命名冲突与覆盖策略。
- 角色：骨骼列表、BoneMap、rest pose、身高/脚底/方向、蒙皮与缺失映射；正侧背和当前俯视镜头并列。角色选择不得污染正常profile。
- 动画：选择来源与目标、列出clip和语义绑定、play/pause/seek/loop/speed、root位移轨迹、循环跳变、手脚接触检查；只标技术与视觉分别通过。
- 首选 GLB/glTF + `AnimationLibrary`，保存 BoneMap / `SkeletonProfileHumanoid` 配置。针对当前专用适配器先隔离验证，不能直接改主角骨骼rest或覆盖所有旧动作。
- Unity Humanoid muscle curves不是可直接映射的骨骼clip；不靠猜Euler角伪造转换。椅子接触、枪握点、脚滑、肩部变形与死亡都需实际观察。
- 玩家移动继续由现有控制器负责，默认用 in-place；root-motion动作只能在明确接入位移/碰撞/保存后使用。动画事件不自行另起一套命中计时。

Godot已有 [骨骼重定向](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html)、[动画库/导入后处理](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)、[Inspector扩展](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/inspector_plugins.html)。应在其上加项目规则，而不是自写FBX解析器。标准GLB后处理与自定义CSV导入是不同问题；只有自定义格式才需要 [EditorImportPlugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/import_plugins.html)。

### P1：敌人原型模板（先一个感染者）

- 保留 `EnemyDefinition` + 当前controller，给独立外观/clip语义绑定做最小 presentation 配置；不是把行为树引入所有敌人。
- 区分“同一行为不同外观”“不同数值”“不同交战行为”，检查报告明确标注类型。
- 一键进入可见性/掩体/近战躲避测试场；测试生死、攻击前摇、距离/墙阻断、碰撞与导航、挂起后待发攻击恢复。
- 不凭一个 `humanoid_presentation` bool 宣称可导入任意骨架；无人机、持枪人形与近战感染者有不同视觉/攻击契约。

### P2：任务与遭遇制作（比多模型更能增加玩法）

- 先沿当前 `ELIMINATE/INTERACT/REACH` 类型做目标绑定与预览；世界目标 stable ID 与存档定义一起检查，不能独立生成脱离场景的任务表。
- 用当前校园六项委托的第二批作真实需求：两座中继站 → 实验记录器 → 分离L-02支路 → 战备交付。不提前制造大而空的任意任务图。
- 固定遭遇模板可定义已有敌人职责、出生候选、目标/资源点、可预判事件和出口条件；发布前检查玩家可达性与公平性。
- 奖励、解锁、掉落、医疗与交易仍走既有服务；有新持久字段时提供schema迁移与失败写入/重复结算测试。
- 只有出现第二、第三个同类需求再把对应硬编码抽成 Resource；先抽最小配置，不建立全局 EventBus/ECS/开放世界框架。

## 5. 首批交付建议与验收

这是建议顺序，不是排期承诺；各批都应产出可玩的内容，而非只交工具面板。

| 批次 | 交付 | 验收样本 |
| --- | --- | --- |
| A：检查与物品 | 只读内容报告、表格插件隔离试用、一个物品向导模板 | 新增3–5件有明确获取/用途的物品；一个拒绝重复ID/坏路径/错误弹药的样本；重跑无额外diff；旧物品/存档不变 |
| B：模型动作 | 独立预览、动画语义绑定与来源清单 | 一个明确区别于PMC的感染者外观；2–3个免费授权且适配通过的动作；真实镜头、受击/死亡/挂起恢复，而非只import成功 |
| C：任务内容 | 针对校园第二批的目标绑定与固定遭遇模板 | 跑通一段新增任务的领取→交互→失败/恢复→撤离→奖励；再做有不同风险收益的变体；不把全部6项宣称已上线 |

量化工具价值：同等验收质量下，记录每件内容的导入/配置/修错时间与修改文件数；观察第二件、第三件是否确实复用。若主要时间仍花在美术接触/玩法迭代，不继续扩张工具平台。

### 发布门禁

1. 来源URL、作者、许可证、获取日期、原始/派生hash、修改记录齐全；当前角色临时授权状态不能被CC0环境资产遮盖。
2. 预览与游戏逻辑隔离；不访问正常存档；不自动购买、调用收费生成API或上传用户资产。
3. 冷导入无ERROR；现有两个FBX UTF-8 warning继续单列。全部实际测试库存、跨进程恢复、Main均执行；先处理本轮runner数量漂移与基地测试帧预算不足，确认完成marker，不能把超时退出0当通过。
4. 单件内容的真实获取→使用→消耗/损失→保存/恢复测试；新世界内容检查导航、碰撞、视线/听觉和出口。
5. 生产镜头中英UI与实际Forward+画面；记录内容前后的frame time、draw calls与资源占用。自动化不替代10–15局/2–4小时真人节奏与最低硬件验收。

## 6. 本轮范围

已做：Git同步、源码/资源/文档审计、一手资料调研和文档更新。未做：插件安装、工具实现、新内容导入、角色替换、购买/收费API、commit/push。上述模板、profile、工作台和新内容批次均是下一步建议。
