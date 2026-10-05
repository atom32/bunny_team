# Alpha 性能基线（2026-10-03）

## 方法

使用 `tools/alpha_performance_probe.tscn`，继承既有 Streets 战斗路线。
固定 seed 907、生产场景/摄像机/画质，真实移动、AI、弹药、装填、两处维修、室内 Loot、撤离与结算。
测试档完成教学/位于最后委托阶段是明确夹具；目标与拾取沿用测试 API，不声称真人或完整 UI playthrough。
独立 APPDATA / LOCALAPPDATA，不能使用真实用户存档执行此工具。

- RTX 5090（32607 MiB），Ryzen 7 9800X3D，驱动 617.14，Godot 4.7.2 / Forward+ Vulkan。
- 关闭 vsync、取消帧率上限。**不使用 --fixed-fps**；物理仍按正常引擎时间推进。
- 测试工具 `--keep-window-size` 只跳过旧驱动的强制 720p；默认测试行为不变。记录真实窗口及根视口 texture 尺寸，而不只看逻辑 UI 尺寸。
- 进入 Battle 后两秒作 warmup；另外记录启动耗时/最大 warmup 帧，不能以排除 warmup 掩盖首次卡顿。
- 帧间隔为单调时钟的 process 间隔，不是 GPU timestamp 或显示器实际 present latency。
- draw calls / primitives 为 Godot 帧监控；primitives 不冒充全部 triangles。
- render resource bytes 为 Godot 跟踪的资源分配，不是整卡 VRAM 驻留；CPU process monitor 不是 GPU 时间。
- 无录屏、逐帧截图。warmup 后只读回一张参考图，排除该次读回与写盘间隔。JSON 仅在退出时写入；采样内存/字典开销包含在测量内。

调用示例（先设隔离用户目录和 BUNNY_EVIDENCE，并使用已导入的隔离项目）：

```powershell
& E:/Godot/Godot_v4.7.2-stable_win64_console.exe --path <isolated-project> --resolution 1920x1080 --disable-vsync --max-fps 0 res://tools/alpha_performance_probe.tscn -- --relay --keep-window-size --perf-1080p
```

720p 省略 `--perf-1080p`。探针通过正式 DisplaySettings.apply_preferences 设置分辨率，只写隔离配置；实际图像/窗口尺寸不符会失败。根 ViewportTexture.get_size 在 1080p 设置下报告 2880×1620，与实际 get_image 的 1920×1080 不同；不把这个逻辑报告当成物理渲染尺寸。旧尺寸断言失败记录保留，最终采用真实图像尺寸。

必须同时检查退出码、`STREETS_COMBAT_RUN PASS`、`performance.json.route_pass`、实际渲染尺寸和日志错误；exit 0 单独不是完成证据。
两次初始所谓 1080p 命令行测量实际被 DisplaySettings 默认设置恢复为 720p；尺寸数据已暴露这个问题，**不计入 1080p 结果**。现已增加正式设置调用与尺寸强断言。

第一次 720p 探针用了 `--quit-after 30000`，高帧率导致路线未结束即退出，**无效**；保留日志，不纳入性能结果。

## 范围

本轮只添加验证工具及分辨率测试开关，不修改 runtime。2688 个 runtime/source 文件相对 relay_release_final/source_manifest.json 字节一致。
最近完整回归为 relay_release_final：57/57；这不是本轮重跑全套的声明。
当前工作站数据不能证明中低端硬件、其他 renderer、其他平台或长期内存稳定性。仍需目标配置与真人多局验证。

## 当前工作站结果

| 实际分辨率 | 帧 P95 / P99 (ms) | 最大帧 (ms) | Draw calls 最大 | 渲染资源最大 MiB | 路线 |
|---|---|---|---|---|---|
| 1280×720 | 2.007 / 2.246 | 27.347 | 2693 | 508.1 | PASS |
| 1920×1080 | 2.015 / 2.256 | 28.466 | 2693 | 640.2 | PASS |

每分辨率当前仅一轮完整测量，不是多次统计认证。两轮均24次开火、2次装填、8击杀、10敌人移动、1回收物，维修两站及撤离结算成功，退出0。

warmup 与启动时间见 performance_validation.json，已观察到超过100ms的启动帧，未把它藏进稳态数字。当前没有证据需要为了5090稳态性能改写Gameplay或降低角色质量。高draw-call数量仍是较弱CPU/GPU的待测风险，不据此直接宣布瓶颈。

1080p参考图已实际查看，生产场景/角色/HUD正常渲染，但右上方英文路线提示与警报文本发生重叠，需要下一步可读性修复；不能把性能路线通过当成UI验收。
