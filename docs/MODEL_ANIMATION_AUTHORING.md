# 模型与动作制作 — 2026-10-15

本批接续内容向导，落实成年男性/女性动作与主角「**年轻成年女性，自然轻盈、战斗实用**」样式。原 Artoria 主角模型不换、不改源文件；控制器、伤害、移动、弹药、交互和任务判定不交给动画事件。整个后续目标仍在进行，未交付新物品和校园第二批任务。

## 编辑器审查入口

顶部 **Neon Tools → Review model / animation (isolated viewport)** 打开独立 Window/SubViewport/World3D，不启动游戏、不创建 PlayerController，也不读写个人 profile。选择成年男性受试者或成年女性动作参考；Model/Library/Profile 可载入项目资源。

- 正面、侧面、背面、生产战斗镜头尺度19.5；播放/暂停、时间拖动、预览副本循环、速度、rest pose。
- 模型原点/尺度/AABB、网格/材质/三角形、骨骼父子/rest位置、clip时长/轨道、位置变化与首末帧循环差。
- 骨骼线和选定骨骼（默认pelvis）的预览轨迹。它是**采样骨骼路径**，不是已接入控制器的root-motion。
- 任意带节点脚本的包装场景拒绝实例化；预览复制AnimationLibrary，禁用方法、音频、value等事件轨道，不改原导入资源。
- AABB是导入/rest范围，**不是动画包围盒**。循环差、骨骼数据通过不等于脚底/枪握点/椅子接触或动画质量自动通过，仍须看实际生产镜头。

审查台只读，不自动保存新绑定。`PresentationProfile`资源可在Inspector编写model_path、skeleton_path、BoneMap、语义→clip、尺度/朝向与来源。校验拒绝错误骨骼路径、未映射目标骨骼和非骨骼事件轨道；动作必须具备idle/walk/run/attack/hit/death。模型延迟加载，避免第一次冷导入时autoload预载manifest抢先加载尚未导入的GLTF。

主角持枪动作请继续用 **Neon Tools → Open weapon workbench**：它运行实际主角适配器、7把生产武器和最终手掌约束。F6会启动项目autoload，要求连读取profile也隔离时必须使用隔离工程/用户目录，不在个人存档中试验。审查台中的普通模型预览不等于主角完整持枪rig预览。

## 成年男女动作资产

