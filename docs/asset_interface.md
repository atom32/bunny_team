# Replaceable Asset Interface

> 2026-10-15最新动作/模型制作入口：[独立审查台、成年男女适配与主角自然战斗样式](MODEL_ANIMATION_AUTHORING.md)。本页旧库存与未实现事项保留为阶段历史，不覆盖新批次状态。

> 2026-10-14工具交付：可编辑校园、YARD stable-ID目录、现有武器/动作工作台与CC0维修室模板已实现，见 [使用说明](CONTENT_TOOLS_IMPLEMENTATION.md)。原始美术/动画未改，任意骨架自动导入与任务批量制作仍是后续计划。

## 当前接口 — 2026-10-14 / `68076ae`

游戏数据与表现已有一定分离，但**角色/敌人不是任意模型即插即用接口**。本节覆盖下方旧Unity-Chan可见玩家说明；旧文本仅保留历史。扩展计划见 [内容路线图](CONTENT_PIPELINE_ROADMAP.md)，本节描述当前代码。

### 数据与注册

- `ItemDefinition`有stable ID、名字、说明、icon、占格、重量、价值与栈规则；普通材料/医疗不自动拥有3D场景。
- `EquipmentDefinition`增加 `scene: PackedScene`、`socket_name`；`WeaponDefinition`增加弹药、射击/换弹等数据。换装备模型通常改`.tres`的scene，仍需检查握点与挂点。
- `EnemyDefinition.scene`是controller根场景，不是任意GLB；另有数值、感知与tactical role。PMC/KITE/感染者采用不同presentation。
- 定义显式注册至 `resources/content/content_manifest.tres`，由 `ContentDB`读取；注册不等于可购买/掉落/制作，获取渠道也要验证。
- 不能改已有stable ID来换外观；ID被库存、装备、掉落与存档引用。profile envelope当前schema **7**。

### 玩家模型与动画

- 可见模型：`assets/characters/artoria_bunny/bunny_player.glb`；不是历史Unity-Chan可见FBX，也不是尚未生成的Bunny Operator。
- `scripts/player/player_controller.gd`固定模型路径、`CHARACTER_BONE_RENAMES`、隐藏Unity-Chan动画源及 `Idle_Gun/Walk/Run/Run_Shoot/Dodge`绑定。
- runtime有 `CharacterRetarget`、`CharacterAnimationPlayer`、`CombatAvatarModel`；真实代码与语义测试为准，下方旧 `CombatAndroidModel`不是当前名称。
- `RetargetModifier3D`转移共享骨骼旋转，position/scale转移关闭；当前有专用骨骼重命名、skin bind处理与rest约束。
- Artoria `pose_adapter.gd` / `hand_modifier.gd`接入 `CharacterCombatRig`，维护双手/持枪/换弹。`validate_visual_integrity()`仍检查当前模型专用网格、三角与52骨骼，不是通用跨模型校验。
- stable socket：`Chest`、`ShoulderL`、`ShoulderR`、`Backpack`、`HipL`、`HipR`、`HandL`、`HandR`。实际骨骼/offset是当前模型专用，有些socket不直接绑定同名手骨，不能凭名称猜位置。
- 武器场景的 `PrimaryGrip`、`SupportGrip`、`ReloadGrip`、`Muzzle`参与现有rig；仅加Muzzle不能保证可信持枪。
- Hideout独立使用Quaternius JSON与 `hideout_idle.gd`，已有 `transitions.json`及区域走动/过渡；装备预览恢复、基地动作和战斗驱动分开，不是通用动画API。

### 敌人模型与动画

- `humanoid_enemy_presentation.gd`固定 `assets/characters/quaternius_scifi/SciFi.gltf`，依赖 `Idle_Gun_Pointing`、`Run_Shoot`、`Gun_Shoot`、`Death`与模型Pistol。
- `infected_presentation.gd`继承它，隐藏Pistol、染色，使用Idle/Walk/Run/Punch_Left；这是占位外观，不是独立感染者模型。
- `infected_controller.gd`重写presentation创建、近身追击与攻击前摇；命中继续由controller负责距离/视线/伤害，动画不另建命中owner。
- 新presentation须实现controller需要的更新、攻击、死亡与位置/方向接口；近战不能强套持枪规范，保存/恢复中待发动作也需验证。

