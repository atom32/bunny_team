# 单机出击恢复 — Alpha 0.1 第一批

> 历史批次报告：相关实现已纳入 `c1cebae`。文中的未提交状态、测试数字、临时路径及后续计划记录当时情况；当前进度与剩余事项以[最新交接](../../Handoff.md)为准。失败与修复记录保留，不代表当前仍失败。

2026-10-03 · Godot 4.7.2 · Windows / RTX 5090 · 工作区未提交。

## 使用

正常出击后，Esc → **保存本局 / 返回主菜单**或**保存本局 / 退出游戏**。
主菜单显示 **继续出击**，恢复同一个任务实例，而不是重新发装备或重新刷 Loot。
**放弃任务 / 返回基地**仍会损失携行装备；它与保存本局是两个明确不同的选择。

![保存本局菜单](suspend_pause.png)

![第二进程恢复后的 Streets](resumed_streets.png)

## 保存边界

- 部署先保存。世界生成后保存布局 seed 与碰撞/导航签名，并开始 2 秒模拟时间自动保存。
- 拾取、击杀和任务推进请求同帧合并保存。任务成功/失败先存结果，正常 Result 结算在同一原子写入中清除 checkpoint。
- 基地库存和活动出击位于同一 schema 3 envelope。活动出击期间禁止军需交易和重复部署。schema 1/2 仍可加载。
- 显式挂起保存当前状态；强行结束只恢复最近有效保存，可能回退约 2 秒。不是逐帧 replay，也不是防存档回滚系统。
- 世界恢复是显式数据白名单，不是任意节点/脚本反序列化。布局/数据不兼容则停止并保留原文件。
- 瞬时 VFX、无碰撞尸体、Loot 弹窗、镜头震动不持久化；实际死亡/掉落/任务及携行物资状态持久化。

## 实现位置

- `scripts/systems/sortie_checkpoint.gd`：会话/世界数据、验证和恢复。只读已有运行状态，不改角色源资产。
- `scripts/systems/sortie_runtime.gd`：部署日志、自动保存、挂起/恢复、幂等结算。
- `scripts/systems/flow_menu.gd`、`scripts/presentation/slice/boot.gd`：生产 UI 路径及保存失败/不兼容提示。
- `scripts/enemies/enemy_controller.gd`：显式保存待发射击剩余计时。正常 telegraph 仍为 0.38 秒，目标/伤害/弹道实现不改。
- `tests/sortie_checkpoint_test.gd`：110 个检查；同文件的 `--write` / `--read` 运行于真实不同进程。
- `tools/sortie_resume_probe.gd`：真实场景和菜单按钮回调的图形自动化，不是人工验收。

人形 NPC 的受击缩放与骨骼姿态会改变实际枪口。恢复因此保留完整 Transform3D（不拆成 Euler+scale 丢失剪切），已有骨骼的当前姿态与动画位置，并刷新 BoneAttachment。12 个活敌人的恢复前后实际 muzzle origin/direction 向量差分别要求 <0.0001。没有 mesh、rest pose 或动画源修改。

## 验证与复现

完整隔离检查（输出必须是仓库外**不存在的新目录**）：

```powershell
python tools/verify_migration.py `
  --godot E:\Godot\Godot_v4.7.2-stable_win64_console.exe `
  --output C:\Temp\bunny-alpha-resume-new `
  --route
```

工具复制当前 Git 可见工作区（包括 WIP）到隔离目录，不改主工作区，不使用个人存档。
45 个测试场景、5 种退出路径、正常 writer/reader、确认自身 writer 存盘且存活后强制结束再 reader、Main 和 Field Office 图形路线全部通过。

新增 UI 图形路线可在上述**隔离 project**中复现。以下 APPDATA/LOCALAPPDATA 只作用于当前 PowerShell 进程；请在专用终端运行，`$run` 指向隔离输出而非主项目：

```powershell
$run = 'C:\Temp\bunny-alpha-resume-new'
$env:APPDATA = "$run\suspend_ui_userdata"
$env:LOCALAPPDATA = "$run\suspend_ui_localdata"
$env:BUNNY_EVIDENCE = "$run\suspend_ui_captures"
$godot = 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --path "$run\project" --resolution 1280x720 --script res://tools/sortie_resume_probe.gd
& $godot --path "$run\project" --resolution 1280x720 --script res://tools/sortie_resume_probe.gd -- --load
```

第一进程：测试专用 Streets 解锁档 → 正常菜单/部署 → 输入动作移动/开火 → 菜单挂起再恢复 → 生产保存/退出按钮。
第二进程：正常继续出击 → 比较同一 session、弹药、携行物品、位置 → 实际撤离 API → Result → Hideout → 存档 checkpoint 清除。
这是**图形/API 自动化**，含明确的 Streets 解锁夹具和直接撤离调用；不宣称新人通关、全程步行撤离或人类长局试玩。

## 结果和未完成事项

- [机器记录](suspend_validation.json)：45/45；checkpoint 110 检查；跨进程读取各 14 检查；图形路线 PASS。
- Fresh import：0 ERROR / 2 个已有 Motus FBX 非 UTF-8 metadata warning。Main exit 0；已有 2 ObjectDB 实例退出警告仍在。
- 没有测试删除、空测试、计数器压失败。现有经济往返测试改为当前 schema，不再要求 schema 2 字面值。
- 本批开始快照中 2096 个角色/敌人素材、美术来源、玩家代码及 Unity-Chan 表现文件字节相同；无删除，用户 WIP 保留。
- 本次 Windows 验证不代表其他平台已验收。长局保存耗时/性能、持续游玩平衡、未来任意地图版本兼容均未认证。
- 医疗、感知/搜索/脱战、长期任务/设施/改装、区域资源与终点仍在 [Alpha 计划](../ALPHA_0_1.md)内；**完整 Alpha 仍进行中**。
