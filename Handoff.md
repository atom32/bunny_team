# Bunny Team — Current Project Handoff

## 当前交接 — 2026-10-05 集成检查点

- 已提交并推送至 `main`：`c1cebae`（基于 `602b722`），整合 10 月 2–5 日的 Alpha 成长、经济、恢复、战术 AI、任务、操作设置及紧凑军事 Hideout。本文后续清理只修改文档。
- 当前功能入口与规则见 [README](README.md)；完整 Alpha 验收范围见 [验收审计](docs/alpha_0_1/ALPHA_ACCEPTANCE.md)。
- 最新已有验证来自 Windows / Godot 4.7.2 的紧凑 Hideout 最终快照：**59 个场景测试、79/79 验证项通过**，跨进程恢复与退出检查通过，冷导入 0 ERROR / 2 个已知 FBX warning。本次 macOS 同步未重跑，不能视为本机验收。
- 仍待验收：真人连续 10–15 局 / 2–4 小时的风险收益、内容节奏与听感；最低硬件目标及对应性能。可选表现改进：坐姿进入/退出混合、风扇/电台环境音。
- 下方紧凑 Hideout 是最新集成报告；历史批次中的 HEAD、WIP、未提交/未推送、测试数字和“下一步”仅描述当时状态，不能覆盖本节。临时目录与 Windows 路径是证据来源，不是跨机器运行依赖。

## 最新集成报告 — Compact mechanized Hideout integrated (2026-10-05)

- Approved 6x4m imported environment now replaces the exhibition shell in Hideout/menu. Hanger retains inventory/loadout/save ownership; camera-only hub, not a new walkable level.
- Floor-level character anchor; equipment preview restoration/rebuild preserved. Rest uses original Quaternius seated clip at a separate imported metal stool. Character GLB/materials/geometry unchanged (27 current Artoria source files SHA256 match).
- Free CC0 concrete/Poly Haven/Kenney resources, field locker, pipe bend and authored electrical cable dressing; local cold/warm lights. No purchase, procedural environment modeling or unrelated WIP reset. This integration is included in `c1cebae`.
- Exact-state 79/79 checks (59 scene tests) PASS; cold0errors/2knownFBX warnings, cross-process/quit probes PASS. C:/Users/admin/AppData/Local/Temp/bunny_compact_releasecheck_20261005. Final runtime/import asset hashes match snapshot. No renderer errors in actual Forward+ captures.
- Docs: scenes/presentation/compact_hideout/INTEGRATION.md. Durable actual menu/equipment/Operations/Workshop/Rest captures, scoped backups/diff and audit: art_source/hideout_mechanized_trial_20261005/.
- Optional next polish: ambient fan/radio audio, seated transition blend, lower-hardware profiling. Do not confuse this presentation integration with complete Alpha human endurance acceptance.


## 历史批次记录

<details>
<summary>展开历史实现、验证与交接记录（当时状态）</summary>

## Historical batch — Quaternius Hideout integration (2026-10-04)

- User authorized integration. Menu/base standing uses free CC0 Quaternius Idle; Rest uses Sitting_Idle at a new visual chair. Talking remains excluded.
- 52 body/finger rotations plus authored seated pelvis-height transfer; character asset hashes unchanged (170/170). Hanger restores equipment position/rig/animation; preview replacement and profile invariants covered.
- Fresh 59/59 tests PASS, cross-process readers PASS, main exit 0 / known ObjectDB warning, cold import 0 ERROR / 2 known FBX warnings. Evidence: C:/Users/admin/AppData/Local/Temp/bunny_quaternius_final_20261004.
- Actual menu/Rest/equipment Forward+ captures inspected. No seated entry/exit blending or mesh-level contact certification. No purchase/Unity install/commit/push; unrelated WIP preserved.
- Details: docs/QUATERNIUS_HIDEOUT_INTEGRATION.md; durable captures and scoped diff: art_source/free_animation_probe/sitting_20261004/integration/.


## Historical batch — Hideout entrance, idle and free animation pipeline (2026-10-04)

- Current HEAD main `602b722b6326a7821d5648386d3932796f48df04`; extensive existing WIP remains uncommitted. Do not reset, clean, stage-all or commit unrelated changes. No commit/push in this session.
- Current production character is **Artoria Bunny**, not the historical Unity-Chan player. Character mesh/proportions/textures/materials were not edited. Hidden existing combat animation driver remains unchanged.
- Main menu full-body framing and compact shared Hideout composition implemented; Operations contract panel is explicitly toggleable. See `docs/ALPHA_ENTRANCE_IMPLEMENTATION.md`.
- Hideout/menu use sourced pixiv MIT idle; Hanger equipment view restores armed preview. `scripts/presentation/slice/hideout_idle.gd` is Hideout-only, not gameplay. See `art_source/hideout_idle/README.md`. This gentle neutral idle still does not satisfy the requested relaxed/crossed-arms personality.
- Full verification after idle: **59/59** (58 existing + one real Hideout idle contract test), main exit 0, cold import 0 ERROR / 2 known FBX UTF-8 warnings, cross-process readers PASS; 170 character asset hashes unchanged. Evidence: `C:/Users/admin/AppData/Local/Temp/bunny_idle_final_20261004`. Not rerun for the later isolated animation experiment.
- User downloaded Mainichi Pose Free v3.1; inspected only in temp. It contains Unity Humanoid muscle curves, NOT directly importable bone clips. No usable Unity Editor found; user declined pursuing that conversion. No model posing by guessed muscle-to-Euler conversion.
- User requested **free resources first**. Quaternius UAL Standard downloaded (CC0, 43 clips, 65 bones). Native GLB imported in Godot 4.7.2; Idle and Idle_Talking retargeted across 22 body bones in an isolated project. 480 sampled frames / 8s video. User saw preview and said “看着还行”. This is positive feedback, NOT authorization to claim final full-body/contact acceptance.
- Evidence/source/driver: `art_source/free_animation_probe/` (Godot-excluded via .gdignore), especially VALIDATION.md, SOURCE.json and evidence/preview.mp4. No Quaternius clip installed in production. Fingers remain target rest; seat/root-height/foot contacts unverified. Source motion is broad-stanced; talking hands are close. No crossed-arms clip confirmed.
- Next safe step: continue free animation trial (e.g. Sitting_Idle), validate chair/foot contact and body/finger mapping, then minimally integrate a suitable presentation clip only after visual acceptance. Do not buy assets, install Unity, invent poses, or alter character geometry. Keep existing armed preview restoration and save semantics.

## Historical batch — Alpha selectable relay operation (2026-10-03)

- Post-tutorial Operations now chooses Records Run or Restore the Relay. Repair municipal-office and repair-shop stations for 12s each, in either order, then extract. Leaving/damage cancels current attempt; local repair noise uses existing hearing. No material cost/new enemies.
- Records are optional in repair missions and still open the alternate exit/trigger their alarm. Unconditional retreat remains available. Existing objective/result/reward persistence owns progress; the final base contract accepts either operation, preserving earlier progress.
- Partial repair persists through pause/restart, including actor/session rebinding. Actual fractional health loss cancels too. Added completion-signal HUD refresh; no combat/AI values or character assets changed. This is a real mission gameplay addition, not cosmetic-only.
- **57/57 full tests PASS**, new operation 37 checks, second-process repair 5 checks. Normal Operations UI -> deployment -> battle 6 checks; English/Chinese UI inspected. Real AI relay combat route: 24 shots, 2 reloads, 8 kills, both repairs + loot + extraction/settlement. Automated, not human balance evidence.
- Cold import 0 ERROR / 2 known FBX warnings; Main exit 0 / known ObjectDB warning. Existing route/save probes PASS. 2381 asset/source/scene/config files unchanged; content manifest intentionally registers one new mission. No removal/stage/commit/push, user WIP preserved.
- Full Alpha **IN PROGRESS**: target-hardware performance, readability/audio, multi-sortie human risk/reward and pacing remain. [Operation rules/evidence](docs/alpha_0_1/RELAY_OPERATION.md).

## Historical batch — Alpha keyboard/mouse settings (2026-10-03)

- Main Menu settings and pause menu now expose 13 primary keyboard/mouse bindings. Draft/apply/default reset, duplicate/reserved-key validation, local device persistence and failure-safe runtime publication; controller events and gameplay values preserved.
- Real interaction/loot/extraction/medical/switch/map/tutorial prompts show bound keys. Route map now consumes its input action rather than hard-coded M. Old test callback migrated to actual input events; its assertions retained.
- **56/56 tests PASS**, new controls scene 36 checks plus 3 independent-process checks. Actual F terminal interaction and N map toggle verified. Forward+ English/Chinese UI inspected. Full route and existing save/load probes PASS; cold import 0 ERROR / 2 known FBX warnings; Main exit 0 with known ObjectDB warning.
- 2437 asset/source/scene/resource/config files unchanged; no files removed, no stage/commit/push. User WIP preserved. [Controls scope/evidence](docs/alpha_0_1/CONTROLS.md).
- Full Alpha **IN PROGRESS**: additional site-purpose variety, target-hardware performance/readability and 10–15 human sorties / 2–4h balance remain unproven. Keyboard settings do not constitute full Alpha acceptance.

## Historical batch — Alpha records alarm (2026-10-03)

- Recovering records starts a visible 25-second simulation countdown. A single local alarm makes audible existing guards investigate the terminal, not track the player. Walls attenuate sound; visual combat takes priority. No new enemies or exit closures.
- Pause/save/restart preserve remaining time. Old completed records do not retroactively trigger an alarm. Existing route/map communicates the consequence before interaction. Audio currently reuses UI cues, not an authored siren.
- **55/55 tests PASS**, all 54 previous scenes retained; records event 46 checks, independent process resume 7 checks. Full graphical Field Office route and other cross-process probes PASS. Cold import 0 ERROR / 2 known FBX warnings; Main exit 0 with known ObjectDB warning.
- Controlled Forward+ 1280×720 before/warning/spent English/Chinese screenshots inspected, not human playtesting. 2437 protected asset/source/scene/resource/config files unchanged; no removal/stage/commit/push. User WIP preserved.
- Full Alpha **IN PROGRESS**: varied site objectives/events, settings/readability, performance and 10–15 human sorties remain. [Rules and evidence](docs/alpha_0_1/RECORDS_ALARM.md).

## Historical batch — Alpha exit/site-objective choice (2026-10-03)

