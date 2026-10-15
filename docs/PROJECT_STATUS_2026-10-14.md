# 项目现状审计 — 2026-10-14

> 后续实现已落地：校园静态作者场景、YARD目录、武器工作台与维修室模块。当前用法和验证见 [内容制作工具使用说明](CONTENT_TOOLS_IMPLEMENTATION.md)。下文保留同日**实施前审计/选型**的原始数据，“未安装/未实现”和66场景数字仅属于当时阶段。

## 同步与范围

- 工作区：`D:\bunny_team`；起点 `main @ c1cebae`，开始时tracked/untracked工作区干净。
- 执行 `git pull --ff-only`，最终快进至 `68076aefac31df3e784fdf62cee64cd2667b29a4`，并再次确认 `Already up to date`，HEAD与origin/main相同。首次直连遇到连接重置/超时；用户提供7897端口后使用命令级 `http.proxy=http://127.0.0.1:7897`，没有修改全局Git配置。
- 新同步3个提交：`57ffed3`（10-08，叙事切片/联系人）、`c6b04a1`（10-11，校园与感染者）、`68076ae`（10-14，校园故事第一批/试玩检查点）。相对起点424文件变化；提交日期不等于每项设计完成日期。
- 本轮只更新文档，不修改游戏源码、资产、测试或原始验证脚本，不安装插件，不commit/push。

## 当前已经有什么

| 领域 | 当前事实与证据入口 |
| --- | --- |
| 运行 | Godot **4.7.2**；本机console实测 `4.7.2.stable.official.ed1daf0bf`。入口 `scenes/presentation/slice/boot.tscn`；桌面Forward+，兼容回退可选。 |
| 游戏闭环 | 菜单→Hideout→Hanger整备→出击→结算→返回。仓库实例所有权、装备、负重、弹药精确携行、死亡/放弃携行损失、交易/制作/改装、医疗、挂起恢复已在代码中。 |
| 内容库存 | 当前manifest注册 **27个物品定义、4个出击任务、7个loot table、3个area definition、3个敌人定义**。这是注册数量，不等于27个独特3D模型/3张新地图，也不包含所有剧情设计任务。 |
| 地图 | `street_district`沿用stable ID，当前场景已是压缩校园，而非旧四房间城区；18物资点、6出生候选、4出口中每局分配2处。另有首任务/原型区域。见 [校园地图](streets/CAMPUS_MAP.md)。 |
| 敌人 | 持枪PMC、KITE、近战感染者。感染者有独立controller与definition，但美术复用人形模型、染色、隐藏手枪与拳击clip，不是新制作的独立模型。 |
| 联系人/任务 | 联系人肖像与交易/委托已有；新版校园**第一批**开放出口侦察Q01与敷料×2/织物×2交付Q02（允许基地库存、分批交付，不再要求药房批次观察）。完成后等第二批；自由出击和交易仍可用。 |
| 新故事范围 | 六项委托为当前制作方向，维修、实验记录器、L-02支路控制、战备交付尚未接入新版故事链；原有自由维修操作不等于故事任务3完成。旧Q04回执/奖励保留历史，不给新任务进度。见 [当前任务稿](narrative/DEVELOPMENT_STATUS_AND_TASK_STORY.md)与 `NarrativeSlice`。 |
| 保存 | `SaveService.SCHEMA_VERSION = 7`；`NarrativeSlice`状态version 4，与外层profile schema不是同一个概念。旧剧情兼容字段不能直接删或当作新故事已经完成。 |
| 主角/动画 | 生产主角仍为Artoria Bunny临时GLB；隐藏Unity-Chan FBX提供战斗移动驱动，专用双手/持枪适配器保留。基地使用Quaternius idle/seated与新增过渡/走动数据；不能再把“完全没有坐姿过渡”当当前事实。 |
| 新原创主角 | `art_source/bunny_operator_20261010/README.md`有输入、预检、Blender与独立展示流程，但状态仍“生成前受阻”；未交付新角色、未替换生产玩家。本轮没有续跑收费API。 |
| 长篇内容 | 十二章、Boss、完整结局仍是设计包，不等于当前可玩章节数量；不得把旧长稿、旧物流核验版本覆盖当前校园六任务稿。 |

## 本轮验证与已发现问题

### 原样仓库runner：不是通过

同步前的 `c1cebae` 隔离副本完成59/59场景与79个结果行；它是**旧提交**验证，不能用于新HEAD通过声明。

