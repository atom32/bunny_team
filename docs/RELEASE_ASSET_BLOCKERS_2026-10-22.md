# 当前运行时资产的发行核对

以便携警铃 Windows 包的 `runtime_inventory.json` 和 `ASSET_LICENSE_MATERIALS.zip` 为准：31 个伴随许可成员及哈希吻合。核对文件齐全不等于每项资产的使用范围都已确定；这里仅列仍需确认的具体来源，不作法律结论。

| 实际入包资产 | 现有记录与待确认项 |
| --- | --- |
| `assets/characters/artoria_bunny/bunny_player.glb` | 当前可见主角。`art_source/artoria_bunny/README.md` 记录源文件未附许可，需确认模型作者的公开游戏分发范围以及底层角色权利。不能把用户提供源文件直接写成原创角色或已获发行许可。 |
| `assets/weapons/mocap_m4/M4_Rifle_01.fbx` 与四张 JPG | 当前 AR 使用的参考武器。相邻 `SOURCE.md` 记录来源和 Standard License 链接，尚缺与该网格／贴图对应的具体范围；16 段动作的额外许可不替代这五个文件的确认，派生弹匣和宣传渲染也需对应。 |
| `assets/characters/quaternius_scifi/SciFi.gltf` | 本地已附 CC0 文本，不应误说成作者禁止发行。现有 LICENSE 的 Males 标注与既有 Women 来源记录需要对上精确源包。 |
| `assets/characters/unitychan_battle/animations/` 中 idle、walk、run、slide 四段 FBX | 仍被导出依赖选中。伴随 UCL3 文本提及用于其他角色时另有适用条款，现有记录未完整说明这一用法；需要核对对应文本与实际用途，不据此直接断言允许或禁止。 |

## 已有记录不重复索证

- `local_motion/library.tres`：实际 16 段，按项目所有者确认的额外公开再分发许可处理；不要求重新证明同一授权，不上传整个 Unity 原包。
- `modern_arsenal` 的五款枪、`khairul_launcher` 以及 `quaternius_subject`／`quaternius_subject_female`：已有相应 CC0 来源／许可记录，保留原文与哈希。
- Arcana 和旧 VRM 模型不在这个运行时清单中。Arcana 作者由用户自行联系、转告回复，不轮询作者页面；它是将来替换候选的授权事项，不是当前包的独立阻断项。

目前不更换用户指定主角，也不替用户向作者发送消息或公开上传包。上述核对与首次试玩改进并行；后续若换资产，按真正选入的新清单重新确认，而不是把本地可玩包直接改名为公开版。