- Of Streets' existing two assigned exits, the farther remains unconditional retreat; the other requires this sortie's records objective. Survey/full mission completion is not required to extract. Existing unassigned exits remain closed; no layout/AI/player changes.
- M map and proximity interaction state conditions explicitly; recorded objective progress opens the alternate route and survives session restore. Existing extraction/result/warehouse settlement remains the owner.
- **54/54 full tests PASS**, 35-check exit fixture across all six spawns; final rendered locked/unlocked en/zh map checked. Full route/cross-process PASS, Main exit 0 with known ObjectDB warning; cold import 0 ERROR / 2 known FBX warnings. [Rules/evidence](docs/alpha_0_1/EXIT_CHOICES.md).
- Full Alpha **IN PROGRESS**: predictable events/site variety, settings/performance and human multi-sortie validation remain. No commit/push; source/character assets and unrelated WIP preserved.

## Historical batch — Alpha regional resource geography (2026-10-03)

- Existing Streets rooms now have distinct normal-loot pools: office electronics/wiring/data, pharmacy medicines/fabric, apartments fabric/salvage, repair shop parts/wiring/propellant. Eight existing ordinary points reassigned; four high-value and six street points, enable odds and node counts unchanged. No new material IDs, map rebuild, spawn/collision/nav changes.
- M route map explains resource tendencies in English/Chinese without disclosing live loot/enemies. Resources feed actual clinic/workbench/fittings/ammunition needs. Existing four exits/two assigned exits remain; richer exit conditions/site objectives are still outstanding.
- **53/53 tests PASS**, new regional 37-check test with 2000 rolls per table, actual bindings and exact saved-loot restore; graphical map inspection PASS. Full route/cross-process checks PASS, Main exit 0 with known ObjectDB warning; fresh import 0 ERROR / 2 known FBX warnings. [Regional rules/evidence](docs/alpha_0_1/REGIONAL_LOOT.md).
- Full Alpha **IN PROGRESS**. Next: meaningful extraction/site-objective tradeoffs and predictable events, then settings/performance/human multi-sortie validation. Unrelated WIP/player assets preserved; no commit/push.

## Historical batch — Alpha exact ammunition packing (2026-10-03)

- Normal Hideout Operations now chooses per-caliber total rounds (including magazines), with actual inventory/capacity preview. Default three magazines is exact, not an oversized whole stack. Shared-caliber weapons share one quantity. Medical choices remain available.
- Production Hanger deployment splits only a candidate warehouse and atomically saves it with the initial checkpoint before publishing. Base remainder keeps its old ID; carried partial stack gets a new ID. Failed writes change neither inventory nor disk. Death/extraction/restart preserve exact quantities.
- **52/52 full regression PASS**; newest packing checks 48/48; second-process restore/failure 6/6; rendered normal Operations → Deployment → Battle 6/6, HUD 30+7 for selected 37. Main exit 0; cold import 0 ERROR / 2 known original FBX warnings. See [Packing](docs/alpha_0_1/PACKING.md) for evidence scope and last UI/test additions.
- Full Alpha **IN PROGRESS**. Next: inspect and connect regional resources, site objectives and extraction choices; settings and multi-sortie human validation remain. No commit/push; unrelated WIP and character assets preserved.

## Historical batch — Alpha instance-owned weapon fittings (2026-10-03)

- Workshop now has one utility fitting per eligible owned firearm after the workbench unlock: quickloader (reload ×0.8, +0.8kg), suppressor (enemy gunshot hearing ×0.5, reload ×1.15, +0.35kg). Exact materials/credits, save-before-publish, no refunds on removal/replacement. Original weapon IDs/resources and character assets unchanged.
- Fits persist with the weapon through deployment, checkpoint and extraction; death loses both. Instance weight flows through inventory, deployment, recovery and UI. Old missing field means standard; invalid/incompatible fit rejected. This is functional modification, not new mesh/sound production.
- **51/51 tests PASS**, new 48-check fitting test; cross-process fitting read PASS (3 checks); en/zh rendered component checks PASS (50). Existing full Field Office route PASS; cold import 0 errors/2 known FBX warnings; Main exit 0 with known exit warning.
- Full Alpha remains **IN PROGRESS**. Exact ammunition carrying, regional resource/exit decisions, settings and multi-sortie human balance still outstanding. No commit/push, user WIP preserved. See [Fittings](docs/alpha_0_1/FITTINGS.md).

## Historical batch — Alpha persistent contracts / functional base unlocks (2026-10-03)

- `main @ 602b722`, uncommitted Alpha work and preserved user WIP. Full [Alpha 0.1](docs/ALPHA_0_1.md) remains **IN PROGRESS**; no commit/push.
- Production Hideout Overview now exposes a five-step chain after First Mission: two recon extractions, clinic material delivery, ammunition-bench delivery, eight survival-confirmed kills, then three further recon extractions. Claims grant one-time credits and actual facilities: medkit assembly, AP crafting, equipment buy discount. Free sorties remain playable after the explicit endpoint.
- Progress records only inside successful idempotent result settlement; failed sorties cannot bank kills, previous settled progress survives. Deliveries consume exact warehouse quantities. Save-before-publish claims protect materials/rewards; stale button IDs cannot claim a different next contract. Active/suspended sorties and recovery lock base claims.
- Schema **4** includes validated campaign stage/progress. Schema 1/2/3 preserves inventory IDs, tutorial and AR upgrade while beginning the new chain without invented history. Facilities derive from claimed stages. Pending sortie, medicine, loss and settlement rules remain.
- Chinese/English normal base UI, Result projected-progress panel, relevant Loot material highlighting, Workshop facility recipes and actual discounted buy prices are integrated. This is gameplay progression/economy/save-field work, not a cosmetic-only change. Player/character art, weapon stats/projectiles, AI, layout/collision/navigation unchanged.
- **50/50 scene tests PASS** (previous 49 + campaign with 95 checks), five quit paths, normal/forced-termination/medical sortie recovery and additional campaign cross-process continuation (9 checks) PASS. Cold import 0 ERROR / 2 known FBX warnings; Main exit 0, known 2-instance ObjectDB exit warning retained.
- Forward+ 1280×720: actual UI Return → claim → delivery → craft → restart/load, 43 + 15 checks PASS, English/Chinese images inspected. Explicit prior-mission/loot/API fixtures; not manual or full combat footage. Separate normal Streets combat/loot/extraction route earned the second contract step (27 shots, 9 kills). Field Office route PASS.
- 2489 protected source/assets/player/enemy/world/resources/scenes/config files unchanged against this batch's snapshot; no old file deleted or staged. [Rules and limits](docs/alpha_0_1/CAMPAIGN.md), [evidence](docs/alpha_0_1/campaign_validation.json).
- Next: limited equipment attachments and carrying decisions, resource geography/site objectives/extraction choices/settings, then human multi-sortie validation. Current five contracts still reuse Streets Recon and ordinary material distribution; **not evidence of 10–15 interesting sorties / 2–4 hours**. No full narrative campaign or new physical clinic room is claimed.

## Previous Alpha batch — Tactical duties (2026-10-03)

- `main @ 602b722`, uncommitted Alpha work; user WIP preserved. Full [Alpha 0.1](docs/ALPHA_0_1.md) remains **IN PROGRESS**. No commit/push.
- Actual guard/patrol/flanker/pressure decisions now differ: defend a post with a 6 m investigation leash, retain patrol spacing, navigate to a reachable side firing position, or close to 4.5 m standoff. Only observed/remembered contact informs decisions. No damage/speed/HP/rate buff or squad omniscience.
- Normal Streets assigns duties to the original 10 spawn points; existing heavy KITE defaults to pressure. Positions, spawn eligibility, geometry/collision/navigation, player/art, weapon/projectile parameters and economy are unchanged. This IS an AI behavior change, not cosmetic-only work.
- Flank plans reject walls, closed doors, occupied positions and disconnected navigation; hold if no valid route. Replan at 4 s or a 3 m observed-contact change. Real collision still blocks a newly closed door before the next replan. No door-opening AI or full squad system.
- Tactical duties/plans/timers persist in the existing checkpoint. Pre-role saves restore authored duties without fabricated plans and preserve the complete old world. Wrong/malformed role data rejects atomically.
- **49/49 scene tests PASS** (48 retained + actual tactical-role scene, 62 checks); checkpoint test 117 checks, 5 quit paths, normal/forced-termination/medical cross-process recovery PASS. Cold import 0 ERROR / 2 known FBX warnings; Main exit 0, known 2-instance ObjectDB exit warning remains.
- Forward+ 1280×720: controlled roles 10 checks PASS with actual movement and damage; Streets combat/loot/extraction/warehouse PASS (27 shots, 1 reload, 9 kills); Field Office route 13 checks PASS (not mission completion). Automated evidence, not human difficulty certification.
- 2464 protected assets/source/player/combat/scenes/config files match this batch's before snapshot; no previous file removed or staged. [Rules/reproduction](docs/alpha_0_1/TACTICS.md), [machine results](docs/alpha_0_1/tactics_validation.json).
- Next substantive work: persistent quests/rewards/unlocks, useful base facilities and limited attachments; resource geography/extraction choices/settings, then 10–15 human sorties. Do not call the full Alpha complete.

## Previous Alpha batch — Player visibility / aim-cover consistency (2026-10-03)

- `main @ 602b722`, uncommitted Alpha work; user WIP preserved. Full [Alpha 0.1](docs/ALPHA_0_1.md) remains **IN PROGRESS**. No commit/push.
- Real player sight hides unobserved enemies/markers independently of camera-faded walls. Aim follows the existing controls; facing cone/range/real door and wall collision govern observation. Unseen actors retain physics, attacks and damage. Tutorial pointers, aim picking, origin VFX and corpses no longer disclose their exact hidden position.
- Short eight-sector sound bearings; enemy gunfire attenuates with range/walls. Movement cues read actual enemy travel; dedicated footstep Foley is still pending. This is not live radar or binaural audio.
- Amber centerline/cover feedback uses the same effective muzzle as firing. **Intentional gameplay correction:** a barrel crossing cover cannot spawn a shot beyond it; ammo is still spent. Clear-space origins remain exact. No weapon stats, actor art, camera-occlusion implementation, arena layout, save format or economy changes.
- **48/48 scene tests PASS**, 5 exit paths, normal/crash/medical cross-process recovery, Main exit 0. New visibility test now has 44 checks (42 in full run + two added real footstep checks rerun together); runtime source is byte-identical to the full-run snapshot. Cold import 0 ERROR / 2 known FBX warnings; known 2-instance ObjectDB exit warning remains.
- Forward+ 1280×720 controlled visibility/cover evidence, real Streets combat/loot/extraction (27 shots, 1 reload, 9 kills, 2.88 damage taken) and Field Office 13-check route PASS. Automated input/API, not manual play; Field Office route is not first-mission completion.
- Old acceptance now checks local renderable KITE asset rather than unconditional visibility; existing damage/breach assertions unchanged, fixture moved out of the entry-cover collider. No test removed/suppressed. 2111 protected character/source/config files unchanged; no prior file deleted.
- [Rules, limits and reproduction](docs/alpha_0_1/VISIBILITY.md), [machine results](docs/alpha_0_1/visibility_validation.json). Next: substantive tactical roles and persistent quests/rewards/unlocks, functional base facilities and limited attachments; then resource geography/extraction choices/settings and multi-sortie human balancing. Do not call the full Alpha complete.