### 替换与最低检查

1. 保留原始来源、许可与hash；候选先进入隔离展示和新目录，不覆盖当前GLB来试错。
2. 检查尺度/原点/朝向、贴图、实际骨骼/rest/蒙皮；世界单位米、+Y向上、controller前方-Z。人形导入profile/来源方向可能不同，需wrapper明确转换。
3. 静态装备可先改resource.scene候选；玩家/敌人还需映射、clip语义和presentation适配。不能仅改路径或关闭当前模型测试来“通过”。
4. 检查生产俯视镜头、正侧背、移动/瞄准/换弹/闪避/受击/死亡、手脚/座椅接触与equipment restore。
5. 冷导入、全部实际场景库存、装备/战斗专项、Main、挂起与跨进程恢复；触及导航/掩体/门/出口另做世界检查。runner当前62/66偏差见 [审计](PROJECT_STATUS_2026-10-14.md)。

授权以 [THIRD_PARTY_ASSETS](../THIRD_PARTY_ASSETS.md)为准：Artoria许可未确立；Unity-Chan动画保留自身条款；Quaternius SciFi包identity仍未完成核验。CC0动作/环境不意味着整个游戏已获发行授权。

## 历史接口（旧Unity-Chan可见玩家阶段，已被上节覆盖）

Gameplay data, the controller, and the current character presentation are separated so the visual asset can be replaced without rewriting combat.

## Current character pipeline

- The visible character is the official Unity-chan Battle Costume FBX at `assets/characters/unitychan_battle/unitychan_battle.fbx`.
- The render skeleton has 328 bones, including secondary hair, skirt, mantle, and costume bones.
- A hidden 140-bone Unity-chan animation FBX provides the runtime pose.
- `RetargetModifier3D` transfers shared-bone rotations to the render skeleton.
- Idle, walk, and run clips are loaded from separate official FBX files and normalized into one runtime `AnimationLibrary`.
- The bundled melee weapon is hidden because this project supplies shooter-specific weapons.

The runtime creates these stable socket names: `Chest`, `ShoulderL`, `ShoulderR`, `Backpack`, `HipL`, `HipR`, `HandL`, and `HandR`. Rifle and SMG visuals are currently stowed on the upper back so the neutral Unity-chan animations do not drag a weapon through the floor.

## Replacing the character

1. Import the replacement FBX or GLB and its animation source into Godot.
2. Update `CHARACTER_SCENE`, texture constants, and `CHARACTER_ANIMATION_SCENES` in `scripts/player/player_controller.gd`.
3. Keep the eight socket names stable. Bone names may change, but the `_add_bone_socket` mappings must be updated.
4. Keep local `+Y` as up. The current Unity-chan mesh faces local `+Z`; the retarget wrapper rotates it to the controller convention.
5. Preserve the `CombatAndroidModel`, `CharacterRetarget`, and `CharacterAnimationPlayer` node names used by smoke tests.
6. Run `res://tests/acceptance_smoke.tscn` and visually inspect Hanger and Battle.

The controller, health, collision, loadout data, shooting, and UI do not reference individual mesh parts.

## Equipment replacement

Each item consists of:

- one GLB or `PackedScene` whose local origin is its mount point;
- one `EquipmentDefinition` or `WeaponDefinition` resource with a stable content `id`;
- a `socket_name` matching a player socket;
- optional movement, damage, fire-rate, projectile, and blast-radius values.

Replacing a weapon model only requires changing the `scene` field in its `.tres` resource. Weapon scenes may expose a `Muzzle` marker; firing falls back to the controller aim origin if it is absent.

## Scale and orientation

- Godot units are meters.
- Controller forward is local `-Z`.
- Character up is local `+Y`.
- Weapon muzzle nodes should be named `Muzzle` and point toward local `-Z`.
- Apply transforms before FBX or GLB export.

## License boundary

Unity-chan files remain subject to the Unity-chan License 3.0. The complete license archive is retained under `assets/characters/unitychan_battle/license/`. Do not use these assets as AI image-generation training or input data, and preserve the license package when redistributing the digital asset files.
