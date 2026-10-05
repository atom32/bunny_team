# 战斗路线 / 警报信息可读性

2026-10-03。性能参考图暴露旧城区右上文本重叠与缺少背景对比。

## 修改

- 将即时 draw_string 的路线/警报文本改为生产 RouteMap 内的 PanelContainer + VBoxContainer + 两个真实 Label。
- 342逻辑像素宽，右上定位；正式项目字体、自动换行、背景面板。键位与语言切换仍实时刷新，警报文字仍来自 RecordsAlarm.caption。
- 展开地图的右侧目标/撤离/资源说明整体下移，为状态卡保留间距；左侧地图、地图输入、目标与警报规则不变。
- 所有新增 Control 使用 MOUSE_FILTER_IGNORE，不拦截射击或交互。
- 没有改角色、美术资产、地图碰撞、AI、警报时序或存档。

## 验证

原 records_alarm_test 46项规则断言保留。`--capture` 新增中英文、720p/1080p、未触发/倒计时/已发出三个状态，共112检查通过：窗口内、暂停按钮下、详细信息上、标签不重叠、无隐藏文本行、实际图像像素匹配。

首轮面板底部173而展开详情从164开始，测试正确失败；将详情移至190并保留至少12像素间距后全通过，不删断言。失败日志保留。

实际查看720p英文展开地图、1080p中文倒计时截图，状态及详情无重叠。不是完整真人多局可读性认证。

证据：外部隔离目录 readability_render_final，12张截图与run.log；初次失败 readability_render。完整回归另记录，不用图形局部通过代替全量。

最终 fresh isolated：57/57、78结果行全PASS；cold import 0 ERROR /2已知FBX warning，Main exit0及已知退出warning。完整机器证据 readability_validation.json。无commit/push。