## Previous Alpha batch — Enemy perception / search / disengagement (2026-10-03)

- `main @ 602b722` + uncommitted Alpha work and preserved user WIP. Full [Alpha 0.1](docs/ALPHA_0_1.md) remains **IN PROGRESS**; no commit/push.
- Enemies now require range/facing/real line-of-sight and acquisition time, hear localized gunfire/footsteps/doors/explosions/alarms, investigate remembered positions and eventually disengage to local patrol. Camera transparency does not grant sight. Shift precision walking is quieter. Human/KITE detection profiles differ; this is not full squad tactics.
- Enemy knowledge and player footstep cadence persist in the same sortie checkpoint. Old snapshots without those optional fields resume a local patrol rather than inventing hidden-player information. Existing actor/ammo/world/attack state remains intact.
- Actual changes are enemy AI/perception decisions and auditory stimuli, not cosmetic-only changes. Weapon definitions/stats, projectile parameters, normal movement values, collision shapes, arena layout and all character art/source remain unchanged. 2100 protected files match the before snapshot.
- Validation: **47/47 scene tests**, 58 new perception checks, checkpoint 110 checks, five exit paths, normal/forced-termination/medical cross-process recovery PASS. Rendered human/KITE encounters each pass 15 checks including real player damage and natural disengagement. Streets combat/loot/extraction and Field Office 13-check route PASS. These are automated, not human pacing tests.
- Cold import: 0 ERROR / 2 known source-FBX warnings. Main exit 0 with known 2-instance ObjectDB exit warning. A reproduced focus-loss busy-tree pause UI bug is fixed by deferred creation, with two additional P0 flow assertions; normal pause/save/abandon semantics unchanged.
- [Rules/evidence/limits](docs/alpha_0_1/PERCEPTION.md), [machine results](docs/alpha_0_1/perception_validation.json). Next: player visibility separate from camera fading, aim/cover feedback, then persistent quests/facilities/attachments/resource geography/extraction choices and human multi-sortie balancing. Do not call the full Alpha complete.


## Historical batch — Alpha 0.1 economy, sortie recovery and medical use (2026-10-03)

- `main @ 602b722` plus uncommitted Alpha work and preserved unrelated user WIP. No commit/push in this Alpha task. Full goal: [ALPHA_0_1.md](docs/ALPHA_0_1.md), **IN PROGRESS**, not a completed Alpha.
- New profiles have finite starting equipment/credits. Death/abandonment now lose actual carried equipment and ammunition, not base stock. Workshop supply offers purchase/sale/barter and restricted failure recovery; existing possessions retain their IDs. Loading no longer reissues the full arsenal.
- Normal production deployments now persist an active sortie. Esc suspend/menu/quit and window close save it; the main menu resumes that same battle rather than the old base state. Save schema 3 accepts schema 1/2. Pending sorties lock base transactions/new deployment; result settlement atomically clears the checkpoint.
- Resume includes actual ammo/health/loot/enemy/death/door/destructible/mission/reinforcement/countdown/rocket state. Enemy firing pose and pending attack timer are restored without changing the authored model or normal attack timings. No player model, texture, official source or player controller edits in this recovery batch.
- Medical: Workshop purchase/barter and Streets loot; Operations packing counts; H dressing (40 HP / 2.5s), J medkit (100 HP / 5s). Stationary, interruptible, consume on completion only, actual carried weight/loss/settlement. Pending treatment resumes with remaining time. No automatic medicine grants; existing finite starter inventory unchanged. [Rules and evidence](docs/alpha_0_1/MEDICAL.md).
- Latest isolated verification: **46/46 scene tests**, 5 quit paths, normal cross-process and verified-live forced-termination recovery, additional cross-process medical recovery, graphical medical purchase/packing/treatment/resume/result route and Field Office route PASS. Main exit 0, known ObjectDB exit warning remains; cold import 0 ERROR / 2 known source-FBX UTF-8 warnings. [Recovery evidence and limits](docs/alpha_0_1/SUSPEND.md), [economy evidence](docs/alpha_0_1/validation.json), [medical run](docs/alpha_0_1/medical_validation.json).
- Explicit suspend saves current state; forced termination can roll back to the last successful periodic save (about 2 simulation seconds). Short-lived VFX/ragdolls/UI are not persisted. Incompatible layouts stop with the file preserved. These are automated checks, not a human long-session pacing or performance certification.
- Remaining Alpha work: tactical perception/search/disengagement, player visibility rules, persistent quests/facilities/attachments, resource geography/extraction choices, settings, and sustained human playtesting. Medical timing/prices and economic balance still need human play; medical animation is not authored yet. Do not call the current work complete merely because regressions pass.

## Historical checkpoint — First Mission, Streets, bilingual UI and spatial warehouse (2026-10-01)

- Godot 4.7.2 / Forward+, normal entry `scenes/presentation/slice/boot.tscn`. This checkpoint collects the improvements since `41c4db5`; the older sections below retain historical context.
- [First Mission](docs/FIRST_MISSION.md) is an authored tutorial sortie with investigation, alarm reinforcements, optional extra salvage, timed extraction and a single permanent Workshop upgrade: 1 Salvage Core → AR damage 20 to 22. Manual AR-primary/SMG-secondary loadouts can deploy. The 8–10 minute target still needs a newcomer timing pass.
- [Armor](docs/ARMOR_TRADEOFF.md) now trades mobility for actual protection: light 10% reduction / 3 kg, heavy 40% / 8 kg. HUD and equipment readouts use runtime calculations.
- After the first mission, [Streets](docs/STREETS_DISTRICT.md) provides six randomized spawn candidates, two assigned exits, randomized investigation, four enterable interiors and indoor/outdoor loot. Camera orientation stays fixed; occluders fade. Six combat-active automated routes have passed; this is not human difficulty validation.
- Seven weapons and the scarf-free imported Bunny remain playable. The production AR uses the MCO pack M4 and calibrated hand IK. The [master-shot study](docs/bunny_master/README.md) is not a final visual standard; MCO pose samples are not a replacement for gameplay locomotion.
- English / Simplified Chinese can switch live; new launches default to Chinese until a preference is saved. Font and translations are bundled. Fullscreen, window resolution and F11 are available. The compact battle HUD and tutorial preserve the central view.
- Hanger warehouse has item footprints, model thumbnails, native mouse drag/drop, R rotation, sorting, selected-item details and persistent cell positions. Drag equipment icons to unequip or swap slots; names retain dropdown selection. Grid rows grow for recovered items; no finite-slot capacity or nested containers are implemented.
- Existing P0 pause, recovery, atomic save and ammunition conservation remain. Death/abandonment preserve pre-sortie warehouse equipment; Continue restores base state, not an interrupted battle.
- Narrative chapters/Bosses remain design documents. Original-source/asset notices remain in [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md). Model/material fidelity, manual first play and target-platform performance remain open.
- This checkpoint verification: **43/43 scene tests**, **5/5 actual quit paths**, Main and a graphical warehouse probe pass. Cold import has zero errors and two known source-FBX UTF-8 metadata warnings; Main retains its known ObjectDB exit warning. Evidence: [checkpoint report](docs/checkpoint_2026-10-01/README.md).
- Validation tooling now expects the current 43 test scenes. Recent targeted evidence is in `docs/stash/`, `docs/localization/`, `docs/hud_layout/` and `docs/streets/`. Use isolated saves for all checks.
- The discussion about separating base presentation from a dedicated warehouse screen is a proposed next UI change; it is not implemented in this checkpoint.

## Historical working tree — P0 recovery / shared rendering / modern arsenal (2026-09-30)

- `main @ 41c4db5` plus uncommitted WIP. An earlier requested pull brought in the recent upstream work; this implementation is not committed or pushed.
- Godot 4.7.2 / **Forward+ desktop + 4× MSAA**; shared AgX/environment reflection/SSAO/glow in `scripts/systems/render_profile.gd`. Compatibility launch fallback remains. Normal Boot → Hideout → Hanger → Battle → Result loop remains.
- Seven modern weapons: P9, SMG-9, AR-556, S12, R7, LMG-56 and separately textured RPG. See [arsenal](docs/MODERN_ARSENAL.md).
- Visible player: user-selected **Artoria Bunny Suit with scarf hidden**; imported geometry, baked textures, 157,293 triangles, 52 display joints and 11 meshes. Existing Unity-Chan locomotion remains a hidden driver; original Unity-Chan geometry/textures were not edited. Source blend remains unchanged. This is an internal prototype, not commercial asset clearance.
- Actual enemies now include imported Quaternius SciFi human patrols and KITE drones. Human death keeps authored geometry/animation; player defeat keeps the skinned model with a posed fall. This is not full physical ragdoll animation. No procedural human/NPC mesh was added.
- Current runtime evidence, reproduction and remaining limitations: [model trial](docs/ARTORIA_BUNNY_TRIAL.md). Human package provenance has an inherited Males/Women notice mismatch; it is explicitly recorded, not silently approved.
- P0: strict save validation + atomic temp/backup replacement + explicit corrupt-save recovery; bounded ammo deployment with visible errors; magazine conservation/weight; atomic result commit/save/retry; warehouse overflow recovery; shared Esc/pause/resume/abandon/base/menu/quit flow, including window close and pending enemy-shot timers. Continue starts at the saved base, not a mid-mission checkpoint. See [updated demo audit](docs/DEMO_READINESS_2026-09-28.md).
- Verification: fresh cold import 0/0, **37/37**, **5 actual quit subprocess paths**, and a Forward+ graphical route passing **13 checks**, normal AI, 58 shots / 3 damage / 0 kills, `mission_completed=false`. Main exits 0 without script errors; forced headless `--quit-after` retains the known 2 ObjectDB instances warning. Latest targeted checks passed after the final cleanup. All profiles isolated; no personal-save modification. [Machine report](docs/p0_verification/verification.json), [UI captures](docs/p0_verification/presentation/05_pause_battle.png).
- Forward+ presentation route also exercised menus, deployment, pause, abandonment, return, save failure and corrupt-save recovery on Apple M5. Short 90-frame battle sample: median 16.708 ms, p95 18.217 ms; not a performance certification. Compatibility fallback rendered successfully. Windows rendering and manual first-player acceptance remain unverified. Temporary Artoria geometry/textures were not revised in this pipeline pass.
- [Narrative production package](docs/narrative/README.md): all seventeen requested sections, twelve chapters, eight bosses, eight adult supporting women, six factions, eighteen key scenes, five relationship scenes, five endings and the first chapter's 95 lines. This is original design work; those chapters, NPC cast and boss encounters are not implemented yet.
- Preserve pre-existing importer WIP and local files. No reset/clean/stash, automatic commits or removal of original character assets. The old Unity-Chan source restrictions still protect those original files; the user's new Artoria trial authorization changes the visible player choice.

