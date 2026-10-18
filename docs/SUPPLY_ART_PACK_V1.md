# Field Supplies Art v1 — 医疗、物资、食品饮品

2026-10-15，基于当前 `e940cd1` 与全部已有校园/Weapon Art Pack WIP。用户确认食品饮品应成为**可拾取、可交易的普通物资**，不是只摆在展示台上；不增加食用效果、饥饿/口渴、配方或新的存档系统。本轮未提交、未推送。

## 实际新增的美术

16 件静态模型，每件均有同源透明背景渲染图标。原生模型放在 `scenes/props/supply_art_v1/`，网格和 PBR 材质在 `assets/props/supply_art_v1/`，PNG/导入设置在 `assets/ui/stash/supply_art_v1/`。

| 模型文件名（`.tscn`） | 物品 ID | 外观内容 |
| --- | --- | --- |
| medkit | medical.medkit | 软包轮廓、前袋、织带、扣件、拉链/拉环、缝线、医疗识别贴 |
| field_dressing | medical.field_dressing | 密封袋、压封边、撕口、独立敷料标识和批号 |
| electronics | material.electronics | 电路板、芯片、针脚、走线、插座、金手指 |
| parts | material.parts | 零件托盘、齿形零件、轴承环、螺栓 |
| wiring | material.wiring | 三色绝缘线束、实际盘绕轮廓、绑带、接头 |
| fabric | material.fabric | 折叠层次、束带、织物细法线和材料标签 |
| data_drive | material.data_drive | 防撞护边、封装壳、紧固件、密封标签 |
| experiment_recorder | story.experiment_recorder | 独立记录器壳体、护边、日志屏、接口、封签；不再借用数据盘图标/通用电脑屏模型 |
| scrap | material.scrap | 不同方向的回收板材和管件 |
| propellant | material.propellant | 密封工业罐外观、盖/加强环、识别标签；没有内部结构或功能制作细节 |
| salvage_core | loot.salvage_core_01 | 回收模块、散热片、接口与识别面板 |
| field_ration | supply.field_ration | 口粮密封包装、压封边、撕口、批号/条码、配色识别 |
| energy_bar | supply.energy_bar | 窄条燕麦棒包装、压封边、独立暖色识别 |
| canned_beans | supply.canned_beans | 豆类罐头、卷边、凹入顶盖、拉环、印刷外套 |
| bottled_water | supply.bottled_water | 瓶身加强筋、肩/颈/盖、盖筋、饮用水标签 |
| citrus_drink | supply.citrus_drink | 细长饮料罐、卷边/拉环、独立蓝色印刷外套 |

使用低饱和橄榄灰、深灰涂层、克制的金属/包装反光和项目虚构 B07 标识。几何在离线构建时按材质合并，生产加载每件单个 ArrayMesh 的多材质表面，不会为每一个针脚或缝线运行建模代码/创建单独生产节点。织物微法线来自固定 seed 的原生 Godot NoiseTexture2D。没有下载或调用生成式服务；**这是自制第一轮物品资产，不是扫描级/高模写实成品声明**。

## 五种食品饮品的真实规则

| ID | 名称 | 单件重量 kg | 买价 | 满耐久单件卖价 | 堆叠上限 |
| --- | --- | ---: | ---: | ---: | ---: |
| supply.field_ration | 野战口粮 | 0.32 | 55 | 19 | 10 |
| supply.energy_bar | 燕麦能量棒 | 0.06 | 18 | 6 | 10 |
| supply.canned_beans | 豆类罐头 | 0.40 | 28 | 9 | 10 |
| supply.bottled_water | 瓶装饮用水 | 0.55 | 20 | 7 | 10 |
| supply.citrus_drink | 柑橘饮料 | 0.36 | 24 | 8 | 10 |

- 五个新 `ItemDefinition` 位于 `resources/items/`，使用现有 `loot`、`supply`、`food`/`drink` 标签；注册到既有 ContentManifest 和 YARD items 目录（31 → 36 项）。不改 ContentDB 的权威归属或 ItemInstance 字段。
- 食品饮品通过现有 SupplyService 买卖；唐葵居民补给拥有它们，沈砚霜/苏弥不重复出售。沿用原先候选状态、保存成功后发布、失败不扣款的交易实现；不新增交易服务。
- 普通掉落在现有 `street_apartment_loot` 和 `street_supply_loot` 中，各新增五条权重 2、数量 1 的条目。原条目的权重/数量不变；归一化后五种食品合计分别约 **9.09%** 和 **5.78%**。因此相对原物资概率略有下降，不能声称经济分布完全不变。没有新增地图储物点，药店、办公室、维修店和高价值/教学掉落表未改。
- 拾取、负重、堆叠、整堆货物交换、死亡丢失、撤离带回、出售及跨重启恢复使用原流程。购买的食品和其他普通交易物资一样留基地，不被弹药/医疗自动装包逻辑冒充为可食用补给。
- **不能吃喝、不能回血、不能解渴**；未创建饥渴数值或假食用按钮。中文名称和说明已加入现有翻译，说明明确本版本用途。价格是本轮起始配置，未声称多局经济平衡已验收。

