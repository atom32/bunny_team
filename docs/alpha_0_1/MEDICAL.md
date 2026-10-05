# 耗时医疗与实际携行 — Alpha 0.1

2026-10-03 · Windows / Godot 4.7.2 · 未提交工作区。

## 玩家流程

1. Hideout → 工坊军需处购买 **野战敷料**或**野战医疗包**，也可用 1 份布料制作 2 份敷料。
2. 作战室设置每类带出 0–4 份；实际只带自有库存与负重允许的数量，多余物资留基地。这里不是免费发放物资。
3. 出击后 HUD 显示实际数量。受伤后找安全位置，H 敷料 / J 医疗包。
4. 静止等进度完成才回血和消耗物品。移动、战斗动作、交互或受伤会中断；再次按医疗键也可取消。
5. 保存本局后退出，再继续时保留治疗剩余时间。药品实际消耗参与正常撤离/死亡结算，不会回基地后补发。

| 物资 | 价格 | 重量 | 仓库格 | 使用时间 | 最大恢复 |
| --- | ---: | ---: | --- | ---: | ---: |
| 野战敷料 | 60 | 0.15 kg | 1×1 | 2.5 秒 | 40 HP |
| 野战医疗包 | 150 | 0.6 kg | 2×1 | 5 秒 | 100 HP |

这是 Alpha 初始数值，不是经过长期真人平衡的定稿。库存不合并成堆，单份物品有独立 ID；选择数量不需要改变现有库存/仓库格式。

![实际医疗装包界面](medical_packing.png)

![正常引擎计时的治疗进度](medical_progress.png)

## 数据与实现边界

- `MedicalDefinition` 是现有 `ItemDefinition` 的最小扩展（healing / use_seconds）。购买、出售、重量、Loot、结算仍走既有系统。
- `PlayerController` 持有 `MedicalTreatment` 节点，推进动作并在受击/战斗操作时取消。角色源文件、模型、贴图、材质、rest pose、动画源及 combat rig 不变。
- 出击物资通过 `DeploymentPlan.medical_ids` 合并入 `carried_ids()`；原 `ammo_ids` 仍只表示弹药，不冒充医疗。
- `ProfileState.medical_pack` 只保存数量偏好，schema 3 兼容缺省字段。旧档不获得额外药品。真实出击恢复的 `world.medical` 保存使用中物品 ID 与剩余时间；老 checkpoint 没有该字段时视为无治疗动作。
- 无同时回血开枪、无限治疗、瞬间治疗或被动回复。现有基础伤害/射速/移动参数、玩家身份、经济结算幂等机制不改。
- 治疗音效复用装填/确认音作为占位；目前没有专门包扎动画。医疗手柄默认绑定和可重绑定尚未做，不把键盘验证描述为完整输入适配。

## 验证

- **46/46**：原 45 场景全部保留，新增 `medical_treatment_test` 含 68 个检查；购买/制作原子性、装包/库存/重量、满血/无药、时间、中断、续玩、消耗结算和失败损失。
- 原 acceptance 的内容注册数由 25 更新成 27，明确新增两种医疗物资，并验证其资源类型/治疗量/时间/重量。没有删旧断言或用空测试凑数。
- 新增独立进程 writer（30 检查）→ exit → reader（8 检查），恢复真实保存中的治疗并结算。现有出击 checkpoint 110 检查和强制结束恢复仍通过。
- 图形路线通过真实场景按钮回调购买/装包/部署，用 InputEventAction 触发 H/J，用引擎时间完成治疗。移动打断、保存/退出、第二进程继续到 Result/Hideout 均通过。
- 图形路线为了可重复性用实际 DamagePacket 注入一次伤害，最后调用会话撤离完成 API；不是一次真人首任务通关，也不是 NPC 压力下的医疗难度测试。
- Field Office 原输入/API 路线、5 种退出路径 PASS。Fresh import 0 ERROR / 2 已知 Motus FBX UTF-8 metadata WARNING；Main exit 0，已知 ObjectDB 退出警告保留。
- [机器记录](medical_validation.json)含命令、日志哈希、源码哈希与隔离路径。所有验证使用隔离存档，没有写用户实际档。

完整复现：

```powershell
python tools/verify_migration.py --godot E:\Godot\Godot_v4.7.2-stable_win64_console.exe --output C:\Temp\bunny-medical-new --route
```

新增图形路线在这个输出的**隔离 project**运行；用专用 PowerShell，避免改变其他工作进程的环境：

```powershell
$run = 'C:\Temp\bunny-medical-new'
$env:APPDATA = "$run\medical_ui_userdata"
$env:LOCALAPPDATA = "$run\medical_ui_localdata"
$env:BUNNY_EVIDENCE = "$run\medical_ui_captures"
$godot = 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --path "$run\project" --resolution 1280x720 --script res://tools/medical_probe.gd
& $godot --path "$run\project" --resolution 1280x720 --script res://tools/medical_probe.gd -- --load
```

完整 Alpha 仍未完成。下一项是敌人感知/搜索/脱战；医疗数值仍需与后续敌人战术、资源稀缺及多局经济一起做真人验证。