同步后原样运行：

```powershell
& 'C:\Python314\python.exe' tools/verify_migration.py `
  --godot 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' `
  --output '<全新仓库外目录>'
```

当前66个 `tests/*.tscn`，runner第94–95行仍要求62个。结果：冷导入PASS，0 ERROR / 2已知FBX UTF-8 warning；随后 `RuntimeError: Expected 62 tests ... got 66`，进程退出1，尚未执行场景回归。失败证据：`C:\Users\admin\AppData\Local\Temp\bunny_current_20261014_294b91f7`。

62→66新增库存来自 `campus_night_test`、`fresh_entry_test`、`hideout_camera_test`、`infected_enemy_test`。本轮不直接修源码；此数量门禁漂移应作为近期小修项，不应删除四个测试或绕过全部验证。

### 临时66场景审计

在仓库外保留原runner派生副本，仅更改：固定root到本工作区、数量门禁62→66及对应错误文字；全部测试、断言、冷导入warning规则、跨进程/强制终止/退出探针保留。没有修改原runner或游戏代码。派生源码和hash偏差记录在审计目录的 `verify_reviewed_66.py` / `runner_deviation.json`。

审计目录：`C:\Users\admin\AppData\Local\Temp\bunny_audit_runner_20261014_5_g6tai3`。

对齐数量后的runner在 `hideout_camera_test`提前退出：无PASS marker，退出0，但清理产生1 ERROR / 1 WARNING。脚本含25组镜头路线和多次等待，默认 `--quit-after 1200`不足完成；不是“退出0即通过”。仅在临时续跑脚本将该测试帧预算提高到60000（180秒外层超时保留）后通过，0 ERROR / 0 WARNING。随后 `hideout_idle_test`同样在1200帧内未完成；扩展预算后通过，0 ERROR / 0 WARNING。未修改断言、运行时或warning名单，也没有声称新图形验收。

原失败日志保留 `hideout_camera_test.log` / `hideout_idle_test.log`，重试分别为 `*_extended_retry.log`；临时续跑源码为 `verify_continue_camera_budget.py` / `verify_continue_hideout_budgets.py`。续跑复用同一隔离项目/profile并跳过已通过行，不混用旧提交或个人存档。

**最终诊断结果：66/66场景、86/86结果行PASS**，均来自同一新HEAD隔离快照，经上述明确的runner数量/预算修正和续跑完成；不是原样仓库runner PASS。五种退出、正常/强制终止checkpoint恢复、医疗/成长/装备改装/精确携行跨进程检查及Main通过。冷导入0 ERROR / 2已知FBX warning；Main退出0、0 ERROR，仍有已知2实例ObjectDB退出warning。没有新增图形路线验证。

版本化汇总、每项退出码/错误/警告/日志hash和派生runner hash见 [验证JSON](project_status_2026-10-14_validation.json)。原始完整日志及隔离profile保留在审计目录，不提交测试profile。与同步后快照对比，除本轮允许修改的文档外，**3663个既有文件hash全部一致**，无游戏/测试/资产改动。

本轮没有新做真人连续试玩、Forward+视觉验收、最低硬件性能认证；测试场景自动化不等于这些验收。

## 优先级判断

1. **验证与文档基线先对齐**：修runner库存门禁和两项基地测试的帧预算/完成检查；启动器 `tools/play_campus_batch1.command`依赖macOS与ignored `.grimdark-loop/campus_batch1_20261012/project`，干净Windows checkout不可直接运行，不应把它当跨机器标准入口。
2. **轻量内容生产流程**：保留现有Resource/ContentDB；优先内容检查、表格批量配置、模型/动作审查与注册向导；详见 [内容工具路线图](CONTENT_PIPELINE_ROADMAP.md)。
3. **为玩法服务**：完成校园下一段真实交互/撤离/结算，用独立感染者外观和合格动作支持新遭遇。不要用换皮数量代替风险收益/任务目的多样性。
4. **Alpha继续IN PROGRESS**：真人10–15次出击/2–4小时、听感/经济/难度与最低硬件尚无本轮验收。现有临时主角授权和部分来源核验限制继续有效。

## 文档维护原则

README/Handoff是当前入口；本审计是2026-10-14快照；`PHASE_INDEX`、旧Art pipeline与各批报告保留历史失败和范围。旧报告中的schema、角色、测试数量、“未提交”和下一步只对当时成立。新增工具规格是规划，不写成已实现。