来源：[Quaternius Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html)免费Standard和已有[UAL1](https://quaternius.com/packs/universalanimationlibrary.html)，CC0。实际选用Superhero Male/Female两个基模，**不是Teen模型，不含收费Source工程**；宣传页完整包数量不代表免费包数量。Standard归档SHA与逐件来源在两处SOURCE.json中。

| 适配目标 | 模型与配置 | 当前用途 |
| --- | --- | --- |
| 成年男性 | `assets/characters/quaternius_subject/subject_clothed.gltf`；`resources/presentation/subjects/campus_subject_profile.tres` | 新出击中的campus_infected独立受试者外观，区别于PMC |
| 成年女性 | `assets/characters/quaternius_subject_female/subject_clothed.gltf`；`resources/presentation/subjects_female/campus_subject_profile.tres` | 可复用动作参考/审查预设，**尚未分配新校园出生点或NPC身份** |

每套65骨骼、53项Humanoid BoneMap，以及Idle、Walk、Run、Punch_Left、Hit_Chest、Death、Interact共7个语义clip。UAL1来源分别是Idle_Loop、Walk_Loop、Jog_Fwd_Loop、Punch_Jab、Hit_Chest、Death01、Interact。原动画是**通用/unisex作者动画，不是已核实男女演员的mocap**；男女动作分别依实际目标rest骨架和腿长重定向，不是复制文件后仅改标签。

重定向以30Hz采样来源全局旋转相对rest的变化，应用到目标全局rest，再求目标父子局部旋转；四元数保持连续。pelvis垂直位移按目标/来源rest腿长比例转换；水平root位移不驱动游戏角色。输出为原生AnimationLibrary，不改变模型rest、蒙皮权重或原始UAL1 GLB。

受试者蓝色临床连体衣和软鞋是原身体三角形的材质分区，头/颈/手保留皮肤；**不是新建宽松病号服网格**。皮肤、身体比例和运动接触仍有人工美术润色空间。头发组件未额外采购/拼装；临床参考采用剃发外观。男性运行时增加L-02编号胸牌，无枪，不复用PMC皮肤。女性并不因此变成新主角，也不随机替换现有敌人。

## 主角样式：年轻成年女性、自然轻盈、战斗实用

`resources/presentation/heroine_natural_combat.tres`通过`HeroineMotionStyle`实际作用于生产Idle_Gun/Walk/Run/Run_Shoot。沿用UnityChan女性角色动画及既有Artoria重定向，保留原动画文件、clip名称、长度、状态机、步频和前后步幅；Dodge保持原滑步动作，换弹仍是当前枪械rig的procedural pose，**不是新增换弹mocap**。

实际关键帧调整以局部rest为基准：髋部横向旋转保留80%、躯干85%、上腿90%，保留前后屈伸。手臂、手指、枪握点和最后手掌求解仍由生产combat rig负责；不添加夸张扭胯、少女化姿态、年龄标签化的随机摆手。已有全身运动/瞄准/换弹混合不换底座。

这里的「年轻成年女性」是**项目角色与动作适配目标**，不是对UnityChan原角色年龄或动作演员年龄的认证；资产许可继续沿用UCL及Artoria试作限制，不因样式修改获得商业发行授权。后续若换成真正女性mocap或原创主角，应另核来源、骨架、动作风格及许可。

## 战斗与旧出击保存

感染者仍使用原近战controller，命中前摇0.38秒、距离/视线检查、HP/伤害/掉落都不改。新动画有0.867秒近战表现时间，表现完整播放不改变命中计时；新增受击clip不打断正在生效的攻击计时。通用presentation API的muzzle位置对无枪角色返回手部打击原点，不启用射击链。

不同敌人不再假设共用第一个活体的骨骼列表。checkpoint按对应模型验证完整骨骼集合；65骨骼受试者与原PMC骨架共存。旧感染者悬停快照若具有完整原PMC骨架，则恢复时保留**原旧皮肤、隐藏枪及采样姿态**，不将旧pose硬套到新骨架。损坏/缺失/混入陌生骨骼仍拒绝恢复。profile schema7、SortieCheckpoint version5和地图布局签名不变。

## 可复现制作与验证

`tools/derive_subject.py`接受固定SHA的免费Standard归档，选择male/female，输出到**新目录**；仅修复原包缺失normal纹理URI与创建材质分区，原贴图像素、顶点、权重、bind骨架不改。`tools/bake_subject.tscn`接收来源GLB、目标模型、新输出目录、适配目标及报告路径。先在隔离工程导入目标，再执行烘焙，审核产物后移回正式资源目录；不要直接覆盖已使用的clip。

```powershell
# 仓库根目录，归档路径自备；不自动购买或下载收费版本
python tools/derive_subject.py --archive '<Standard.zip>' --sex female --output '<全新模型目录>'

# 已导入的隔离工程；output是该工程内的新res://目录
& '<Godot console.exe>' --headless --path '<隔离工程>' res://tools/bake_subject.tscn --quit-after 1200 -- --source '<UAL1_Standard.glb>' --target 'res://assets/characters/quaternius_subject_female/subject_clothed.gltf' --output 'res://resources/presentation/new_review' --demographic 'adult female' --profile-id 'presentation.review_example' --report '<仓库外JSON>'

# 完整隔离回归与真实图形自动路线
python tools/verify_migration.py --godot '<Godot console.exe>' --output '<全新仓库外目录>' --route
```

新增`asset_review_test`、`heroine_motion_style_test`、`presentation_checkpoint_test`，库存75。覆盖只读预览、拒绝脚本/事件、骨骼/语义契约、男女目标比例、主角真实关键帧修改、7武器×5动作状态手掌接触、原模型完整性与混合/旧骨架精确恢复。图形探针在隔离工程采样男女每个clip五个时间点、正侧背/生产镜头以及主角五个动作；编辑器探针通过真实菜单进入tool SubViewport。**自动化图形截图不是人类游戏节奏/动作审美/听感验收。**

本批日志、源hash、失败与修复记录见[验证记录](model_animation_2026-10-15_validation.json)。新增真实物品、校园后续任务、任意骨架一键导入及完整版Alpha仍未完成，无commit/push、购买或个人存档修改。

最新精确代码/资产快照已通过 **75/75场景、96/96结果项，0 ERROR**；仅冷导入保留2条原始FBX UTF-8警告，Main与Forward+自动路线无警告。真实编辑器审查窗口探针0错误。151个既有主角/驱动/PMC/动画源文件SHA未变；现有感染者16项数值导出保持HEAD值。