The sections below are historical. Their player choice, test counts and earlier scope restrictions describe those checkpoints, not this working tree.

## Historical checkpoint — Phase 5 + portable development sync (2026-09-27)

- Branch `main`; runtime baseline **`bc4984b`** (Phase 5), enemy decoupling **`7ddb981`** (Phase 4E).
- **Godot 4.7.2 / GL Compatibility**; normal entry `scenes/presentation/slice/boot.tscn`.
- Flow: **Boot / Opening → Main Menu → Hideout → Mission → Deployment → Urban Arena / Field Office → Combat / Loot → Extraction → Debrief → Hideout**.
- Production Player: Unity-Chan Battle Costume; official geometry/textures and Phase 4B material semantics remain locked. Production Enemy: native KITE-07; **no AvatarSample_A / legacy humanoid skeleton runtime dependency**.
- Phase 5 retained verification: **33/33**, two graphical routes **64/64 each**, cross-process save/load PASS, cold import **0 ERROR / 0 WARNING**, Main exit **0** (known ObjectDB exit warning). See `art_source/phase5/README.md`; these are automated graphical routes, not manual playtesting.
- This sync versions the missing original FBX texture dependencies, 4.7 import configuration, byte-identical legacy-source relocation, recovered official authoring sources, and source/validation records. No gameplay or production character edits.
- Blender master repair is **four relative image paths only**; no geometry/rig/action/material-semantics change. Character leg-length investigation: `docs/CHARACTER_PROPORTION_CHECK.md`.
- This sync's **staged-only clean-copy** rerun: **33/33**, cold import **0/0**, Main **exit 0 / no warnings**; exported official source **68/68** hashes match. Graphical routes/save-load above are retained Phase 5 evidence, not newly rerun.
- New-machine setup and exact clean-index verification: **`docs/DEVELOPMENT_SETUP.md`**. Screenshots, videos, personal saves, cache and unrelated trial scripts are deliberately not part of this sync; local copies remain untouched.
- Internal demo only. This sync does not grant or re-audit release rights. Retain all existing license/source notices; do not use Unity-Chan as AI input.

**Read this section and current code first. All reports below retain their historical phase context; old “current”, “BLOCKED”, “not production”, rig-dependency and no-push statements do not describe this checkpoint.**

## Historical checkpoint — Phase 4D (2026-09-27)

- 项目：**Neon Bastion / Bunny Team**，日系科幻机娘俯视角撤离射击游戏；`D:\bunny_team`。
- **运行内容基线：`main @ a40b765`**（完整 SHA：`a40b7658f9fe282697ce6887a76d59ea2d64b94b`）。
- Godot **4.7.2**；当前本机配置为 GL Compatibility，入口 `scenes/hanger/hanger.tscn`。
- **Internal Demo checkpoint / Not pushed**。Phase 4D 只追加文档提交，最终 HEAD 请用 `git log` 确认；运行内容基线不变。
- **可完整跑通、可录制展示的内部 Demo；不是内容完整版本，也不是公开发行版本。**
- 工作区有意保留历史 WIP。验证描述的是本机含 WIP 的工作区，**不保证仅 checkout 此 SHA 就能复现全部本地证据或迁移状态**。

## PLAYER CHARACTER HARD RULE

> Do not procedurally generate, reshape, sculpt, remodel, AI-edit,
> or regenerate Unity-Chan character geometry or character textures.
>
> Official source is immutable.
>
> Current visual issues must be solved at presentation/material/lighting
> level unless explicitly authorized otherwise.

玩家 geometry、贴图、官方包均锁定；不要把 Unity-Chan 送入 AI workflow。
保留 `Chest / ShoulderL / ShoulderR / Backpack / HipL / HipR / HandL / HandR`。
不要为敌人或环境问题修改玩家。Phase 4D 不修改任何材质、灯光、模型或运行代码。

## Current gameplay flow / ownership

```text
Hanger → Sortie → Field Office / Terminal → Urban Arena combat
       → Extraction → Result → Hanger
```

Field Office 是 Sortie 的 Urban Arena 内部区域，不是新增的独立关卡切换。
Player/Enemy controller 继续拥有 gameplay，视觉 asset/adapter 不拥有游戏状态。
Person/逻辑身份、WeaponDefinition、weapon IDs、伤害、射速、弹药、换弹、移动、闪避、
碰撞、AI、导航、spawn、交互、撤离、经济、Warehouse / Save / Result contract 均保持原有语义。
存档 schema 1 保留 owned-item IDs / loadout / inventory；**没有独立 Person ID 字段，不要补造**。
艺术扩展未重设计 gameplay；历史独立授权修复仅包括离场射击回调保护 `d69b56c`
和测试退出音频清理 `ea16447`，不能据此扩大后续 gameplay 改动范围。

## Current visual state

| 模块 | 当前实现与边界 |
|---|---|
| Player | **Unity-Chan Battle Costume 已是 production player**（`955ce1f`）；Face / Eyes / Hair 材质语义已恢复（`cc81d30`）。官方 source 68/68 hashes unchanged；无程序化人物生成、无人物 mesh remodeling。不是 Unity UTS 像素级复刻声明。 |
| Weapons | AR / SMG / Rocket；原有握持/挂载、切换、换弹和射击已验证，没有新增 weapon ID 或 gameplay。 |
| Enemy | **KITE-07 已是 production enemy presentation**（`a40b765`）；仅替换可见模型，旧 AvatarSample_A 及 humanoid firing rig **仍实际加载并参与运行**，不是 enemy system fully migrated。 |
| Environment | Hanger / Field Office 服务道具、装饰；Urban Arena 八处既有 cover 的视觉外壳。没有重写布局、碰撞或导航。 |
| VFX | muzzle flash、hit、smoke、rocket trail、dodge、death 已有覆盖；不等于全套最终品质。 |

当前事实以本页 + 当前代码 + 对应最新阶段证据为准。
历史报告中的 “BLOCKED / 尚未替换玩家 / 32/33” 是当时阶段状态，不能覆盖 Phase 3D/4B/4C.1 结果。

## Verification state — retained evidence, not rerun in Phase 4D

最新完整验证来源：[Phase 4C.1 报告](art_source/phase4c1/README.md)、
[最终验证](art_source/phase4c1/final_validation.json)、[原测试结果](art_source/phase4c1/regression/results.json)。

| 项目 | 最近已完成的结果 |
|---|---|
| Tests | **33/33**；Phase 4C.1 未改原测试，Phase 4D 也不修改测试 |
| Fresh cold import | **0 ERROR / 0 WARNING**，独立新副本，不复用旧缓存 |
| Main exit | **0**；仍有已知 **2 ObjectDB instances leaked at exit** 警告，不声称 warning-free |
| Graphical routes | **两条 PASS**，Rifle+Rocket / SMG+Rocket，各 39 项检查；包含敌人交战、死亡、撤离和返回 |
| Cross-process save/load | **PASS**，各路线独立重启后五项检查；仓库合并/装备身份保持，使用真实存档副本 |
| Enemy fire comparison | **360 samples PASS**；origin / direction 差值为 0，同时检查碰撞、导航、死亡物理与 RNG |
| Unity-Chan official source | **68/68 hashes unchanged** |

证据在 `art_source/phase4c1/`；本阶段只读核对内容、路径、代码引用和 Git 范围，**不重新冒领一次回归 PASS**。

[2026-09-27 Playthrough](art_source/phase4c1/local/playthrough_20260927/index.html)：
约 **52 秒 / 1280×720 / 60 FPS / 游戏原声**；录制记录 `recording.json` 确认代码和正式存档未改。
录像在 ignored `local/` 下，只存在于本机，不随 Git checkout 提供。
**自动化输入/API 验证 ≠ 人工试玩体验评测；成功录制撤离流程 ≠ 已验证全部任务目标。**

## Known technical debt / release boundary

1. **Enemy legacy dependency（下一阶段首要问题）**：AvatarSample_A visual 与旧步枪已隐藏，
   但真实 humanoid skeleton / AnimationTree / IK 仍求值。`EnemyController` 从旧 rig 读取
   muzzle origin/direction；新无人机只跟随它。死亡沿用原六刚体，替换可见碎片而非死亡逻辑。
   依赖和运行开销尚未清理，旧资源 public-release authorization blocker 仍未解除。
   敌人 debug 页面仍是旧 rig 诊断，不代表正常生产场景没有切换。
2. **Visual coverage**：城市大面积环境与 UI 仍有原型感；部分战斗反馈可 polish；
   Terminal 专项美术切片未完成。不要据此立即开始大规模 asset expansion。
3. **Performance**：low-end PC、持续 FPS、内存与加载时间均未完成验收；
   **720p60 录像成功不能作为性能认证**。
4. **Release / licensing**：目前不是发行验收；Unity-Chan 为 UCL，不是 CC0，保留 credit/license/source，
   商业发行需另审。AvatarSample_A 历史授权阻塞仍在；不阻止有边界的内部 Demo 工作，
   但不能把内部验收描述为 public-release-ready。
5. **Workspace / documentation**：历史 `.import`、`project.godot`、迁移资源、Blender master、
   报告等 WIP 有意保留。禁止 reset / clean / stash / 自动整理 / 删除 / 顺手提交。
   本页历史区的原有未提交段落也保留为 WIP；本次只提交新 current 区、历史区封装及阶段索引。
   旧报告目录中也有本地未提交文件，见索引的持久化标记；不要假设所有证据已入库。

## Next-step roadmap — not authorization to start implementation

```text
Phase 4D  Checkpoint / Handoff consolidation（本轮仅文档）
    ↓
Phase 4E  KITE-07 legacy skeleton decoupling
    ↓
Phase 4F  Fixed Demo Route presentation polish
    ↓
Phase 4G  Performance / release audit
```

**Phase 4E 目标**：单独解除 KITE-07 对 AvatarSample_A / legacy humanoid skeleton 的运行时依赖。
先审计真实 fire chain，而不是删除隐藏节点后让测试“看起来绿”：

- 保持 enemy gameplay、firing behavior、projectile/hitscan origin 和 direction、attack timing、hit/death、spawn/碰撞/导航。
- 保持并扩展原 **360-sample 行为对照**；在等价证据成立后移除不必要的旧视觉/骨架依赖。
- 当前部分敌人测试绑定真实旧 VRM/骨架/IK；必须先识别行为契约与实现假设，
  需要契约迁移时单独明确范围，不能删断言、加假节点或降低标准来掩盖变化。
