# Neon Bastion / Bunny Operator 单角色生产流程

当前状态：**生成前受阻，未交付新角色模型**。原始设计、裁切、官方 API 客户端、Blender 整理与独立 Godot 展示入口已准备并验证。API 控制台当前没有密钥、余额为 0；Studio 页面虽然显示 145 点，但提示多视图生成和导出需要升级。没有提交收费任务、充值、购买订阅或替换现有角色。

## 已锁定的输入与工程约定

`reference/design_sheet.png` 是用户附件的原始字节副本，SHA-256 与下载目录原件一致。`reference/manifest.json` 记录精确裁切坐标和各图校验值。仅裁切和加边，未生成新设计、调色、拉伸或镜像。正面图的右腿枪套位于画面左侧；侧面图能看到同一枪套，作为 `right` 视图。没有 `left` 图，不镜像不对称装备。右侧细节小图不作为另一人物输入。

当前玩家资源为 `assets/characters/artoria_bunny/bunny_player.glb`，角色骨骼沿用 `Character1_*`，已有双手 IK、`HandR` / `HandL` / `ShoulderR` 等挂点。武器自己的 `PrimaryGrip`、`SupportGrip`、`ReloadGrip` 和 `Muzzle` 继续由既有系统提供。全套接口未改。

Godot 使用 +Y 向上、-Z 朝前。胶囊半径 0.36m、高度 1.85m、中心高度 0.93m；兔耳/长发属于视觉结构，不为它们扩大玩家碰撞。战斗正交镜头 size=19.5，相对观察目标偏移 `(0,18.2,13.7)`。新角色含兔耳目标全高 2.05m；朝向必须查看实际生成网格后明确指定，不能仅凭 API 默认值宣称正确。

本机 Blender 5.2.1、Godot 4.7.2、ComfyUI 已安装。已安装 ComfyUI 模型目录中未找到 Tripo/Hunyuan/Trellis 3D 权重；没有把 API 节点模板误当作免费的本地生成模型。

## 人工配置凭据及额度

