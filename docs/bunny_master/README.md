# Bunny 持枪近景：真实动作与 M4 接触校准

`scenes/presentation/bunny_master/master_shot.tscn` 是独立演示场景。
`mco_relaxed_preview.png` 和 `mco_aim_preview.png` 使用真实 Bunny 与包内 M4，
3840×2160，Godot Forward+、8× MSAA。尚未锁定为最终视觉金标准。

免费包实际含 7 个 Rifle FBX：放松持枪、瞄准待机、瞄准转放松，
以及持枪走路和慢跑各自的移动/原地版。没有换弹或射击 clip。
授权来源见 `assets/animations/mocap_online_rifle/SOURCE.md` 与 `assets/weapons/mocap_m4/SOURCE.md`。

## 骨架与接触

`rifle_pose.gd` 以 MotusMan_v55 的真实动画采样到 Bunny 的 52 根骨骼，修正朝向与 A/T 参考姿势差。
可显示原始骨架进行对照；原始骨架的可见 skin 保留其原始骨骼名。
Maya 文件里提供的挂枪平移/旋转直接用于 Godot 会让枪竖起，不能照抄。

`rifle_contact.gd` 使用右手实际手指轴与手背法线确定枪械朝向。
M4 实例保持固定 0.9 比例；不再随双手距离缩放，也不再仅以两掌中心决定枪械翻滚。
握把锚点为模型局部 `(0.024, -0.015, -0.025)`，护木下方锚点为 `(0, 0.055, 0.24)`。
左臂两段解析 IK 把手腕送到护木，保留原有臂长和所有骨骼局部位移。
左手方向与护木一致；中指、无名指、小指增加收拢，拇指两段链收紧贴近护木侧面。
原始模型、动画、贴图均不修改；校准只作用于预览实例。

两掌中心误差近零只是 IK 的数值结果，不代表所有指尖与网格表面的接触都已精确验收。
正面、瞄准与侧面近景已实际渲染；侧面近景见 `contact_detail.png`。
仍应检查不同视角的手指/枪托接触，以及后续动态战斗中的表现。

## 材质与验证

局部材质处理皮肤 SSS、眼球粗糙度、角膜、头发高光与服装反射。
原始贴图和烘焙腮红保留。灯光和后处理只作用于独立 SubViewport。

`tests/rifle_contact_test.tscn` 检查放松、瞄准、转换、原地走路、原地慢跑 5 个 clip，
每个采样 0.1/0.5/0.9 s，共 15 个姿势：护木中心接触误差 <1 mm，
臂长不变、所有骨骼局部位移不变、所有骨骼变换有限。日志为 `contact_test.log`。
该测试不检查网格穿透，不能替代视觉检查。
原始 8 个动画/参考 FBX 与下载包 SHA-256 一致；M4 与四张贴图也逐一验证。
MCO 动画目前仍用于冻结采样帧；正式战斗保留现有 Unity-Chan 动画源。
正式 AR 已换成包内 M4，挂载比例 0.9。动态手部校准按掌心而非腕骨定位，
换弹时改变左手朝向，并针对这副骨架限制枪械下沉幅度。
`tools/dynamic_grip_probe.tscn` 覆盖七把武器的站立、行走、完整换弹和缩放翻滚，
检查两掌到运行时目标 <15 mm、全部骨骼局部位移不变和变换有限。
日志与 M4 动态截图见 `dynamic_grips.log`、`dynamic_m4_*.png`。
这仍不是逐根手指的接触验收；当前近景中的手指包覆、弹匣取放和枪托贴肩还需继续打磨。

## 运行

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/presentation/bunny_master/master_shot.tscn
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/presentation/bunny_master/master_shot.tscn -- --master-capture /tmp/bunny.png
/Applications/Godot.app/Contents/MacOS/Godot --headless --fixed-fps 60 --path . tests/rifle_contact_test.tscn
```

`--aim-pose` 检查瞄准待机；`--contact-detail` 检查放松姿势侧面接触；
`--source-rig` 显示原始 MotusMan 骨架动作（不挂枪）；`--baseline` 保留导入材质。

M4 动态左拇指另有护木侧面接触点（`support_thumb_contact`），通过两段拇指 IK 收拢，
换弹时按换弹权重平滑释放。当前侧面截图已消除明显向上翘出的拇指；
掌心误差、局部骨骼位移和有限变换检查继续通过。仍需更多视角检查指尖网格穿透。

右侧近景 `dynamic_m4_idle_right.png` 揭示并修正了右手法线/弯曲符号的左右手差异，
M4 前移 10 cm、上移 1.5 cm，主握点改为 `(0.024, 0, 0.065)`，减少身体遮挡/重叠。
四个左手指链另有护木侧面接触目标，换弹时平滑释放；逐指皮肤网格接触仍需视觉校验。
`--right-hand-detail` 可重现另一侧近景；`--grip-fit-grid` 仅在渲染探针实例中比较握点。

2026-10-01 portability: the seven unchanged animation FBXs are archived under `assets/animations/mocap_online_rifle/source/` with `.gdignore`; runtime sampling uses Animation-only `.tres` derivatives with identical tracks. This avoids absent demo pistol-texture references on a cold checkout. See the package `SOURCE.md` and checksums.