- 重跑完整 33 项回归、Main、fresh import、graphical combat/extraction routes、跨进程 save/load。
- 不改玩家、武器语义、Terminal、Arena 或 AI 参数；严重契约冲突时 STOP，报告而非补 gameplay hack。

入口：[EnemyController](scripts/enemies/enemy_controller.gd)、
[旧视觉/rig](scripts/characters/humanoid_retarget_visual.gd)、
[CharacterCombatRig](scripts/player/character_combat_rig.gd)、
[无人机 adapter](scripts/presentation/enemy_drone_presentation.gd)、
[对照 probe](art_source/phase4c1/contract_probe.gd)。本轮 **不开始 Phase 4E**。

## Phase report index

[完整阶段索引与证据可用性](docs/PHASE_INDEX.md)：
3A → 3A.1 → 3A.2 → 3A.3 → 3B → 3C → 3D → 4A → 4B → 4C → 4C.1 → 4D。
索引只引用实际存在的报告；明确区分历史失败、后续通过、已提交记录与本地 WIP。

## For next Codex session

1. 绑定 `PROJECT_ROOT=D:\bunny_team`，先读 **`Handoff.md`**，不要假设历史 conversation 存在。
2. 执行 `git status`、`git log --oneline -10`，核对 HEAD、分支与 WIP；不要从旧 commit 猜当前状态。
3. 阅读 `docs/PHASE_INDEX.md` 和对应 phase report；Phase 4E 首先读 `art_source/phase4c1/README.md`、
   `final_validation.json` 与上面的实际 fire chain。先确认验证新鲜度，旧 PASS 不自动覆盖新改动。
4. 保留历史 WIP，不提交无关文件、不 push；未授权不扩大范围。测试/录制只用存档副本。
5. 本轮 4D 到此停止；下一轮获得明确任务后再做 4E。下方内容仅历史记录，不是当前指令。

---

<details>
<summary>Historical handoff notes — superseded; retained verbatim, including local WIP</summary>


# Bunny Team Engineering Handoff

## Historical handoff — Phase 3A Presentation Spike (2026-09-25)

**Decision: BLOCKED. Do not switch the default player.** Personal-demo derivative,
not commercial-release clearance. No new character searches, AI or Terminal work.

- New excluded workspace: `art_source/unitychan_battle_derivative/`. Blender master,
  self-contained GLB, prefab mapping, reproducible build/isolated-validation scripts,
  complete UCL 3.0 license/logo bundle and evidence retained. Read its `README.md`.
- Official source + meta fingerprints unchanged. 24 skinned + one static nose
  renderer mapped; separate head retained, bundled melee weapon excluded. Derivative:
  37,359 triangles, 24 meshes, 328 bones, five materials, four base-color images.
- Corrected centimeter/root-transform loss; applied 180-degree presentation heading
  normalization. World-position/rotation checks passed; not full skin/animation parity.
- Fresh isolated derivative import: **0 ERROR / 0 WARNING / exit 0**.
- Isolated replacement: **32/33 tests PASS**. ACCEPTANCE_SMOKE FAIL is old avatar
  `Face` name/height assertion. Tests were NOT weakened. Main exit 0; visual-slice,
  world traversal, presentation gameplay, weapon behavior/switching suites PASS.
- Eight mounts available; AR/SMG sampled grips converge. Strict all-weapon grip probe
  **FAIL: Rocket left-hand offset ~12 cm**. Measurement-only probe's PASS label is
  superseded by `evidence/grip_acceptance.log` (exit 1).
- Real OpenGL 1280x720 production-camera route PASS through Field Office, terminal,
  extraction/Result: normal AI, 60 shots, 3 damage, 0 kills; early extraction, not full
  mission. Automated API/input, NOT manual. Hinge waypoint failure retained; only
  test path changed to door opening center, not gameplay geometry/routes.
- Visual acceptance NOT ACCEPTED: Hanger hair/face overexposed, equipment occlusion;
  cloth/skin behavior, full animation visual review and performance still unverified.
- Live runtime/player/enemy/gameplay/config unchanged, main remains c4ca114; all
  prior WIP preserved. No commit/reset. Phase 2B 33/33 describes the OLD baseline,
  not the new derivative. ObjectDB warnings retained; not warning-free.

Next bounded step: presentation-only Rocket grip calibration + anime material and
skin/animation review, then reviewed model-independent face/adapter acceptance and
complete regression. Do not adopt the derivative based on route PASS alone.

---

## Historical handoff — Battle Costume source recovery (2026-09-25)

User selected **Unity-chan Battle Costume for a personal demo**. This supersedes
candidate shopping and next-Terminal proposals below. No Terminal work.

- **SOURCE RECOVERY PASS; CHARACTER INTEGRATION NOT VERIFIED.** Official Humanoid
  1.1 package downloaded (12,531,513 bytes); main FBX hash exactly matches legacy.
- Recovered 20 original PNGs, six Unity materials, official prefab, both body/head
  FBXs and shader/include evidence in `art_source/unitychan_battle_legacy/official_1_1/`.
- Six Maya authoring PSDs are NOT in the official release. Shipped appearance uses
  PNGs via Unity materials. All assigned-shader declared non-null texture references
  resolve; seven dangling old saved-property references are not used by that shader.
  No fake PSD, texture substitution, FBX/rig/animation rewrite.
- Blender 5.2.2: 20/20 PNG decode PASS, main FBX import PASS; 39,241 triangles,
  character 328 bones + weapon 11 bones. Not prefab/runtime or animation acceptance.
- Fresh isolated 4.7.2 current-project import: **0 ERROR / 0 WARNING / exit 0**.
  Source remains under `.gdignore`; this is not Battle Costume runtime acceptance.
- Existing 33/33 and graphical route PASS are Phase 2B evidence, not rerun this step.
  Runtime assets, Gameplay, player/enemy presentation and project config unchanged.
- `main @ c4ca114` preserved with all prior WIP; no commit/push/reset.
- Evidence: `art_source/unitychan_battle_legacy/RECOVERY.md`, `recovery_manifest.json`,
  `blender_source_probe.json`, and `docs/art_pipeline_validation.log`.

Next: isolated Blender prefab/material reconstruction, then deformation/retarget
verification and player-only presentation adapter. Main FBX alone does not reproduce
the separate-head prefab. Bind-pose behavior still needs verification. Existing
VRM release restriction remains in effect.

---

## Historical handoff — Phase 2B — Migration Gate Closed (2026-09-25)

**MIGRATION GATE: PASS for continued internal development on Godot 4.7.2. PUBLIC SHOOTING-DEMO RELEASE: BLOCKED — VRM authorization unresolved.** No Terminal selection/production was started. Stop here.

### Accepted gate standard and evidence

- User explicitly authorized **automated graphical input/API route acceptance instead of the original manual-keyboard gate**. It is NOT human/manual input. The current acceptance standard, not the older manual requirement below, governs this checkpoint.
- Actual working-tree snapshot → entirely fresh `.godot` → Godot 4.7.2 cold import: **0 ERROR / 0 WARNING / exit 0**. A separate fresh repair candidate also passed 0/0. No cached `.godot` was copied.
- Real dependencies repaired: official UnityChan 1.2.1 archive contains all six existing animation FBXs with **identical SHA-256** and all five missing TGA files. Only those original TGAs and their Godot `.import` settings were added, at the unchanged FBXs' expected path. No FBX/rig/animation/material rewrite or substitute texture.
- Unused Battle Costume FBX and original sidecar moved intact to `art_source/unitychan_battle_legacy/`, excluded by `.gdignore`. Filename/path/UID reference searches plus resource dependency checks found no runtime reference. The six missing PSD references and two bind-pose warnings remain in that preserved legacy source; no rest-pose reset was performed.
- Live idle/walk/run/slide + VRM bone hierarchy/rest/pose, skin binds and animation track/key fingerprints match before/after exactly. **150 runtime source files** used by the regression copy match the checkout. Character presentation, movement, combat and routes unchanged.
- After fix: **ALL TESTS 33/33 PASS**, ACCEPTANCE_SMOKE PASS, MAIN HEADLESS exit 0, VISUAL_SLICE_ASSETS_TEST PASS, WORLD_TRAVERSAL_TEST PASS, PRESENTATION_GAMEPLAY_TEST PASS, RESULT_RETURN_TEST PASS. No runtime ERROR/SCRIPT ERROR. MAIN and sortie_outcome_test each reported a **KNOWN NON-BLOCKING EXIT WARNING: 2 ObjectDB instances**; not warning-free.
- OpenGL 3.3 / RTX 5090, 1280×720 production camera: Hanger → movement → door E → entrance → interior → Terminal → exit → original outdoor route → extraction → Result **automated PASS**. Normal AI/health/collision retained. Terminal objective 1/1; early extraction successful, mission otherwise incomplete (0 kills; 9 damage taken). This is not full-mission completion or a manual-combat skill test.
- First scripted route attempt hit the entrance jamb due to a diagonal waypoint; only the test path was corrected to cross the doorway before turning. Production collision/map/code were NOT altered. Failed attempt evidence retained.

### Git and reproducibility

- Branch `main`, HEAD still `c4ca114e732ff8508370928dd5d16e04d838a6a0`, same origin. Original Phase 1/2 documentation WIP preserved. No reset, discard, commit or push.
- Worktree changes: migration dependency restoration + legacy relocation + validation tools/evidence/documentation. Git shows deletion at the old FBX path and an untracked destination until staged; this is a byte-identical move, not destruction. Carry all untracked files if migrating this checkpoint; cloning HEAD alone does not include this fix.
- Fixed scripts: `tools/verify_migration.py` (fresh WIP snapshot/import/regression/optional graphical route), `tools/audit_migration_dependencies.py` (read-only material/source trace), `tools/phase2b_route_probe.gd` (normal-AI graphics route).
- Durable evidence: `docs/phase2b/validation.json`, `dependency_trace.json`, `route_result.json`, `captures/`; the directory has `.gdignore` so screenshots are not game resources. Full diagnostic details/reproduction fingerprints appended to `docs/art_pipeline_validation.log`.
- Original official archive and intermediate failures retained outside Git at `C:\Users\admin\AppData\Local\Temp\bunny_phase2b_20260925_214246`. Only ~15 MiB of original dependency textures added to runtime source; no asset-pack dump or AI work.

### Release boundary / next phase

VRM author/model/FAQ pages were checked again. Their current permissions differ from the fixture metadata; the exact old-file authorization/version is still unresolved. Keep the model intact and **blocked for public shooting-demo use**, do not remove metadata or use it as AI input. This documented restriction does not block this internal migration checkpoint. C03 replacement remains DEFERRED.

