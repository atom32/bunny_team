# Windows 本地独立试玩包

已构建并实际运行 Windows x64 Release 模板包，不再要求从 Godot 编辑器启动。**仅限本地原型验证，不可上传或再分发**：资产授权审查尚未通过，包含仅供验证的 QA 入口，未签名，未发布到 itch.io。生产角色不变，Arcana 未打包。

## 本机试玩

- ZIP：`D:/tmp/bunny_release_20261019_build04/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，277,932,102 字节。
- 解压后运行 `NeonBastion.exe`；保持它与 `NeonBastion.pck` 放在同一目录。无需在旁边放源码或编辑器。
- 名称为 `Neon Bastion Local Prototype`，使用独立的原型存档目录，不读取或覆盖源码项目的个人存档。验证进程另外使用专用 APPDATA。
- 操作、规则和角色沿用当前工作区；这是可运行的本地包，不是完整首小时已验收或已获授权的发行版。

## 本批解决的问题

正式退出原先只发送停止音频请求，音频线程尚未完成释放时就结束对象清理。旧版三次 Main 退出中有两次出现 AudioStreamPlaybackWAV 与 AudioStreamWAV 泄漏。现在正式退出也使用原有测试中已采用的两个混音周期排空等待；播放时不等待，不改音量或素材。候选三次 Main 及音乐、密集音效、暂停三种正式退出夹具均无警告，夹具故意不调用 `shutdown_for_test()`。

首次独立包暴露出 PresentationProfile 依赖编辑器插件 asset_review 的问题。把原有 SceneState 脚本检查原样移到运行时/编辑器共用的 scene_safety；保留根节点与子节点脚本拒绝检查，不通过删掉安全校验来绕过导出错误。原型包排除编辑器插件、原始制作资料、工作台、测试和开发工具，只复制明确标识的 local_qa 验证入口。

## 构建与运行证据

- 官方 4.7.2 标准模板归档已核对 GitHub 发布资产 SHA256，再安装 Windows x64 模板，保留原有 4.6.1。归档校验：`f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`。
- 导出使用真正的 Release 模板；生成 EXE 的 SHA256 与官方 release 模板一致，PCK 独立保存。普通启动不需要 QA 参数。
- 构建流程 7 项结果通过：冷导入、Release 导出、真实 BOOT 到菜单、实际校园挂起写入、另一个进程恢复生命 137/资金 1777、schema-2 旧档夹具迁移、包内正常 AI 校园交战撤离。只有冷导入保留两条既有 FBX 元数据警告。
- 将三文件包复制到含中文和空格的新目录，从 PATH 移除 Godot 并清除 GODOT_PATH 后，普通启动、再次读回、Forward+ 原生菜单、Compatibility 原生菜单及 Forward+ 原生校园路线都通过；菜单和实战截图已检查。
- ZIP 解压到另一个中文/空格目录后，三文件 hash 完全匹配，再次实际启动 EXE 恢复挂起存档通过。解压前后是同一版本，不冒充跨版本更新验收或干净虚拟机测试。
- 包内按源 manifest 的完整稳定 ID 集合核对 **36 项运行定义**，并核对 23 段人物对白 JSON 的完整文件 hash。早期注记中的“31”不能作为当前库存；本批未增加或删减物品定义。
- 包内正常 AI 自动路线：9 发、一次换弹、3 次击杀、回收物资并撤离。它使用自动移动/瞄准及部分交互 API，不是陌生玩家六委托通关。原生验证在本机 5090 上、音频使用 Dummy，不证明最低配置或真实听感。

源码最终隔离回归 `D:/tmp/bunny_release_20261019_final/`：**89/89 场景、126/126 结果通过，0 ERROR**，仅冷导入两条既有 FBX warning。Main 与三个新增正式音频退出子进程均要求零警告，不再把测试专用清理作为通过条件。3,696 个非文档文件与工作区、执行快照及实际构建源一致，结果日志 hash 已复核。见 [机器记录](local_windows_2026-10-19_validation.json)。

打包文件表审计覆盖1,429项：没有制作资料/编辑器插件/开发工具的原文件或其导入缓存，没有 Arcana 名称条目。它证明排除规则执行，不替代剩余资产的权利审查。

## 重复构建

`D:/bunny_team/tools/build_local_windows.py` 的 `--godot`、`--templates`、`--output` 是必填参数，`--smoke` 运行实际导出包。输出目录必须是仓库外尚不存在的新目录，不覆盖旧包，不上传文件；源工程只读。它在隔离副本中配置模板、排除制作文件、显式包含运行 JSON 并加入 LOCAL_ONLY QA，然后冷导入、导出、验证和记录 hash。

正式公开构建应在授权完成后另行去掉 QA 入口、补齐署名和发行材料；不能把这个带 LOCAL_ONLY 标记的包直接换名上传。

## 失败记录保留

- `D:/tmp/bunny_release_20261019_build01/`：导入日志 CRLF 使警告白名单误判，随后手动导出暴露运行时引用被排除的编辑器脚本。原日志、导出物和失败探针记录保留。
- `..._build02/`：Release 二进制不提供 `--script` 独立工具入口，不能沿用编辑器的 SceneTree CLI 探针。确认实际 `--help` 后停止自有进程，改为仅在本地构建中注入 Node QA；没有换用 debug 模板冒充 Release。
- `..._build03/`：BOOT 实际启动，但验证误沿用旧“31”统计。当前源清单一直为36；改为逐项比对当前源清单，而非降低覆盖或删掉断言。
- `D:/tmp/bunny_audio_exit_20261019_run01/probe_compile.log`：独立 SceneTree 入口过早使用 autoload 标识符的编译失败；最终 QA 使用正常 Node 生命周期。

## 发布门槛

可运行包不等于可分发许可、完整新玩家体验、实际硬件验收、公开页面或真实 80% 好评。本批未上传、未联系或冒充作者许可，未修改人物剧情或玩家个人存档。

标准 Windows 导出将独立运行二进制与项目 PCK 配合使用，见 [Godot Windows 导出说明](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)。模板来源为 [Godot 4.7.2 官方发布](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)；命令支持范围以实际 Release `--help` 及 [官方命令行说明](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) 为依据。
