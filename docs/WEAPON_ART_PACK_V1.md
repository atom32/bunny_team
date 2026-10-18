# Neon Bastion — Weapon Art Pack v1

2026-10-15。本轮在实际 HEAD `e940cd1` 和已有校园试玩 WIP 上实施，未回退到历史 `68076ae`，未提交、未推送。只处理一把基准步枪及配套展示资源，不重做主角、地图或武器系统。

## 实际交付与接口

| 交付 | 实际资源 / 接口 |
| --- | --- |
| 基准 AR-556 | `resources/weapons/assault_rifle.tres`，ID `weapon.assault_rifle_01`，生产场景 `scenes/weapons/assault_rifle.tscn` |
| 原生产模型 | `assets/weapons/mocap_m4/M4_Rifle_01.fbx`，仍直接使用 `Art/Model/M4` 的原 17,319 顶点 / 8,758 三角面、UV 和四张贴图；没有替换成程序化低模 |
| 新表面处理 | `assets/weapons/art_pack_v1/m4_finish.gdshader`、`m4_finish.tres`；深灰蓝涂层机匣、橄榄灰聚合物、金属弹匣，复用 DF/NM/AO/SP，降低过强反光和磨损表现 |
| 快装弹匣 | `scenes/weapons/art_pack_v1/quickloader_adapter.tscn`；保留枪上原弹匣，底部贴合橡胶快拉底套/拉环。`quickloader_magazine.tscn` 是原弹匣区域提取后的独立展示/图标场景，不是新增库存弹匣实体 |
| 消音器 | 同目录 `suppressor.tscn`，短包覆式外壳、安装环和散热环；外壳覆盖现有末段枪管，前端距原枪口约 6mm，不延长逻辑射击起点 |
| 观察瞄准镜 | 同目录 `observation_optic.tscn`，导轨座、金属壳、调节旋钮、紧固件、光学玻璃。安装时仅通过该武器实例的材质参数隐藏原瞄具外观，避免叠放；没有新增倍率/准星玩法 |
| 弹药展示 | 同目录 `ammo_556_box.tscn`、`ammo_556_round.tscn`，纸盒/标签、黄铜壳/铜色外弹头；只标识现有 `ammo.556_standard`，无装药/内部结构、脚本、碰撞或数量状态 |
| 仓库图标 | `assets/ui/stash/weapon_art_v1/{ar556,quickloader,suppressor,observation_optic}.png`，由实际 3D 资源透明背景渲染，已替换上述武器/三个实体套件的 icon 路径；旧图标仍保留 |

新增部件为本项目离线制作的倒角/旋转轮廓静态硬表面网格，材质与轮廓已实机查看；不将它们声称为购买的高精度写实模型。美术源文件为 `art_source/weapon_art_v1/build_assets.gd`。生产运行不执行该构建脚本。

弹药定义 `resources/ammo/556_standard.tres` 和现有 `assets/ui/stash/ammo.svg` **保持原样**。弹药盒/单发是可直接实例化的展示资源，不新增世界拾取对象或弹药物品类型；现有通用补给箱/拾取提示和库存数量展示不改。本轮没有把所有箱子替换成弹药盒。

## 材质规范与安装路径

- 聚合物：低金属度、较高粗糙度；涂层合金：中低反光；裸露钢/黄铜/铜：金属响应；橡胶：近零金属度、高粗糙度；纸盒：哑光；光学玻璃：克制的有色透光。对应原生材质集中于 `assets/weapons/art_pack_v1/`。
- `scripts/player/player_controller.gd::_equip_weapon_definition` 在原装备挂载完成后把已有 `weapon_instance.fitting` 传给 `weapon_visual.gd::apply_fitting_presentation`。基地 Hanger、武器工作台和战斗 PlayerController 共用同一生产场景。
- 新 `FittingVisuals` 仅管理三个可见子节点；未配置此路径的其他武器保持原行为。原有 **single utility slot** 不变，三个部件不是可同时叠装的三个新槽位。
- `quickloader` / `suppressor` / `observation_optic` 分别仍消耗现有 `material.quickloader_kit` / `material.suppressor_kit` / `material.observation_optic_kit`。安装、替换、免费拆卸、无退款、买卖、战损与保存仍归原服务所有。
- 替换观察镜的 shader 参数按实例复制，不污染别的枪；未安装观察镜时保留原瞄具。

## 未改变的契约

原根节点 mount_scale=0.9、pose_offset=(0,0.015,-0.10)，Art 原变换均未改。以下 Marker3D 名称、位置和旋转保持原样：