Next separately authorized phase: exactly **one Terminal vertical slice**. This session ends at the migration checkpoint; do not proceed automatically.

---

## Historical handoff — Phase 2 Gate checkpoint (2026-09-25)

**Result: BLOCKED before Terminal production; Definition of Done NOT achieved.** This section supersedes the Phase 1 proposals below. Latest user authorization: use **Godot 4.7.2**, with other platforms to be unified by the user. Engine selection is settled; migration acceptance is not. Do not obtain 4.6.3 or call 4.7.2 merely an unauthorized temporary version. `project.godot` remains at its compatible 4.6 feature level; no rendering/configuration change was needed for this audit.

- Git: `main`, HEAD `c4ca114e732ff8508370928dd5d16e04d838a6a0`, origin `https://github.com/atom32/bunny_team.git`. Start-of-Phase-2 WIP was the Phase 1 Handoff edit and four untracked documentation paths listed in the validation log. Preserved. This phase changes Documentation only; no Gameplay, imports, rigs, runtime assets, commits, resets or package downloads.
- Fresh 4.7.2 cold import of a new HEAD archive: **FAIL — 72 ERROR / 38 WARNING**, process exit 0. Reproduced independently of the old cache. Six animation FBXs each contribute 10 missing-texture errors/5 warnings; `unitychan_battle.fbx` contributes 12 errors/8 warnings, including both multiple-bind-pose warnings. Details and safe next choices: `docs/ART_PIPELINE.md`, Phase 2 section.
- Unity-Chan dependency cleanup: **DEFERRED**, not cosmetically silenced. Idle/walk/run/slide remain live animation/skeleton dependencies even though their meshes are hidden. Entire-directory ignore/deletion would break runtime. No replacement textures or rest-pose edits.
- VRM release/license: **BLOCKED**, with new evidence rather than a blanket claim that the author forbids combat. Official AvatarSample_A page currently allows violent use. The repository binary exactly matches the VRMMetalKit fixture, but retains OnlyAuthor/Disallow metadata; applicability of current author terms to this particular distributed version is unresolved. See `docs/art_candidates/README.md` for URLs, hashes, permissions and limitations. No public footage or AI input approved.
- C03 bounded compatibility probe: existing glTF loads as PackedScene with one 62-bone skeleton; direct replacement is **not compatible** with current Character1_* bone contract. Eight sockets have anatomical counterparts but no tested adapter/IK/AnimationTree acceptance. Local LICENSE says **Ultimate Modular Males**, conflicting with Phase 1's Women pack attribution; exact pack identity must be reconciled. No character replacement made; C04 not downloaded.
- Fresh runtime verification: **ALL TESTS 33/33 PASS**, including ACCEPTANCE_SMOKE, RESULT_RETURN_TEST, PRESENTATION_GAMEPLAY_TEST, VISUAL_SLICE_ASSETS_TEST, WORLD_TRAVERSAL_TEST. MAIN HEADLESS exit 0; no runtime ERROR/SCRIPT ERROR. Two-instance ObjectDB exit warnings remain in main and two suites; not warning-free.
- Manual Field Office Enter/Exit, Terminal reachable, original route/result: **NOT VERIFIED**. Migration failed first, so no claim of manual acceptance and no Terminal selection/integration. Entrance/Terminal/Character visual acceptance, before/after performance, four new screenshots and 20–30s footage: **NOT VERIFIED / not produced**.
- Raw evidence: `C:\Users\admin\AppData\Local\Temp\bunny_phase2_20260925_211817`; durable results, commands, hashes and diagnostic output appended to `docs/art_pipeline_validation.log`.

### Next checkpoint, in order

1. Close cold import on 4.7.2: recover the exact lawful original image dependencies OR prove a geometry-free animation-source derivative preserves every bone/rest/track/key and PackedScene contract. Do not simply switch animation FBXs to AnimationLibrary: current code expects PackedScene + Skeleton3D + Take 001. Keep original sources and licenses archived; quarantine only verified unused references, not the live animation directory.
2. Reconcile the VRM metadata/version with author permission (or separately approve a small presentation-only character adapter spike). Do not rewrite embedded licensing metadata as a substitute for permission.
3. Complete actual-window keyboard/mouse route acceptance, then select **exactly ONE** Terminal/Cabinet, comparing processed C09 with C02 and C01 only if superior. The old 3–5-model proposal below is superseded. No Hanger/weapon/UI/environment expansion.
4. Blender master → GLB → presentation wrapper without collision/interaction changes → full regressions → production-camera 1280×720 performance/screenshots/video/manual acceptance. No AI workflow needed unless a real supporting-art gap is identified.

---

## Historical handoff — RTX 5090 Art Pipeline Audit (2026-09-25)

**Latest authorized phase: migration validation + sustainable art production planning, not Gameplay implementation or bulk asset replacement.** This section supersedes the old "stated next task" below. The Visual Slice 01 implementation and historical acceptance evidence remain intact.

### Read next

- `docs/ART_PIPELINE.md` — workstation facts, production gates, Blender normalization, rollout order, Windows test commands and acceptance limits.
- `docs/ART_ASSET_INVENTORY.md` — measured inventory, current presentation contracts, P0/P1 priorities and licensing blockers.
- `docs/art_candidates/README.md` — 16 individually documented source entries: 2 already integrated, 12 candidates, 2 rejected for style/scope. No new packages downloaded or approved for integration.
- `docs/art_pipeline_validation.log` — consolidated fresh test/tool evidence, including cold-import errors rather than a false clean-migration claim.
- `docs/visual_slice_01/REPORT.md` — historical visual implementation/manual evidence, unchanged.

### Workstation / Git

- Project is already on the RTX 5090 machine at `D:\bunny_team`.
- Initial tree **clean** (no modified or untracked files); branch `main`; HEAD `c4ca114e732ff8508370928dd5d16e04d838a6a0`; origin `https://github.com/atom32/bunny_team.git`; remote main checked and matches HEAD. Clean baseline can be cloned/checked out directly. This phase leaves only its documentation edits uncommitted; no reset/discard/commit/push was performed.
- Installed Godot: `E:\Godot\Godot_v4.7.2-stable_win64_console.exe`, **4.7.2**, not the historical **4.6.3**. All importing/testing occurred in a temporary git-archive copy, not the production working tree. No engine upgrade was applied to project configuration.
- Blender: `F:\SteamLibrary\steamapps\common\Blender\blender.exe`, **5.2.2 LTS**. Existing CC0 AR → Blender → GLB → separate Godot test import/instantiate passed; 802 triangles and Blender world bounds preserved. No production asset replaced.
- RTX 5090, driver 616.92, CUDA driver UMD 13.4; ComfyUI Python 3.13.11 / Torch 2.13.0+cu130 completed a CUDA tensor calculation. System Python 3.14.2, Node 24.12.0, Git 2.52.0; Python/Node are not game runtime dependencies.
- MiniMax H3 and WAI Anima weights/nodes/workflows exist under `D:\ComfyUI-aki-v3.2\ComfyUI` (0.33.2). Full model inference/API workflow has **not** been validated. `anima-preview.safetensors.part` is incomplete and is not counted as a working model. No installs, model downloads or AI generation performed.

### New blockers (do not conceal behind test PASS)

1. **Cold import is NOT CLEAN:** Windows Godot 4.7.2 import exited 0 but logged **72 ERROR / 38 WARNING** lines, including missing original Unity-Chan TGA/PSD texture paths. Runtime suites subsequently pass; this does not clear the import gate. Diagnose with a pinned Godot version and repair import dependencies separately, without empty substitute textures or Gameplay changes.
2. **Current player AND enemy VRM licensing is not cleared for a shooting Demo:** actual `avatar_sample_a.glb` metadata contains `allowedUserName=OnlyAuthor`, `violentUssageName=Disallow`, alongside `licenseName=CC_BY` and `commercialUssageName=Allow`. The generic bundled model-license notes are insufficient to resolve this. Obtain explicit applicable permission or choose a cleared replacement (C03/C04 are investigation candidates), before public gameplay/promotion. Do not feed this model or Unity-Chan assets/screenshots into AI.
3. **Manual Field Office Enter/Exit remains NOT VERIFIED.** Hanger/AR/SMG/Rocket VERIFIED are inherited previous-machine observations, not fresh 5090 manual verification. Full AI inference and actual 5090 GL rendering/manual acceptance are still pending.

### Fresh validation, exact scope

- Windows **Godot 4.7.2** isolated copy: **ALL TESTS 33/33 PASS**, RESULT_RETURN_TEST PASS, PRESENTATION_GAMEPLAY_TEST PASS, WORLD_TRAVERSAL_TEST PASS, ACCEPTANCE_SMOKE PASS, VISUAL_SLICE_ASSETS_TEST PASS; all runtime test exit codes 0 and no ERROR / SCRIPT ERROR / `: FAIL`.
- MAIN HEADLESS: exit 0, no ERROR, **2 ObjectDB instances warning** at forced exit. Do not describe as warning-free.
- 31 assertion suites + 2 scripted visual smoke flows; not automated image approval or direct manual input acceptance.
- Historical Godot 4.6.3 33/33 baseline is preserved, **not rerun on this machine**. Cold import errors above are a separate failed migration gate.
- Test profile data was isolated with per-process APPDATA/LOCALAPPDATA under the audit temporary directory. Original user saves, runtime code, Resource definitions, scenes and source assets were not modified.

### Next authorized proposal (requires an implementation task)

1. Resolve engine version/cold import; finish existing direct keyboard/mouse route acceptance. Resolve VRM release permissions separately before public output.
2. First vertical art slice: **Field Office entrance + briefing/terminal nook**; keep layout, collisions, camera, roof cutaway and route intact. Existing Kenney modules are a baseline, not an instruction to make a pack showcase.
3. Choose one licensed terminal/storage asset (C02 versus reworking existing C09), normalize in Blender, export GLB, adapt only Presentation, then full regressions and actual-camera comparison. Limit first slice to 3–5 models, 2 material sets and a small atlas, not an entire library.
4. Character/animation replacement, Hanger, Rocket silhouette and UI are later separate slices. No new drone/turret/weapon gameplay. Existing A → adapted B → optional AI C priority is mandatory; AI must not replace source/licensing/quality evaluation.

**Stop point:** planning delivered; workstation has the core production capability but migration/release readiness is conditional. No art integration, Gameplay changes, source-code edits or large downloads were made in this phase.

---

## Historical handoff — Visual Slice 01 (retained evidence)

> **Authoritative status: Gameplay vertical slice complete; Visual Slice 01 integrated, full regression passes; visual quality/manual route acceptance still partial.**
>
> **Last updated:** 2026-09-25, after Visual Slice 01.
>
> Read this document first. Do not restart architecture, re-audit the whole project or repeat the asset search.

