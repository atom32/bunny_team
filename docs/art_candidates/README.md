# Art candidate pool — 2026-09-25

> **Current checkpoint (2026-09-27):** Phase 5 `bc4984b`, Godot 4.7.2.
> Player = production Unity-Chan (Phase 3D + Phase 4B fidelity); Enemy = native
> KITE-07, no legacy humanoid dependency (Phase 4E). Phase 5 validation: 33/33,
> two automated graphical routes 64/64 each, cross-process save/load PASS.
> See `Handoff.md` and `docs/DEVELOPMENT_SETUP.md` for current setup/verification.
> The reports below are **historical**, not instructions to repeat old gates or
> replace current assets. Local screenshots, trial scripts and profile copies
> referenced by historical reports may deliberately be absent from Git.

## Phase 2B — evidence chain disposition（最新）

**Migration internal checkpoint PASS；current VRM public shooting-demo use remains BLOCKED — authorization unresolved。** 用户接受自动化图形路线替代本轮手工 Gate；这不是许可授权，也不是人工操作。未检索/下载/批准 Terminal，C01/C02/C09 状态未推进；C03 replacement DEFERRED。

2026-09-25 再核验：

- [作者账户 VRoid Project / 36144806](https://hub.vroid.com/en/users/36144806) 列出 AvatarSample_A；[模型页](https://hub.vroid.com/en/characters/2843975675147313744/models/5644550979324015604) 的 model ID/author 与 R01 一致，当前页面显示 VRM 0.0 和允许 violent/commercial/modification/redistribution 的条件。
- 原始作者下载入口是该模型页的 Use this model；[官方 FAQ](https://vroid.pixiv.help/hc/en-us/articles/4402394424089-VRoidPreset-A-Z) 指向同一模型页。未取得该入口当前下载二进制及其版本许可快照，不以同名页面证明旧 fixture 自动获准。
- FAQ 显示 updated 2024-12-26，条款不是 CC0；没有取得明确覆盖该旧 GLB 的 AI input/training 授权。其链接的 Hub/general ToS 本轮网页工具未成功读取，不能称完整 ToS 审核已通过。
- 旧 GLB 的 CC_BY（无版本号）/OnlyAuthor/violent Disallow 字段没有改动；下方 R01 的本地 SHA-256 与 distributor blob 同一性仍有效。fixture 引入提交 2026-05-10 不是原作者授权或原始下载时间。
- 本地文件 mtime UTC `2026-09-25T12:07:24.401957+00:00` 只是工作站文件时间，不是下载证据；原下载日期及适用许可版本仍 unknown。不得以转换/重导出/清 metadata 解决此冲突。

本轮唯一来源恢复为 **已有 Unity-Chan 动画的缺失 TGA**，不是新美术候选：官方 1.2.1 包，全部六个 FBX hash 与本地一致，只取五张原图；原包/逐文件 hash 和当前 UCL 3.0 边界见 `assets/140301_unitychanmodel_Celsis/SOURCE.md`、`docs/phase2b/validation.json`。Battle Costume FBX 只做原样 legacy 隔离，未改变任何授权。所有 Unity-Chan/VRM 素材仍禁入本项目 AI 生成工作流。

## Phase 2 — release evidence / checkpoint（2026-09-25）

本轮未批准或集成新资产，没有下载新包。Terminal 候选仍是 C09 加工版对比 C02，C01 仅在明确更优时考虑；**尚未选定任何一个**。Gate 未关闭，不能把下方旧的首批多资产建议当成本轮执行范围。

### R01 — 当前 AvatarSample_A，状态 BLOCKED（不是新候选）

| 字段 | 核实结果 |
|---|---|
| Asset ID / local file | R01 / assets/characters/vrm_avatar/avatar_sample_a.glb |
| Author / original page | pixiv VRoid Project / [作者官方模型页](https://hub.vroid.com/en/characters/2843975675147313744/models/5644550979324015604)，页面日期 2021-06-29，VRM 0.0 |
| Current author terms | [官方示例角色使用条件](https://vroid.pixiv.help/hc/en-us/articles/4402394424089-VRoidPreset-A-Z)，不是 CC0；不是已确认版本号的 CC BY。访问日 2026-09-25 |
| Acquisition evidence | 本地 SOURCE.md 指向 [VRMMetalKit](https://github.com/arkavo-org/VRMMetalKit)。GitHub contents API 返回 AvatarSample_A_0.0.vrm.glb 的 blob SHA-1 与本地 git hash-object **完全相同**：7968f4145ad45e1e144c8a217454f38d6eec7325；18,566,868 bytes。未下载另一个模型 |
| Pinned distributor revision | [05afb6828fd48415b8d0141f5047e8b91b5b0c75](https://github.com/arkavo-org/VRMMetalKit/blob/05afb6828fd48415b8d0141f5047e8b91b5b0c75/AvatarSample_A_0.0.vrm.glb)，该路径提交历史记录日期 2026-05-10；这是分发仓库证据，不是作者授权日期 |
| File SHA-256 | a8b4c8e0f3e350012e6c0d2c4a2ce68654f44c1267b0761a115ecb60c0fe74e7 |
| Package SHA-256 | N/A；原下载包未保留，本次未下载包 |
| Embedded license/version | licenseName=CC_BY，未提供 CC BY 版本；allowedUserName=OnlyAuthor、violentUssageName=Disallow、sexualUssageName=Disallow、commercialUssageName=Allow |
| Commercial / violence | 作者当前 Hub 页面：企业、个人商业、暴力表现均 Allow；但尚未完成此二进制版本与作者当前授权的对应，**本项目 release 尚未批准** |
| Modification / redistribution | 作者当前页允许改作/再分发；FAQ 禁止将示例原模型/其数据有偿再分发、改称 CC0、用于角色创建服务等。成品打包需按适用条款确认，不能推断为无限制源码再分发 |
| Attribution | 作者当前页不要求；分发 fixture 的 notes 声称 CC BY。冲突未消除前保留 pixiv VRoid Project 署名，但署名本身不解决使用限制 |
| AI input / training | 已查作者模型页与示例 FAQ，没有取得此确切文件版本的明确 AI 授权结论。标为 NOT VERIFIED / 不投入 AI，不把未写条款解释成允许训练 |
| Release status | BLOCKED；不改写 metadata，不声称 CC0，不公开包装当前射击演示 |

闭环需要：取得作者适用授权的明确版本/说明，或从作者渠道取得条件一致的文件并保留下载/许可证据、核对与当前模型差异。当前仅证明了分发文件同一性，**没有证明分发者有权用自己的 LICENSE-MODELS.md 覆盖作者条件**。官方当前允许 violent use 是重要新证据，因此不能再断言“该角色作者禁止所有射击用途”。

### C03/C04 replacement spike 边界

- C03 已有 SciFi.gltf：SHA-256 `f163dfc7bb42676715ad3c69879e13b642ca97c235dc54895e65ac42f1d79f1c`；LICENSE.txt SHA-256 `e8dbf915a2b82229913e301a0787696611241bdefec4832bc084f54161db1efe`。导入/骨架读取 PASS，接口兼容性 NOT VERIFIED；非直接替换方案。详见 ART_ASSET_INVENTORY。
- Phase 1 的 Women 包 URL 与本地 **Ultimate Modular Males** LICENSE 标题不一致，精确包来源须重新核对，当前仍为 candidate。CC0 1.0 的商业/改作/再分发许可并不自动证明包身份或 IK 兼容性。
- C04 未下载、未导入、未验 rig，不为绕过 R01 阻塞而全面重做角色。

---

本轮只读作者/平台产品与许可页，不下载新素材。`candidate` 是桌面初筛，不等于已检查拓扑、包含指定型号、可直接导入或最终高质量批准。未获取包的 polycount/贴图规格明确标为未知；下载后逐文件核验再转 `approved`。现有两包为 `integrated`，其余没有伪造 approved。

状态流：candidate → approved（许可、具体文件、风格、技术均签收）→ integrated（回归+画面验收）；任一门禁不符 → rejected。同包 Standard/Pro/Source 的内容不同，购买档位不代表同名文件已取得；本轮不购买。

通用 CC0 含义依据 [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)：允许商业、修改、再分发，不要求署名；不代表授予商标/肖像权或担保上传者权利。本项目仍保存作者、URL、许可、取得日期及原包 SHA-256。

## C01 — Modular Sci-Fi Megakit / P0背景、P1入口

- Asset: Modular Sci-Fi Megakit，先评估门框、墙、顶板，最多挑 3 件。
- Source / URL: [Quaternius 官方产品](https://quaternius.com/packs/modularscifimegakit.html)
- Author: Quaternius
- License: CC0；产品页明确。Commercial Use: 是。Attribution: 不强制。Redistribution Restrictions: CC0 无版权再分发限制；保留来源；确认所获版本附带文件条款。
- Format: FBX/OBJ/glTF；Blend/引擎项目在 Source 档。Polycount: 单件未公布、未实测。Texture: 有纹理/可调色 shader 的版本，分辨率待包审。
- Style: 模块化 stylized sci-fi；Pros: 比单纯积木有层次，可做 corridor / military facility / ceiling / floor；Cons: 标示总量 277 不等于免费档数量，不能原样引入其碰撞/shader。
- Potential Use: 入口 framing、briefing 背墙、Hanger 日后装饰；不是整场景替换。
- Status: candidate；下一步只比较门框比例、GL Compatibility 材质和现门洞。

## C02 — Sci-Fi Essentials Kit / P0交互外壳、P1道具

- Asset: Sci-Fi Essentials Kit；先选屏幕/终端、箱体/设备架类可用件。
- Source / URL: [Quaternius 产品页](https://quaternius.com/packs/scifiessentialskit.html)；[作者 itch 下载档位](https://quaternius.itch.io/sci-fi-essentials-kit/purchase)
- Author: Quaternius
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制；具体 Source shader 文件仍核验包内声明。
- Format: FBX/OBJ/glTF；Source 有 Blend/引擎项目。Polycount: 未核实。Texture: textured guns/screens 等，贴图尺寸未知。
- Style: stylized sci-fi。Pros: 终端/箱体/枪/animated robot enemies 可一起比较；Cons: 静态终端不自带本项目交互，免费档不含全部，不能认定机器人 rig 可直接替换当前 humanoid。
- Potential Use: briefing desk 终端与一件 storage；robot/drone 外形只作以后研究，不新增敌人能力。
- Status: candidate。优先选少量 prop，禁止整包搬进 assets。

## C03 — Ultimate Modular Women / SciFi / P0角色

- Asset: SciFi 角色（在库参考）；并非当前 VRM。
- Source / URL: [Quaternius 官方](https://quaternius.com/packs/ultimatemodularwomen.html)
- Author: Quaternius
- License: CC0，官网+在库 LICENSE。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: 官方 FBX/OBJ/glTF/Blend；在库 SciFi.gltf 为 embedded buffer。Polycount: 在库实测 8,038 triangles。Texture: 在库 9 材质；贴图方案需 Blender 检查。
- Style: low-poly stylized humanoid，非现有细腻 anime 比例。Pros: 已在库，无需下载，62-joint/24-animation 数据可检查；Cons: 骨名/身高/脸/手部与 VRM 不同，不能直接换路径；低多边形不等于符合角色设计。
- Potential Use: 授权明确的角色 Presentation spike 或敌方轮廓参照；最终主角由美术方向决定。
- Status: candidate（已有文件不等于已批准新用途/风格）。

## C04 — Universal Base Characters / P0角色备选

- Asset: Universal Base Characters
- Source / URL: [Quaternius 官方](https://quaternius.com/packs/universalbasecharacters.html)
- Author: Quaternius
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: FBX/glTF；Source 含 rigged Blend。Polycount: 官方平均约 13k triangles，非本地测量。Texture: 有纹理，分辨率未知。
- Style: stylized humanoid。Pros: 比例选项与 humanoid rig，适合独立角色基础；Cons: **不是现成 anime tactical soldier**，服装/装备需另获授权或加工；不是本轮直接采用的主角。
- Potential Use: 与 C03 对照，评估换装与手部变形成本，作 NPC/主角底模。
- Status: candidate。

## C05 — Universal Animation Library / P1动作

- Asset: Universal Animation Library
- Source / URL: [Quaternius 官方](https://quaternius.com/packs/universalanimationlibrary.html)
- Author: Quaternius
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: FBX/GLB/Blend（随档位）。Polycount: N/A，动作库。Texture: N/A。
- Style: 通用 humanoid locomotion/combat。Pros: 有 gun/combat/多方向移动，较适合重定向研究；Cons: 120+ 为整包说明，不代表免费档全部，握枪/足底仍需验证，不能替代现有战斗状态机。
- Potential Use: 只选 idle/aim/run/reload 对照，Root motion 不接管位移，原 reload 事件/时长不动。
- Status: candidate，后于角色选择。

## C06 — Steampunk Turret Pack / P3（本轮否决）

- Asset: Steampunk Turret Pack
- Source / URL: [Quaternius 官方](https://quaternius.com/packs/turretpack.html)
- Author: Quaternius
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: FBX/OBJ/Blend。Polycount: 未公布。Texture: 未核实。
- Style: steampunk。Pros: 可读 turret silhouette；Cons: 风格不是 anime tactical，而且当前没有获准的新 turret gameplay。
- Potential Use: 以后外形参考，不作当前集成。
- Status: rejected（本切片风格/范围，不是许可证不合法）。

## C07 — Blaster Kit 2.1 / 当前武器基准

- Asset: blaster-e / blaster-g / blaster-o
- Source / URL: [Kenney 官方](https://kenney.nl/assets/blaster-kit)
- Author: Kenney
- License: CC0 1.0（本地原 LICENSE）。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: 在库 GLB。Polycount: 802 / 618 / 664 triangles。Texture: 512² palette。
- Style: 极简低多边形 sci-fi。Pros: 已通过握持/切换基线，低成本；Cons: Rocket 四管/单发语义不一致，细节少。
- Potential Use: AR/SMG 暂留；Rocket 优先 Blender 局部改轮廓而非改弹药；必须保存 Muzzle/Grip。
- Status: integrated（历史集成；本轮未改）。

## C08 — Sci-Fi Modular Gun Pack / P1武器备选

- Asset: Sci-Fi Modular Gun Pack
- Source / URL: [Quaternius 官方](https://quaternius.com/packs/scifimodularguns.html)
- Author: Quaternius
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: FBX/OBJ/glTF/Blend。Polycount: 单件未知。Texture: 待包审。
- Style: modular sci-fi。Pros: 组件和组装枪适合 Blender 定制轮廓；Cons: 握把比例、拆件和 muzzle pivot 要加工；**未确认存在合适 Rocket/SMG 型号**。
- Potential Use: 一个 AR/紧凑枪的 A/B 样本；找不到更优者继续 C07，不能为了包而新建武器定义。
- Status: candidate。

## C09 — Space Station Kit 1.0 / 当前环境基准

- Asset: 现有 16 件 modules/props
- Source / URL: [Kenney 官方](https://kenney.nl/assets/space-station-kit)
- Author: Kenney
- License: CC0 1.0（本地原 LICENSE）。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: 在库 GLB。Polycount: 单件 12–198 triangles，完整表见 inventory。Texture: 512² palette。
- Style: low-poly sci-fi。Pros: 已有 source/hash/导入/路线验证，可作固定比较基准；Cons: 过度重复管线/墙件容易像素材包展示。
- Potential Use: 保留大部分壳体，Blender 统一入口道具、柜体；不要重新下载现有包。
- Status: integrated。

## C10 — Particle Pack / P1 VFX

- Asset: Particle Pack
- Source / URL: [Kenney 官方](https://kenney.nl/assets/particle-pack)
- Author: Kenney
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: 2D particle sprites，具体归档格式下载时核对。Polycount: N/A。Texture: 产品页 80 件、512×512。
- Style: 通用粒子形状。Pros: 可用少数图形制作 flash/smoke/sparks/hit；Cons: **不是 Godot 成品特效包**，仍需调时序、透明度、billboard/overdraw。
- Potential Use: 同一 atlas 先做 muzzle + impact + smoke，后做 explosion；rain/shell ejection 另评估，不声称包已覆盖。
- Status: candidate。

## C11 — UI Pack - Sci-Fi / P1 UI

- Asset: UI Pack - Sci-Fi
- Source / URL: [Kenney 官方](https://kenney.nl/assets/ui-pack-sci-fi)
- Author: Kenney
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: 2D UI，PNG/vector 的具体文件清单待下载核实。Polycount: N/A。Texture: 分辨率待核；页面标示 130 件。
- Style: sci-fi panels/buttons。Pros: theme 切片容易，与当前冷色一致；Cons: 原样套用仍像素材包，不能遮挡 HUD 文本或更改按钮交互。
- Potential Use: 选 1 panel 和少数 icons 作 Godot Theme，保留所有 Warehouse/Result 字段。
- Status: candidate。

## C12 — Metal Plates 001 / P1地板

- Asset: Metal Plates 001
- Source / URL: [ambientCG 单项页](https://ambientcg.com/view?id=MetalPlates001)；[官方许可](https://docs.ambientcg.com/license/)
- Author: ambientCG / Lennart Demes
- License: CC0 1.0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: 允许原文件随项目再分发。
- Format: PBR JPG/PNG sets。Polycount: N/A。Texture: 1K/2K/4K 可选，第一轮只考虑 1K。
- Style: 工业银色金属板。Pros: 适合 floor/panel 粗糙度研究；Cons: 原样较写实/嘈杂，必须减细节、调金属比例与色值。
- Potential Use: 小块地板 A/B，不铺满全图，警戒线另做清晰矢量/贴图。
- Status: candidate。

## C13 — Painted Metal Shutter / P1材质比较

- Asset: Painted Metal Shutter
- Source / URL: [Poly Haven 单项页](https://polyhaven.com/a/painted_metal_shutter)；[许可](https://polyhaven.com/license)
- Author: Charlotte Baglioni（摄影）、Dario Barresi（烘焙）、Rico Cilliers（处理）
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: 可再分发资产；网站 logo/示例渲染不因此自动 CC0。
- Format: PNG/JPG/EXR maps、Blend/glTF。Polycount: N/A。Texture: 1K–8K，2m 宽物理参考。
- Style: 有风化的工业波纹金属。Pros: 提供受控磨损参考；Cons: 波纹不是平坦喷漆钢板，不能冒充通用 office trim，勿用 displacement 改碰撞。
- Potential Use: 设备背板/百叶局部，或粗糙度比较；初选 1K。
- Status: candidate，不是首批必选。

## C14 — Animated Explosions / P1否决比较

- Asset: Animated Explosions
- Source / URL: [OpenGameArt 单项作者发布页](https://opengameart.org/content/animated-explosions)
- Author: ansimuz
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制。
- Format: 2D animation sprites，归档未下载。Polycount: N/A。Texture: 尺寸未核。
- Style: pixel art。Pros: 爆炸动画轮廓可读；Cons: 明显像素风与现 3D/anime 方向不一致。
- Potential Use: 仅比较，不集成。
- Status: rejected（风格）。

## C15 — Concrete Floor 01 / P1入口材质

- Asset: Concrete Floor 01
- Source / URL: [Poly Haven 单项页](https://polyhaven.com/a/concrete_floor_01)；[许可](https://polyhaven.com/license)
- Author: Rob Tuytel
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: 可再分发资产；不包括网站其他受保护内容。
- Format: PNG/JPG/EXR PBR maps、Blend/glTF。Polycount: N/A。Texture: 1K–8K，2m 宽参考。
- Style: 写实风化粗混凝土。Pros: 入口落脚区有物理尺度参考；Cons: 必须降低颗粒/颜色噪声才能融入 stylized，湿地面需另调 roughness，不是现成湿地面 shader。
- Potential Use: 只比较入口 1 块 ground，不改道路结构；初选 1K。
- Status: candidate。

## C16 — Ultimate Guns Pack / P3扩展枪型调查

- Asset: Ultimate Guns Pack
- Source / URL: [Quaternius 官方](https://quaternius.com/packs/ultimategun.html)
- Author: Quaternius
- License: CC0。Commercial Use: 是。Attribution: 可选。Redistribution Restrictions: CC0 无版权再分发限制；实枪标识/商标另检。
- Format: FBX/OBJ/Blend。Polycount: 单枪未核。Texture: 未核。
- Style: stylized guns。Pros: 多枪型可比较 AR/SMG/pistol/shotgun 的轮廓；Cons: 与科幻方向未必一致，40 件不代表全部握持/动画兼容，也未核实适合的单管发射器。
- Potential Use: 未来武器外形研究，本轮不增加 pistol/shotgun gameplay。
- Status: candidate，低优先级。

## 检索覆盖、空缺与淘汰规则

- Field Office 的 interior/corridor/facility/floor/ceiling/doors/lights/pipes：C01+C09；terminal/computer/crates/storage：C02。locker/rack 的**具体文件尚未包审**，可先加工已在库柜体，不声称新包必有全部物件。
- Character/soldier/NPC：C03/C04；robot：C02。**未批准专门 drone 模型**，不为填表引入未知来源；turret C06 本轮不合适。
- Weapons：C07/C08/C16；当前 AR/SMG 保留，Rocket 单管是仍需选型的明确空缺。
- VFX：C10；C14 展示“许可合格也可因风格否决”。rain、shell ejection 延后。
- Materials：C12/C13/C15；glass/rubber/warning stripe 优先现有简单材质/可读标线，不必为每种表面下载新包。
- itch 使用作者账号产品页；Sketchfab、Fab/Unreal、Unity Asset Store、BlenderKit 是后续备用渠道，本轮**没有批准任何具体条目**。不能把平台名/Free 标签当许可。
- 若引入商店资源，必须检查独立于原引擎使用、公司/席位、AI-input 条款、原文件能否进入当前 Git remote，以及成品分发限制；不是买了就能上传公共源码库。[BlenderKit/Blendkit 官方许可说明](https://www.blendkit.com/docs/licenses/) 也区分 CC0 与 Royalty Free，不能混称 CC0。
- 排除未知作者、盗模/游戏拆包、IP 同人授权不清、Editorial/NC 不适合用途、来源无法追溯、真实政治/军事徽记权利不清的素材。优先原创虚构标志。

## 首批建议（仍需用户美术签收）

1. 不下载：C09 在库门框/柜体 Blender 归一化，对照原版；保留 AR/SMG。
2. 一次只查一个包：C02 一个 terminal + 一个 storage；如轮廓已足够再跳过 C01，不同时引入两套建筑语言。
3. C12 或 C15 二选一做 1K 材质样片；C10 只选少量粒子形状。
4. C03 对 C04 做独立角色选型；未解决 VRM 授权前不公开含当前角色的 gameplay 宣传。
5. 只有 A/B 已明确现成资产不适用，才允许 AI 做原创标志/概念补足；本候选池没有把任何 AI 输出列为 approved。
