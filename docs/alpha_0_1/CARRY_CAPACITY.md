# Alpha — 背包容量（进行中）

> 历史批次报告：相关实现已纳入 `c1cebae`。文中的未提交状态、测试数字、临时路径及后续计划记录当时情况；当前进度与剩余事项以[最新交接](../../Handoff.md)为准。失败与修复记录保留，不代表当前仍失败。

本批是真实 Gameplay/平衡规则变化，不是纯表现。Alpha 初始参数：无包 18 kg；野战背包 +17 → 35 kg；推进器背包 +7 → 25 kg，并保留已有移动修正。装备、弹匣弹药、备用弹药、医疗与 Loot 共用上限。没有修改武器数值、角色或物品重量。

ProfileState.get_carried_capacity 使用实际选中的背包；DeploymentPlan、SortieRuntime 的 request.loadout、SortieSession 共用它。仓库容量不变；既有 checkpoint 恢复使用已保存 inventory.capacity，不重算、不删旧档物品。新出击才使用新规则。医疗/弹药面板显示实际 capacity；机库背包标题显示当前上限，中英翻译同步。

测试：ammo_packing 原58项保留、增加15项，73 PASS；首任务升级“不改变容量”断言从旧100改为实际野战包35，升级行为仍需不影响容量；首任务 PASS；checkpoint117 PASS。新增覆盖三种容量的真实部署、Loot 填满拒绝、精确预览和旧100kg挂起恢复。

初版回归曾未通过（已由下方“技术回归完成”关闭）。冷导入0ERROR/2已知FBX warning；acceptance_smoke 出现4项失败：重装拾取第三份核心被正确拒绝，连带旧“全部核心回收”断言失败。不得删除测试或放大生产容量来凑绿。下一步拆清容量拒绝与有空间回收的验收场景，保留物品ID/入库/保存覆盖。

本批失败运行：C:\Users\admin\AppData\Local\Temp\bunny_alpha_20261003_m1iewf__/carry_capacity_20261003_141839

之前最后全量PASS仍是playtest_followup_retry_20261003_141129，不代表当前容量批次通过。没有commit/push；用户WIP与角色资产保留。需要补充实际图形容量展示、跨进程容量恢复及全部回归，再继续独立试玩存档的重新整备。参数尚未经过长局平衡验收。


## 技术回归完成（后续更新）

- 重装验收保留原战斗/弹药/任务检查，明确一份高价值核心成功、一份因容量拒绝；拒绝不消耗物品、不修改携行、不在结算/保存中凭空出现。入库数量只计实际带回物资。
- 新增轻装回收场景：通过真实 DeploymentPlan 部署，不携带副武器/护甲，实际35kg野战包；三个LootPickup均成功，正常撤离/结算后逐一验证原ID入库与重载、恰好三个核心且原仓库物品不丢。
- result_return旧100kg断言迁移为真实35kg背包、独立于升级后的仓库上限。没有删除测试场景、关闭失败或用测试专用大容量绕过新规则。
- 最终全量57/57场景、78/78步骤PASS，含正常/强制结束/医疗/委托/改装/弹药跨进程恢复、五退出路径、Main exit0、13项图形路线。路线不是新的人类通关。冷导入0ERROR/2原FBX warning；Main保留已知ObjectDB退出警告。
- 结果和两次旧失败路径见carry_capacity_validation.json。完整Alpha依然IN PROGRESS：容量有实际作用不等于18/25/35kg已经通过长局平衡；仍须用独立试玩存档继续补给、搜刮与撤离取舍。

- 同一最终快照追加Vulkan首任务图形运行PASS、退出0，直接检查capacity_ui/first_mission_loadout.png及first_mission_training.png：机库显示背包35kg且任务按钮不挡导航，战场HUD显示14.2/35.0。是测试驱动场景，不是人工多局平衡认证。
