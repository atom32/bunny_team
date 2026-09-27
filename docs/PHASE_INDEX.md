# Phase report index — Phase 4D consolidation

更新：2026-09-27。当前入口：[根 Handoff](../Handoff.md)。
运行内容 checkpoint：`main @ a40b7658f9fe282697ce6887a76d59ea2d64b94b`；Godot 4.7.2；内部 Demo，未 push。
Phase 4D 为后续文档提交，不改变运行内容。用 `git log` 查最新文档 HEAD。

## How to read

- **已提交**：文件存在于 `a40b765`；不代表其中全部工作区增量都已提交。
- **本地 WIP**：文件实际存在，但未跟踪或内容有未提交增量；本轮只链接，不代为提交。
- **本机 ignored**：不随 Git checkout 提供。没有该文件时明确报告缺失，不捏造证据。
- 历史报告保留当时结论；后续阶段只能覆盖对应问题，不能抹掉历史失败或扩大发行授权。
- `unitychan_battle_derivative/README.md` 顶部仍有 Phase 3B 的历史状态，**请定位所列阶段标题**，
  不要把“尚未 production replacement”读成当前状态。该文件自身 WIP 本轮不改。

## Phase index

| Phase / 实际阶段 | 真实报告与证据 | 历史结论 / 持久化状态 |
|---|---|---|
| **3A — Unity-Chan presentation spike** | [Derivative README](../art_source/unitychan_battle_derivative/README.md)，标题 `Phase 3A — Unity-chan Battle Costume Presentation Spike` | 当时 BLOCKED：手持姿态、材质/变形及旧 Face 断言；历史章节已提交，不是当前生产状态。 |
| **3A.1 — Static weapon pose diagnostic** | 同一 [README](../art_source/unitychan_battle_derivative/README.md)，`Phase 3A.1 — Static diagnostic checkpoint`；[static_measurements.json](../art_source/unitychan_battle_derivative/phase3a1/static_measurements.json) | BLOCKED：位置收敛不等于可信手持；没有独立 3A.1 README，不能编造。已提交。 |
| **3A.2 — Hand-pose authoring** | 同一 [README](../art_source/unitychan_battle_derivative/README.md)，`Phase 3A.2 — Hand authoring checkpoint`；[HAND_HIERARCHY.md](../art_source/unitychan_battle_derivative/phase3a2/HAND_HIERARCHY.md) | 历史 Gate A BLOCKED，保留真实手骨/姿态诊断。已提交。 |
| **3A.3 — Animation / switching / IK validation** | 同一 [README](../art_source/unitychan_battle_derivative/README.md)，`Phase 3A.3 — Final integration validation`；[completion_audit.json](../art_source/unitychan_battle_derivative/phase3a3/completion_audit.json) | 隔离 presentation 验证完成；轻微手滑/穿插限制已记录，当时旧 Face 测试仍为 32/33。已提交，不等同当时已替换生产玩家。 |
| **3B — Demo presentation polish** | [MATERIAL_LOG.md](../art_source/unitychan_battle_derivative/phase3b/MATERIAL_LOG.md)、[completion_audit.json](../art_source/unitychan_battle_derivative/phase3b/completion_audit.json)；同一 README 顶部 `Phase 3B — Demo Presentation Candidate — PASS` | 当时 Demo Candidate PASS，材质/装备优化；这些阶段报告为 **本地 WIP**。后续正式材质基线以 4B 为准。 |
| **3C — Production replacement readiness** | 同一 README 的 `Phase 3C — Production Replacement Readiness`；[completion_audit.json](../art_source/unitychan_battle_derivative/phase3c/completion_audit.json)、[DEPENDENCY_INVENTORY.md](../art_source/unitychan_battle_derivative/phase3c/DEPENDENCY_INVENTORY.md)、[READINESS_AUDIT.md](../art_source/unitychan_battle_derivative/phase3c/READINESS_AUDIT.md) | 技术迁移准备 PASS，270 个玩家武器对照样本；**本地 WIP**。READINESS_AUDIT 顶部仍写 IN PROGRESS，是早期审计，不覆盖最终 completion_audit。 |
| **3D — Production player switch** | [report_section.md](../art_source/unitychan_battle_derivative/phase3d/report_section.md)、[final_validation.json](../art_source/unitychan_battle_derivative/phase3d/final_validation.json) | `955ce1f`；实际 production Player 切换及旧 Face 测试的语义契约迁移，33/33。已提交；不是商用授权验收。 |
| **4A — Visual asset expansion** | [README](../art_source/visual_coverage_4a/README.md)、[ART_ASSET_COVERAGE.md](ART_ASSET_COVERAGE.md) | `10e9d82`；服务道具、Hanger/Office 装饰、柔和烟雾/尾迹。已提交；不是重做整个城市或 Terminal。 |
| **4B — Unity-Chan visual fidelity recovery** | Derivative [README](../art_source/unitychan_battle_derivative/README.md) 的 `Phase 4B — Unity-Chan Visual Fidelity Recovery`；[final_validation.json](../art_source/unitychan_battle_derivative/phase4b/final_validation.json)、[geometry_comparison.json](../art_source/unitychan_battle_derivative/phase4b/geometry_comparison.json)、[comparison.html](../art_source/unitychan_battle_derivative/phase4b/comparison.html) | `cc81d3034d364d51f213cb9b5d1128d1564222a6`；Face/Eyes/Hair PASS，官方几何保真、材质语义恢复，无人物生成/重塑。所列章节与证据已提交；不依赖未跟踪的 README_SECTION.md 副本。 |
| **4C — Combat VFX + Urban Arena cover** | [README](../art_source/phase4c/README.md)、[final_validation.json](../art_source/phase4c/final_validation.json) | `e915d21`；有边界的 C+D 子阶段，敌人替换当时 deferred，原三把武器保留。已提交。 |
| **4C.1 — KITE-07 enemy visual replacement** | [README](../art_source/phase4c1/README.md)、[final_validation.json](../art_source/phase4c1/final_validation.json)、[comparison.html](../art_source/phase4c1/comparison.html) | `a40b765`；production **visible presentation** PASS，33/33、两条完整撤离路线、360 个敌人开火对照；真实旧 firing skeleton 仍保留。已提交。 |
| **4D — Checkpoint / Handoff consolidation** | [Handoff](../Handoff.md) 的 Current checkpoint 区 + 本索引下方记录 | 本轮仅文档；运行内容、原测试和历史 WIP 保持。不新增虚构的独立阶段报告。 |