## 1. Historical Phase / Exact Stop Point

**Visual Slice 01 — Weapon & Field Office Art Upgrade** was the latest authorized task. It superseded the former environment-only spike and explicitly included three weapon models.

Current art status: **Visual Upgrade Partially Complete — Asset Quality Limited**. The selected CC0 low-poly kit is integrated, licensed and working, with new roof/facade/interior dressing and weapon models. This is not a claim of final production art quality. The direct manual Field Office Enter/Exit check remains **NOT VERIFIED**; deterministic non-headless production-input traversal passes.

The playable loop remains:

```text
Hanger -> Loadout -> Deploy -> Outdoor -> Field Office -> Interior / Combat
       -> Terminal / Loot / Threat -> Back Exit -> Extraction / Death
       -> Result -> explicit Commit / Save -> Hanger / Warehouse
```

### Read these first, then stop or continue only within the next user request

- `docs/visual_slice_01/REPORT.md` — final selections, scope, test evidence, exact manual-verification limits.
- `ASSET_AUDIT.md` — current selection/licensing ledger (the earlier inventory is marked as inherited baseline).
- `scenes/areas/field_office_art.tscn` and `scripts/presentation/field_office_presentation.gd`.
- `scenes/weapons/{assault_rifle,smg,rocket_launcher}.tscn` and `scripts/weapons/weapon_visual.gd`.
- `tests/visual_slice_assets_test.gd`, existing `presentation_gameplay_test.gd`.

### Stated next task

No further implementation is authorized automatically after this stop. If asked to continue, first finish **direct WASD manual Field Office acceptance** with the current production camera: approach, open Door, enter, combat, Terminal, Back Exit. Review current screenshots/art quality with the user before further art expansion. Do not redownload packs, tune gameplay or start a second map.

### Completed in the latest pass

- Preserved all pre-existing definition Resources and arena gameplay placements byte-for-byte.
- Integrated 3 CC0 Kenney GLBs via the existing WeaponDefinition.scene mapping; no registry or PlayerController model-path lists.
- Kept AR combat markers; corrected socket-mounted SMG/Rocket display using the existing rig's pose/IK targets while retaining their gameplay muzzle/reload/recoil paths.
- Preserved Idle_Gun and AnimationTree ping-pong; preview begins at a three-quarter angle.
- Added one environment kit, a small authored office prop set, unified palette/materials, roof/canopy/sign/windows and 6 local unshadowed office lights.
- Added a roof cutaway on approach/inside for the current high-angle camera.
- Kept existing Field Office body/shape blocks identical; added no imported collision meshes.
- Dressed the rotating Door, existing cover and destructible Barrier; Barrier decorations disappear with the original visual.
- Added a visual asset regression test; made the two pre-existing interactive visual smoke scripts auto-advance/cleanly finish when headless.
- Captured new actual OpenGL gameplay and presentation images under `docs/visual_slice_01/captures/`.
- Native UI verified Hanger, three Primary weapon models, Warehouse equipped indicators, Deploy and Battle Q switching. Direct movement did not sustain under the UI tool's taps; the attempted native sortie ended in death and was closed without committing/saving. Do not call that a completed manual Field Office route.

## 2. Current Implementation State

### Content and definitions

- `ContentManifest` and `ContentDB` resolve stable IDs to static Godot Resources.
- Implemented definitions include items, equipment, weapons, ammo, enemies, missions, objectives, loot tables, and areas.
- Definitions are immutable configuration. Mutable combat, inventory, mission, and world state lives in runtime objects.
- `AreaDefinition` resolves `prototype_arena` to its authored scene; Area means **where**.
- `MissionDefinition` describes objectives; Mission means **what to do**.
- `EnemyDefinition` describes enemy configuration; `EnemySpawnPoint` determines where an enemy starts.
- `LootTableDefinition` describes what may spawn; `LootSpawnPoint` determines where loot appears.

### Profile, inventory, and persistence

- `ProfileState.inventory` is the persistent Warehouse.
- `LoadoutState` stores stable ItemInstance IDs for Primary, Secondary, Armor, and Backpack.
- `SortieRequest` contains area ID, mission ID, a loadout snapshot, and explicit carried item IDs.
- `SortieSession.inventory` is an isolated carried-inventory snapshot. It never shares mutable ItemInstance objects with the Profile.
- `SortieSession.initial_carried_instance_ids` records exactly what entered the sortie.
- Item stacking, splitting, consuming, capacity, and stable instance IDs are implemented.
- Warehouse capacity is `1000.0`; carried Sortie capacity is `100.0`.
- `ProfileRuntime` upgrades legacy loaded profiles to at least the current Warehouse capacity without changing the save schema.
- `SaveService` remains the only serialization boundary and uses the existing single profile save.

### Sortie lifecycle

```text
ProfileState
  -> SortieRequest
  -> SortieSession
  -> SortieOutcome
  -> SortieOutcomeService.commit_outcome()
  -> ProfileState
  -> SaveService
```

- `ACTIVE -> COMPLETED` occurs only through Extraction.
- `ACTIVE -> FAILED` occurs through player death.
- `ABANDONED` retains its existing no-recovery behavior.
- A successful Outcome merges the recovered carried inventory into the Warehouse using `initial_carried_instance_ids`.
- Failed and abandoned Outcomes do not modify the Warehouse.
- Outcome commit is idempotent.
- Mission completion and successful Extraction are separate facts. A player may extract with an incomplete mission.

### Weapons, ammo, and combat

- Primary and Secondary slots contain real ItemInstances and independent `WeaponRuntimeState` objects.
- Assault Rifle, SMG, and Rocket Launcher use the same production combat boundary.
- Magazine state is Sortie runtime state. Reserve ammo is carried inventory.
- Reload consumes only matching ammo definitions from the active Sortie inventory.
- Successful Extraction materializes remaining magazine ammo into carried inventory once before Outcome creation.
- Failed sorties do not materialize runtime magazine ammo and do not change the Warehouse.
- Combat delivery is:

```text
WeaponAction
  -> DamagePacket
  -> target.receive_damage(packet)
  -> target-side Armor / Health / Structure resolution
```

- Weapons do not inspect Basic/Heavy enemy identity or directly mutate target HP.
- Basic and Heavy enemies use the same controller and scene with different `EnemyDefinition` values.
- Cover is static and indestructible and blocks hitscan through physics collision.
- `DestructibleWorldObject` consumes only `structure_damage`; destruction disables its collision and visuals.
- Rocket explosion uses the same DamagePacket receiver path as hitscan/projectile combat.

### Missions, threat, loot, and world

- Objective runtime supports `ELIMINATE`, `INTERACT`, and `REACH`.
- Objective state belongs to `SortieSession`; UI reads it but does not calculate it.
- The authored Terminal records its interaction objective and is connected at the Area composition level to the local `ThreatEvent`.
- Threat is sortie-local: `NORMAL -> ALERT`, once, only while ACTIVE.
- Threat reinforcement reuses authored inactive `EnemySpawnPoint` nodes and `EnemySpawnService`; it does not create a global director or wave system.
- Generated loot becomes a real ItemInstance, enters only Sortie inventory, and reaches the Warehouse only after successful Outcome commit.
- Door, Cover, Barrier, objectives, extraction, loot, enemies, and threat are authored Area content and are freed with the Area.

### Hanger and presentation

- Hanger can configure Primary, Secondary, Armor, and Backpack, including `NONE` where valid.
- The Warehouse summary groups Weapons, Ammo, Equipment, and Salvage, and shows used/max capacity, quantity, weight, and equipped tags.
- Equipment changes refresh both UI and the character preview.
- Hanger uses the existing VRM character with the current idle animation through an active `AnimationTree`.
- `prototype_field_office.tscn` is a visually dressed traversable authored interior with floor, walls, roof framing, collision, front Door, interior Cover/Barrier, Terminal, loot, enemies, and a rear exit.
- The Field Office now uses a scoped low-poly CC0 visual slice; it is not a final map. See the current report for art-quality and manual-acceptance limits.

## 3. Important Architecture Decisions and Invariants

These are hard boundaries unless a future task explicitly changes them.

1. `ProfileState` owns persistent long-term state and the Warehouse.
2. `SortieSession` owns temporary carried inventory, weapon runtime, objective runtime, combat statistics, and threat state.
3. Profile and Sortie inventories use distinct InventoryState and ItemInstance objects.
4. Battle, Player, LootPickup, Door, objectives, enemies, ExtractionPoint, Result UI, and Area scenes never directly modify Profile.
5. Only `SortieOutcomeService.commit_outcome()` may formally apply sortie recovery to Profile.
6. `COMPLETED` means successful Extraction, not necessarily mission completion.
7. `FAILED` and `ABANDONED` do not mutate the Warehouse.
8. `GameState` is scene switching only. Do not put gameplay or persistence state in it.
9. `SaveService` is the sole persistence/serialization boundary. Do not add another profile or Outcome save.
10. Persisted data uses stable definition/instance IDs. Do not persist Nodes, NodePaths, scenes, or runtime Resources.
11. Magazine ammo belongs to Sortie runtime; reserve ammo belongs to Sortie carried inventory.
12. Definition Resources are static. Runtime state must not mutate definitions.
13. Weapons create DamagePackets; receivers decide how to consume them.
14. Area scenes own authored placement and local composition. They do not own Profile, Outcome, or Save behavior.
15. Mission, Area, Loot, Enemy, and world-interaction concerns remain separate:

```text
AreaDefinition    = WHERE
MissionDefinition = WHAT TO DO
EnemyDefinition   = WHAT ENEMY
EnemySpawnPoint   = WHERE ENEMY STARTS
LootTable         = WHAT LOOT MAY APPEAR
LootSpawnPoint    = WHERE LOOT APPEARS
SortieSession     = WHAT HAPPENED THIS SORTIE
```

## 4. Assets / Presentation Boundaries

- Kenney Space Station Kit 1.0: `assets/environment/kenney_space_station_kit/`, 16 selected GLBs; CC0.
- Kenney Blaster Kit 2.1: `assets/weapons/kenney_blaster_kit/`, only blaster-e / blaster-g / blaster-o; CC0.
- Each directory contains LICENSE.txt and SOURCE.md with original URLs and ZIP SHA-256.
- Existing VRM and Unity-Chan license materials are retained; no new character/animation source.
- Both palettes are 512 px. 19 GLBs total, 337,612 source mesh bytes. AR/SMG/Rocket: 802/618/664 triangles.
- Visual art owns no profile/session state. Window panels are sealed; wall collision remains fully solid.
- `track_socket_visual()` in CharacterCombatRig reuses existing targets but leaves `equipped_weapon` null and `has_weapon()` false for legacy socket weapons. Do not casually change this distinction: PlayerController still uses it for the original muzzle/reload/recoil behavior.
- Production Battle camera and GL Compatibility are unchanged. Alternate cameras/paused AI exist only in capture fixtures.
- Warehouse UI remains the existing inspection/configuration MVP; no stash redesign.

