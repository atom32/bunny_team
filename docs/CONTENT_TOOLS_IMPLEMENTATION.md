# 内容制作工具使用说明

> 2026-10-15最新动作/模型制作入口：[独立审查台、成年男女适配与主角自然战斗样式](MODEL_ANIMATION_AUTHORING.md)。本页旧库存与未实现事项保留为阶段历史，不覆盖新批次状态。

> 接续开发：内容检查与物品向导现已实现，当前进度和新增入口见 [下一批内容制作](CONTENT_AUTHORING_PROGRESS.md)。下文四菜单项及70测试是上一批交付记录。

2026-10-14，在 `main @ 68076ae` 上的本地实现。先解决校园无法在编辑器制作的问题，再接表格与生产武器联调；不替换现有 ContentDB、玩家控制器、命中逻辑或存档格式。所有修改尚未 commit/push。

## 快速入口

使用 **Godot 4.7.2** 打开 `project.godot`，等待导入完成。项目已启用 YARD 与 Neon Content Tools；如果插件被本地禁用，在 Project Settings → Plugins 中启用。

上一批顶部 **Neon Tools** 的四个入口：

| 操作 | 打开的内容 |
| --- | --- |
| Open editable campus | 生产校园 `scenes/areas/street_district.tscn`；固定环境来自下面的静态作者场景 |
| Open weapon workbench | `scenes/tools/weapon_workbench.tscn`，按 F6 运行联调台 |
| Open module sample | `scenes/tools/module_sample.tscn`，按 F6 查看室内模块 |
| Synchronize YARD catalogs / stable IDs | 按定义本身的 `id` 更新三个编辑目录，Output 显示报告与错误 |

## 校园现在可以直接制作

**真源是 `scenes/areas/campus/static_world.tscn`，不是只读截图，也不是运行时生成器。** 打开它即可选择、移动和保存建筑、陈设、碰撞体、导航和作者点位。生产入口继承该场景，并额外挂载夜间灯光与少量每局逻辑。不要把生产入口的继承场景直接 Make Local 成另一份整图。

- 保存了原有 **2042 个 MeshInstance3D、161 个碰撞形状**；生产包装另含夜间灯具。普通游戏脚本没有整体改成 `@tool`。
- `RoomAnchors` 是房间/侦察作者点，`RecordSites` 是记录终端候选位置，`RelaySites` 是维修站作者点。`StreetSpawn0…5`、`Exit0…3`、LootSpawnPoint、EnemySpawnPoint 都是保存节点。
- 任务抽签、敌人/掉落、出口选择和任务依赖的维修节点仍在出击时配置；编辑器打开地图不会启动一局游戏。
- 日间环境与当前已保存导航保留；夜间灯光独立在 `night_lighting.tscn`，运行时夜间环境复制后调整，不污染共享日间资源。
- 老构建脚本存为 `art_source/campus_editor_migration/legacy_source/*.gd.txt`，只用于追溯；生产地图不再调用它们重建固定几何。

### 碰撞和导航修改

移动美术时，也检查同组碰撞体；只移动 Mesh 不会自动移动另一个兄弟 CollisionShape。选择 `StreetNavigation` 的 NavigationMesh，用原生 **Bake NavigationMesh** 更新导航，然后保存作者场景。已配置按 `campus_navigation_source` 组递归解析 Static Colliders、碰撞层 1 和 3；`NavigationBakeExclusions/Lake0…2` 为湖面烘焙排除轮廓，关闭运行时 avoidance，不额外加碰撞体。

本次**没有重烘焙生产导航**，保留旧地图的碰撞/导航签名与旧挂起兼容；在隔离副本中验证原生重新解析/烘焙得到有效网格且湖面排除生效。新烘焙算法与旧手工格网不同，改图后需检查门口/小房间/湖岸、敌人到达与撤离，并按新地图处理旧 checkpoint，不能继续声称同一布局。

根 metadata 的 `campus_roads`、`campus_lakes`、`campus_buildings` 是路线地图绘制数据，**不会因拖动模型自动同步**；大改道路、建筑轮廓或湖面时同步这些数据及湖面排除节点。此轮还不是道路绘制器/自动小地图生成器。新模块若放在校园根下，会参与该组的递归导航烘焙。

迁移回归专用 `campus_editor_scene_test` 对比 `legacy_layout_signature`；未来刻意改图后，应审核更新迁移基准与兼容策略，而不是删除断言或修改签名来掩盖意外漂移。

## 用 YARD 编辑现有 Resource

