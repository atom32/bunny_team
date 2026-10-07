# Alpha — 玩家观察与掩体反馈

> 历史批次报告：相关实现已纳入 `c1cebae`。文中的未提交状态、测试数字、临时路径及后续计划记录当时情况；当前进度与剩余事项以[最新交接](../../Handoff.md)为准。失败与修复记录保留，不代表当前仍失败。

2026-10-03，当前批次 **PASS**；完整 Alpha **IN PROGRESS**。未 commit / push。

## 玩家实际得到的规则

- 相机能看见建筑另一侧，不等于角色能发现另一侧的敌人。敌人须在瞄准朝向 160°、32 m 内，且头/胸的实际物理视线至少一条畅通。无遮挡的近身 4 m 为全向观察；Shift 使用现有武器的观察扩展。
- 墙/关闭的门使用 world collision layer 4 遮挡，即使相机把其 mesh 淡出。只隐藏敌人 presentation 和警觉标记，不隐藏 gameplay root、不关 AI/碰撞。未观察到的敌人仍能射击和受伤。
- 未观察位置不生成枪口、受击、攻击预告、火箭尾迹等定位特效；曳光只显示可见的连续段。人物尸体/无人机残骸随视线再次显示，不用其位置泄露死亡地点。地形保持可读，不做全屏黑雾。
- 枪声/实际移动产生短暂的八方向方位提示，1.5 秒后消失。没有距离、世界坐标或隐藏敌人追踪。步声感知范围 12 m、敌枪声 40 m，墙后听觉范围乘 0.45；活跃枪声提示不会被脚步覆盖。
- 鼠标射线跳过未发现敌人的碰撞体，不再用隐藏敌人高度暗中“吸附”准星；新手任务也不为隐藏巡逻兵显示精确距离与箭头。仍可以盲射，实际攻击 ray 没有忽略隐藏碰撞体。
- 琥珀色准星/拦截点表示枪口中心线被掩体挡住。它不是命中承诺或散布预测。角色胸前到枪口的线段若穿墙，射击起点停在墙的近侧；不会通过模型枪管穿墙从远侧生成射击。仍扣正常弹药，无遮挡原始枪口位置不变。

**明确的 Gameplay 差异**是信息可见性、瞄准拾取和穿掩体起点修正，不能称这批“纯美术”。没有改 WeaponDefinition、伤害/射速/弹药/装填参数、敌人 AI/攻击射线、地图碰撞形状/导航、存档和经济语义。角色 mesh、贴图、材质语义、骨架和官方源均未改。

## 验证

机器记录：[visibility_validation.json](visibility_validation.json)。

- **48/48** 场景测试；前 47 个保留，新增 `player_visibility_test`。完整新冷拷贝跑了 42 项新增检查；随后补入两个实际巡逻脚步检查，44 项一起在隔离项目复跑通过。完整回归后 runtime scripts 哈希零变化。
- 新检查覆盖：前/后方/近身/视距/镜头观察扩展、真实 Door 开关和相机淡出、根节点与 checkpoint 不受隐藏影响、声音衰减/量化/过期/优先级、真实隐藏敌人伤害、实际巡逻位移声、VFX/瞄准泄漏、原始枪口保留/掩体截断、扣弹、火箭撞墙、尸体重新发现，以及 HUD 屏幕边界。
- 旧 acceptance 的 KITE 断言改查局部可渲染实例，不能再要求所有场景敌人无条件可见。旧破障夹具原本把玩家放在 `InteriorEntryCover` 内（barrier +4 m）；现改为两掩体间合法位置（+3 m）。所有伤害、护甲、破障、弹匣和命中断言保留，没有 suppress、删除或空测试。
- 五种退出路径、正常存后重启/已存后强制结束重启、医疗恢复和结算跨进程 PASS。可见性不写入 gameplay root；声音提示、短暂特效、尸体不作为持久化知识保存。
- Fresh import：0 ERROR / 2 个已知原始 Motus FBX UTF-8 metadata warning。Main exit 0，已知 2 ObjectDB instance 退出警告保留。不能写 warning-free。
- 相对本批开始快照：2111 个角色/动画/美术来源/项目配置保护文件字节不变，无旧文件删除、无暂存，用户 WIP 保留。

### 图形证据（自动化，不是人工）

Forward+ / RTX 5090 / 1280×720。已实际查看输出帧；声音提示左边裁切问题已修复，测试现在检查其矩形完整处于 viewport。

- [受控记录](visibility/result.json)：6 项。生产角色/敌人/HUD/物理/伤害/弹匣，固定测试地面与墙；不是生产地图或完整任务。比较 [可见](visibility/01_observed.png) / [透明墙后不可见](visibility/02_occluded.png)，[后方真实枪击](visibility/04_rear_fire.png)，[掩体拦截](visibility/05_cover.png)。
- [真实 Streets](visibility/streets_route.log)：seed 907，正常 AI；27 发、1 次装填、9 击杀、10 敌人移动、1 项回收、受到 2.88 伤害。完成任务地点、Loot、撤离与结算 API。测试控制器只用实际可见敌人/近似声源方位，不直接索取隐藏目标。见 [生产画面](visibility/streets_survey.png)。
- [Field Office](visibility/field_office_result.json)：生产机库/入口/入门/终端区域/退出/撤离/Result，13 项 PASS；7 发、0 击杀、任务未完成。是路线回归，**不是首任务通关**。

## 边界 / 剩余工作

- 当前是按实体、数个采样点的观察，不是像素级可见性或未知地图探索记忆；露出头/胸的一部分即可显示整个人。瞬时特效已有部分可能在失去观察后的短寿命内残留。
- 现有 AudioDirector 是全局音效池：敌枪声有距离/墙衰减，方位由 HUD 提示；**不是双耳空间音频**。移动已产生提示，但尚未制作专门的人形脚步/无人机运动 Foley。不能把提示通了写成完整音频完成。
- 声音量化、视距、视角、4 m 近身观察、掩体手感仍需真人多局测试。没有完成人类反应速度、潜行难度或性能认证。
- AI 的角色分工/协作、跨局任务/设施/有限改装、资源分区与撤离选择、必要设置和 10–15 局/2–4 小时真人验证，仍在完整 Alpha 目标内。

## 复现

```powershell
$env:PYTHONUTF8 = '1'
python tools/verify_migration.py --godot E:/Godot/Godot_v4.7.2-stable_win64_console.exe --output <新的仓库外目录> --route
```

图形专用工具：隔离项目、独立 APPDATA/LOCALAPPDATA，设置 `BUNNY_EVIDENCE` 为仓库外输出目录后，运行 `--script res://tools/player_visibility_probe.gd`。真实 Streets：`res://tests/streets_combat_run.tscn -- --combat-capture`。不要覆盖个人档，工具不是生产入口。

当前完整结果及原始日志路径记录于机器 JSON；少量关键日志/帧放在本目录，未保存大量录像。