## 5. Validation Baseline

```text
All test scenes: 33/33 PASS (31 assertion suites + 2 scripted visual smoke flows)
ACCEPTANCE_SMOKE: PASS
PRESENTATION_GAMEPLAY_TEST: PASS
RESULT_RETURN_TEST: PASS
WORLD_TRAVERSAL_TEST: PASS
VISUAL_SLICE_ASSETS_TEST: PASS
Main headless: exit code 0
```

Inspect both exit code and log text (ERROR, SCRIPT ERROR, ': FAIL'). Do not match the word FAILURE in the successful SORTIE_FAILURE_TEST name. The two headless visual smoke passes are not image assertions or manual tests.

Main forced exit has an ObjectDB warning identifying the playing AudioStreamWAV/AudioStreamPlaybackWAV Music stream, no ERROR. The prior `4 resources still in use` errors from the two interactive visual test scenes were eliminated by completing/cleaning those headless runs. Audio lifecycle was not redesigned.

Run each test with Godot 4.6.3:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/xudawei/bunny_team res://tests/acceptance_smoke.tscn --quit-after 1200
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/xudawei/bunny_team --quit-after 180
```

Optional non-headless capture env vars: `PRESENTATION_CAPTURE_DIR`, `RESULT_CAPTURE_DIR`, `VISUAL_SLICE_CAPTURE_DIR`. Tests that persist state must use temporary save paths. The native UI review did not commit or save to user://profile.json.

## 6. Manual Status / Known Limits

- Hanger: VERIFIED (actual native UI).
- AR: VERIFIED (Hanger selection/held model; non-headless gameplay close-up).
- SMG: VERIFIED (Hanger selection/held model; non-headless gameplay close-up).
- Rocket: VERIFIED (Hanger model, Battle Q switch; non-headless gameplay close-up).
- Field Office Enter/Exit: NOT VERIFIED manually; the actual-window scripted production route passes and has screenshots.
- The low-poly sci-fi kit is a visual improvement, not a final production map/art set. The launcher uses a stylized four-tube model with unchanged single-projectile gameplay. Lighting/VRM material integration still needs an art-quality judgment; no bulk assets should be added to disguise this limitation.
- Git is initialized on `main` with `origin` set to `https://github.com/atom32/bunny_team.git`. Godot's generated `.godot/` cache, OS metadata and local credentials are excluded from version control. A pre-change local snapshot was retained at `/tmp/bunny_visual01/baseline` for this session; do not treat temporary files as durable project storage.

## 7. Do Not Do Yet

Do not add maps, open world, procedural generation, streaming, chunks, HLOD, large cities, multiplayer, networking, new combat/weapon/AI frameworks, balance changes, new weapons/ammo/enemies/objectives/loot, global EventBus/ECS, economy/trader/currency/crafting/insurance, grid stash/drag-and-drop/sorting/filtering/search, second saves, schemas or persistent Outcome logs.

Do not change the Outdoor -> Field Office -> Interior -> Combat -> Back Exit route or collision nodes to accommodate decorative art. Do not change renderer, add heavy GI/ray tracing, large textures or many shadowed lights. Preserve existing runtime/data ownership boundaries above.

The next work must start from these selected assets and evidence, not from a fresh design or whole-project audit.

</details>


## 2026-10-03 — Alpha 工作站性能基线

- 新增真实时间渲染探针（无 fixed-fps），实际 1280×720 / 1920×1080 Streets 维修→战斗→Loot→撤离→结算完成。每档一轮，非多局统计认证。
- 5090 / 9800X3D：帧 P95 2.007 / 2.015 ms，P99 2.246 / 2.256 ms；最大 draw calls 2693，Godot 跟踪资源峰值约 508 / 640 MiB。不是 GPU timestamp 或整卡显存。启动 warmup 约142–145ms最大帧单列，不能称无卡顿。
- 修正纯测试分辨率驱动：正式 DisplaySettings 设置、实际图像像素校验。提前退出/误用命令行尺寸的无效测量保留，不计入结果。
- 2688个runtime/source文件相对 relay_release_final 相同；本轮只改验证工具/测试分辨率开关/文档。最近完整57/57来自上一批，未冒称本轮重跑全套。无commit/push，WIP保留。
- 1080p参考图发现右上英文警报/路线文本重叠，下一步修可读性。较低配置、长期内存、10–15局真人风险收益仍未验收；完整Alpha继续进行，不标完成。
- 方法和限制：docs/alpha_0_1/PERFORMANCE.md；汇总：docs/alpha_0_1/performance_validation.json。


## 2026-10-03 — Alpha 战斗信息可读性修复

- 右上路线入口/档案警报改为有背景、自动换行的真实Label布局；展开地图详情让位，不再叠字。键位/语言/倒计时保持实时，控件不拦截鼠标。
- 720p/1080p × 中英文 × 三种警报状态：112检查PASS，12张实际渲染截图；已查看英文展开地图、中文倒计时。首次间距失败证据保留，修复真实布局后通过。
- fresh isolated完整57/57及78结果行PASS，跨进程恢复、实际战斗、Field Office路线PASS；冷导入0 ERROR /2已知FBX warning；Main exit0，已知ObjectDB退出warning仍有。
- 2688 runtime/source文件相对上次完整快照，仅route_map.gd改变。警报/任务/AI/存档规则、角色资产和用户WIP不动；未commit/push。
- docs/alpha_0_1/READABILITY.md 与 readability_validation.json。完整Alpha仍进行中；下一步战术声音与连续出击体验，不能用UI自动化替代真人多局测试。


## 2026-10-03 — Alpha 实际战术移动声音

- 接通自有脚步、轻步降低音量、可听人形脚步及KITE机械移动提示。敌音严格沿用原听觉半径/墙衰减，八方向方位映射镜头左右，不显示隐藏敌人、不改变AI。
- Kenney Impact Sounds 1.0官方CC0，4个原始OGG，无生成/AI音频。原license/来源/hash齐全。独立8声道池，不占枪声池；暂停/切场景/退出清理。
- 实际SFX总线录音验证左右声道能量方向与无削波；不是真人听感/战斗混音质量认证。原visibility44项保留，新增12项，共56通过。
- fresh isolated完整57/57、78结果行全PASS，实际战斗/图形路线与跨进程恢复PASS。Cold import 0 ERROR /2已知FBX warning；Main exit0，已知ObjectDB warning保留。
- 既有2688 runtime/source仅3个声音接入脚本变更；另新增4音频及import/license/source。角色/玩家controller/敌人controller/资产源/用户WIP未动。未commit/push。
- 证据：docs/alpha_0_1/TACTICAL_AUDIO.md、tactical_audio_validation.json。警报/维修专用音色、实战听感、真人多局经济节奏与较低配置仍待完成；完整Alpha继续。


## 2026-10-03 — 同存档12次连续真实出击

- 独立12进程，实际采购/弹药消耗/AI战斗/拾取/任务/撤离/领取；初始只标教学完成，不赠材料/装备/资金。907–918种子，recon/relay混合。
- 12/12运行通过；逐进程完整profile精确接续，成功/唯一outcome每局+1，checkpoint清空。未重置档案。
- 暴露体验风险而非完成声明：脚本第7局完成委托链，资金1500→8188，几乎无伤。导航/即时瞄准自动控制器不能代表真人；没有死亡/医疗/装备决策，不据此宣称难度合理或2–4小时内容完成。
- docs/alpha_0_1/CAMPAIGN_CONTINUITY.md 与 campaign_continuity_validation.json。仅测试工具/文档，无runtime变更，既有57/57基线不变；未commit/push。下一步失败后的连续恢复及真人节奏反馈。


## 2026-10-03 — 连续死亡后的恢复与空手撤离风险

- 同一有限新档9进程：7次真实敌人击杀、正常购买补给、2次条件应急整备、2次成功提前撤退。无HP/钱包/物资注入；静止受击控制器不是人类难度样本。
- 9/9完成，完整profile精确跨进程接续，携行损失/基地保留/唯一结算/应急不可重复领取通过。第9次沿用返回装备继续出击。
- 新证据：无新Loot/未完成任务的第8/9次撤退都获100信用点，124→224→324。可重复空跑收益可能破坏搜刮动机；下一步明确奖励边界，不通过测试驱动偷偷改钱包。
- docs/alpha_0_1/FAILURE_CONTINUITY.md、failure_continuity_validation.json。此批工具/文档，runtime不变，未commit/push。完整Alpha仍未完成。


## 2026-10-03 — 关闭纯空跑信用点收益

- 实际经济规则修正：任务完成原奖励保留；未完成但净带回新物资仍100；只有原有装备弹药的空返奖励0，仍成功、保留装备、不计失败。既有余额不追扣，存档schema不变。
- 使用出击实例原数量与返回数量按definition比较，防止弹匣返还新ID伪装Loot；Result新增物资与付款同源，中英文0奖励说明已实际查看。
- 经济测试102→130检查，保留原覆盖并迁移空返两项旧规则预期；完整57/57及跨进程恢复PASS。冷导入0 ERROR /2已知FBX warning；Main exit0及既有退出warning。
- 首次图形路线失焦后出口超时，失败记录保留；串行同源重跑13项PASS。无teleport/无敌补丁，未将首轮全量伪写为全绿。
- 同一失败恢复存档继续第10/11/12次实际空返：余额均324，正确成功结算；不再每次凭空+100。
- docs/alpha_0_1/RECOVERY_REWARD.md、recovery_reward_validation.json。这批Gameplay经济有改动，战斗/AI/地图/角色/用户WIP未动。未commit/push；完整Alpha继续，单件物资补贴与多局真人体验仍需验证。


## 2026-10-03 — Alpha完整验收审计与独立试玩入口

- docs/alpha_0_1/ALPHA_ACCEPTANCE.md逐项对应原10个完成标准；没有把自动12局当成人工验收，也未缩小目标。
- 当前2698 runtime/source文件与最后回归build一致；本轮只新增试玩启动工具与验收记录，不改Gameplay。
- tools/start_alpha_playtest.py以独立持久profile启动正常BOOT，无教学跳过/自动操作/fixed-fps，不改用户原存档，不导入/删文件。14项参数/隔离/模拟子进程测试通过；未实际替用户启动。
- 完整Alpha仍缺10–15局/2–4小时真人体验、听感/风险收益反馈，以及最低硬件目标与对应测量。已有异步问题尚待答复。未commit/push，WIP保留。

</details>