### Independent authorized fixes within Phase 4C chronology

- `d69b56c`：敌人离场后取消待执行射击回调；不是 AI、射速或伤害重设计。
- `ea16447`：只修 `AudioDirector.shutdown_for_test()` 的退出清理；不改正常音效或测试断言。
- 两者均已提交，细节/证据在 [Phase 4C README](../art_source/phase4c/README.md)。保留这两项授权边界，不能概括成历史敌人源码从未改过。

## Latest verification / local recording

- [33 项测试 + Main](../art_source/phase4c1/regression/results.json)；[fresh import](../art_source/phase4c1/cold_import.json)。
- [360-sample enemy contract](../art_source/phase4c1/contract.json)；[Rifle route](../art_source/phase4c1/route_Rifle/route_result.json)、[SMG route](../art_source/phase4c1/route_SMG/route_result.json)。
- [Rifle restart](../art_source/phase4c1/persistence_Rifle/reload.json)、[SMG restart](../art_source/phase4c1/persistence_SMG/reload.json)。
- [52-second playthrough](../art_source/phase4c1/local/playthrough_20260927/index.html)、[recording verification](../art_source/phase4c1/local/playthrough_20260927/recording.json)：**本机 ignored**，2026-09-27。
- 自动化 input/API ≠ 人工试玩；撤离成功 ≠ 所有任务完成；720p60 Movie Writer 输出 ≠ 持续性能认证。

## Phase 4D consolidation record

- 起点 `main @ a40b765`；本轮目标仅 `Handoff.md` current 区与本索引。
- 核对实际 Player/Enemy 引用、项目配置、Godot 4.7.2、最近提交、现有阶段报告和最终验证 JSON。
- 最新完整 gameplay 证据沿用 Phase 4C.1；4D 不重复 regression，不把历史结果标为本轮新测试。
- 根 Handoff 旧正文按原样留在折叠历史区；用部分暂存将已有 Handoff WIP 留在工作区。
  提交中的历史正文来自 `a40b765:Handoff.md`，不把此前未提交段落搭车入库。
- 完成时检查只有这两个 Markdown 文件进入提交；对照开始时文件 hash，确认其余 tracked/untracked 文件未改、未删。
- Commit message：`Phase 4D: consolidate project handoff checkpoint`。无 push、无 runtime/test 改动。
- **本轮不实施下一阶段**。顺序：4D → **4E KITE-07 legacy skeleton decoupling** → 4F fixed Demo route polish → 4G performance/release audit。
- 4E 的理由：新外观已投入使用，但旧 AvatarSample_A / humanoid rig 仍承担真实 fire contract，保留成本与授权阻塞。
  先建立行为等价，再移除依赖；保护 origin/direction/timing/hit/death 与 360-sample 对照，重跑全套验证。
