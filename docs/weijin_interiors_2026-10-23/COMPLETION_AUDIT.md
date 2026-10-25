# 完成审计：地图细化、室内与任务

依据当前源码、实际Godot执行日志与原生渲染逐项核验，不沿用上一批的源码指纹冒充新证据。
需求门槛：`docs/streets/WEIJIN_INTERIORS_DIRECTION.md`。玩法与边界：`docs/streets/WEIJIN_INTERIORS_2026-10-23.md`。

| 门槛 | 当前权威证据 | 判断 |
| --- | --- | --- |
| 1. 真实外部地理与继续细化 | 保留指纹文件与5项源测试；41项原生美术、31项地理；3入口导引、东门设施、2湖岸装置的实际图 | 完成，外部1:1不变，未把调查装置冒称真实水文设施 |
| 2. 三处不同室内、实走与碰撞 | `campus_interior.gd` 三分支布局；74项中的三楼层、地面、边墙、钥匙门夹具；48项完整普通输入回路；三处原生室内与平面图 | 完成，明确为设计楼层，非真实室内测绘或467楼全部开放 |
| 3. 完整任务、有条件操作与可恢复错误 | 实机13项操作：接取、目录、柜电、档案、支路图、检修、误断、恢复、正确隔离、签收、两调查、回报；图/日志/物件与灯态；74项前置/重复/恢复检查 | 完成，未用任务面板跳阶段或直接发状态来替代路行 |
| 4. 接近、视线、门与返回 | 74项远程门拒绝、实际穿墙E拒绝、门/家具碰撞、真实E进出/返回原位；完整回路保留家具绕行与源轮廓接驳 | 完成，只有明确门口转换会在设计室内/校园之间搬移角色 |
| 5. 日志、目标、室外/室内地图与近景 | 实际J/M输入暂停，3张分区楼层图；任务道路/入口接驳、距离与当前目标；人物与装置原生近景；缩短相邻开关图例文字 | 完成，数值/像素自检不是外部美术签收 |
| 6. 独立持久化，不改旧存档 | 74项验证独立写入替换、部分进度、重新实例化场景、A在线/B隔离灯态、损坏保护、实际保存失败反馈、确认/取消重开；完整Profile比较与旧代码指纹 | 完成，不把独立章节完成等同于旧任务迁移或向旧经济发奖 |
| 7. 实机完整流程与旧内容回归 | 原生48项/约2931.2米/13操作；headless相同流程；原生和Compatibility各74项、菜单基地18项、地理31项、美术41项、旧UI26项、旧布局0失败、源5项 | 完成，Compatibility只证明其74项夹具，不冒称已跑过该渲染器的完整章节 |

## 可复查材料

- `native_campus_fieldwork_run.log` / `native/fieldwork_run.json`：真实控制器输入、实际按钮选择、操作顺序、米数与状态。
- `native_campus_fieldwork_test.log` / `native/fieldwork_unit.json`：74项状态、文件、物理、UI与重进场景夹具。
- `compat_campus_fieldwork_test.log` / `compat/`：独立真实OpenGL加载、渲染、输入和文件验证。
- `headless_*.log` / `headless/`：无界面逻辑/物理回路，不作为图片证明。
- `preserved_geography_and_legacy_sha256.json`：本轮未改变的地理JSON、SOURCE、旧校园静态图、布局和检查点代码。
- `source_sha256.json`：当前构建实际读取的地理/室内/任务脚本、材质、场景、入口及测试指纹。
- `native/entry_*.png`、`interior_*.png`、`floorplan_*.png`、`library_archive_collected.png`、`workshop_repaired.png`、
  `master_choice.png`、`master_blackout.png`、`emergency_power_preserved.png`、`relief_handover.png`、
  `completed_journal.png`、`save_failure_journal.png`：实际Godot原生帧。

最终通过日志无ERROR/WARNING；绿色计数同时经过日志检查，不能把早期运行错误当作无错误通过。
早期出现的路线撞桌、凹形入口不连通、点击按钮立即释放报锁定、损坏JSON打印错误等均在本轮报告记录；已修正并重跑。

## 不在本次完成声明内

全校园所有真实室内、所有建筑测绘、旧战斗章节迁入、真人通关/五小时内容、最低配置、真实音频、完整本地化、
新Windows导出和公共发行。当前新章节文字为中文。原素材许可/角色与本地发布限制继续适用。