安装 [YARD v1.3.1](https://github.com/elliotfontaine/yard-godot/releases/tag/v1.3.1)，固定 commit `a496be3dfa1279bfdd999950e0936eaac0d84fc3`。仅包含插件；许可、来源与一个 Godot 4.7.2 启动兼容补丁见 `addons/yard/UPSTREAM.md`。没有带入 demo 或另一套库存/战斗框架。

在 FileSystem 中打开 `resources/editor_catalogs/weapons.tres`，通过 Registry 主界面查看表格；同目录还有 `items.tres` 与 `enemies.tres`：

- weapons：7 行；items：27 行，包含武器、装备、弹药、材料和医疗；enemies：3 行。
- 表格编辑的是**同一份生产 `.tres`**，不是独立数据库副本；可编辑伤害、重量、换弹时间、scene 等导出字段，Undo/Redo 后保存资源。编辑后检查 Git diff，重开资源并跑相应测试。
- **不要改已有 `id`、Registry 的 String ID 或 UID 来换外观。** 这三个标识不是可随意更名的展示名称；保存的库存、装备和任务按 stable ID 关联。同步采用定义的 `id`，关闭按文件名自动扫描。
- 同步拒绝缺失/重复 ID、重复 UID，以及同一已登记 UID 的定义 ID 改名；验证失败不替换已有三个目录。它不是任意数据迁移器，也不会阻止你直接在表格/文本里写坏定义，发布前仍需回归。
- 原有30份定义只增加原生 UID header，数值/引用正文未改变。新增资源由 Godot 管理自己的 UID，不复制旧 UID。

### 添加一件内容的最小流程

1. 从对应 `ItemDefinition` / `WeaponDefinition` / `EnemyDefinition` 模板新建 Resource，填写全新且唯一的 `id`、显示名和必要字段。不要把普通材料强行换成武器类。
2. 武器场景从 `scenes/weapons/` 合格模板派生；保留 Muzzle、PrimaryGrip、SupportGrip、ReloadGrip 与正确原点/朝向。敌人 `scene` 是现有 controller 包装场景，不是裸 GLB。
3. 将定义显式登记至 `resources/content/content_manifest.tres`，再配置购买、掉落、制作或任务获得渠道。**Sync 目录不等于注册到游戏，更不等于加入了玩法。**
4. 使用 Neon Tools 同步编辑目录，检查 Output；重新打开目录资源以刷新表格视图，在 YARD 或 Inspector 编辑正式参数并保存。
5. 跑内容/武器或敌人测试，再验证获取→携行→使用/损失→保存恢复；记录资产来源与许可。

此轮没有通用物品导入向导、任意骨架自动适配、动画重定向向导或批量敌人行为编辑器。保留这些后续需求，不宣称安装表格就已实现。

## 武器与动作联调台

打开 `scenes/tools/weapon_workbench.tscn` 按 F6。使用真实生产 PlayerController、CombatRig、握点和现有命中路径，但关闭玩家物理移动、不发布 SortieSession。

- 可切换全部7把现有武器，查看正面/侧面/背面和实际战斗镜头尺度（19.5）。
- Idle、Walk、Run、Dodge 使用现有 locomotion；Reload 使用现有 reload pose，**不是新导入的 mocap 换弹 clip**。
- Fire 在本地靶上调用真实射击链；Reload/Dodge、暂停/继续、播放速度与清靶用于姿态检查。
- 青色球为握点，红色球为枪口；正式武器场景另有编辑器 gizmo 显示枪口方向与握点连线，可选择对应 Marker 用原生移动/旋转工具调整。
- Damage / Reload Time 仅改当前克隆定义，不保存正式数值；正式参数请回 YARD/Inspector 保存。工作台动作不改 profile 或当前出击，测试检查了前后数据一致性。

F6 仍启动项目 autoload，ProfileRuntime 可能读取当前用户 profile；本台没有写入 profile 的操作。若要求连读取也隔离，请使用下面的全新验证副本/用户目录，不把个人存档带入试验。本次自动化与截图都使用隔离目录。

## 可复用维修室样例

`scenes/modules/service_room.tscn` 是真正的原生 6×8m 模块，不是裸模型集合。复用仓库已有 **Kenney Space Station Kit CC0** 地板、墙、工作台、椅子、电脑和箱体，保留现有门与维修物资点。

- `Art` 是可替换美术；`GameplayGeometry` 是独立碰撞；`Markers` 包含 RepairAnchor、SupplyPoint 与提示。
- 独立作者模块不带全局 WorldEnvironment；样例展示场景 `scenes/tools/module_sample.tscn` 带自己的相机/灯光。
- 放入关卡后检查门的交互距离、通道/碰撞、导航、物资点与本局结算。直接 F6 展示不抽签物资。
- 该模块**未替换生产校园房间，也未接入新任务**；它是第二个房间可复用的制作模板，不是已增加一段可玩剧情。

没有下载或提交受限的 Analog Memory 素材包，没有购买插件/资产，没有修改原始角色、武器或动画资产。

## 验证方式与证据

```powershell
& 'C:\Python314\python.exe' tools/verify_migration.py --godot 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --output '<全新仓库外目录>' --route
```

runner 已审核对齐 **70 场景**（原66 + 4个新工具回归），为两个原有长时间 Hideout 测试补足帧预算；未放宽错误判定、完成 marker 或游戏断言。图形 route 显式 Dummy 音频：这是画面/路线证据，不是声卡听感验收。

验证结果：**70/70场景、90/90非图形路线结果项通过**，覆盖跨进程读回、已确认落盘后的强制终止恢复和 Main。冷导入有原始2个FBX UTF-8 warning；Main退出保留已知2个ObjectDB实例泄漏 warning。最后一次完整runner的图形route失焦后超时，原失败未改写；仅修测试驱动的按键缓存释放，随后正常路线与主动插入真实暂停的路线各通过一次，未放宽任何路径/碰撞/AI断言。因此不把原完整runner伪称为91/91通过。

最终结果与源文件 hash 见 [验证记录](content_tools_2026-10-14_validation.json)。编辑器验证包含真实 `Engine.is_editor_hint()` 场景、YARD 表格的单元格编辑信号链/Undo/Redo/保存重载、同步幂等、非法 ID 拒绝和隔离原生导航烘焙；画面包括实际编辑器3D viewport和 Forward+ 工作台。临时探针不作为游戏源码发布，失败日志保留在仓库外证据目录。

完整 Alpha 仍需真人节奏、听感与最低硬件验证；此交付不改变 Artoria 临时模型的发行授权限制，也不把工具完成等同六项校园任务全部上线。
