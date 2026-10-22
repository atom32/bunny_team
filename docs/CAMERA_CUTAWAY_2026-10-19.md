# 兼容渲染的室内遮挡修复

2026-10-19。上一版校园宿舍截图里，Compatibility 模式的屋顶挡住了主角。本轮修复这个实际画面问题，并让警铃响过后的地图点明确显示「警铃已经响过」。没有新增章节、替换模型或修改关卡碰撞。

## 玩起来的变化

- Compatibility 模式下，挡住角色的屋顶、墙体表现和装饰顶棚采用直接剖面；离开遮挡区域后恢复。Forward+ 沿用原来的渐隐，不改变相机角度。
- 只切走渲染实例，不改节点的真实可见状态、共享材质或物理形状。这样纯装饰顶棚不会因为被隐藏就下一帧又失去检测，已经被游戏隐藏／销毁的物件也不会被恢复出来。
- 墙仍挡弹和视线，未观察到的敌人仍由原观察系统隐藏；不是给角色加透视能力。
- 接线箱灯、世界文字和地图共享状态：待操作、已拆线、已经响过。已响过的点不再把「4秒」显示成仍可完成的工作。

[新版 Compatibility 真实控制输入路线画面](D:/tmp/bunny_cutaway_20261019_build02/compat_isolation_route_captures/isolation_run_records.png) · [已响警铃地图夹具画面](D:/tmp/bunny_cutaway_20261019_build02/compat_isolation_captures/bell_too_late.png)。前者是实际游戏路线，后者是控制状态的回归截图，不是真人试玩录像。

## 为什么以前的测试没拦住

Godot 的实例 `transparency` 在 Compatibility／Mobile 中会被忽略；因此读到属性值变成 1，不代表画面已经透明。[官方属性说明](https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html#class-geometryinstance3d-property-transparency)。本轮改用当前实际渲染器判定；不支持该透明方式时，通过渲染实例做剖面，保留场景与物理状态。[RenderingServer 接口](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-instance-set-visible)。

新回归渲染一个被红色顶棚遮住的绿色代理体，直接取画面像素。初始夹具在旧实现的 Compatibility 版有 4 项实际可见性失败，不能再用属性 getter 通过替代显示正确。

- 普通材质、自定义 Shader、无碰撞顶棚三种情况；切开后 13×13 采样区为 169/169 绿色主导像素，切开前为 0。
- 无碰撞顶棚遮挡下的代理体连续 8 帧稳定可见；离开后红色遮挡重新绘出，外部隐藏时画面保持缺席，单独释放控制器后恢复。
- 检查原材质对象、相机变换、keep-visible 标记和真实物理射线。两个导出渲染器各 **83 项通过**；headless 仅有 25 项结构检查，不当作像素证明。
- 另看了实际主角在宿舍内的独立包截图。绿色代理体用于隔离渲染问题，不冒充真实模型或全部屋顶验收。

## Windows 本地包与验证

- [新版 ZIP](D:/tmp/bunny_cutaway_20261019_build02/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip)：239,296,430 字节。
- SHA256：`b83c30f8e0943fc66926f14737e5264d7990a2e82ec2ef22b8aacb163c4a6d21`。
- 已解压运行到 `D:\tmp\小兔试玩 室内视野修复 20261019 02\LOCAL_ONLY_DO_NOT_UPLOAD`。运行同目录 `NeonBastion.exe`，保留伴随文件，无需安装 Godot。
- 权威源码 `D:\tmp\bunny_cutaway_20261019_final02`：**98/98 场景、147/147 类别**；构建 **23/23**；中文路径解压、无 Godot PATH 的串行独立运行 **27/27**。最终无 ERROR；每份冷导入日志各有两条既有 FBX 元数据警告，其余运行无警告。
- 从前版实际导出程序复制的旧校园挂起档、广播车档，以及部分拆线／已拆线快传两份档均读回；旧校园再次保存后再读回，原档 hash／时间未变。不是全部历史档兼容矩阵。
- 3,707 份非文档源文件在工作区与两份清单一致，并复核执行／构建副本实际文件；仅隔离应用名称和私包 QA autoload 有明确配置差异。881 份原资产、92 份原场景、1,233 条译文未改。正式个人档与 Arcana 原文件未变。
- 实际 AI 路线仍为种子907、3发、1击杀、生命260、0次工作中断。PCK 1,282 条目逐项 checksum／排除审计通过；660 个选定资源、22 个普通文件，29 份既有许可材料保留。

首轮完整回归的原生广播车导航断言确实失败过：诊断重复中，地图 iteration 1 返回空路径，iteration 2 才有完整绕行路线。测试现在先确认两个端点的导航数据已同步，再执行原来的绕行断言，没有等到期望路径才放行，也没有改生产导航。final01／build01 和开发失败日志保留，以 final02／build02 为准。

命令、日志 hash、失败记录与像素输出见 [机器证据](camera_cutaway_2026-10-19_validation.json)。

**仍仅供本地测试，不可公开上传。** 角色发行授权尚未闭合，Arcana／CombatGirls 不在包内；未 commit、push 或发布。真人从正常启动到六委托的首小时、真实听感、最低硬件、Mobile 设备及真实口碑仍待验收，测试比例不是 80% 好评。