用户在[官方密钥管理页](https://platform.tripo3d.ai/api-keys)创建密钥，并自行在[官方账单页](https://platform.tripo3d.ai/billing)配置 API 额度。创建持久凭据与付款由用户完成；不读取浏览器认证数据库、不绕过导出限制。

在本机 Terminal 执行：

```sh
python3 /Users/xudawei/bunny_team/art_source/bunny_operator_20261010/scripts/configure_keychain.py
```

助手调用 Apple `security`，将 `-w` 放在最后以启用隐藏密码提示。密钥不出现在源码、命令参数、输出或项目文件；保存在登录钥匙串 `neon-bastion-tripo-api`。客户端也接受调用进程已有的 `TRIPO_API_KEY` 环境变量。不要将密钥发送到聊天或写入项目。

用户另外明确本次消耗上限。配置方案单次预计 60 credits：多视图+纹理30、高细节几何20、高细节纹理10。自动绑定25，检查免费。建议总上限150（约$1.50），用于最多两次生成与一次绑定；不是对充值最低金额的承诺。尚未获得消耗授权，尚未执行。[价格依据](https://developers.tripo3d.ai/en/pricing)

## 可重复执行的生产步骤

从项目根目录执行。这里只描述下一步具体操作，**不表示已执行在线生成**。

```sh
python3 art_source/bunny_operator_20261010/scripts/prepare_references.py
python3 art_source/bunny_operator_20261010/scripts/tripo_pipeline.py balance
# 仅在用户明确授权上述消耗上限后执行：
python3 art_source/bunny_operator_20261010/scripts/tripo_pipeline.py generate --run v001 --max-credits 150
```

客户端使用经官方文档核对的 v3 API：`POST /files` 上传三图，`POST /generation/multiview-to-model` 将 `front/back/right` 放在**一个** `inputs` 数组里，`GET /tasks/{task_id}` 查询一个统一模型。参数在 `config.json`，不混用 v2 字段。原始 GLB、任务 ID、输入校验值、参数、状态和实际 credits 存在 `runs/v001/`；签名下载 URL 的查询凭据不会写入记录。授权头只发给官方 API，不随模型下载请求发给 CDN。

相同 `--run` 会继续已有任务，不再提交。POST 发生网络故障且无法确认结果时，保留“不确定提交”状态，拒绝自动重试；应先在官方 Usage 核对。新版本使用 `v002`，不会把三个视图各生成一个模型。客户端合计所有 run 的成本与进行中的预计占用，不只检查单次预算。API seed 是官方支持的复现参数，但不保证未来服务版本的逐字节一致性。

取得模型后，先只检查：

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --disable-autoexec \
  --python art_source/bunny_operator_20261010/scripts/process_model.py -- \
  --input art_source/bunny_operator_20261010/runs/v001/source.glb \
  --output art_source/bunny_operator_20261010/runs/v001/normalized.glb \
  --height 2.05 --yaw-degrees 0 --inspect-only
```

之后依据实际正侧背观察选择 yaw，再移除 `--inspect-only`。0 度只是检查示例，不是已经核验过的新模型朝向。输出 GLB、打包贴图的 `.blend` 和 `.inspection.json`；处理使用共同父节点修正尺寸、朝向、地面原点，保持各网格、UV、材质、蒙皮与局部变换。不会自动减面、焊接、合并全部网格或重置全部变换；不同来源的已存输出拒绝覆盖。`--exclude-mesh` 默认不排除任何网格，只有人工确认的辅助节点才可明确指定。

检查面部、手指、马尾、机械兔耳、荷叶边、腰带/枪套及靴子，记录最严重三个缺陷。如果缺陷显著，应保留 v001，以相同设计输入调整生成配置到 v002，而不是将导出成功当作视觉通过。拓扑边界可能来自头发/衣服的开放面，检查报告记录它们但不盲目补洞。

绑定检查和绑定仍待真实模型：

```sh
python3 art_source/bunny_operator_20261010/scripts/tripo_pipeline.py rig-check --run v001 --max-credits 150
python3 art_source/bunny_operator_20261010/scripts/tripo_pipeline.py rig --run v001 --max-credits 150
```

只有检查返回 `riggable=true` 且 `rig_type=biped` 才可提交绑定。使用官方人形模型 `v1.0-20240301`、Mixamo 命名和 GLB 输出。保留原始静态模型及 `rigged_source.glb`；绑定后重新检查蒙皮、关节变形和方向。不要把空骨架或静态网格描述成动画完成。长发、兔耳的拆分/独立运动与手指权重需要实际检查，再决定修改；当前没有生成骨骼或验证新角色站立、行走和持枪。

经视觉核验后，才将选定规范化 GLB 复制到新目录 `assets/characters/bunny_operator_v1/bunny_operator.glb`，保存资产清单。运行 `scenes/art_showcase/bunny_operator.tscn` 可选择正面/右侧/背面/实际战斗镜头，右键旋转、滚轮缩放。展示场景读取新资源路径，缺少时明确显示阻塞，不替换成旧角色来伪装成果。它不实例化 PlayerController，不调用存档/库存/战斗；尚未接入正式角色定义、物理或武器挂点。

## 已执行验证与实际边界

- 原稿可读取，三视图裁切完成并查看；原件和输入校验值已记录。
- API 客户端6项**离线**回归通过：一个多视图任务、任务恢复不重复 POST、不确定提交不重试、跨版本预算、日志隐藏签名参数、认证错误不泄漏密钥。没有将 mock 返回当作服务端生成结果。
- 用旧角色测试样本实际运行 Blender → GLB → Godot；11个原渲染网格、52根既有骨骼及材质/贴图保留。旧资源中 `Icosphere` 是42顶点、80面、无材质/无权重的辅助球，仅本地测试导出显式排除；原始文件未修改。新生成模型不预设排除项。
- Blender重复导出得到相同 GLB SHA-256。测试输出位于 `/tmp/bunny-operator-pipeline-fixture/`，不是新主角。
- Godot实际运行了四个镜头，屏幕明确标为旧角色测试样本。蒙皮尺寸验证使用实际骨骼和 bind pose 计算顶点，保持2.05m全高/脚底地面的严格检查；没有将保守渲染AABB误当作可见蒙皮边界。
- 三组现有角色表现、持枪接触、弹药携行回归通过，见 `regression.json`。正式用户存档未使用测试结果覆盖。

`status.json` 是交付状态的事实记录。**统一新模型、设计一致性、动画/骨骼、武器适配以及新角色正侧背/游戏截图均未完成**，需要密钥和额度授权后继续，不能报告整个任务完成。实际 API 支出0；没有可靠记录的新模型成本。

官方文档列表在 `docs/sources.json`，公开页面快照保留于本地。在线资产结果必须逐项核验文档支持与真实返回；若服务改变输出字段，应报错而不是假造 URL、模型 ID 或任务状态。