## 不再只做独立展示

`scripts/presentation/item_presentation.gd` 是小型只读外观表，映射上述 16 件物品和上轮已有的 5.56 弹药盒/三个套件模型。它不持有库存/价格/存档状态。

- **仓库和商店：** 原 11 个物品定义仅改 icon 外部资源路径；不改重量、售价、医疗效果、堆叠规则或任务 ID。五个食品有自己的实际模型渲染图标。库存 UI 的格子/交易行为不改。
- **世界拾取：** 原 `LootPickup` 为已映射 ID 加载实际模型，不再用发光方块代替；未覆盖的武器/弹药等继续用原 fallback，不批量重制其他武器。setup、整堆交换或恢复更换槽位物品时会刷新模型身份，避免还显示旧物。
- **打开的补给箱：** 原 `SliceLootContainer` 打开时在箱顶展示首个剩余真实物品；关闭时隐藏。只调整独立视觉节点，原物品实例、容器数量、交互距离、碰撞和地点均不动，不把内容克隆成第二份掉落。
- **任务记录器：** 原 `scenes/world/campus_actions/recorder.tscn` 保留根脚本、Art 节点、WorldLabel、动作 ID 与位置选择逻辑，只将 Art 换成同一记录器场景，保留旧档位置和拾取后隐藏行为。

## 保持不动的内容

profile schema **8**、checkpoint **6**，没有字段迁移、库存重置或免费发放食品。全部原武器/人物/动画/挂点和前一批 Weapon Art 资源字节未改。校园地图、导航/碰撞、旧挂起任务、领取/交付条件和奖励未改。现有医疗逻辑、旧物品价格重量和全部原掉落条目数值保留。已有校园、武器 WIP 原样保留；共有的第三方来源记录、中文翻译与测试 runner 仅追加本批内容。

## 验证方式、证据与边界

- 新 `tests/supply_art_v1_test.tscn` **164 项检查**：20 个展示映射（16 新 + 4 上轮复用）、真实图标/无碰撞、食品普通物资属性、联系人归属、真实购买/部分出售/保存失败原子性、拾取外观替换、正常部署、已有宿舍储物点通过真实 seeded LootRollService/LootSpawnPoint 产出五食品、实际拾取、箱盖显示/隐藏、世界存盘恢复不重抽、撤离数量守恒、schema7 旧档不凭空长出食品。
- 第二个 Godot 进程 `--read` **31 项检查**：正常 profile 重载、五种拥有数量与外观重建。
- 完整冷导入及全部场景回归以 [本轮验证记录](supply_art_pack_v1_2026-10-15_validation.json) 为准；未以早期 FAIL 或单个 PASS 标记冒充最终日志清洁。`acceptance_smoke`/YARD 计数显式改为 36，区域掉落白名单显式增加五食品，原材料倾向断言和所有旧测试保留。
- 最终 Godot **4.7.2** 独立冷导入运行：**82/82 场景、107/107 结果项 PASS，0 ERROR**；仅冷导入两个既有 FBX 非 UTF-8 元数据警告，Main 本次无退出警告。全部运行时资源、场景、脚本、图标和导入设置与该执行快照哈希一致。随后在同一个已验证副本再次运行 Forward+ 物资图形探针，0 ERROR/0 WARNING。
- `tools/supply_art_v1_probe.tscn` 使用实际 Forward+ 渲染 16 件近景、原生 Godot 总览、真实 LootPickup 近景、现有中文仓库和唐葵商店。近景为了看模型仅在探针里隐藏原有大号世界标签，**生产标签样式未改**；UI 截图是有限库存夹具，不是自然获得全部物品的真人流程。
- 本机最终图形证据、日志和哈希在 `art_source/supply_art_v1/evidence/`（Git ignored），原始隔离目录/完整逐文件修改清单在验证 JSON。独立 APPDATA/user://，不触碰玩家真实档案。

没有宣称真人长期游玩、最低硬件性能或真实音频验收。半写实材质、包装褶皱/织物软感、标签设计仍可继续精修；当前不将基础硬表面建模称作最终 AAA 美术。原有不相关角色授权门槛不会因新增物资而解除。

来源/修改/字体许可证见 `assets/props/supply_art_v1/SOURCE.md` 和 `ASSET_HASHES.json`；离线构建源与重建限制见 `art_source/supply_art_v1/README.md`。