| 节点 | 原局部位置 |
| --- | --- |
| Muzzle | (0, 0.09, -0.625) |
| PrimaryGrip | (0.024, 0, 0.065) |
| SupportGrip | (-0.024, 0.055, -0.24) |
| ReloadGrip | (0, -0.075, -0.10) |

不改射线、弹道、碰撞、双手 IK、动画、枪械数值、弹药重量/数量、物品 ID、ContentDB 归属、经济或 UI 交互。四个定义资源仅改 icon 路径。原 MoCap FBX/四图、弹药定义/图标和未涉及的库存资产均做字节哈希核对。profile schema=8、checkpoint=6，未增加存档字段。

## 验证与证据

- Godot **4.7.2 stable**，独立 Git-visible 工作快照、独立 APPDATA/user://，不触碰实际玩家档案。完整回归结果与逐文件交付清单见 [机器可读验证记录](weapon_art_pack_v1_2026-10-15_validation.json)。
- 最终完整运行：**81/81 场景、105/105 结果项 PASS，0 ERROR**。冷导入保留两个已存在的 FBX 非 UTF-8 元数据警告；另有 Main `--quit-after 180` 强制退出时的 2 个音频对象泄漏警告。已在隔离副本恢复改动前的步枪场景/脚本/定义复现同样的 `AudioStreamWAV` / `AudioStreamPlaybackWAV` 警告，未归咎于新资产，也未做范围外音频修改；实际 quit 流程探针和新资源/图形探针没有该警告。**不是全日志零 WARNING。**
- 新 `tests/weapon_art_v1_test.tscn`：210 项检查；另外启动新 Godot 进程 `--read`：37 项检查。覆盖三套件真实库存消费、基地模型、部署、实际射击减一发、缺一补一/换弹时间、切枪、挂起换弹存盘及恢复、撤离、拆卸、保存失败原子性、重装、三把独立实例跨进程恢复和 schema7 无 fitting 旧档读取。
- 完整回归还运行原有 `rifle_contact_test`、`heroine_motion_style_test`、`weapon_behavior_test`、`weapon_switching_test`、`weapon_fitting_test`、`fitting_kit_test`、`save_service_test`、checkpoint/crash recovery、校园旧任务和库存/经济测试。
- `tools/weapon_art_v1_probe.tscn` 使用 Forward+ 实际渲染同机位升级前后、四种装配状态侧面/俯视、独立部件、弹药，以及实际 Hanger、角色持枪/换弹工作台和战斗相机截图。运行日志必须同时无 ERROR/泄漏警告，不能只看 PASS 文本。
- 本地截图和原始日志保留在 `art_source/weapon_art_v1/evidence/`（Git ignored）；原始隔离副本路径记录在验证 JSON。Hanger 仓库页面本来遮挡 3D 角色，本轮未为截图改变 UI；仓库截图验证新图标，近景使用实际生产 PlayerController 的工作台。

最终运行时资源/场景/脚本/导入设置与完整回归快照哈希一致。完整回归之后仅图形探针补充了“截图前通过原 FlowMenu.close 关闭失焦暂停”的受控采集处理，并独立重新运行通过；未修改生产的失焦暂停规则。说明/验证记录属于运行后报告，不影响运行时。

**边界：** 这是自动化引擎运行及受控图形检查，不冒称真人完整战斗验收、实际听感或最低硬件性能验收。射击/瞄准/换弹/IK 的程序回归不代替最后一轮真人握持观感检查。图形探针禁用敌人 AI 以稳定拍摄，不据此评价正常难度。

## 来源与许可证

详见 `assets/weapons/art_pack_v1/SOURCE.md`、`ASSET_HASHES.json` 和既有 `assets/weapons/mocap_m4/SOURCE.md`。原 M4/贴图仍受 MoCap Online/Motus Standard License 约束，不能改称 CC0 或独立转售素材包；原模型提取弹匣及相关图标继承限制。本轮没有下载新第三方模型/贴图，也没有生成式服务素材。新自制部分不擅自授予项目公共许可证。纸盒文字复用既有 Noto Sans SC UI 字体与其已保留的 SIL OFL 1.1。

## 未提交范围

本批现有文件修改：步枪场景、共享 weapon_visual、PlayerController 的展示调用、AR/三套件定义的图标路径、两份来源记录，以及已有回归 runner 增加一个场景/跨进程 reader。新增资源/场景/图标、离线构建源、图形探针、新测试和本说明。**完整逐文件新增/修改列表**在验证 JSON；本轮开始前已有校园 WIP 原样保留，唯一共用 runner 只叠加上述测试入口。没有自动 commit、push 或覆盖玩家存档。
