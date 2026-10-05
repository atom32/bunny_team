# 全屏 QA：五项问题修复

2026-10-02；基于 `main @ 602b722b6326a7821d5648386d3932796f48df04` 的工作区。**五项修复已完成，未 commit / push。** 原始体验报告保留在 `REPORT.md`，不重写历史结果。

## 已修复

| 问题 | 实现与验证 |
| --- | --- |
| 第二次出击简报错误 | Operations 读取实际 `streets_recon` 任务及目标；出口尚未分配时只提示抵达后分配两个出口、按 M 查看。不再预告南侧出口；Streets arrival 同步去掉南入口文案。中英显示通过。 |
| 失败结算标签错误 | 明确显示“带回负重 / 带回物品”；继续读取既有 outcome 的回收库存，不伪造阵亡库存快照、不改变失败损失。 |
| 仓库挡住角色 | Hanger 默认显示完整角色和右侧装备；“仓库 / 整理物资”打开原有仓库，“返回角色展示”折叠；离开机库恢复预览模式。原有拖拽、旋转、交换装备、归还仓库和持久化保留。 |
| 战斗镜头与入口遮挡 | 普通正交镜头 size 24.5 → 19.5；狙击远距观察仍采用原有 24.5 + 扩展值。修正正交视线方向，将无碰撞的雨棚、门楣、顶边及入口灯条纳入既有淡出逻辑；离开视线后恢复。不改角色、碰撞、门或路线。 |
| PMC 重叠 | 原 NavigationAgent 已启用 avoidance，却没有提交速度或使用返回速度。接通 `velocity_computed` 并采用安全水平速度；半径设为 0.55 m，对应既有 0.5 m 胶囊。相同追击方向的三敌测试，稳定后最小间距从 0.0010 m 改善为 1.1259 m；仍会追击、攻击和造成伤害。 |

**行为边界：** 敌人的局部移动轨迹因避让而有意改变，不能把本次描述为“完全没有 Gameplay 改动”。未改寻敌决策、射击冷却、伤害、移动速度数值、碰撞层/形状、武器、经济、存档、地图或角色资源。暂停/训练禁用敌人的移动回调也有验证。

## 新验证结果

在独立项目副本及独立 `user://` 中运行，Godot 4.7.2 / Windows / RTX 5090。用户的编辑器和正式存档未动。

| 验证 | 结果 |
| --- | --- |
| 现有完整测试清单 | **43/43 场景 PASS**；没有删除测试或修改 runner 计数。不是沿用历史 33/33。 |
| 五种退出路径 | **5/5 PASS**：base / battle / failure / transition / recovery。 |
| 新鲜隔离导入 | **0 ERROR / 2 WARNING**：原 Motus FBX 的 `Bad UTF-8 string (x10)`、`(x9)`；未改原 FBX，不能写 0/0。 |
| Main headless | **exit 0**；保留已知 2 ObjectDB instances 退出警告。 |
| 五问题定向检查 | 原版在五类问题上共 12 个断言失败；最终 **25 个检查 PASS**，含南北门遮挡和避让。 |
| 全屏定向画面 | Forward+ / 2560×1440，简报、角色预览、仓库、失败标签、南北入口、PMC 分离截图已检查。使用受控 fixture，不冒充实战路线。 |
| Field Office 图形路线 | 正常输入/API、真实 AI：机库 → 南门 → 室内 → Terminal → 出门 → 撤离 → Result，全部路线检查通过；57 次开火、承受 3 点伤害。此路线不完成全部任务目标。 |
| Streets 图形实战 | 既有 `streets_combat_run`：档案 → 庭院 → 室内 Loot → 撤离，30 次开火、1 次装填、10 击杀、10 个敌人移动、1 项回收，PASS。真实移动/碰撞/AI/弹药；目标和撤离通过既有测试 API 触发，不称纯人工验收。 |
| 仓库图形输入 | 渲染视口内重放鼠标按下/移动/松开及 R 键；原有真实 GUI 拖拽、旋转、换槽、卸装、换甲、保存断言全部 PASS。 |
| 跨进程存档 | 复制前轮真实游玩的 QA 存档，进程 A 加载/开关仓库/保存并退出，进程 B 再加载；完整 profile、schema、实例 ID、装备、升级和布局与输入存档一致。 |
| 工作区完整性 | 初始 3299 个文件中，只有下述 13 个本轮目标文件发生变化，无删除；原有 `.import`、`project.godot` 和旧阶段 WIP 哈希未变。角色/官方源文件未改。 |

## 测试适配说明

- `modern_arsenal_test.gd`：只将“退出精确观察后恢复普通镜头”的旧 24.5 常量改为新的普通镜头常量；仍严格检查恢复值。`camera.size > 38` 的狙击视野断言完整保留并通过。
- `verify_migration.py`：只归一化 Windows CRLF；原已知 FBX 警告精确匹配规则不放宽。此前尾部 `\r` 导致已知警告被错误判为新警告。
- `stash_probe.gd`：增加打开新仓库面板的步骤及可选 `--embedded-input`。旧脚本在 Windows 非焦点窗口中，桌面鼠标没有随 `warp_mouse` 到达目标；原版 UI 也出现相同两项失败。新模式渲染真实仓库，用独立 SubViewport 指针驱动原有 GUI，不调用数据层来代替拖拽，不删改任何原断言。它验证逻辑视口的 UI 操作，**不冒充操作系统鼠标或多分辨率人工测试**。
- `fullscreen_fixes_probe` 是新增独立定向检查，不充入现有 43 个测试的计数。

## 复现

先建立隔离副本；不要用日常存档直接运行会新建 profile 的 probe。

```powershell
python tools/verify_migration.py --godot E:\Godot\Godot_v4.7.2-stable_win64_console.exe --output <新的仓库外目录> --route
# 在生成的 project 副本中，使用独立 APPDATA / LOCALAPPDATA：
Godot_v4.7.2-stable_win64_console.exe --path <隔离project> res://tools/fullscreen_fixes_probe.tscn
Godot_v4.7.2-stable_win64_console.exe --path <隔离project> res://tools/stash_probe.tscn -- --embedded-input
Godot_v4.7.2-stable_win64_console.exe --path <隔离project> res://tests/streets_combat_run.tscn
```

## 文件与证据

生产修改：
- `localization/zh_CN.json`、`localization/zh_CN.tres`
- `scripts/battle/battle.gd`、`scripts/battle/camera_occlusion.gd`
- `scripts/enemies/enemy_controller.gd`
- `scripts/presentation/field_office_presentation.gd`
- `scripts/presentation/slice/battle_presentation.gd`、`scripts/presentation/slice/hideout.gd`
- `scripts/ui/hanger_ui.gd`、`scripts/ui/result_ui.gd`

验证修改：`tests/modern_arsenal_test.gd`、`tools/stash_probe.gd`、`tools/verify_migration.py`。新增 `tools/fullscreen_fixes_probe.gd/.tscn` 与本报告。

精选截图和日志：`local/fixes/`（Git 忽略，Godot 不导入）。完整隔离工程及过程日志：`C:/Users/admin/AppData/Local/Temp/bunny_qa_fixes_20261002_q1j453ri/`。最终全回归在 `regression_final/`；最终画面在 `visual_final/`。早期失败日志保留，不替换最终证据。

## 仍未处理

Rest 的 Kohaku 文案、失败结算站立持枪的情绪表现仍是原报告中的次要观察，不在本次五项修复内。未进行难度平衡、全图所有遮挡点验收、性能优化或正式音频混音。没有人物造型或比例改动，也没有扩资产。
