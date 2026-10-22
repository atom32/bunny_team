## 用户收敛优先级：能玩先交付 不再自动扩展验收（2026-10-21）

- 用户明确“抓紧了，Token也不是无限的，能玩就行”。已响应：可玩交付优先，非关键美术/完整QA后置，不再自动开新一轮。不要恢复旧55矩阵、重跑全量或继续加验证脚本。
- 额外full源码job已在engine间yield安全停止：PTY6801/child17256，full_source01_stopped_for_delivery.json，87项全PASS但并非251完成，未杀任何Godot窗口。不是goal完成或暂停状态声明。
- 已交付可玩入口 D:/tmp/bunny_backup_only_20261021_dev01/开始游戏.cmd，以及快速进入校园.cmd。使用当前恢复修复＋外置16动作，最小正常首战/战斗/撤离/返营/升级/独立read两项通过（PTY81249 terminal0），playable_smoke_complete01.json。两个已用CMD模式静态核对，未再强加native矩阵；需本机已有Godot，无自动打开游戏。
- playable_ready01.json为准；该project现在冻结（frozen_play_project_manifest），play／preview独立存档，旧个人与试玩源均不覆盖，11保护hash/mtime核不变。paid16仅本机外置。其他场景均是现有内容，没有增加已测游玩时长，也没新独立Windows包。
- 当前Root仅两恢复文件增量，定向恢复验证和之前ZIP41范围见下文；旧dd568 ZIP不含这次恢复fix，不再为其刷完整矩阵。五小时/80%/权利目标未证明；用户现在明确优先能玩，后续以实际反馈决定修什么，不再自行投入大规模QA。

---

## 当前接续 2026-10-21 ZIP北门原生4项已过 发现孤立备份缺口并修源码 新全量运行

- 上一goal turn是progress：新ZIP dd568...、15真实预览/16CMD、37/96无界面、30/16实际启动与30备份哨兵版本调用已过；不是新Windows交付。此turn收到fresh call_c8568答复后跑新ZIP --gate-native-phase。PTY48306已terminal1，先误报路线失败，随后已经对用户更正：四游戏进程全部rc0/PASS，失败是外部footer读取read报告不存在的profile_before；gate_native_footer_original01.py.txt与gate_native_footer_rejected01.log保留。修为实际parent return/profile_after vs independent read/profile_after整份gameplay比较（仅既有stash显示例外），同批41日志sha全核、无重跑/重置，gate_native_complete01.json=true。
- 已告知窗口释放可切走，hold自动重建，不沿用call_c8568。亲看8图 gate_native_visual_review01.json接受局部ZIP北门/结算目标：F+quiet9shots3kills/open0，CompatEnglish loud17shots5kills/open2，实际R1→R2、Q01已存/Q02新请求及完整read一致。世界字仍灰小/挡角色轮廓，副物理告示英文仍中文，非全游戏美术/听感/乐趣验收。当前ZIP41/96、余55native/deps未验，无新user交付。
- 复查发现真正源码缺口：ProfileRuntime.initialize只看主档存在，孤立有效bak被当成新玩家（launcher虽不覆盖bak，但runtime仍可能新开档）。新dev D:/tmp/bunny_backup_only_20261021_dev01，--import-only已terminal0 PTY57342，两已知FBX警告；external orphan_backup_boot_probe 用当前EXE赚取R1原字节仅作bak，主档缺失，旧代码实测两断言FAIL且没有写存档，orphan_reproduced01.json。不用个人档，不以哨兵版本调用冒充正常恢复。
- 已改isolated并集成Root两文件：scripts/systems/profile_runtime.gd 缺主档有bak时阻止自动存档并展示既有恢复选择；明确恢复/新建前归档实际幸存原件（主档无则bak），不自动换新档。tests/p0_recovery_test.gd 追加有效/损坏孤立bak、阻止fallback写、显式restore/start、原字节归档、真空新玩家等断言。source_integration01.json：4090其他非文档不变，runtime不改schema/枪/loot/剧情/付费hooks。
- 隔离fix_complete01五项通过：复用同一个原失败bakuserdata，真实BOOT恢复按钮→原R1基地＋独立read、扩展P0、正常新档首战/read。extra02的valid BOOT过，pending实际恢复v8但QA误把pose微量float重建与合法新checkpoint备份轮转判为数据变更；extra03又漏PackedFloat数组类型，两个FAIL/log/userdata均留。没有重置pending_boot02_userdata；continuation04正常BOOT/RESUME同一主档实际signedv8＋损坏备份的实际archive/start按钮两过。pending_readback_diagnostics04列出全部差异，仅16个enemy firing骨矩阵小于1e-6（实测max约2e-17），ammo/loot/health/进度/位置精确，原raw bak在recovery archive保留，原failed source hash+mtime不变。无整个checkpoint豁免。
- 当前Root已是上述2文件增量，因此之前251/149与dd568ZIP41/96只能作其前基线，不含新恢复修复。已交付的source16工程也保持冻结，别暗改。**新全量运行PTY6801、child17256，输出 D:/tmp/bunny_backup_only_20261021_final01，计划127/251，尚未完成**；日志本dev/full_source01_runner.log，完整只认full_source01_complete.json。非文档为该job冻结；外置guarded_full_entry只支持case间full_source_native_hold.flag yield，不改测试。无新build/ZIP、无待答原生问题；全部旧hold保持。接下来看真实full结果再安排新二进制恢复UI验收，不为了旧ZIP刷完55就隐藏已知修复差异。
- 目标active，五小时真人/80%口碑/公开权利/听感/低配/干净机仍缺；无上传/commit/push/作者联系/换模/子代理。9原保护＋旧失败checkpoint/R4等保持，当前dd568ZIP和两份已交付source工程不可覆盖。下面旧顶部“原生待答”仅历史，call_c8568已经使用且时段结束。

---

## 当前接续 2026-10-21 新ZIP无界面37/96与CMD30/16完成 原生待新答复 未交付

- 上一goal turn是progress：当前源码127/251、原生6项/看8图局部接受、16动作源码本地入口冻结、新Windows默认动作149及PCK1673核验完成。新turn没有改Root runtime，不覆盖已经给用户的任何工程/存档或ZIP。
- 新packdev D:/tmp/bunny_readability_package_20261021_dev01。verify_failed_profile_binary01.py已terminal0（PTY12420），当前release实际从原六连空R9副本找枪/取回/装备/实战/read至R11，源hash/mtime未改；旧错误footer没有带入，新read比较整份gameplay和同find实例。earn_gate_preview01.py也terminal0：当前EXE正常新档首战R1/升级AR＋独立read，另存原字节给校园北门预览，不借旧源试装档/造档。
- prepare_packet01.py已terminal0（PTY16937）：新candidate D:/tmp/bunny_readability_20261021_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip，246384929B，SHA dd56834065d26fa0fdd0a2b9eadeaa56c5729e7c13ea3c6e88823f9d9f3cf2ca。独立解压 D:/tmp/小兔试玩 北门与可读性 20261021 验收01/LOCAL_ONLY_DO_NOT_UPLOAD，15个当前EXE真实预览/16CMD，旧15入口保留。新增预览校园北门用当前真正R1；gate准备记录的method字符串误说bootstrap，command实际None/原字节一致，preview_preparation_scope_corrected01.json明确更正，不重跑/改日志。
- 所有预览CMD新加仅当主档与bak都无才初始化，复制失败返回1，不覆盖可恢复备份；原用户旧CMD不动。实际CMD30/16（旧28＋gate route/read）及expected invalid exit1已全过；15预览各做backup-only/main+backup的30次实际CMD --version，保留全部哨兵原字节、不补seed/metadata，backup_guard_complete01.json。这30次只是初始化保护检查，不冒称30条新游戏路线或正常备份恢复。run_cmd_phase01.py已terminal0（PTY33150，cmdchild33684和guard41172均结束），不要再轮询。
- verify_packet01.py --headless-phase 已terminal0（PTY26810），37/96全过，59个native或依赖read还缺；current_packet_headless_complete.json在build01。新96计划保留旧87定义逐项相等，另9gate；当前4组件＋真实R1读、shared及原六连空真实9→11/read等都过。43静态文件在bundle／ZIP／独立解压／CMD解压逐字节一致，CRC/官方EXE/PCK1673/4092源输入与11保护hash+mtime再次核过。没有任何native窗口，Dummy不是听感。不要把37说96，portable_results_complete不存在。
- 当前ZIP未交付、无新user目录、native未开；上一轮call_970c94五分钟前台已结束，不沿用。已通过request_user_input_async新问gate两条实际路线/read5–8m，尚待用户真实答复；方便后才核CIM无引擎、精确移build01/native_hold.flag到唯一used名，运行verify_packet01.py --gate-native-phase（2native＋2read，上限420秒）。结束重建hold、告知可切走，再亲看gate_00_bolted、gate_02_opened和05_q01_debrief两renderer实际图。其余55个旧native矩阵及依赖仍另批，不能拿源码native6复用冒充新ZIP；不关闭失焦暂停/强制focus。当前无游戏引擎／livejob，portable_active_case等仅历史；不从它猜活。默认Windows不含paid16或Arcana；16动作只另一本机冻结源码入口。目标active，五小时真人/80%口碑/公开权利/听感/低配/干净机仍缺，不把测试数当新增内容。

---

## 当前接续 2026-10-21 可读性＋16源码本地交付 全量127/251完成 Windows候选149完成但未验ZIP

- 上一轮是progress（北门+16本地交付）。本轮已实际改结算左列opaque底板／18px正文，42种双语Outcome矩阵778断言、普通回营／失败重试等10项过。首轮native01收到call_e040答复后跑8项：7PASS，最后CompatEnglish普通射链失败，read未运行；source full安全yield于20640、batch结束后恢复。已告知可切走，native_hold.flag在，不能沿用旧窗口同意。旧交付门+16工程保持冻结，不覆盖用户play/preview数据。
- 首轮实际F+返营图中，左列浅色正文在不透明深底上确实清楚，角色主体与返回按钮仍可见。门字却因原FontFile实际名Noto Sans SC Thin而细空；当前已改复用HUD FontVariation(wght400)，不是继续盲加字号。Root5个UI/marker原增量在source_integration01.json；再补font资源／unit字体断言／控制器QA三项在post_native_fix02.json。无新物理碰撞/命中箱/导航/奖励/存档字段，付费16库与两hook仅新dev外置。
- 射链失败不是失焦：原耐久checkpoint actor x=-8.3416，cardinal aim(0,0,-1)真实nominal ray先中GateBody；max14枪未开门，原图gate_02_opened文件名不能当开门证明。recovery02..05尝试鼠标推事件/warp在headless cursor仍0，均FAIL保留；最终删掉这些方案，**没有OS鼠标warp入Root**。改为正常precision_move小步从x=-8.3416走至-8.0213再cardinal fire，recovery06正常BOOT/RESUME同失败checkpoint副本、实际1枪打断、两守卫、E读牌/撤离/回营R1→R2和独立read都过。原失败源21发checkpoint未改，原进程结尾16发不是同一个保存时点。external tests/gate_failed_recovery只在dev不入Root。新鲜进度不回滚，原失败原件保留。
- source FULL01已terminal1（PTY41056，child20640不再轮询）：176 engine categories全PASS，但Python断言Q02必须一局(R3)失败，实际合法随机搜刮两局后R4且Q02已交付。full_source01_rejected.json与原profile/outings保留，不重抽或把R4改R3。
- 已修QA计数：tests/normal_start_test.gd新增QA-only _expected_returns，读0..2额外Q02局数flag；12处后续helper仍保持精确canonical+extra数值与所有奖励/物品/进度断言。verify_migration/build_local_windows仅从实际Q02 outings+before/after推extra，独立medical intercept从R2分叉不加offset。新增tests/test_campaign_return_offsets.py验证1/2/3局和8种坏证据、不修改输入。source类别250→251（场景仍127），compiled计划148→149，不是已编译。
- counter初次normal_start函数混空格/Tab导致parse失败，counter_parse_rejected03.json及multi_trip03原日志保留；已改Tab并直接autoload后parse0。multi_trip04复用同一个multi_trip03_userdata（没有重置），从原full01 **真实R4** 正常relay/read、power、pack、supply/read六项过到R7，原R4源hash/mtime不变，multi_trip04_complete.json。这是实际两局Q02的后续路径，不是只测函数或重抽新档。
- FULL02已terminal1（PTY50296/child25924不再轮询）：新Pythonunit rc0/OK被旧通用PASS footer拒绝，原log保留，已修显式OK分支。**FULL03已terminal0：PTY63380、child41524结束，D:/tmp/bunny_readability_20261021_final03，127场景／251类全PASS**；results SHA e2265a7959fdb58ee342e4d5fc9beaafc3de2cc041514a4d8239c9d896392e70，4092个Root非文档输入匹配，6保护不变，full_source03_complete.json为准。这次Q02真实1局、offset0，原真实2局R4→R7由单独multi_trip04证据保留，不声称本次full就是2局。没有引擎并发／重抽失败档。
- 第二批收到fresh call_970c94答复后，先让FULL03 PID41524在引擎间yield（ready匹配/CIM无游戏引擎），再跑verify_native02.py。PTY29201已terminal0，6/6过：F+中文quiet组件/read、Compat English loud组件/read、Compat English原失败checkpoint正常恢复/read。已告知可切走、native_hold重建，full_source_native_hold移used02恢复同一FULL03，不沿用这次短时段。亲看8图，native_visual_review02.json接受本地近景字重／实际地坪上结算正文，whole-game=false；俯视世界字仍灰小、英文标题近景会延伸到对白后，底部不透明HUD主操作仍清楚。首批未变ResultUI的双语矩阵/F+回营范围另列；native_complete02_scope_corrected.json纠正原footer范围，不冒称新9/9。原失败源仍21发保存时点，hash+mtime及九保护文件通过protected_check04；无新CMD/ZIP。
- targeted_complete01默认动作10过；targeted_complete02是local16的10过，原错误Default scope由targeted_complete02_scope_corrected纠正。finish_local_trial04.py已执行：当前dev两个新入口“运行可读性与十六动作本地版.cmd”“预览修正版校园北门.cmd”，play／preview均未预玩，preview只有主档与bak都不存在才复制真实R1源，不覆盖进度。Root生产1563输入逐个比，只有两motion hooks不同；付费库仅外置。frozen_play_project_manifest.json已生成，**该project现在冻结，不要覆盖或改用户userdata**。local_trial_ready04.json；CMD只是已用模式静态核查，普通BOOT/route/native另证，不冒称新CMD或ZIP验证。
- 九保护baseline见本dev/protected_before.json，protected_check04.json已核hash+mtime，含原native失败21发checkpoint另证不变。旧gate/combat16工程、carrier b20bZIP、internal6b3ZIP和个人档不变。Windows：新Windows内部候选已实际导出149类通过，尚未做新ZIP／CMD／原生整包验收，未交付。runner D:/tmp/bunny_readability_20261021_dev01/build_candidate01.py，PTY70194已terminal0/child47092结束，不再轮询；依赖source/native/review已满足，输出新 D:/tmp/bunny_readability_20261021_build01，默认动作，不含付费库，guarded_build仅case间yield，不改验收。build_candidate01_complete已true，4092非文档输入匹配；PCK1673条byte-range/MD5和全部旧内容门槛＋新门/字体/UI通过，readability_pack_audit_complete.json；无paid/Arcana/原档/外置diagnostic。最终readability_local_delivery04_complete.json验证源码trial4759项manifest未变、九保护＋原失败checkpoint及真实R4共11文件hash/mtime不变、无活游戏引擎。不是新ZIP/CMD/native整包通过，默认Windows动作仍旧。无upload/commit/push/作者联系/换模/子代理；goal active，真实5小时、公开权利、80%口碑、听感/低配/干净机仍缺。

---

# 当前接续 2026-10-21 北门＋十六动作本地版已交付 全量与双渲染器完成

- 北门已经集成Root，不是下文旧顶部所说的未集成原型。fresh Q01为map8，Exit2档案条件+最远其他无条件退路；实际外侧E或实弹10HP链开门，后者仅两名有限增援，不额外奖品/治疗/赠弹，不自动铭牌/结算。原v5中途档保原场景和碰撞导航签名。7changed+13added见source_integration01.json；另verify_migration/build_local_windows/local_build_probe映射3文件已改，计划127/250源码、148编译；没有新EXE/PCK/ZIP。
- 工作区外 D:/tmp/bunny_campus_exit_gate_20261021_dev01/project 使用16动作，与Root付费挂接隔离。前期component16、earned4、legacy2、regression6、clean default source9证据分别保留，不能叠成全游戏。普通route真实从已赚取R1首战档BOOT继续，活AI/真实开枪/E/返营/R2独立读；不修改个人进度。实际旧exported v5签名fixture只是fixture，不冒称真人赚取。
- 用户call_7b988确认后native01八个逻辑/读档过，批次结束已告知可以切走；亲看14图后native_visual_review01.json=false：近景旧铭牌/出口名叠穿门，普通视角门栓不清，所谓English earned实际被BOOT重置中文，不能算英文验证。未交付这版。旧截图/log均保留。
- 当前修正6文件见visual_fix02_final_delta.json：仅v8隐藏旧堆叠world标签，单独可读门/链/外栓标签，外侧金属栓提到上沿且手柄高于hood；旧v5及其他出口不改。closed铭牌仍显示原档案条件；Q01显式放置unit fixture改为先真实OutsideLatch.interact再读，未绕过规则；earned QA仅隔离语言偏好持久化以免BOOT重置。component03首例未过（battle后创建plaque导致未隐藏），原失败保留，增加deferred apply后component04八过，Q01 day/night与原v5同userdata再读三过。最后栓上沿仅渲染微调在完整final02快照内，画面待复查。
- FULL01已terminal1（PTY97727不再轮询）：86中85PASS、q01_slice FAIL12。FULL02也terminal1（PTY8227不再轮询）：104中103PASS，Q01已过，但sortie_guidance显式放置fixture同样未拔栓，2次失败。两个rejected记录和原log/results保持；仅修该QA实际OutsideLatch.interact（guidance_fixture_delta03.json），本地单项238+checks过。新FULL03已terminal0：PTY28727、child33544结束，D:/tmp/bunny_campus_exit_gate_20261021_final03，127scene/250categories全PASS；results SHA152a6f81d8c874e9ae6a1d640967d969b3c94ff49610d5d0b676d61dd3c58d80，4091 Root非文档输入匹配，6保护hash+mtime不变。full_source03_complete.json为准；不是148编译或新Windows验收。不再轮询28727，不依据process.json重启。
- 新call_d535c8用户确认后native02已实际完成8/8（PTY31273 terminal0），full02当时已终态无引擎才开窗口，未并发。已告知可以切走、native_hold.flag重建，无待答问题；其他三处hold仍在。亲看14张当前图：旧世界字堆叠消除，实际金色外栓/把手可见，普通E/开门/原条件/返营无误；Compatibility这次确为English，外层检查真实HUD文本不只看flag。native_visual_review02.json接受本地灰盒目标、whole-game false；小字低对比、斜近景链字局部被门片遮、非手到门栓接触、部分英文次提示中文、原灰盒与结算对比仍在，不冒称正式画面。普通quiet 6shots2kills/open0，loud16shots5kills/open1。
- 已交付最新Windows仍carrier b20b...，内部maintenance02 6b3...依旧40/87，不在本门内容内。上一用户十六动作launcher保持冻结，不覆盖play_userdata。无commit/push/upload、作者联系、换模、子代理或付费数据入默认工程。五小时真人游玩/80%评价/公开权利/听感/低配及干净机仍未达成。

- finish_local_trial03.py已实际terminal0，**不能重跑覆盖**。新交付本地源码试装 D:/tmp/bunny_campus_exit_gate_20261021_dev01：运行北门与十六动作本地版.cmd为独立新档，预览校园北门.cmd为原真实赚取R1原字节预览（hash79adc...，仅无主档/备份时初始化，重复不覆进度）。未自动启动，play_userdata/preview_userdata尚未创建。两CMD仅静态路径/隔离审查，普通BOOT/实战另由native02证明，不冒称新CMD原生矩阵。旧Combat16入口不动。local_trial_ready03.json/frozen_play_project_manifest.json已冻结新工程，后续改动要新副本，不覆盖本交付或用户未来游玩数据。所有Root assets/scenes/scripts/resources/localization仅两预期本地hook差异，paid library.tres SHAa747...匹配16库。九文件hash+mtime最终相同见protected_check03.json。

---

## 当前接续 2026-10-21 最新十六动作本地版 与维护区原生复查

- 用户明确要求大量采用 CombatGirls_RifleCharacterPack v1.2 动作取代旧姿势。本轮已实际迁移旧十二段到最新Root内容副本，新增FL/FR/BL/BR共16段；非仅动作播放器。外部工程 D:/tmp/bunny_combat16_20261021_dev01/project，正常游戏入口同目录上层“运行最新游戏_十六动作本地版.cmd”；尚未自动启动，play_userdata尚不存在，独立新档，不改个人进度。原主角不换，付费数据不进Git／默认PCK。当前已交付Windows仍carrier旧包、默认旧动作，不能说当前旧EXE已替换。
- source_motion16采样只保留骨骼transform，未执行Unity脚本／events；bake52骨，source archive hash/mtime保持。正常16段由真实输入／事件触发；精确步态下身朝向瞄准、六向取最近源片段，不冒称八向blendspace。物理闪避／弹药／伤害／AI／奖励不变。Root只改tools/local_rifle_trial_player.gd一份干净可选模板（新增16支持），备份与before/after在optional_code_integration.json。默认player/rig挂接未改；最新126/242源码与140编译全量基线**早于这一个可选工具文件增量**，别再声称4078逐字节全匹配Root。实际16工程仅另同步该模板，已冻结非.godot清单frozen_play_project_manifest.json。
- 本轮headless7全过（20受控组合／24方向旋转、真实首战96项全16状态、read、原工坊训练、最新维护区互助／救援及read），native6全过（双renderer受控20组合、正常首战各96及各read），同一新适配器另接原3/12库两项过，原库未动且最终恢复16。全部普通路线无传送／grant／禁AI／直接伤害，实际AI命中／开枪／搜刮／撤离／核心升级。current_local16_complete.json是本轮最终记录；真实首战head/F+/Compat开火14/14/8，源使用16键均>0。不是完整游戏全量、真人手感或五小时证明。
- 两个新的前台确认均已完成并告知用户可以切走，无待答原生问题。所有引擎串行，未强制focus/unpause或禁失焦暂停。motion native PTY66016已terminal0，head55059 terminal0，import31917 terminal0，backward直接terminal0，勿轮询。native_hold.flag三处均在（motion/contact/build02），后续窗口需要新的真实可用答复。
- 已亲看当前16张motion图，斜向／枪身不穿脸／换弹／最终收枪放松可供本地试装；脚底浮离、衣物接触仍需细修，Put中段源伸臂过渡仍在。只AR556完整原生验，其他枪型／快速切枪／死亡／中途档组合未齐；家具仍专用CC0接触，不把39段持枪包说成已有体操家具动作。docs/COMBAT12与combat16机器记录为准。没有新EXE／ZIP或公开发行。
- 维护区当前手部修正版已复验：source --close-only7子集（非11），独立ZIP --shared-native-phase8新项+既有32=40/87（余47，非全native）。两真实ZIP路线6→7带回消音kit，活AI／实际E/TAKE／救援／同实例read过；其40logs与source7logs hash复核。亲看12张图：基本掌贴杆／箱标签无遮挡／无叠物名／真实取货UI过；精细手指不冒称，普通俯视角色小、Compatibility地坪偏亮、既有黑切墙与结算对白低对比保留，whole-game visual false。native_visual_review02.json在contactdev；两旧失败图审查不改。source/ZIP runner PTY54498/11506都terminal0。新内部ZIP6b3...hash不变，未新用户交付。
- 外置tree诊断01根Node错误、无脚本timer退出，CIM证明确切自有44256(parent36432)/38844后只停这两个，rejected scene/log/owned_process保留；改Node3D的02 headless826检查过，tree只有一个Survivor，不凭另蓝色人影猜重复NPC。此diagnostic仅外置，不计Root场景／编译门槛；最初wrapper28756已终态-1，不再轮询。
- 另一个旧隔离原型 D:/tmp/bunny_campus_exit_gate_20261021_dev01：quiet00显示24checks PASS但有缺失physical_gate metadata的ERROR，**不得接受为干净通过**，没有Root集成。初log、world仍保留，后续修has_meta再测；当前动作优先，不重启或遗忘失败。北门安静绕行／射链有限增援方案尚属外置未完成原型，不计已测分钟。
- 个人profile/.bak、Arcana、旧三ZIP及CombatGirls原归档hash/mtime均复核不变；内部6b3 ZIP不变。没有commit/push/upload、作者联系、换模、付费数据入库或子代理。goal active，公开权利、真实5小时／80%口碑、音频／低配／干净机仍不满足。下面旧顶部的“待答/32项”只作历史，不覆盖本段当前结果。

---

## 当前内部ZIP 无界面32/87与CMD28/15已过 原生仍待答 未交付

- 本轮progress：真正准备 D:/tmp/bunny_maintenance_shared_20261021_build02/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip，246351125B，SHA 6b3ebd03491dd0700c5444580a7bf68fcc93e9bd1b1ebb022fda6cd98ad6db19。这是内部候选，不是用户新交付/公开发行。41静态文件、15CMD、14份当前编译正常流程示例；新“预览互助收获.cmd”来自当前EXE实际6→7帮忙/取货/救援返营的消音工具包实例与原metadata，不注入新档。旧14入口保留；“预览蒸汽救援”CMD测试已升级实际shared_earned救援同行开箱，原普通路线仍由编译/ZIP既有门槛保留。
- prepare_packet02.py已终态0（PTY34884），14预备档全过：medical直接原字节，其余真实BOOT/Continue只允许stash显示布局变化；原来源及metadata hash不变。audit_pack02.py已终态0，1657 PCK条目逐项范围/MD5全验，保留全部旧内容门槛并加v3 shared_cache/survivor/zone、saved_tools表与两新privateQA，source外置diagnostic没混入，Arcana/CombatGirls/原profile/.bak/userdata无条目，不等于全素材版权清关。
- verify_launchers02.py在全新 D:/tmp/小兔试玩 互助与收获 20261021 CMD01/LOCAL_ONLY_DO_NOT_UPLOAD 已终态0（PTY11450）：28次真实CMD正调用/15隔离组+expected invalid exit1全过；二次校园调用5→6证明不覆盖进度，新shared示例同原kit与metadata保留。完整launcher_results_complete.json仅在全部后置条件后写，部分在launcher_results.json；没有原生窗口，Dummy非听感。此CMD目录已玩过，仅测试用，不是最终未预玩交付目录。
- verify_packet02.py --headless-phase 已终态0（PTY34470）：独立中文空格路径 D:/tmp/小兔试玩 互助与收获 20261021 验收01/LOCAL_ONLY_DO_NOT_UPLOAD 正32/87，剩55包含native及其依赖read，不能说87过。全保留旧72门槛，加15：shared组件/read/pending、双renderer组件及read、双renderer实际帮忙earned及read、shared预览read、真实旧exported v3 signed读回、原六连空9→11及read。当前7项新headless都过，包含新ZIP原失败档真实一局找枪+装备实战/读回；无新seed/赠品/重置。新当期语义partial通过，原Legacy v3/v4/v5与旧开仓/负重/存档等也过。portable_results_complete.json不存在，native_hold.flag在，未开native。
- finish_headless_packet02.py已终态0，current_packet_headless_complete.json为准：归档CRC+41静态文件在源bundle/独立ZIP解压/CMD解压逐字节相同；官方release EXE相同，PCK1657、当前Root4078非文档输入与build一致，6保护文件hash/mtime不变；ZIP自身不再覆盖。源bundle/独立ZIP样例均未变，CMD目录新userdata可存在不可删。所有source+packet helpers都在D:/tmp/bunny_maintenance_package_20261021_dev01或build02外部，不改Root runtime。
- 原生5–8分钟问题仍待答，不重复询问/默认同意/用旧已结束时段。为减少无谓前台重复，已给 contactdev/verify_native02.py准备--close-only：只跑当前字节精确源的两renderer受控近景和各read，加已过3头检后是7/11 subset（不宣称Source11过），普通native earned严格放在真实独立ZIP。收到真实当前方便回复、确认前台时段后，精确移除contactdev/native_hold.flag，run --close-only；接着若时段还充足，移除build02/native_hold.flag，run build02/verify_packet02.py --shared-native-phase（只当前shared，四native，上限4/420s）。两段约5–8分钟前台，期间不开图/面板，不关失焦暂停/强制focus。整段结束后才看实际Source近景+ZIP同动作/正常loot UI图，审握杆/手指/标签而非只看数学坐标。若某段超可用时段，保留边界再约，不能延长授权。此阶段也不算全87通过，旧矩阵剩余另需新较长前台时段。
- 两native hold均在，当前无活引擎或job。34884/11450/34470均已终态0，62609/7981等旧handle早结束，勿轮询/按process.json猜活。prepared source镜像4078输入当前一致，仅app名不同，外置diagnostic不入Root/PCK；不要拿该多一scene目录做全量。Root仍是source c7b334... 126scene/242＋实际binary140全过，原失败9→11 currentEXE的两gate已过，初footer KeyError原失败记录仍保留。
- 下一步若仍无前台回复，不要反复跑已过的32/28或改hash措辞假装进展。可在保留当前Root/ZIP候选冻结的前提下做下一项真正可玩内容的隔离原型或已列首玩发行缺口；新增内容不得偷偷覆盖当前候选的验收范围。正式新交付还缺native画面/其余独立ZIP/最终图片审查与未预玩解压。两份候选说明目前明确“内部验收、未交付”；将来若改成实际交付说明，应保留此ZIP、另做明确两txt的静态差异与新归档hash，不把旧SHA或旧runtime测试冒充新整包全测，程序/PCK/CMD/样例不动。没有当前可给用户试玩的新完整包。
- goal active：5小时真人首通、可公开权利、真实80%好评、实际听感/低配/干净机仍缺，不加游玩分钟。无作者联系、换模、付费源、上传、commit/push或子代理；个人存档/旧三游戏ZIP等保护文件均未改。docs/MAINTENANCE_SHARED、RECOVERED_ARMS及validation、README/FIVE_HOUR同步当前内部packet headless范围，不冒称已出新合格试玩。

<!-- maintenance-candidate02-current-start -->
## 上一轮候选02编译记录 已由顶部独立ZIP状态更新

- 本轮progress：从当前已过源码重新构建新目录 D:/tmp/bunny_maintenance_shared_20261021_build02，未覆盖失败build01或现有交付carrier ZIP。build_candidate02.py已终态0（PTY62609/child35356已结束），candidate02_complete.json确认140个实际导出门槛全过，保留旧133且新增shared7；各loghash、4078个Root非文档输入、6保护文件与官方release EXE相同均核验。manifest SHA 47630779a9b92bfae21d4fc60cfb42bf376eee4afd0d1725b1d9ad8791c31f7f。随后在当前release二进制中用原六连空9返营文件原字节副本继续：一局找到quickloader weapon.smg_01，带回装备再战7shots/1kills，9→11及独立read过；原档hash+mtime不变。两个附加门槛另列，不伪称140变成新剧情/分钟。
- dev D:/tmp/bunny_maintenance_package_20261021_dev01。保留build01真实66项处失败（65过，六次无种子搜枪全空）的原档与证据，不复用它的成功行冒充新二进制。第二候选从头运行所有门槛。开发引擎模板专属guard原拒绝仍保留，没放宽。
- 同目录verify_failed_profile_binary02.py引擎route/read已过；原外层footer被拒后，另用finish_failed_profile_binary02.py对同一原始证据复核通过：须candidate02_complete存在且true才运行；原build01的9返营profile整文件拷进独立userdata，用当前EXE正常BOOT/E/TAKE/返营/装备/实战/read，保持原文件与所有原游戏字段，不重置/授予/定seed。结果failed_profile_binary02_complete.json为准。
- 这还不是可交付新游戏ZIP：修正版手部与标签的原生复查、独立ZIP/CMD矩阵/截图仍未完成；原生5–8分钟问题仍待回复，不重复问/不默认同意/不复用已结束前台时段。contactdev/native_hold.flag仍在；若用户在长headless过程答复方便，先说明当前项，短时段过期要另约，不能强制focus或关失焦暂停。窗口批次结束后才开图。
- 当前手部原生副本已额外同步后来builder2/空跑3五文件，native_support_sync01.json核4078非文档输入与Root一致、project.godot仅隔离app名；初始source_manifest不覆盖，旧版本备份pre_support_sync。现在应使用contactdev/verify_native02.py，native_results02.json三项当前headless预检已过（PTY7981终态0），native_hold.flag仍在。收到真实新的前台答复后精确删除自有flag，默认运行02续余8；不要运行旧01或在这个有外置diagnostic的副本做全量。窗口期间不开图、不关失焦暂停/强制focus。
- 外层原失败档校验首次KeyError: find（读回证据没有顶层find，正确字段在profile_after.inventory）；原script/log/两行engine结果及footer拒绝记录全保留。finish_failed_profile_binary02.py在同一两份日志和原JSON中核真正读回的同ID/配件、已装备primary与全部游戏字段（仅排stash显示格位）；没有重跑路线/重置存档或放宽保留要求。62609终态0，72106为footer失败终态1，7981终态0，当前无活引擎或job，不再轮询这些handle/旧process.json。
- 当前Root源码完整基线 D:/tmp/bunny_archive_support_20261021_final01 已终态126scene/242gates，SHA c7b33413fd6dc6863df5742cfd375a707725379ddaf1f2955a6cc616f2ca89f3，4078输入匹配。此后本轮没有改运行时代码，只做当前编译和隔离原失败档二进制验证/文档；hand5+builder2+support3已在该full中。原source/fixture旧failed logs、存档和已交付文件均保留。
- goal active：5小时真人首通、公开许可、实际80%评价、听感/低配/干净机仍缺，不加游玩分钟或宣称公开可发。无上传、commit/push、作者联系、换模、付费源导入或子代理。

<!-- maintenance-candidate02-current-end -->

<!-- archive-support-current-start -->
## 上一轮源码与空跑支援记录 已由顶部候选状态更新

- 本轮progress：先补两个私人Windows模式maintenance_shared(Node3D)/shared_earned(Node)与七个导出检查，两个builder文件的差异见 D:/tmp/bunny_maintenance_package_20261021_dev01/builder_mapping_delta01.json。源引擎预检虽printed PASS和exit0，但模板专属guard有ERROR，外层正确判false，editor_preflight_rejection01.json保留；**未放宽guard**。随后真实导出候选 D:/tmp/bunny_maintenance_shared_20261021_build01 在第66项失败（前65过，前三个新shared组件/read/pending过），不是合格候选、没交付/新游戏ZIP。candidate01_rejected.json记录真实6次无seed档案室全空；原9返营profile和日志保留，没清档重抽。wrapper52801/child48716终态1，不再轮询。
- 实际解决空跑而非刷绿QA：源码在仓库/装备无有效fitted gun时，原档案室高价值箱保证多一把现有三种随机改装枪；已有则35%，只有kit不算。失去/卖掉最后一把可再次支援，不是永久首取标记或计数条。原core/普通RNG/物品40/掉落表数/位置nav/敌人/任务/schema不改。LootSpawnPoint显式chance>=1同时仍消耗同一个bonus_roll，避免randf上界令“保证”落空；已有挂起/空箱不补发。必须真实TAKE/负重/安全返营，不送仓库/弹药/主线进度。
- 新dev D:/tmp/bunny_archive_support_20261021_dev01，三文件（street_district.gd、loot_spawn_point.gd、recovered_arms_test.gd）审过集成，source_integration01.json，原件pre_integration_root保留；其余Root4074个非文档字节未改（另隔离project.godot不复制），6保护文件及原失败profile hash+mtime不变。support_results_complete01十一项过：组件1123（原35%500roll仍185；新无枪支援500全有、core/普通流不改、条件/反复滚/旧档/死亡等），其read、shared三项、carrier两项、原失败档副本实际9→11首次找到消音AR/装备再战9shots3kills/1.84s及read，英文真实3→5找到观察镜R7/装备实战2shots2kills/2.42s及read。全是无界面合成输入，不是真人时长/乐趣或native画面。
- 完整Root新快照 D:/tmp/bunny_archive_support_20261021_final01 已终态126scene/242categories全PASS，full_source01_complete.json为准，SHA c7b33413fd6dc6863df5742cfd375a707725379ddaf1f2955a6cc616f2ca89f3，4078个Root非文档输入匹配、6保护文件hash/mtime不变。PTY11688/child36468已结束，勿再轮询。
- 当前相对旧full D:/tmp/bunny_maintenance_shared_20261021_final01 的明确增量：手部5文件+builder2文件+空跑3文件，共10。新完整若过才覆盖当前运行态；builder的真实导出候选01早于新空跑规则且已失败，不能冒充新规则的binary证明。下一候选应新目录build02，预计仍140导出门槛（旧133+新7），不得覆盖/复用失败候选结果；新源码之后再改需明确delta。
- 手部修正版的5–8分钟前台问题仍待回复，**不要重复问、拿默认选项/旧结束时段当同意**。准备的native runner在 D:/tmp/bunny_maintenance_contact_20261021_dev01/verify_native01.py，native_hold.flag仍在，native_results01仅3headless预检。其contact脚本与Root仍相同，后来builder2/空跑3不在此snapshot（手部画面scope明确）；新Root完整不要用带外置diagnostic的contact snapshot跑。引擎必须串行，若用户在长headless过程答复方便，先告知当前项，不占旧短时段/强制focus或关闭失焦暂停；过期时另约实际可用时段，不假定无限有效。原生完批才看图，须审手指/杆与标签而不是仅坐标；未合格不交付。
- 现在完整job已结束、没有活引擎或job；本轮import96248/preflight拒绝/QA wrapper52801/import27184/target73840均终态，勿按旧active_support或process.json猜活。docs/RECOVERED_ARMS及两个validation、README、FIVE_HOUR/MAINTENANCE已同步WIP、原失败与当前范围，现有已交付carrier ZIP/个人profile/.bak/Arcana/旧ZIP均保留。没有新游戏ZIP/launcher矩阵/上传、commit/push、作者联系、换模、付费源/子代理。goal active：5小时真人首通、可公开权利、听感/低配与真实80%口碑仍未满足，不添加游玩分钟。

<!-- archive-support-current-end -->

## 前一轮手部修正集成记录 已由顶部当前状态更新

- 本轮progress：修许棠手未贴把手和标签遮挡。新dev D:/tmp/bunny_maintenance_contact_20261021_dev01，Root三production（shared_survivor/cache/zone）+两QA（maintenance_shared_test/tools maintenance_shared_run）五文件审过并集成，source_integration01.json和pre_integration_root备份。其余4072非文档文件不变，隔离project.godot未复制，原v1/v2/基础Survivor/碰撞nav/schema/奖品/主线不改；6保护文件hash+mtime复核仍不变。
- 新HandleReach是v3专用SkeletonModifier3D内类，在原动画后仅旋转真实臂链/手腕。核过BoneMap和臂长；原站距/低把手确实超自然范围，故helper沿真实nav走到-.72侧、停距.06、朝把手，双手目标在有支柱的1m握杆。无骨骼位移缩放/角色瞬移，.2s左右上肢贴合过渡；实际两掌接触才ready（不是仅Interact名）。够不到不ready不开箱，走开取消清任务/pose；原等待标志保留。v3缩小远世界标识、近处以HUD提示，隐藏叠在同点的物品名字但正常检查UI名字保留；不改箱位置/掉落。
- contact_results_complete02.json十一项PASS：component05、其read/pending、上一完整基线原字节v3签名开箱/中断档read、原art02/journey02、普通中文earned_zh02与英文救援优先earned_en02及各read。真实6→7、活AI实弹/正常E/TAKE/救援撤离。component测60帧双掌，max误差 2.69739825853321e-06m、臂段长变化 1.34110450744629e-07m，所有受影响骨骼position/scale不变；明确半尺寸rig仅受控够不到负例，不出现在earned。正常两路线各实际两掌坐标证据，不能冒称手指握姿/演出画面已过。
- 初component01 helper名set_basis撞Node3D原生方法被拒；component02 QA错要求原动画pelvis也不平移，原失败QA保留后改查实际受影响臂链并追加真实臂段长；component04 QA Variant推导parse失败，无timer可退出，仅在CIM证明自有22100(parent24404/精确project+scene)后停止，false结果/owned_process证明保留。后续修明确float才过。development_failures01.json；不改写旧失败日志。
- native新runner已准备在本dev verify_native01.py；--headless-phase已终态0，当前native_results01.json仅3pass（外置contact_native_diagnostic当前代码/独立read/pending）。native_hold.flag在。**新的5–8分钟前台问题已问，尚无回复，不能拿旧已结束时段或默认选项当同意**。收到真实新回复后精确删本dev自有flag，默认run同一脚本续余8，双renderer受控camera近景和普通earned各read，带420s新native启动边界。当前external-only tests/contact_native_diagnostic.gd/.tscn不在Root/出包，不用这个多一scene副本做完整场景数。批次结束才看图，并审真实掌/手指/握杆、标签、普通UI，不能只看坐标宣布视觉过。
- 所有引擎串行。本轮import85781/target76573/headless35694已终态0，失败41562终态1，勿轮询/按active_case元数据猜活；当前无运行job。上一轮83428/8785早终态。旧完整126/242来自D:/tmp/bunny_maintenance_shared_20261021_final01，是本五文件之前基线，不覆盖新修正；新full尚未启动。已备好本dev/full_source01.py，下一新目录D:/tmp/bunny_maintenance_contact_20261021_final01，预计仍126/242；从Root新快照、6保护检查，需终态complete才算过。若窗口新回复到达，别并发引擎或让短时段在长headless任务中耗尽；先安排窗口，结束后再新full。
- docs/MAINTENANCE_SHARED及validation、README、FIVE_HOUR已明确新差异/原生待验，不冒称新full、手指接触或最终画面合格。Windows builder mappings尚未新增shared/shared_earned，本轮未新出Windows、未动已交付carrier ZIP、用户档或模型。goal active：五小时真人首通、许可、听感/低配/实际80%评价未满足，不新增已测分钟。无作者联系、换模、付费源导入、上传、commit/push或子代理。

## 修正前的原生与完整基线记录 已由顶部增量更新

- 用户本轮重新确认前台5–8分钟，并答复互助开箱专门问题。verify_native01.py已终态0（PTY83428）；四个native加对应read与三项前置共11全过，native_results_complete01.json。已告知用户窗口批次结束、可以切走；**本次方便时段已结束，不沿用到下一批**。无待答前台问题、无原生引擎；没有关闭失焦暂停或强制focus/unpause。
- 窗口结束后亲看10张当前图，native_visual_review01.json：两种renderer近景手腕未贴把手，工具箱标签遮挡人物，正常俯视loot标签也重叠；所以native gameplay/read PASS，但visual release gate FALSE，不能以Interact名证明手部接触。中文实际快装kit，英文消音kit，正常TAKE/救援6→7/活AI/实弹/真实返营和独立BOOT同实例过。既有灰盒/切墙/结算对比度仍在。**未出新Windows，不给用户交付未通过演出的互助包**。
- 本轮完整Root新快照 D:/tmp/bunny_maintenance_shared_20261021_final01：126scene/242categories全部PASS，wrapper full_source01.py终态0（PTY8785，child27512已结束），full_source01_complete.json为准，results SHA 0994c6d911426fd143957bb3b3cfb1bbe2ee13339d26cef9ba869299d828c86a；4078个Root非文档输入全匹配，六个保护文件hash+mtime不变。没有复用带外置diagnostic的source01做全量。冷导入既有FBX警告保留，测试错误为0。不要再轮询83428/8785或依据旧process.json重启。
- docs/MAINTENANCE_SHARED及validation、README、FIVE_HOUR已同步“逻辑过/演出未过”。运行时代码本轮无修改；新外置full/review/docs helpers不入Root。旧source01保持接受测试的原样，外置diagnostic仍仅受控观察camera，不是普通earned画面。
- 下一步修v3专用SharedMaintenanceSurvivor手臂/黄铜把手贴合及shared_cache标签层级。参考现有seat_moment.gd旋转式两段手臂reach，但CC0骨架名称/骨长需先核；不要挪/伸长骨骼、传送helper或只改测试阈值来冒充接触。先隔离修改和实际骨长/范围/取消/恢复headless验证，再取得新的前台时段做当前版本双renderer近景及普通路线。运行时代码一旦变更，本次242只作明确旧基线，不能冒称覆盖新差异。之后才补build_local_windows/local_build_probe的shared及shared_earned私人映射和新Windows候选；已交付carrier ZIP保留。
- 所有新证据/helpers在 D:/tmp/bunny_maintenance_two_person_20261021_dev01。goal active，五小时真人首通、公开资产许可、真实80%好评/听感/低配仍未完成；不添加游玩分钟。无作者联系、换模、付费源混入、上传、commit/push或子代理。

## 前一轮源码集成记录 已由顶部验收结果更新

- 本轮progress：Root已新增E请许棠实际走到另一把手、以现有Interact动作就位、玩家拉扣再真实取货的可选行动。保证1既有快装/消音/观察镜kit，另1药房常规随机物资（不一定是药品）；不是新永久属性/材料条。原两医疗箱/主线/敌人/碰撞nav/蒸汽周期/schema不变。v3专用shared_survivor脚本，v1/v2原图及原Survivor逐字节保留。原等待/跟随标志保留，走开取消，无传送/锁玩家/禁AI/直接奖励；0.65s仅开锁后NPC收尾，领取不等待。
- D:/tmp/bunny_maintenance_two_person_20261021_dev01/source_integration01.json记录Root9changed+14added。物品仍40、loot表11→12、译文1789（原1776逐值保留）。随后post_integration_dialogue_qa02.json明确4文件对白/QA实际locale增量；新对白“我一个人掰过这个盖子/谁赢了/盖子/替你报仇/这回一起”，不再让两个可见把手和“在我兜里”矛盾。未拷隔离project.godot、私人档/付费源或换主角。
- earned_results05八项过：component09/read09/pending_read09和普通中文预清、英文救援优先两条真实6→7 E/TAKE/活AI/实际弹药/救援返营/独立BOOT；分别观察镜/消音kit，ready clip=Interact。该8项早于仅对白/QA locale增量；当前集成副本另有native_results01三项source_component/read/pending_read过及loghash。**仅3/11，尚未开始native**。受控新造parts只验证合法exchange，不出现在普通earned里。legacy_results01五项过（前版源码签名v1/v2档原字节、v1救援/v2蒸汽/既有美术碰撞nav），不冒充所有历史导出矩阵。
- 失败保留：earned01接近目标落在Bed1Body，原档/旧scene留存后箱移空地；earned02实际跟随停距令她离箱3.32m，原档留存后改明确帮忙任务，不放宽导航或距离、不宣称两个旧失败world已恢复。早期JSON版号/string比较及read崩溃证据也保留。当前number防护、未滚物品/超2槽拒绝、合法exchange和中途帮忙请求读回均已测。
- Root与D:/tmp/bunny_maintenance_shared_20261021_source01/project：4077个非文档文件逐字节相同，另project.godot只改隔离app名，其余配置文本相同；总4078，integrated_snapshot_match01.json。Source01只是--import-only，终态0、两条既有FBX BadUTF8 warning留存；后来4文件已明确同步。外置tests/shared_native_diagnostic.gd/.tscn不在Root/出包，所以不要在这个多一测试scene的目录跑完整场景数门槛。完整应从Root新建D:/tmp/bunny_maintenance_shared_20261021_final01，当前tools/verify_migration.py已保留旧125并加1scene/2read/4普通earned门槛，计划126scene/242categories；**完整尚未运行**。
- 新5–8分钟前台方便问题已问，尚未有回复；native_hold.flag在，不能用默认选项/旧已结束时段当同意。准备verify_native01.py：headless-phase已终态3项过，收到真实回复后精确删自有flag并默认运行同一脚本，续余8（双renderer受控close-up各read，双renderer普通earned各read）。只改受控观察camera并量手腕，不改身体/奖励/碰撞。原生期间不开图/面板，不关失焦暂停/强制focus/unpause；图等批次结束再看，必须亲查手/把手和提示，不能只以Interact名证明最终接触。
- 当前没有活引擎/verifier。87299/4159为失败终态；4700/86034/91547/13980/55564/63376均终态，不再轮询。native_active_case元数据是已结束headless，不是活进程。diagnostic_headless_preflight01已实际终态0（自有32972已结束），diagnostic_preflight01.json=true；外置camera脚本编译/受控headless检查过，但不算native。不要按旧状态文件猜活。若仍无窗口回复，可继续Root新完整无界面回归或私有build映射，不把等待许可/窗口当停止制作理由。
- docs/MAINTENANCE_SHARED_2026-10-21.md及validation、README、FIVE_HOUR已标源码WIP；新内容不在下方已交付背架包。六个保护文件含新ZIP hash/mtime复核不变；最终目录可能已被用户玩，不删userdata。未新增Windows/上传/commit/push/作者联系/子代理。goal active：五小时真人首通、正式音画/听感、低配/干净机器、可公开许可/平台页及真实80%评价仍缺；不加已测分钟。

## 最新交付 背架改装 Windows 本地包已验收 2026年10月21日

- 本goal turn为progress：当前候选真正完成并创建未预玩交付 D:/tmp/小兔试玩 背架改装 20261021 01/LOCAL_ONLY_DO_NOT_UPLOAD。新“预览轻便挎包.cmd”和“预览重载背架.cmd”来自本候选实际7→9带回/选择/装备/再出击的原字节示例，14入口各自存档；主线仍哨卡，9返营不是9剧情。3kg旧架消耗1换1，无额外刷钱材料，27kg/+0.55/1.2kg与47kg/-0.90/4kg，原35kg/2kg保留。旧已开仓不补发，不再误提示；旧未开仓第一次开才按新表。
- build D:/tmp/bunny_recovered_carrier_20261021_build01。compiled133终态0；独立ZIP72及全部语义后置条件终态0（最后PTY31011），CMD26成功/14组+预期invalid exit1过；1639 PCK范围/MD5全验，13真编译预览及metadata完整。finish_packet01.py已实际终态0，delivery_complete.json为准。最终38静态文件与同一ZIP全部匹配，官方4.7.2 release EXE相同。不要重跑finish覆盖已存在最终目录。
- ZIP246309576B，SHAb20b04ee1a281e7d51d555c82b878b73a3e894ea5a88cef5efaa59723197ccd5。docs/CARRIER_WINDOWS_2026-10-21.md和carrier_windows_2026-10-21_validation.json为当前交付；README/FIVE_HOUR/PUBLIC_PLAYTEST与源码carrier说明已同步。旧改装枪与广播装箱ZIP不改。
- 当前真实新包普通路线：中文Forward+轻便与英文Compat重载均7→9，活AI/实弹/碰撞/真实cache TAKE/实际Su Mi选项/仓库装备/正常MENU保存，带同一个包下一局实战搜货/撤离/返营/独立BOOT。二者下一局实测8.75与7.3m/s，ZIP中文6shots2kills、英文3shots1kill，都是精准合成控制，不是真人难度或分钟数。旧恢复世界与战备35/60也在当前ZIP独立实跑过。
- 三批前台都有新用户确认。PTY66124与27281各12native后按边界3退出（shell1），43/72和64/72全过，不是测试失败；最后用户确认5–8分钟后31011续8到72终态0。已通知窗口批次结束，可以切走。没有活原生或待回答前台问题；未关闭失焦暂停/强制focus/unpause。所有截图在批次结束后才看；visual_review_complete.json记录12张当前ZIP亲看及hash，含8背架相关和4旧流程抽查。图标占位、英文Freight Fram裁剪/信用点后缀、灰盒切墙黑区、结算左文对比度等仍保留，不冒充美术完成。
- source full03终态125scene/235categories，SHA73bf6d252d5f5bd4915726dbc3d5def8ed743acbde56dd59b777f2a846283f75。post_full_source_delta.json明确后续5changed+2added（QA下次实战/构建映射/旧开仓提示及测试），不拿235覆盖后续全部差异。交付时4064个非文档Root输入与build快照匹配；顶部WIP是之后的明确源码增量，不在旧包中。早期full01/full02、nativeForward06原因未证、raw tree.quit漏正常保存、parse等失败原证据保留；后续成功不倒推早期原因。
- 发行审查有具体进展但未清关：当前30份伴随许可及engine notices与manifest逐项匹配，docs/runtime_rights_2026-10-21_validation.json。Women官方glTF目录有SciFi但下载遇Drive quota，未完成字节匹配、不改原Males license或绕配额。MCO免费动画Standard许可不直接证明其M4参考模型/贴图范围；Artoria权限仍未建立。无作者联系、换模、付费源入默认包、上传、commit/push或子代理。个人profile/.bak、Arcana和两份旧ZIP hash+mtime不变。

## 早期隔离试作记录 已由顶部当前源码更新

- 在等待前台期间已实际制作 D:/tmp/bunny_maintenance_two_person_20261021_dev01/project：维护区v3可选双把手工具箱，须已释放许棠、两人实际近距且各自视线无遮挡；打开后两份普通维修掉落，原两医疗箱保留。没有主线新门槛/长计时/永久奖励/免费入库，沿用拾取、负重、失败与checkpoint；v1/v2继续选原图。
- prototype_scope.json和targeted_results04.json为当前隔离证据：7项全PASS含component03、read04、两份前试作源码真实签名v1/v2中途档逐字节副本读回、原v1救援和v2蒸汽回归。当前新增类型负例防JSON float版号/字符串；v3专用shared_zone恢复刷新使暂停读回也不显示锁箱旧外观。**这些不是普通earned路线、原生图、最终双人手部接触动作或Root集成证明**。不在新背架Windows包，不增加分钟数。
- 初read01因JSON float与Array.has比较失败后只核CIM自有31332(parent45368,明确隔离project+scene)停止；原checkpoint与日志不改。read02同原档数值比较后过；追加component02又暴露String/int比较SCRIPT ERROR，虽印PASS(28)仍被外层拒绝。targeted_results01/03 false保留；现加SaveService.is_number后04七项通过。冷导入两条既有FBX BadUTF8 warning保留。PTY73143/67525/35820均终态，04引擎无活进程，勿轮询。
- 下一步先从当前ZIP真实6返营maintenance预览原字节，在隔离副本用普通BOOT/出击、活AI/真实弹药与实际同行走到工具箱、E/TAKE、正常救援返营与独立read，不能传送许棠或发物品；可继承tools/maintenance_run.gd，在work(WardControl)之后增加真实同行开箱，return_from_debrief校验同一cargo。再补新箱未滚却有物品/超原2格伪造存档负例（不能破坏合法exchange_cargo），以及旧实际导出档范围与渲染/接触检查。project.godot是隔离改名，未来不可直接拷回Root。完成后只集成审过的增量，再做新源码/新Windows，当前已交付包保持不动。
- goal active：五小时真人首通、可公开许可、实际听感、低配/干净机器与真实80%评价都尚未完成。下一批必须继续可玩行动/人物互助，不以更多菜单/审查文档/回归计数替代内容。

## 上一版 改装收获 Windows 本地包已验收并交付（2026-10-21）

- 最新且未预玩的目录：D:/tmp/小兔试玩 改装收获 20261021 01/LOCAL_ONLY_DO_NOT_UPLOAD。新“预览改装收获.cmd”是当前编译真实搜到、带回、装备、实战返营的R7原字节示例，不注入三枪；主线仍relay，八次返营含搜索支线，不等于八段剧情。其他十一入口保留，各自存档不覆盖。
- build01已终态0，当前125类compiled通过；独立ZIP verifier03 PTY67690已终态0，最终60项+语义后置条件通过；CMD PTY95164已终态0，22次成功启动/十二组+预期exit1通过。finish_packet01.py已实际终态0，delivery_complete.json为准。所有这些handle/PID已结束，不再轮询、不重启或重跑finish（最终目录已存在）。
- 新ZIP 246268606 bytes，SHA256 65640f6ac95943c35dbe61c0b4cd187b3a5b787a356b1e03cce6a73639e8e682；PCK1611项范围/MD5完整，4047非文档Root输入与构建快照一致，全部静态文件/11示例实际来源/新枪元数据验过。个人profile/.bak、Arcana、旧PApacking ZIP hash+mtime不变。没有清空用户档/关闭用户引擎/上传/commit/push/作者联系/换模/付费源混入/子代理。
- 原ZIP试验01与02各有一次paused=true/flow_mode=pause失败，日志/结果false与原battle档均留存。01恢复诊断未运行到PASS同样拒绝；03只复用同一包48项已通过且hash复核结果，另用原3返营示例的全新隔离档重验失败项目及剩余12项，未重置原中断档、未声称它们原世界已恢复、未取消失焦暂停。历史失败世界续关门槛另外实际通过。用户回复方便保持前台后最终原生批次完成，全部截图在批次结束后才看。
- 当前独立ZIP实际新收获：F+六次自然搜索找到快装SMG（空箱也实际返回），英文Compat首次找到观察镜R7；两条均真实TAKE/撤离/仓库双击/再战/射击击杀换弹/返营与独立BOOT读回。新包12张实际图亲看，visual_review_complete.json，fixture明确分开。门口横梁部分遮挡与结算左文对比度仍待美术修整，不冒充完美验收。
- 源码124/231是掉落早期基线，后续配件标识与earned QA差异清楚列出，不借旧全量冒充当前新源码全量；当前二进制125/ZIP60/CMD22是真实本批。文档docs/RECOVERED_WINDOWS_2026-10-21.md及validation已更新。
- goal仍active：本批是第一步搜刮惊喜，不报新增游玩分钟或五小时/80%口碑达标。公开许可、实际听感、干净机器/低配和更多后区差异成长仍缺。接下来做后区独特收获、人物动机与可选择成长，不只堆售价/材料/重复刷取。先让用户试本交付，不再把未验收源码当已经发布。

---
## 以下为历史过程记录

下文“正在构建/当前真实工作/PID存活/尚未交付”等是当时状态，已被顶部最终记录取代，不应据此重启历史进程或覆盖历史交付。

## 最新：独立ZIP原生失焦一次，保留原场景，当前重验中

- 旧独立ZIP PTY66714已终态FAIL：前5（双渲染器改装组件、组件读回、双渲染器结算）PASS；第6 recovered_earned_forward 首箱自然空、真返营3→4，第二次走到档案室门口因**paused=true/flow_mode=pause**停止移动，不是可报告的寻路/赚取成功。portable_results.json原6 rows（含false）、原log与profile不改，focus_interruption_rejected.json有sha。原battle checkpoint原字节另存focus_interruption_original_profile.json，不能清空进度/关失焦暂停来通过。
- 当时也在工具中查看截图，不能确证焦点来自用户还是预览；后续将**所有图片/面板预览延后到原生批次全部结束**。已异步询问用户是否方便保持前台；未将默认选项视为回复。若用户说不方便，用build01/native_hold.flag阻止后续原生case，并继续无界面/文件工作，不暂停整个goal。
- 外置只读恢复诊断 focus_resume_diagnostic01 尝试release --script，自身未运行到任何PASS标记，exit0帧预算退出但外层明确FAIL；result.json=false，不算恢复或独立验收，不改PCK/源码/原始存档。没有把它算进ZIP60，也不声称原暂停现场已完成恢复。
- **当前真实工作是新外部verify_packet02.py**，PTY **26240**，Python/CIM身份在dev01/packet01_state.json/current_process。只复用相同未改PCK的5个已验证case及原loghash；用同一原始第三次返营示例的原字节，在全新portable_recovered_earned_forward02独立userdata重验普通赚取，不覆盖原中断档，不固定seed，不改碰撞/AI/伤害/暂停。然后继续原剩余55项；原50旧gates全部保留。新进度 portable_results02.json，原始portable_results.json false保持。只有portable_results_complete.json与semantic_acceptance能说明60项接受集完成；不能说所有尝试都PASS。
- 当前Native测试期间只续等相同PTY/核实CIM，不开图/页面，不强制focus/unpause。观察超时不重启工作。verify_packet02.py若检测native_hold.flag会在下一原生case前exit3并保留已接受记录，不会覆盖当前游戏。
- 当前候选仍build01编译125全PASS、PCK1611逐项校验和ZIP65640f6ac95943c35dbe61c0b4cd187b3a5b787a356b1e03cce6a73639e8e682。十二CMD/11真编译预览已生成（find为实际R7），尚未做CMD22或交付；个人存档、旧包与Arcana不变。未改Root运行时代码。后续只在相同ZIP全新CMD01目录做启动脚本检查，最后全新01目录才是未预玩的交付。

## 当前验收：改装收获 Windows build01 / 独立ZIP60运行中

- 上一goal turn为progress（UI标识/真实赚取闭环/启动build01）；本轮已完成当前二进制125类编译检查全部PASS，build PTY44695与Python42560终态0，local_build_manifest.json存在且125 rows全PASS，勿再轮询或重启。PCK1611项范围+MD5逐条通过，Arcana/CombatGirls/原始tools/tests/用户档与备份均未打包；新掉落、UI标识、结算和三个私有QA模式均存在，current_pack_audit_complete.json。
- 当前候选 D:/tmp/bunny_recovered_arms_20261021_build01 已prepare_packet.py成功：11份真正本候选编译流程的示例、12个CMD入口。新find来自compiled recovered_earned实际3→8（第4次搜索才找到R7，并实际4枪3kills/换弹2.42试枪），不是加枪或修改计数；主线仍在中继，所以说明明确返营次数不等于剧情出击数。伴随的recovered_run_expected.json也从该实际进程原字节复制，只供私有QA读回，不是奖励入口。
- ZIP已生成但**尚未交付**：D:/tmp/bunny_recovered_arms_20261021_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip，246268606 bytes，SHA256 65640f6ac95943c35dbe61c0b4cd187b3a5b787a356b1e03cce6a73639e8e682。独立解压校验文件逐项匹配官方release模板；验收目录 D:/tmp/小兔试玩 改装收获 20261021 验收01/LOCAL_ONLY_DO_NOT_UPLOAD。
- **正在运行当前ZIP独立60项**（旧50全部保留，加新10，先跑新10）：PTY **66714**，实际Python身份见dev01/packet01_state.json/current_process，命令新build01/verify_packet.py。portable_active_case.json与CIM核实具体当前子进程；所有Godot/EXE仍串行。观测超时不重启同一工作，结束才看portable_results_complete.json/semantic_acceptance。没有旧结果冒充本批。新scope包含双渲染器发现/仓库、主次结算、两条真找到带回装备再战和独立读回、现有find预览读回；普通自然空箱不补发。
- 新build01/verify_launchers.py已准备22成功启动+1预期失败，12组独立userdata，尚未执行。需先从相同ZIP新解压到 D:/tmp/小兔试玩 改装收获 20261021 CMD01（不能用被ZIP原生测试玩过的目录），再执行。新“预览改装收获.cmd”只在profile不存在时一起复制原字节profile与对应QA metadata，不覆盖现有进度；两次只读启动须保持全部游戏字段（仅允许普通BOOT显示格位初始化）。
- 之后仍需亲自查看当前包的原生图（新发现/实际装备/试枪/主次结算及必要旧路线）、验证新ZIP/全部静态文件/示例来源hash、制作全新未预玩交付目录 D:/tmp/小兔试玩 改装收获 20261021 01（目前不应存在）。确认所有实际过程终态再交付并写新Windows文档。个人档/.bak、Arcana、旧PA/packing ZIP仍须hash+mtime保持；Root运行时代码与build4047输入保持，不在本批上继续堆游戏改动。
- 外部helper均在新build01内，只读复用旧packet助手后明确扩展新内容；旧包与旧助手未修改。现有最终已交付Windows仍PA/packing build02，用户五小时/许可/真实80%好评仍未达成，goal active。不上传、不commit/push、不联系作者、不换模/付费源入默认包、不起子代理。

## 正在构建：改装收获 Windows 候选01

- **已确认真实活进程** Python PID42560(parent27228)，命令 tools/build_local_windows.py --godot E:/Godot/Godot_v4.7.2-stable_win64_console.exe --templates C:/Users/admin/AppData/Roaming/Godot/export_templates/4.7.2.stable --output D:/tmp/bunny_recovered_arms_20261021_build01 --smoke。PTY **44695**，下轮续等同一handle，超时不重启。dev01/build01_process.json和CIM可核实。当前在隔离project冷导入，尚无新的已接受包或ZIP。预计125类compiled不是已通过数量。
- 当前Root4047个非文档输入与build01源manifest逐字节一致，build01_source_audit.json；个人profile/.bak、Arcana和旧ZIP hash+mtime保持。构建结束前别改Root运行时代码或新QA，以免混批。docs可更新。没有用户编辑器/游戏被关闭；之前停止的42804仅为明确记录的自有崩溃QA实例。
- 构建完成需检查同一实际进程终态、build_results与最终local_build_manifest，再做当前二进制原生/独立ZIP/PCK/launcher验收。旧包仍PA/packing build02。建议新包增加“预览改装收获”入口，只能来自本候选recovered_earned真实流程的原字节已装备存档，不注入三把枪或个人档。不要覆盖旧包或未预玩目录。

## 当前 2026年10月21日 改装收获闭环已验证，准备Windows候选

- 上一goal turn为progress（真实新增掉落与组件），本轮为progress：掉落底座完整124scene/231 categories已终态PASS，结果SHA a9e9abeecfdc8e79e3ce42af426ba3e4de7b62f03dbe33eb594ba1ffcdef05d6，4044输入匹配；exec22539/wrapper23416/child22028均终态，勿再轮询。dev D:/tmp/bunny_recovered_arms_20261021_dev01，冻结final01。之后有明确UI/QA差异，不拿231冒充当前Root所有新增代码。
- 后续生产只做仓库格子/装备栏配件短badge、选择列表完整配件名和tooltip，3译文至1764。Loot数据、概率、碰撞、AI、伤害、保存无改。tests/recovered_arms_test增加实UI组件至617，双native各625通过。current_source_visibility_audit.json列9 changed+3 added，当前4047非文档输入；四张本轮当前图已查看，visual_review02.json（含实际中文装备与英文原场景实战，门口横梁仍会遮住部分人物）。
- 真正中文F+ earned_find_forward01=27 checks，从实际第三次返营编译示例原字节开局，首箱快装SMG，实际取走/撤离/仓库双击/下一场实战26发1kill、1.08秒换弹、返营3→5，独立BOOT读回过。英文Compat_en01两箱自然无枪、第三箱R7，实际带回装备；试枪房间无敌人且QA在退路交战前过早读统计，所以50checks明确FAIL。保留真实7次返营状态继续。
- QA retry en02误猜IndoorLoot1_0节点名（实际1_3/2_6/3_9）崩溃，已拒绝；只经CIM核验并Stop自有GUI child42804(parent46052, dev01/project/recovered_arms_run)，未停止用户游戏。原battle checkpoint原字节保存owned_trial_crash_profile.json及process.json，随后en03_resume用普通BOOT/RESUME同一未改场景，真实R7 1枪1kill/换弹2.42，返营7→8；英文独立BOOT读回过。无新seed、补发、定位、禁AI、直接伤害或强制focus/unpause。每次失败日志保留，不能合成全部尝试PASS。
- 其他QA失败：headless01同步读异步reload漏记；headless02 JSON数量float/native int比较，实际ID/装备一致，改为ItemInstance.from_dict规范化，随后同一赚到的R7普通试枪headless03过且read04过。owned_read03仅stash_layout普通BOOT显示初始化变化，原严格失败保留；仅豁免该显示字段，完整inventory/loadout/credits/progression仍相等。读取不赠物。
- earned_visibility_results02.json有原英文FAIL，不能全量判过；其余五个已接受case + earned_visibility_results04.json五个PASS及各loghash为当前证据。最新PTY70045已终态0（含最后weapon_fitting/stash_rotation/debrief专项），旧58100/18371终态FAIL，勿重启/轮询。原强组件、QA wrappers和新earned脚本分别有scope记录；脚本已用真实campus_storage元数据解析公共补给点并观察整条路线含退路，shots/kills/reload标准未放松。
- 新工具tools/recovered_arms_run.gd/.tscn/.uid只做QA；Windows构建私有映射已补recovered_arms/recovered_earned/debrief_guidance三模式，预计新增五类compiled checks至125，尚未开始或宣称通过。下一目标 D:/tmp/bunny_recovered_arms_20261021_build01，新目录，模板 C:/Users/admin/AppData/Roaming/Godot/export_templates/4.7.2.stable，--smoke。完成本轮源证据后立即构建；候选/ZIP/launcher未验收前不交付。
- 个人profile/.bak、Arcana、旧ZIP hash+mtime不变；无commit/push/upload、作者操作、换模、付费源默认入库、子代理。旧Windows仍PA/packing build02，既无新结算亦无改装收获。goal active，五小时/许可/真人口碑未达成，不加游玩分钟。先交付本批，再补后区独特收获与可选择成长，不以刷材料/售价/掉率/测试数量冒充内容。

## 当前进行中 2026年10月21日 改装武器搜刮

- 已实现首批真实源码收获：原校园档案室高价值箱核心保持，35%额外三选一（消音AR、快装SMG、观察镜R7），既有实例fitting槽，无伤害/永久加成、弹药赠送、新箱/任务/碰撞/敌人或schema。开箱显示好处/代价，背包标注，仓库tooltip详述；普通loot RNG不变，旧挂起不补发。新资源campus_recovered_arms已ContentDB注册，译文+4至1761，旧1757逐值保留。
- dev D:/tmp/bunny_recovered_arms_20261021_dev01，import01 clean；新增recovered_arms_test headless592/native各598 + 独立read2，三种具体枪的失败/成功/重复提交/下一场装备射击换弹等受控fixture通过。500seed额外185，原普通RNG逐次相同。targeted_results01.json十一项均PASS，四张当前原生图已亲自查看，visual_review01.json。原生fixture禁敌/冻结/放置明确标注，不是 earned 实战，不是用户乐趣/时长证明。
- **最新完整源码正在运行**：PTY session22539，full wrapper D:/tmp/bunny_recovered_arms_20261021_dev01/full_source01.py，verify child PID22028，输出 D:/tmp/bunny_recovered_arms_20261021_final01，预计124scene/231 categories。应续等同一PTY/核实活PID与结果，不因等待超时重启。只有 full_source01_complete.json 才确认全部完成，结束前别改Root运行时代码（wrapper会逐字节比较）。tools/verify_migration.py已加入124及新scene/read最终marker。targeted PTY40319与import11469均终态。
- 结算批次已完成123/229但不覆盖本批新掉落；旧包不含本批或新结算。当前个人profile/.bak、Arcana、旧ZIP的hash+mtime再核对不变。没有新EXE/PCK/ZIP、commit/push/upload、作者操作、换模或子代理。新docs/RECOVERED_ARMS_2026-10-21.md和validation状态为running，完成后要更新。
- 接下来不是再加一层材料：先补普通出击实际发现→开箱取走→实际撤离→基地装备→下次实战的earned route；组件三把枪是夹具，不能替代这条验收。再依据玩家“搜刮和成长缺乏惊喜”做后区独特收获与可选择成长，不只加掉率/售价，不报新游玩分钟。goal active，五小时/许可/真人80%好评未达成。

## 当前源码 2026年10月21日 主次结算分离

- debrief_guidance已完成源码完整回归：123 scene／229 categories全PASS，结果SHA256 3af259c159a57e9a2612e86b3951948c48f25f3f25cc4399dc2d355fe7961851，4040个Root非文档输入逐项匹配。dev D:/tmp/bunny_debrief_guidance_20261021_dev01，冻结final01；full_source01_complete.json为准。exec17334及wrapper/child已终态，勿再轮询。
- 新21种结果×双语夹具614、双原生各622；另两条普通BOOT实际relay 3→4与独立BOOT读回全部通过。仅分离主线、可选目标、撤离与待返回保存；无奖励/进度/世界变更。5张当前图已查看；初次capture脚本错误、布局02/03失败保留。个人档/.bak、Arcana、既有ZIP不变。
- 未生成新Windows包，下面旧交付的hash和120/50/20仍是历史真实证明，不覆盖本批新UI。后续源码变化不能借用此229作为新全量。
- 最新用户反馈：搜刮和成长缺乏惊喜。优先做能带回、改变下一局配置且有取舍的发现；不加售价/掉率/计时器凑内容。goal active，无新增游玩分钟、公开发行或80%口碑声明。无commit/push/upload/作者操作/换模/子代理。

## 当前交付 校园广播与战备引导 Windows

- 本轮为progress：将已验证生产内容真正装进独立Windows包，并完成当前二进制验收，不增加章节或游玩分钟。新doc docs/CAMPUS_WINDOWS_2026-10-20.md，机器记录 docs/campus_windows_2026-10-20_validation.json；五小时、正式音画、许可和真实80%口碑仍未完成，goal active。
- 当前build D:/tmp/bunny_campus_pa_packing_20261020_build02：120类编译全过；独立中文路径ZIP50全过，十一组CMD20成功＋预期错误exit1过。源码冻结仍 D:/tmp/bunny_packing_guidance_20261020_final01 的122scene/228类；当前生产运行时代码逐字节保持，只有 tools/build_local_windows.py、tools/local_build_probe.gd、tools/relay_diversion_run.gd 三项私人QA/harness差异，source_provenance02明确记录。当前Root与build的4037个非文档输入匹配。不能把旧228说成新QA所有代码已经同批全量测过。
- ZIP D:\tmp\bunny_campus_pa_packing_20261020_build02\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip，246229484B，SHA256 5c6f31094b82ae4aa184eeeaaa90a2e1596895f72de2c677e7b06cc52a46bc6d。未预玩交付 D:\tmp\小兔试玩 广播与装箱 20261020 01\LOCAL_ONLY_DO_NOT_UPLOAD。预览中继广播.cmd→继续→作战室→确认；十份示例来自当前编译正常流程，十一入口进度隔离，不包含个人35/60档。上一药房ZIP b4a1da82...与fresh04保留。
- 当前ZIP广播Forward zh18 checks/9shots/3kills/260HP，Compat en19/6shots/2kills/260HP，3→4及独立BOOT读回。当前ZIP装箱Forward23、真正English Compat25，原35/60外置副本仅花75补25，保持原装备/携行计划/返营，finished仍false，独立读回过。个人profile/.bak与Arcana hash+mtime保持。18张当前编译原生图已逐张看，out/compiled_visual_review.json，不复用source/build01图；Dummy不代表听感。
- 第一候选build01编译120，但ZIP第39项失败：非暂停，接近开关时QA无条件release fire，被45HP CampusInfected10实体挡住。原失败及原字节现场4efc0386...保留，不交付、不改成成功。只去掉QA禁火，未改生产AI/碰撞/伤害。当前build02既测原出击前档，也用原失败现场BOOT/RESUME，实际观察原敌人died信号、使用广播/维修/记录器/撤离，3→4，156.32HP，独立读回通过。源码恢复01因读取已释放尸体对象出SCRIPT ERROR，虽旧PASS仍拒绝；恢复02用死亡信号＋完整返营记录过。记录dev01/pa_approach_diagnosis.json及source_resume01_rejected.json。
- 当前build02 ZIP50全新跑完，无复用旧候选成功行。CMD第一轮relay_read engine PASS但外层hash失败，保存原两行launcher_results.json及launcher_original_attempt_rejected.json；原始profile与bak只有stash_layout不同。相同ZIP另解压CMD02，在完整raw envelope对比中只允许该正常BOOT的显示格位变化，其余读回仍字节相等，20项通过。最终launcher_results_complete.json/expected_negative02.json，packet02_state为terminal_pass_with_launcher_harness_continuation。勿用原两行失败记录冒充20成功。
- 本轮串行进程已结束：build02 exec43470、packet02 exec51298（CMD首轮失败终态）、CMD续验exec45258均关闭；不要轮询旧handle/PID或按状态文件重启。此前source228的exec57202早已结束。dev D:/tmp/bunny_campus_pa_packing_20261020_dev01；helpers02与finish_packet02.py已成功执行，fresh01已存在，不可重跑覆盖。
- 下一生产修正：结算仍把未做的可选档案任务写成笼统“任务未完成”，虽校园已推进，应明确主次。英文商店信用点后缀仍中文；灰盒场景和尸体表现也不算美术完成。完成这项误导修正后继续补有意义局内遭遇、人物动作与情绪片段，不继续用测试数量或等待凑五小时。
- 无commit/push/upload、作者联系、换模、付费动作入默认包或子代理。本轮Blender MCP仅核对已安装并加载，没有为用工具而改资产。

## 当前源码 2026年10月20日 战备装箱引导与广播原生验收

- 本轮progress：玩家刚遇到的35/60卡点已改成实际可走的游戏内引导。作战室入口明确装箱／接应，沈砚霜委托最上面显示仓库缺口；跳到正常交易后将缺货置顶、按实际缺口预填数量，返回委托后仍须玩家点击提交。原有价格、确认、分批消费、身穿护甲保护、现场接应、撤离和存档schema不变。
- controlled packing_component03共44 checks，中英文／身穿与耐久／不同弹种／缺口／导航不消费／改键／布局通过。用玩家当时原字节35/60存档（D:/tmp/bunny_campus_help_20261020_01/profile_original.json）仅复制到隔离目录，正常BOOT+Continue与窗口鼠标完成中文Forward23、英文Compat25检查；都只花75补25，原库存／装备／携行计划／返营数保持，finished仍false。两者独立BOOT读回通过。当前个人profile的hash与mtime和本轮起点一致，没有再操作个人进度。
- 原native Compat01虽正常购买提交过，但BOOT重读默认语言后实为中文；不算英语验收。QA仅将英语偏好保存到隔离目录并显式检查实际locale=en，再用全新原字节输入跑Compat_en02及读回，两者过。组件01有parse error且exit0，已拒绝；组件02／diagnose01卡片位于对白下方超出17px，生产放到真正顶部后通过，未放松边界断言。所有尝试保留。
- PA普通原生路线也完成：中文Forward17检查，9shots/3kills/172.16HP，激活时没有新听者；英文Compat18检查，15shots/5kills/260HP，实际StreetPMC1针对Speaker(-50,0,-43)进入INVESTIGATE。两条都真的按交互键、完成双relay＋recorder并从3返营到4，独立BOOT读回过。没有强制focus/unpause、定位、伤害调用、加物资或禁AI；精确合成控制不是真人平衡／时长，Dummy不是实际听感。
- 本轮已逐张查看装箱8张＋PA5张当前原生图，sha见 D:/tmp/bunny_packing_guidance_20261020_dev01/visual_review.json。新中文译文12条，总1734，原1722逐值保留。既有引导／校园／经济／联系人／基地UI与普通读回六专项过。冷导入仅两条既有FBX UTF8警告；git diff --check无错误，旧autocrlf提示不改设置。
- 上一PA冻结源码 D:/tmp/bunny_relay_diversion_20261020_final01 的121scene／227 categories现已确认全部PASS，旧“运行中”记录已纠正；不是当前新UI的全量证明。**新完整源码已终态PASS：122scene／228类别全部通过**，输出 D:/tmp/bunny_packing_guidance_20261020_final01。原exec57202已结束，wrapperPID33096／verify childPID34008及本批Godot均已退出，勿再轮询。结果SHA256为6a303b8540402e68e3804ea0116f320c78dd09c10fa73383958cdf44992e3be1；结束后当前Root的3969个非文档输入与冻结manifest逐项一致，个人profile的hash和mtime保持。命令与日志保留在dev01/full_source01_process.json、full_source01_runner.log，当前源码审核current_source_audit.json。
- Root运行时代码已经复制进新完整回归；其后只更新说明和验证记录。证据 docs/campus_packing_guidance_2026-10-20_validation.json 与PA validation为准。新tests/campus_packing_test和tools/campus_packing_run的UID已从隔离导入保留。工具安装在用户.codex外置目录，Blender MCP现在已在工具列表出现，不为使用工具而改角色或引入新资产。
- 未生成新EXE/PCK/ZIP。122/228源码已通过；下一步把PA与装箱引导纳入Windows候选的private QA映射、编译、原生和独立ZIP验收，避免继续在未交付分支堆改动。当前仍以药房build02/fresh04为最新Windows交付。实玩另发现结算会把可选档案目标未完写成笼统“任务未完成”，尽管校园主线已推进；保留截图，后续应明确主次，不改奖励或凭空补完成。
- 无commit/push/upload、作者操作、换模、付费动作入默认包或子代理。goal active；本轮不计新增游玩分钟，五小时内容、正式音画、资产许可、真人验收与真实80%好评仍未达成。

## 上一源码批次 2026年10月20日 中继广播与QA超时修正

- 上一goal turn为progress：药房build02/ZIP33/CMD18/fresh04已真正交付。本轮实际新增中继西墙PA选择，不加敌人/任务/奖励，不延长原12s作业；新relay map7，old restored3-6保持。事实5/profile11/checkpoint6不变。原喇叭用现有听觉+墙衰减/导航，看到玩家仍优先交战；自制合成音与12新译文至1722，无配音/新角色/付费动作。
- 当前Root不再等于已交付final03。tests/normal_start_test._wait_scene已调用check(false)记录超时，默认15s不变，显式fixture1ms/暂停仅供单元；normal_start_wait_test10 checks过，另一个早退进程真FAIL/exit1验证过。不是改生产失焦暂停。
- pa_component04=23，write01=22/read01=6，原实际编译Q02第三次返营档原字节→当前普通PA路线3→4=17 checks/6shots/2kills，实际StreetPMC1听到Speaker(-50,0,-43)，非开关(-49,0,-12)；独立BOOT read=6。skip route14 checks也完成4，campus_chapter clean02过。组件定位/冻结与普通无传送/加血/禁AI实战分别记录，不冒充真人时长。
- 真实旧冻结final03源码在D:/tmp/bunny_relay_legacy_v5_20261020_01写出原map5 checkpoint，当前legacy-read3过，无PA；只改隔离config+新增明确fixture，原运行时代码hash不变。第一次postaudit把原manifest的checkout config与隔离config比较失败，已确认唯一差异project.godot，原引擎早已成功不重跑，修正审计后原字节读回；保留correction.json。
- 失败组件01/诊断02误以为12个作者出生点全都活动、挑了未出生guard9、只等nav iteration1空路径；夹具改成实际现有guard1并等待真实可达路径，没改生产AI/碰撞/阈值。chapter_regression01有SCRIPT ERROR但旧脚本输出PASS，已明确拒绝；map-marker测试增加CampusAction类型检查，clean02过。原失败都保留。
- helper仍在D:/tmp/bunny_medical_runners_20261020_dev01，run.py新别名relay_pa；源码3档输入provenance pa_earned_input.json，证据pa_earned01_captures/campus_entry.json。新docs/CAMPUS_RELAY_DIVERSION_2026-10-20.md和validation.json为准。上一冻结源码 D:/tmp/bunny_relay_diversion_20261020_final01 的121scene/227已终态PASS（旧exec16680已结束，勿再轮询PID27444）。当前原生画面/普通路线验收与新122/228完整回归见本文顶部；新private Windows QA映射/编译和真实听感仍待做。
- 已交付药房ZIP和fresh04不含PA/本轮QA修正，包本身仍已验收，个人档/.bak与外部Arcana/付费源hash+mtime本轮保持。无commit/push/upload、作者操作、换模或子代理。goal active，五小时、正式音画、许可与真实80%口碑未达成。以下交付摘要的Root一致指当时，不能拿旧221当当前全量证明。

## 当前交付 2026年10月20日 药房白袋截取

- 本轮progress：医疗截取及表现修正已进入真正独立Windows包。新的医疗map6、可见搬运手标记、两组compact物资箱/原UI、无重复背包/悬空死者标记，原主角和仓库外paid12不变；不新增主线局数或已测分钟。
- source D:/tmp/bunny_medical_runners_20261020_final03 119scene/221、build02 113、独立中文ZIP33与十组CMD18成功+预期错误exit1全部通过；Root/frozen/build所有Git可见非文档输入逐项一致，只冷导入保留2条旧FBX警告。完整普通新档仍到10与停机尾声。
- ZIP D:/tmp/bunny_medical_runners_20261020_build02/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip，246170968B，SHA256 b4a1da82b25a88effe337bbf89b9df52adac085a8c8534c63e856c03819b84e2。未预玩交付 D:/tmp/小兔试玩 药房截取 20261020 04/LOCAL_ONLY_DO_NOT_UPLOAD。预览药房截取.cmd→继续→作战室→确认出击。医疗示例是编译正常Q01返营2档原字节复制，编译与独立ZIP验证其普通BOOT/Continue/实战；不拿只接受Q02后的campus bootstrap去伪造准备。其他8份经普通BOOT，严格除stash_layout外不变。
- 当前ZIP F+中文/Compat英文实际2→3，真AI/弹药/E/TAKE/容量/撤离/基地交付、独立BOOT读回通过。source组件与禁AI/定位/直接damage的受控夹具分开；不是人类时长或难度证明。当前编译图片已检查，原库存标签和整体场景仍灰盒。
- 真旧已交付宿舍EXE使用本包实际2档正常Q02，实际移动后仅只读抓取签名map5 battle字节，旧进程自然完成；新EXE和独立ZIP --legacy-v5-read保原图、无新敌人/奖励/进度。v3/v4供给旧档也保留；v4只称状态恢复，不称原导航已修好。源→源旧夹具和EXE→EXE原字节证据分开保存。
- 原build01独立ZIP第25项失败已保留，原因未确证；新build02另验证原失败档的真实BOOT/RESUME/旁通轮/同一core/撤离及独立读回，失败诊断不改生产规则。两次prezip native gate和同一当前ZIP33覆盖均过。独立矩阵首轮第11项明确处于pause，保留原失败；前十个成功保留，第二次续跑累计19项完成；第20项被切场景暂停打断，单独保留；该项虽原QA标PASS，因缺profile_after被外层拒绝。用户确认可保持前台后，剩余14项在相同EXE/PCK的全新隔离数据目录完成，无强制focus/unpause。
- PCK 1569条MD5/边界逐项核验，含本段、private QA和全部旧区域，排除原作者工程/Arcana/CombatGirls/local_motion。旧资产/场景和1705旧译文不改，当前1710；个人档/.bak和外部两个源hash+mtime不变。此前源码/表现失败留在prior_medical_source_validation.json；所有本批串行测试进程已结束。
- 下一代码修正：tests/normal_start_test.gd的_wait_scene超时只返回false却没记failures，会让某些早退写PASS；外层profile_after/返营字段验证已拦截，原缺失记录不算完成。下一轮先补明确失败及受控超时用例，再继续局内内容；当前交付包没有宣称已包含该QA修正。
- 无commit/push/upload、作者操作、换模或代理。goal active，五小时/正式音画/许可/80%真实口碑未完成；下一步补既有校园单局中的有意义路线与遭遇，不主要增加菜单、计时或测试计数。

## 运行中补记 2026年10月20日 医疗候选二

- exec **92302** /pipeline PID39636已实际启动，source_build子helper14684、当前final03隔离Godot已由CIM确认。流水线状态dev01/candidate02_pipeline_state.json；源码日志full_source03_runner.log，wrapper候选二另记candidate02_source_build_wrapper.log。当前final03完整119scene/221类别已全过，Root非文档输入逐项hash一致；已实际进入build02编译矩阵（CIM确认NeonBastion.exe正在water_tanker），113尚未完成。后续会串行build02/113、native gate2、PCK/预览、ZIP33、CMD18；不要重复启动、不要把观察超时当终止。
- candidate02_helpers/finish_packet.py已按final03/build02/ZIP33/fresh04准备，尚未执行；必须查看当前编译独立包至少9张图片（含原失败档恢复）并记录真实hash，不能复用build01视觉报告。新旧候选所有失败保留。目标active。

## 当前状态 2026年10月20日 医疗候选独立包未通过

- 上个用户状态答复未推进制作；本轮已重验当前文件与进程，接着诊断独立包真实失败，不重述计划作进展。final02确为119scene/221 PASS，build01确为113 PASS；exec45359已结束0。原旧档observer57076读活动文件PermissionError后失败；新observer56074/producer02自然完成旧EXE出击，实际旧v5→build01读取通过。原排队72869未创建包即失败，后续53080已结束1。
- build01独立ZIP完成25/31项，24 PASS，第25 market_earned_forward走向旁通轮停于(-22.50159,-.00416,-16.63127)→(-22,0,-16)，因此没有CMD18/预期失败码/未预玩交付；它不是新交付。01测试解压已被推进，02未创建。原宿舍04与宿舍ZIP仍最后通过的交付，不含医疗。
- 当前Root只比final02多两个QA脚本改动：story_finish_run失败分支只读记录暂停、焦点、physics、接触、路径与敌人；water_market_run新增--resume-delivery，严格要求原map3 pending public、原已搜到的唯一core，实际BOOT/RESUME/旁通轮/撤离。没有移动阈值、生产碰撞、AI、伤害、暂停或奖励改动。
- 新隔离源码market_diag_f01正常7→8=25checks过；原失败包checkpoint原字节(9ba59ab76f0037015594d926911ded902dc0d0808a7bbff6b72f4107177b12dc)恢复到旁通轮/8次返营/同一core，resume_delivery_f01=12checks及独立read=1过，源码截图已看。不能声称原失败已过、一定是失焦或已定位实体bug；原失败缺诊断，原因未确认。早期bypass_failed_checkpoint01=8只为隔离源码诊断夹具，不混作导出验证。
- 下一候选final03/build02，helper在dev01/candidate02_helpers；pipeline.py拟串行完整source221→build113→两次真实native预检(fresh/actual failed resume)→audit→9seed/10CMD→独立ZIP33(新增真实失败档EXE恢复+read)→CMD18及预期负例。新测试解压03，未预玩交付保留04；旧build01/旧失败资料不可覆盖。当前尚未启动，以后续状态补记与真实OS句柄为准；不要重复现有目标。
- 全链通过后还需查看当前build02独立EXE的医疗/真实恢复图片、写新compiled_visual_review并改新finisher至33类与fresh04；原dev01/finish_packet.py是旧build01/31/02，绝不可直接执行。新候选未交付，更不代表五小时或公开发行。个人档/.bak、Arcana、付费源hash+mtime本轮均保持。
- 无commit/push/upload、模型替换、作者联系或子代理。引擎串行，只在隔离project与APPDATA/LOCALAPPDATA，不在Root/个人档运行；原生运行期间不要开Codex面板/强制focus或unpause。目标active，下一内容阶段继续现有短局密度，不以测试和短场凑五小时。

## 历史流水线状态 以下exec45359和57076均已结束

## 当前最新 2026年10月20日 医疗截取表现已修复 正在源码与导出

- 本轮progress：白袋可见短标记/更大背包、落地compact箱/去重复标签/即时原UI注册已实现。native发现死亡presentation被reparent后标记悬空与重复包，已在died时实际删除，cleanup_unit01=37、cleanup_f01/c01各39及QA mapping check-only全部通过；已检查最新三张cleanup图和Compat实际交战/拾取图。仍灰盒，原库存箱标签未整体改；不报五小时。
- pre-polish final01已119scene/221类exit0；不是当前Root。polish exec62398已exit0，12项全部过，含真正旧map5 source writer/read、双renderer实际2→3截取、各自BOOT读回。cleanup exec34594已exit0。polish_checks外层与run.py曾共用case.log造成wrapper/child内容混写；不称原始逐字日志，原JSON/PNG/exit证据保留；post_cleanup已分wrapper日志。后续完整新冻结/编译会有独立干净日志。
- 真正旧source producer D:/tmp/bunny_medical_legacy_v5_20261020_01，4595旧文件在实际import/writer后仍hash保持（仅隔离config名与明确QA新增）。old_checkpoint_provenance记录原字节签名，当前reader保原map5且不加敌人/资源/完成。Root medical_runners_test --legacy-v5-read独立branch也用原字节8 checks过；该范围source→source，EXE→EXE还未证明。
- **当前串行exec45359** /helper PID41224：source D:/tmp/bunny_medical_runners_20261020_final02 119scene/预计221→若全过且Root非文档hash不变，自动build D:/tmp/bunny_medical_runners_20261020_build01 --smoke预计113。已实际确认source2引擎在新隔离目录活动，当前Root非文档逐项一致。不要重跑目录/不要改运行时，继续同一handle。
- **排队exec57076**：old_exported_v5.py等同一41224实际结束且113全过后，使用当前编译正常Q01的medical_seed2，在旧已交付宿舍build02 EXE普通BOOT/Q02中只读抓取map5实际移动>1.5m的battle原字节。旧进程自然交付完成后才跑当前EXE --local-qa medical_runners --legacy-v5-read。无脚本注入、强制中断、focus/unpause/JSON修改。现在仅排队，不称此项通过。原旧包EXE/PCKhash预期会逐项校验。
- helper均D:/tmp/bunny_medical_runners_20261020_dev01，source02_build01.py输出full_source02_runner.log/build01_runner.log；old_exported_v5_producer后续provenance/current_exported_read_result.json。当前还没有新ZIP、预览CMD或交付解压。原宿舍04与ZIP仍最新可交付，不含截取；下一步实测PCK/新medical预览与独立ZIP/所有CMD，不能先发旧包冒充新内容。
- 导出tool已纳入private medical_runners/medical_intercept；6组件阶段+2普通实战与读回，预计113；在正常q01后保存实际2返营medical_seed，无改进度。当前119场景、1710译文。新medical需要第10个CMD/第9份preview seed；旧prepare_packet/verify_packet/verify_launchers/finisher绝不能直接复用旧输出路径或旧计数。预览档仍普通BOOT只无档复制、fresh交付未预玩。
- 原个人档/.bak与两个外部源hash+mtime已再次核对不变，无commit/push/upload、模型替换、作者操作或代理；所有引擎串行，勿在Root运行、抢焦点或禁生产暂停。goal active：五小时/正式音画/公开许可/真实80%口碑仍未达成。

## 当前表现收口 2026年10月20日 医疗截取

- 上轮为真实progress。本轮在上轮冻结final01继续回归的同时，Root新增白袋更大白色背包与仅随可见presentation显示的短标记“白袋/MED BAG”；掉落两组改compact_drop，只缩小本段箱体并隐藏重复标签，动态箱在落地即由register_loot_cache建立，同一函数复用初始/后生箱避免重复。角色、碰撞、导航、奖励、profile/checkpoint版本未改。当前Root已不等于pre-polish final01，不能拿那轮221的通过声称当前全部通过。
- pre-polish final01已真正终止exit0，119场景/221类全过，仅冷导入两条既有FBX警告；它不含下述Root表现改动，不当作当前全量。
- 串行polish exec **62398** /Python helper PID44720 已live确认；等源回归helper21660终止且221全过才启动真正旧source5 producer→当前source读回，然后源码/双renderer组件、drop写读、F+中文与Compat英文真实赚取的2档→3截取及独立BOOT读回。原52485仍是pre-polish全量；观察超时不重跑。D:/tmp/bunny_medical_runners_20261020_dev01/polish_checks.py，日志polish_results.json。
- 旧producer已静态准备 D:/tmp/bunny_medical_legacy_v5_20261020_01/project：原宿舍final03的4595文件逐项hash不变，仅隔离配置名和明确QA writer新增；实际旧游戏代码未改，尚等串行引擎写出。控制Q02夹具，不冒充已赚实战。当前reader是dev/project/local_qa/legacy_q02_reader，不进Root，源→源范围不是EXE→EXE。
- 导出工具已准备medical_runners与medical_intercept两私有QA映射、6组件/阶段+2实战与读回检查，预计build113类；在正常编译新档q01→q02之间留真正2次返营medical_seed，不改进度。尚未导出、未验证Godot端映射解析，不要报编译完成。当前译文1710，先前1709保持。完整119/221新冻结待polish实际全部完成后再做final02。
- 请勿并行引擎、Root运行、抢焦点/禁暂停/传送或直接damage真实路线；不做commit/push/upload、换模、联系作者或代理。原宿舍04/ZIP仍最新可交付，不含截取；五小时与80%口碑未达成，goal active。

## 当前源码批次 2026年10月20日 医疗搬运手截取

- 本轮progress：新的Q02药房出击加入有限搬运手与绕侧护卫，接近才启动真实离场路线；正常视听/导航/枪械接战，不用离屏倒计时。杀搬运手只掉两份独立敷料与两份织物；实际E/TAKE、容量、撤离后原基地交付仍需完成，无新物品ID或奖励。白包在可见presentation的model下随转向，不泄露隐藏敌人。动态掉落在E时接入原补给箱界面。
- 源码新Q02 map6，其他fresh仍map5，旧3/4/5不添加本事件；profile11/checkpoint6/campusfacts5不变。module phase/route_index/introduced/drop_position与spawn/敌人/物资一致性校验。真正途中写入在route_index2且实际离开起点，独立读回发现JSON float的Array.in整数匹配问题，已显式int转换；不是放宽布局/枚举范围绕过。
- helper D:/tmp/bunny_medical_runners_20261020_dev01。component04 32、physical_escape02 21、drop_write/read03、正常新档first02→q0102→intercept02(28)通过。native_results8项已通过：组件中英、真实route write/read02、正常已赚2返营档F+中文/Compat英文实战到3、各自独立BOOT读回。不是human时长或难度证据。all Dummy音频，不能算听感。
- 当前串行全量exec **52485**（等待已结束的native exec29873之后启动）在 D:/tmp/bunny_medical_runners_20261020_final01，119场景，预计221类；以实际results和terminal为准。source helper PID21660当时live；native helper25240已完成8/8。不要重跑这些目录、不要并行引擎、不要在Root启动游戏。Root运行时已冻结供当前全量；尚未构建本批Windows包。下方宿舍04与ZIP仍是最新可交付，不含搬运手。
- 已见当前native实战/单位像素：文本可读，但物资箱标签重叠、白包远镜头识别度仍待改；不要报正式美术。失败保留component01类型推断、component02读取已free对象、component03敷料非法stack2、physical_escape01 target=null导致RVO不走（测试夹具错误，未改生产速度/碰撞）、drop_write01调用不存在API、earned_intercept01动态掉落未入UI、route_read01枚举float错误。诊断只在隔离copy的checkpoint加打印，Root没有debug放宽。
- 119场景清单只新增medical_runners_test；实际路线放tools/medical_intercept_run，不由无种子单元循环误启动。verifier新增5种中途/掉落/离场及独立实际截取路线，原Q02普通搜刮路线保留。当前native与Root仅QA/空session guard等后续差异，不声称所有native都与最终Root逐字节同版；完整新冻结回归/后续当前EXE验证负责收口。
- 无commit/push/upload、换模、作者操作或代理；原个人档、Arcana、付费源应再次核对hash/mtime。目标active，五小时/正式音画/许可/80%真实评价尚未达成。下一步收口全量、补原图Q02真实签名兼容证据，解决掉落标识与包识别，再纳入实际独立包；不能先发旧包冒充有新内容。

## 当前交付 2026年10月20日 宿舍南窗接应独立包

- 本轮progress：校园现场接应已进入新独立Windows包；未备齐不再显示虚假箱子或播已备货对白，组件新增真正复活枪手的拒绝测试。原主角和仓库外paid12不变，无额外章节或重复装备消费。
- 源码 D:/tmp/bunny_campus_handoff_20261020_final03 118scene/213类别、build02 105类全部过，Root/source/build非文档输入匹配；仅两条既有冷导入FBX warnings。当前新中文解压目录19类全新检查及九组CMD16次全过，不复用上批33项来冒充本批验证。全链实际新档仍到10次成功返营与停机尾声。
- ZIP D:/tmp/bunny_campus_handoff_20261020_build02/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip，246139908B，SHA256 27e75f2964dbd765a68058509a45b8bccbaed40f6191567fd486d563de2183cf。未预玩交付 D:/tmp/小兔试玩 宿舍南窗 20261020 04/LOCAL_ONLY_DO_NOT_UPLOAD。预览宿舍接应.cmd→继续→继续主线：真实5返营、正常商店/联系人备好装备档，直达前院/接应窗/撤离。其他八个入口保留，各用独立userdata/localdata，仅无档时复制。测试03已推进，别拿它当新预览。
- 真实5档由本包正常新档到power，再正常购买/联系人打包后停在基地；新QA --pack-only和--bootstrap-only仅准备示例，不修改完成状态。8份预览都经普通BOOT/Continue，严格只有stash_layout显示位置允许变化，无JSON直改。F+中文与Compat英文在独立ZIP经真实AI/弹药/碰撞/窗口E/实物箱过线/撤离5→6并另进程读回；组件另明确定位/禁AI/直接伤害。
- 上一份water_market build03 R2真实EXE在正常供给出击途中只读抓取实际v3 battle档，旧进程自然完成6，无外部脚本注入或强制中断。新EXE legacy-read接受其原布局和十字段、无新窗口/敌人，并按原撤离规则完成。EXE→EXE与此前source→source证据分开；绝不混用编辑器/导出地图签名。
- PCK 1557条MD5/范围逐项核验，含窗口脚本/场景与private QA，所有既有区域保留，排除作者工程/Arcana/CombatGirls/local_motion。881旧assets、105旧scene及1686旧译文不改，当前1705；个人档/.bak与外部模型/动作归档hash+mtime不变。helper D:/tmp/bunny_campus_handoff_20261020_dev01，所有本轮流水线终止成功，无引擎残留。
- 仍仅本地；五小时、正式场景/手部接物、听感、最低硬件、干净机器、公开许可与真实80%好评未完成。无commit/push/upload、作者操作、换模或子代理，goal active。下一批继续校园搜刮/取材与复访路线内容，不只加菜单或测试计数；真实新手游玩数据仍需收集。

## 已结束的候选验证 source03与build02 2026年10月20日

- 本轮progress，不是已交付：source02/213、build01/105、独立ZIP18全过，但实际CMD第一项FAIL。日志明确中文echo片段被当命令且endlocal掩盖游戏exit1，真实行走也卡在关闭Shutter，paused=false/flow为空，坐标(-30.78761,29.27907)→waypoint(-30.82474,30)。候选ZIP与测试01、所有日志保留不交付；22340已exit1。
- 修复生产导航而不是改QA走法：新campus facts5、fresh map_revision5；八份静态导航资源（四个实物警铃箱位置×有无关闭卷板）去掉真实碰撞+胶囊净距，未用顶点压缩以保持可识别的新布局签名；卷板真正抬到净高后才开HandoffDoorLink。旧map3/4及facts1-4保留原图/导航；profile11/checkpoint6不变，严格known map range只扩到5。旧原场景/模型/碰撞未删改，不关闭卷板碰撞，不改AI/血量/暂停/速度。
- 根因验证：nav_physics03/04真实输入从实测门内卡点绕出、再穿过已抬起门通过。unit里一只普通感染者被冻结在门口而阻挡，诊断contact是CharacterBody非Shutter；只在明示组件夹具用直接伤害清理那只被冻结演员，普通earned不禁AI。nav_all_layouts02为72checks，六出生点×四警铃箱布局都绕开实体碰撞；等待实际NavServer iteration发布，不用固定六帧冒充已同步。nav_pending_write/read通过。nav_earned01解决门后又碰RecordsIsolator，已有新fresh地图警铃箱变体后nav_earned02实走5→6通过，真实AI/弹药/碰撞，无传送/加血/暂停重置。
- records_isolation_test旧断言要求柜中心可站人，与实体柜相悖；改为真实交互半径可到达且active柜实体+胶囊足迹必须不可走，72checks过；streets_layout24seed全过。旧导出v4卡点档原字节已保存在dev01/old_exported_v4_checkpoint.json，加入新PCK19矩阵中的--legacy-v4-read，仅证明原图/状态恢复，不假造它已经完成接应。
- CMD只含ASCII命令/提示，完整中文说明留txt，文件名和中文目录保留。显式保存ERRORLEVEL、endlocal & exit /b；D:/tmp/小兔 启动脚本 验证 20261020/results.json 已验证真实成功0/失败1，用旧build01只隔离启动协议，不冒充新导航验收。
- 当前串行exec **76027** 正在source D:/tmp/bunny_campus_handoff_20261020_final03 全量118scene/213类；通过后自动build D:/tmp/bunny_campus_handoff_20261020_build02（105）→PCK audit→8预览普通BOOT准备→中文测试03独立ZIP19→CMD16。未来全链若通过，必须查看新build02编译图片并写compiled_visual_review.json，再运行dev01/finish_packet.py作未预玩04解压与报告。该finisher已有路径/19项/版本5/失败历史更新，但仍需读回措辞（旧字符串可能残留），绝不要提前宣称交付。
- helper均D:/tmp/bunny_campus_handoff_20261020_dev01，build_after_source_v2.py /prepare_packet.py /verify_packet.py /verify_launchers.py。测试目标D:/tmp/小兔试玩 宿舍南窗 20261020 03，交付拟04。不要复跑build01、不要覆盖01或02（02未生成），观察同一76027及OS句柄，超时不重启。原个人存档和外部源保持，不在Root运行引擎，无commit/push/upload、作者操作、换模或代理。goal active，完整五小时/正式音画/公开许可/真实80%口碑仍未达成。

## 失败候选build01打包过程（以下22340已终止，不能交付）

- 上一goal turn为progress：新接应源码与真实5→6已实现。本轮继续打包，补了未备齐时不显示虚假箱子/不播发货对白；组件新增真正复活枪手的篡改用例与未备货实景（40 headless /44 F+ checks通过），不是只改测试名。打包工具新增private campus_handoff组件及跨进程检查。
- 新预览用实际5返营后正常商店/联系人备货的完整档，不直接加物资或胜利。QA-only --pack-only（16checks）和--bootstrap-only（4checks）均通过；后者用普通BOOT/Continue生成仓库显示位置，严格除stash_layout外无变化，避免上次首次布局初始化误判。
- 旧已交付water_market build03 R2 EXE在单独APPDATA中正常从5买装备、出击、返回6；其运行中真实v3 supply战斗检查点已只读抓取，原进程自然完成，无注入/中断/强制focus或unpause。D:/tmp/bunny_campus_handoff_20261020_dev01/old_exported_v3_producer/provenance.json PASS。这个EXE→EXE签名夹具不同于旧source→source夹具，不能混用。
- 当前串行流水线exec **22340**：source冻结 D:/tmp/bunny_campus_handoff_20261020_final02（目标118scene/213类）→build D:/tmp/bunny_campus_handoff_20261020_build01（105类）→PCK audit→prepare_packet（8个真实预览档经正常BOOT准备，九组CMD）→新中文目录ZIP18→CMD16。当前确有source helper在跑，继续同一handle，观察超时不重启。build_after_source.py是在尚未执行前补齐post步骤，不是修改活动进程。所有helpers在dev01；未来结果文件分别source02_runner.log/build01_runner.log。
- 目标测试解压 D:/tmp/小兔试玩 宿舍南窗 20261020 01，最终未预玩交付拟用02；新ZIP/测试都尚未全部完成，不能当已交付。本轮Root非文档输入已变，旧final01的211只证明其旧快照。上一份南市08目录和ZIP仍可用，但不含窗口。
- 全链全部过后，还要看当前编译独立包的unpacked/moving/received和真实5→6截图、核对个人档/资产原hash+mtime，做新鲜02解压，更新机器记录和内容说明才交付。不要在原项目运行Godot、不要覆盖真人存档、不要开并行引擎，别再运行旧water_market的prepare/finisher。
- 无commit/push/upload、作者操作、换模或子代理。goal active，五小时、完整正式音画、公开许可、最低配置/干净机/听感、真实80%口碑未达成。

## 上一源码检查点 2026年10月20日 校园宿舍南窗接应

- 本轮progress：campus_supply空跑改为宿舍前院guard/flanker两名枪手、西巷一名感染者、实体卷板/补给箱交接及安全撤离。无新章节、第二笔装备消费、全图清场或站桩长计时；原主角和仓库外paid12不变。
- 冻结 D:/tmp/bunny_campus_handoff_20261020_final01：118scene/211类别全过，仅冷导入2个原FBX warnings，Root非文档输入逐项一致。13项专项全过，含35checks组件、38checks两原生排练、当前场景pending写/读、校园/迁移/指引/对白/冲锋回归及真正旧v3源码挂起读回6checks。helper D:/tmp/bunny_campus_handoff_20261020_dev01/run.py、continue_checks.py。流水线已成功结束，不重复跑现有目录。
- 真正旧编译包4返营示例→当前普通供电5（8shots/3kills）→复制清洁5档给native F+中文earned_f02、Compat英文earned_c01，经真实商店备货、正常AI/枪械、窗口E/箱过线、撤离到6，各24checks并另进程读回。组件明确禁AI/定位/直接伤害，不冒充普通路线。实际4b及单元moving/received像素已看。
- profile11/checkpoint6不变，新campus facts4多supply_received；旧v1-v3仍十字段。legacy_v3_project只复制冻结final04、改配置名并加显式fixture writer，旧游戏代码没改；它写出的真实签名检查点由legacy_read01接受且无窗口/新敌人，按原撤离结算。搬运进度/出生/存活/receipt严格关联。
- component01两fixture变量推断parse失败，核实后仅停owned PID45732，保留日志；Dictionary类型已修。earned_f01逻辑过但画面站进台面，作废视觉基线，已调整操作点/台面/住户并用f02/c01及真实Hitbox边界断言验证。不是所有尝试都成功。
- 881旧assets、105旧scene、1686旧译文保持，19新增译文至1705；个人档/.bak及Arcana/付费源归档hash+mtime保持。无commit/push/upload、作者操作、换模或子代理。详见docs/CAMPUS_HANDOFF_2026-10-20.md和对应validation.json。
- 完整源码普通新档链已实际读回10次成功返营、campus.finished、maintenance_closed与空checkpoint，未挡后续水塔街、救援、停机和尾声；不是真人首通时长证明。
- 尚未导出本批Windows包！下方上一批ZIP及未预玩08仍是南市版本，不含窗口。下一步纳入本地构建，验证实际旧v3导出档和正常新档全篇，然后继续校园现场密度。五小时、正式音画、公开许可、低配/干净机器及真实80%口碑未达成，goal active。

## 上一批Windows交付 2026年10月20日 南市搜刮与门先别关

- 本轮为progress：南市与可选维修仓、门先别关两个源码批次已进入同一个真正的Windows独立包，不再将旧维护区包当新内容。源码 `D:/tmp/bunny_water_market_20261020_final04` 117场景/208类、编译build03 100类、独立ZIP33类、CMD14类、同包校园种子前缀4类全部通过；Root/frozen/build所有非文档输入逐项一致。
- ZIP `D:/tmp/bunny_water_market_20261020_build03/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64_r2.zip`，245607262B，SHA256 b51c4c546a371c27036ae6ba8f1559d6f1e8ee918dd5155a38534c9e02c14839。未预玩交付 `D:/tmp/小兔试玩 南市搜刮 20261020 08/LOCAL_ONLY_DO_NOT_UPLOAD`。继续后半程.cmd→继续→继续主线：本包真实救援7档进南市v3；西摊断铃/东巷响铃开仓/不搜仓均可继续供水。八组userdata/localdata只无档复制，测试07已推进，不要拿07当新预览。
- 打包r2仅把两份预览档换成本包实际正常BOOT/Continue产生的仓库显示位置完整档，严格JSON差异只有已有两件物品的stash_layout新增，不改任何物资、任务或收益。33类覆盖中前20项因EXE/PCK/对应输入及其他文件逐项相同保留05记录，后13项在新07独立解压重跑；旧失败21项及r1ZIP保留，不能宣称所有尝试都成功。
- 独立解压原生F+中文安静仓、Compat英文响铃仓经实际枪械/AI/载重/门/供水/撤离7→8，准确core ID回仓并独立读回；skip路线亦实走。新的QA北门先等待真实短路径<12m，不能仅凭z<50冒充走门。市场组件44checks含真实输入胶囊过门；部分开门另进程读回，旧冻结v2部分锁扣档在EXE走旧图。正常新档仍经市场到10与尾声。
- 同一解压EXE的门短场在F+中文preclear、Compat英文rescue-first真6→7后从结算按钮进入，等待/扶门/过线/扣门钩/回身/重播/skip/Rest与独立读回通过。原生排练及保存失败组件也通过。无新奖励/seen字段，profile11/checkpoint6不变；paid12动作仍仓库外，Arcana不换。
- PCK 1533条逐项MD5/边界全验，含water v1/v2/v3、market三个脚本和rescue scene/script，无作者工程、开发测试目录、Arcana/CombatGirls/local_motion缓存混入（local_qa为明确本地自检例外）。881旧assets/104旧scene/1652旧译文保持，现1686；个人档hash+mtime、两个外部源hash/mtime均保持。验证JSON及内容docs均已更新，helper D:/tmp/water_market_helpers_20261020。
- 仍仅本地，不能称五小时/20分钟单局达成，也没有真人难度/喜欢或80%好评、公开许可、听感、低配或干净机器。无commit/push/upload、作者操作、换模或子代理。目标active。下一批补校园现场内容，尤其补给阶段目前在基地交装备后只需撤离，需替换空跑为实际行动；不继续主要加短场、菜单、计时或新章节。

## 历史打包尝试 2026年10月20日 水塔街南市（以下进程已结束，以顶部交付为准）

- 当前最新验收：source04/208与build03/100全过，prezip_rescue_gate真F+6→7、短场/重播/skip/Rest已PASS，未改护送/暂停/移动规则；post **9953**正在测试解压05的33类矩阵（prepare/audit已过），launchers14与fresh06/finisher仍未执行。沿用此handle和build03，不要当作已经交付。旧两次原生停滞原因仍未确证，新增只读失败诊断保留，不得编造已定位或用外部observer无心跳当证据。

- 当前流水线最新：source final04 exec59878已exit0，117scene/208类全过（仅QA失败诊断新增，游戏规则未改）；build03 exec **31184**（等待helper PID26668）将完整编译100类；post exec **9953**先跑prezip_rescue_gate真实F+六到七次返营（带pause/focus/碰撞/截图诊断），若失败立即保留并停止，不会继续声称ZIP通过；门禁通过后才prepare/audit/ZIP33。build02失败不可当新交付。后续应直接读取build03/prezip_rescue_gate/run.log与process.json，不能盲目重试或强制focus/unpause。

- build02 source03/100编译已过，但post69944在独立ZIP第17项停：rescue_earned_forward实际路线卡在病房门外（尚未到返营/UI），第二独立同EXE尝试卡在远侧蒸汽阀附近；不能宣称是按钮或确定物理bug。旧QA未记录pause/focus，checkpoint停止更新且重启诊断同档同行者能穿过开门，仅碰地面，提示可能是正常失焦暂停/测试卡点，原因待证。外部--script观察器在release EXE没有输出心跳，不能当观察证据。两个失败均保留，未交付、无强制focus/unpause。Root仅tools/maintenance_run.gd失败分支加只读pause/focus/接触/截图诊断，无游戏规则、移动或护送阈值改动；下一候选source final04/build03、测试解压05/交付06，帮助定位而非改到测试能过。

- 修复后原生专项已完成：rescue_layout_f01与c01各54checks，中英真实点击两种重看入口都正确；rescue_repaired_f01从真正6档实打到7并完整扶门/重播/skip/Rest再打开共43checks、19shots通过。新source03当前exec **20836**，build02等待helper exec **2448**（Python PID34896），postbuild exec **69944**会等同一build helper结束再prepare/audit/独立ZIP33，日志写post_*.log；旧source02/build01不再作为当前交付候选。继续同一handle，不能因等待超时重启或复跑目录。

- 独立ZIP本轮发现实际bug：build01 portable_rescue_earned_forward完成救援与门短场，但回Rest后按钮y642与NavOverview重叠，真实点击误进Overview，候选不交付；64584已exit1，无引擎残留。生产hideout改为y590重看行：仅一个350宽、两个各168宽/14字体，避免底栏y632；RescueResult新增鼠标区域/文字拟合/两按钮实际重看。新source目标final03/build02，新的测试解压03/交付04，矩阵33；旧build01/测试01全部保留。不要复跑旧prepare。当前dev本地正在96478原生回归，单独helper源不进包。

- 后续打包轮实时状态：source session97939已exit0，117场景/208类全过；build helper session18316已exit0，100类编译全过。postbuild session **64584** 正在同一编译包产实际校园前缀种子，然后prepare ZIP/audit/31类独立解压；不要重复跑prepare或删文件，继续观察同一handle。launchers14与fresh02/文档finisher尚未运行。新包仍未最终交付。

- 本轮为 progress：用户明确五小时是玩家游玩时间后，优先扩单局内容而非继续以短场为主。水塔街新出击使用独立v3：南市西侧掩护/感染者与东侧暴露/枪手；可选维修仓可绕西侧断铃安静开，或直接开仓响铃引来有限两人。真实6kg核心/维修物资与8kg泵电池争容量，实体北门内侧横闩开近路；不搜仓仍可正常供水，提前南退能保货但不记供水。原角色/默认动作不换，付费十二动作仍独立本地试装，无新外部资产。
- 新 `WaterMarket` 保存 isolated/mode/progress/back_open 四个世界字段，校验两响应点、货物已roll与门进度一致。waterworks事实仍5字段，version允许2/3；new3、old2选v2、empty选v1。profile11/checkpoint6不变。881资产/104已有scene/1652旧译文逐项保持，现1686译文；个人档hash+mtime、Arcana和付费包源hash保持。独立v3生成器按父路径唯一命名，避免旧生成器同名Door资源复用；v1/v2字节不碰。
- 源码专项当前项目 `D:/tmp/bunny_water_market_20261020_dev01/project`。最新 component06=44checks，包含实际输入与角色胶囊过北门、载重拒绝/精确拾取、无供水撤退保货、快照拒绝；write01/read01=17/6，旧冻结v2程序真实写部分锁扣并由新读回4checks。原waterworks02=100、delivery01=21通过。新QA后补北门短路径<12m等待异步导航，quiet02=25checks完整真实7→8；不能只用z<50声称一定走了北门。
- 真实七次救援返营种子来自上一维护区包preview_save/act2/profile.json，未改flags或库存。quiet/loud/skip三种旧首版headless均实走供水→撤离8并独立读取。当前最终几何native quiet_gui02 F+中文24checks、loud_gui02 Compat英文24checks与各自独立read通过；实际仓内core ID回仓，主线送水后续没被可选仓替代。Native导演随后仅加强了QA短路径断言，游戏运行时未改；新source完整回归会覆盖三路最终QA。
- 画面已看：出生点由91移86，离南撤92有6m不再一落地提示撤；新路牌pixel_size .016/字体30；仓内新增真实挡弹工作台与地面分格，仍灰盒不是正式美术。无Dummy听感/低配/真人时长证明。loud_gui01因正常失焦暂停在部署4.91秒而FAIL，已保留；无抢焦点/强制解暂停/改暂停规则。确认终止后独立fresh loud_gui02正常完成。component01仅QA变量类型解析失败，02仅异步导航等待不足；waterworks01旧总数断言10未随真实新增5敌人改，后02精确15通过。
- 上一门先别关源码 `D:/tmp/bunny_rescue_return_20261020_final02` 已完整116scene/199类别全过，但其等待旧build helper PID46220在新内容优先级调整时被精确验证后停止，旧build01未创建。不要重启 `rescue_return_helpers_20261020/pipeline.py`；它的root hash guard必然拒绝新南市源码。新门短场代码/测试/12动作及其他所有已有内容仍保留，将随下一新包一并验证。
- 完整回归final01在cold import通过后被旧116场景inventory guard拒绝，session96387已exit1。已核对只新增water_market_test.tscn、无旧scene移除，guard改117；新实际目录 `D:/tmp/bunny_water_market_20261020_final02`，当前exec session **97939**，应跟踪同一handle；观察超时不等于停止，应117scene/208类别（按实际inventory核实）；新build目标 `D:/tmp/bunny_water_market_20261020_build01`，QA已加water_market/market_earned组件/挂起/三路线，预计100类别，不能把预计当PASS。所有引擎串行，隔离项目和APPDATA/LOCALAPPDATA，不碰主仓.godot或个人档。专项记录 `docs/water_market_2026-10-20_validation.json`，内容 `docs/WATER_MARKET_2026-10-20.md`，helper `D:/tmp/water_market_helpers_20261020/`。
- 新独立包尚未生成/交付，上一可用包仍 `D:/tmp/bunny_maintenance_art_20261020_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip` 与未预玩中文02目录。下一步完成整体验证和包含门短场/南市的真正独立新ZIP，仍需原生F+/Compat、旧v2挂起、源/PCK审查、独立解压与启动脚本。可复用旧rescue_return_helpers模板但必须重算矩阵/路径/内容/证据，不能照抄199/91/21/14为本轮PASS；act2种子应优先本包真实rescue_earned七次档。
- 五小时是首次正常游玩目标，当前10次验证返营不是10张独立地图/10局充分展开。此前约1–2小时只是范围粗估，不是陌生玩家测量；本批不报新实测时长，也不拿多路线/渲染器/回归累计。约12局、主要20–25分钟加基地的300min是后续内容预算。目标active，许可/公开分发/5h/80%真实口碑均未达成，没有commit/push/upload、换模、作者操作或subagents。

## 当前接续 2026年10月20日 维护区场景与蒸汽表现

- 本轮progress：新增MaintenancePresentation渲染层，SteamZone._ready挂载；旧103scene不改。复用混凝土PBR、已有radio/terminal/toolbox；新代码床架/毯子、柜细节、路标、供汽管、地漏MultiMesh80、阀轮/表。Shader地坪降原图斑驳并加4m分格，病房2m浅暖地坪，管廊深金属。96 CPU alpha quads替换15个实体SteamJet占位，.65s生命，gradient64，depth disabled；Steam.refresh按原phase同步，禁新增collision/nav/state。
- source D:/tmp/bunny_maintenance_art_20261020_final01：114场景/195类别；build01编译87，ZIP13，CMD12，同包校园4次种子4通过。源输入Root-frozen-build非文档manifest逐项相同；881资产/103旧scene/1628旧译文保持，现1634。个人档hash+mtime与Arcana/paid源包hash保持。
- 新ArtTest own ART_PATH，与旧原始场景去掉root hook后的collision/nav完整签名精确相同；新look不得有CollisionObject/CollisionShape/NavRegion/NavLink，旧cone各自hidden不被parent.visible再带回；phase开启CPUvapor，off停发+wheel转，shutter身体原Y5升门但render Mesh隐藏，只留顶箱，防悬空半透明门片罩头。CameraOcclusion对高装饰照常F+/Compat切开，不改瞄准、弹道、AI或跟随。
- ZIP D:/tmp/bunny_maintenance_art_20261020_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip；未预玩D:/tmp/小兔试玩 维护区场景 20261020 02/LOCAL_ONLY_DO_NOT_UPLOAD。仍预览蒸汽救援.cmd→继续→继续主线。同包真实校园6种子，七独立userdata/localdata，只无档复制，测试01已推进勿给人当新预览。
- 原生F+中文preclear/Compat英文rescue-first都在EXE真6→7；独立read，旧v1余5s+wait继续原图，上一编译包真v2热3.4/cooldown.3/wait新源码与EXE不改签名续上。profile11/checkpoint6/maintenance两facts不动，完整新档到结尾10仍过。粒子不新增遮挡或伤害，单纯表现；当前视觉/音频/配置不等于发行品质或人类时长。
- 开发art_f01原粗糙水泥图大面积噪声像土，改painted_concrete.gdshader混低权重磨损+分格；art_f02重看地坪/病房，art_c02查Compat、gate额外hide。原WorldLabel长段在控台上隐藏但E/HUD保留，用地面分区号引导。helpers D:/tmp/maintenance_art_helpers_20261020；dev01原生截图保留。无新素材下载、模型替换、子代理、commit/push/upload或再联作者。
- goal active，下一轮继续关键场景统一表现、人物行动兑现和首小时观察；不是增加新章/菜单/刷材料。付费12动作仍外部试装，未来近战包未购。尚无真人五小时、正式听感、低配、干净机器、公开许可/发布或80%口碑证明。报告docs/MAINTENANCE_PRESENTATION_2026-10-20.md、maintenance_presentation_2026-10-20_validation.json。

## 当前接续 2026年10月20日 维护区蒸汽救援

- 本轮progress：maintenance v2独立scene；中央8m廊、热区Rect2(-3.6,-16,7.2,6)，4.8s循环=清2.4/预警.8/热1.6。实际6base伤害/.5s，护甲正常；对面(2,-23)阀门近距+LOS永久切断，无新增收集。新Bypass/Ward/North即时，North需隔离；许棠未关阀停黄线、非手动waiting且非可射血条；隔离后回12m范围，手动wait还需回来叫follow。4+2+2有限敌人不扩波。三MC仍无线电，无新演员／配音，主角及Arcana/付费动作未换。
- Source D:/tmp/bunny_maintenance_v2_20261020_final01：113场景/194类；build01编译86、独立ZIP10、CMD12、同包校园4次种子生产4通过；主线6→7→8→9→10完整。Root-frozen-build非文档逐项相同。原881资产/102场景/1594译文保持，现1628；正式个人档hash+mtime与两外部源hash保留。
- Session/Outcome.maintenance可选2字段version2/steam_off；空/缺沿用maintenance_zone.tscn/map1+6/4/8s。默认独立v2。profile11/checkpoint6保持。Steam.cycle_time/hit_cooldown/warned/followed保存；关阀需Bypass、北门需steam_off，热区不得恢复Follower，remaining新控只能0。旧前版冻结代码用真6档生成North余5s+waiting，当前源码与EXE保map1并完成旧控；非手造新版伪旧档。
- ZIP D:/tmp/bunny_maintenance_v2_20261020_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip；未预玩D:/tmp/小兔试玩 蒸汽救援 20261020 02/LOCAL_ONLY_DO_NOT_UPLOAD。预览蒸汽救援.cmd→继续→继续主线，种子同包实际校园6，非改flags。七入口各自userdata/localdata，仅无档复制，测试01已推进勿当新预览。图形Dummy不证明听感，5090不证明低配，自动操作不证明五小时／80%。
- tools/maintenance_run默认preclear；--rescue-first实际放人→前线blocked→wait→timedcross→valve→return→follow→north→safe→normalsettle7。组件独立JOURNEY_PATH不撞legacy测试；旧MaintenanceTest显式legacy，不一律倒退新测。源码/EXE两renderer实弹两线都通过，独立read。朝向/脚底/光照仍灰盒。
- 开发preclear01因1m网格+.9padding让病房前3.3m窄廊无完整单元而不可达；改half-meter+.75留边后实际全线过，没放宽1.2m终点或传送；189→191nodes含常亮黄线，9515navpoly，129唯一resources。生成器拷贝截断旧作者工具，绝不执行会重写旧scene/registry的旧生成器。新font动态状态更可读；旧Blockade labels .012显示open/rising，不改既有102scene。
- 无commit/push/upload/换模/子代理/再联作者。目标active。后续优先人物行动兑现、陌生玩家首小时与统一音画；不再开新章节或以刷物资/空走/延时计时凑五小时。报告docs/MAINTENANCE_JOURNEY_2026-10-20.md和同名validation JSON；helpers D:/tmp/maintenance_steam_helpers_20261020，dev01失败与证据保留。

## 当前接续 2026年10月20日 哨卡接近与北场突围

- 本轮实际progress：新哨卡v2为前场探照灯／掩体／维修门或实弹链锁，原360HP广播车战，停机后北场Rammer+infected、东亭配重闸、实际撤离。Alarm有限2人且不重刷；车停机另开post2人，不等于完成，Gate5m升起约1.54s后才record旧Van目标；南退不封。三MC无线电短争执／牵挂，不冒充三新演员或配音，原主角／付费动作／Arcana未换。
- 权威源码D:/tmp/bunny_blockade_v2_20261020_final01：112场景/189类；build01编译81、独立ZIP10、CMD10、同包校园4次种子生产4通过，所有运行时/测试/导出工具非文档Root-frozen-build逐项相同。原881资产/101场景/1567译文保持，现1594。个人档hash+mtime与两外部源hash保留。
- 新Session/Outcome.blockade可选4字段version2/alarm/van_down/escape_open；profile11/checkpoint6不变。空／缺保持原blockade_checkpoint.tscn/map1，默认新map2独立scene。灯phase/exposure、Passage.service_open/escape_started/progress、链锁HP、4增援flag、既有Van状态严格交叉验证；HalfGate未完成、毁车后死亡／南退未clear。旧前版冻结代码由真实8返营档产生remaining1.033预告，当前源码／EXE续接原规则并结算通过。
- ZIP D:/tmp/bunny_blockade_v2_20261020_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip；未预玩D:/tmp/小兔试玩 哨卡突围 20261020 02/LOCAL_ONLY_DO_NOT_UPLOAD。预览哨卡突围.cmd→继续→继续主线；种子是同包真实送水8，不是手造flags。六入口各自userdata/localdata，已有档不覆盖，测试01已推进不要给人当新预览。主线全链10仍通过；无真人五小时／80%／听感／低配／干净VM证据。
- 原生中文F+安静线/英文Compat实弹报警线均普通输入8→9，独立读回；精确控制器不证明难度。源码standalone两路线各真实子弹+AI+配重+撤离；组件46检查含网格1x.8x.18、门4/6/4宽、无侧缝射线、物理遮灯／阈值、增援不重刷、部分链／扫光／闸写读与错误快照。新test独立JOURNEY_PATH不撞旧blockade_test.json。
- 开发失败保留：journey01类型推断ParseError，精确PID停后补Dictionary/Vector3类型；quiet01因AlarmCoverWest把维修门出口与旧建筑挤成不可达口袋，实际缩窄并移开新掩体，没改旧scene／放松路径终点。原生图再发现新生成器父节点不同却资源同名：链锁用了Van网格、门宽共享；已改父路径限定资源id并duplicate断言，补mesh/shape/side-ray测试，重跑实际两线。预发行WIP checkpoint不交付；旧发布map1仍匹配。
- 新tools/blockade_return_run继承story_finish，真8档普通BOOT/Continue/mainstory→9，输出blockade_earned.json。source/build均从当前实际Bucket8复制独立组，不污染主故事7→10；StoryFinish.checkpoint默认走新前后段。旧BlockadeTest与Readability显式legacy fixture保原签名，新增JourneyTest覆盖v2；不是一律降旧使测试绿。QA loader list/mapping单独插入并check-only通过。
- 最终编译图已检视中文维修门与英文北闸：重复网格／门宽问题已消失；新WorldLabel目前偏大，开门后仍显示操作词，后续统一视觉时要改成状态标签并缩到不遮演员，不把当前灰盒报正式美术。
- 无commit/push/upload/换模/再联作者/子代理。目标active，下一轮优先既有维护区独特压力、人物行动与首小时节奏，不再加章／刷物资／延时读条。报告docs/BLOCKADE_JOURNEY_2026-10-20.md、同名validation JSON。

## 当前接续 2026年10月20日 校园供电冲锋遭遇

- 新鲜校园power事实v3添加CampusPowerEncounter（1持盾冲锋+2感染者），旧v1/v2不加模块、保留原6s。新路线0.95s锁线→真实move_and_slide冲锋→撞墙STUN2.6s/伤害1.5x→枪击→回E控制台断B留A→安全撤离。HP55，前盾普通伤害.3，penetration>=16穿盾；非追踪/无限刷怪/加血条计时。仍CC0成年占位，不冒充未来近战包，默认付费十二动作仍未入包，主角未换。
- 权威源码D:/tmp/bunny_campus_ram_20261020_final04：111场景/179类别；build01编译71、独立中文ZIP12、CMD8、同包真正4次返营种子生产4全部通过。原881资产/99场景/1555译文不改，现1567。新Scene2+测试1，profile11/checkpoint6不变。世界保存module.phase、3个spawnflag、ram六字段，严格恢复phase/direction/timer/travel/impactcounts，拒绝伪造工作计时。旧v2冻结代码实际生产剩4s检查点，新源码和EXE续接通过。
- 可玩ZIP D:/tmp/bunny_campus_ram_20261020_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip；未预玩D:/tmp/小兔试玩 校园供电 20261020 02/LOCAL_ONLY_DO_NOT_UPLOAD，优先预览校园供电.cmd→继续→继续主线。种子实际首战/Q01/Q02/relay4，不是flags补档。重复CMD继续供给至6，不覆旧档；其他后半程/桶/尾声入口保留，5个userdata/localdata均独立。测试01目录已玩，不当新预览。
- 原生中文F+/英文Compat实际普通输入均完成4→5，观测wallimpact>=1、playerimpact0；新进程供给/读回6。组件两渲染42checks，各阶段独立写读；实际站线受伤、shield/AP、错误检查点也验证。控制器刻意先引墙，不据此报难度/真人时长。Dummy音频，无听感/低配/干净VM证据。完整主线10出击由当前源码与EXE全链覆盖，非五小时证明。
- 开发失败保留：final01为QA loader字典生成重复键项的预检失败而停止的导入；final02在旧输入测试仍期待6s而失败；final03末段发现新组件测试继承旧测试文件名覆盖其完成档，已以chapter_path虚函数给新测试独立campus_power_test.json，先验证旧写→新组件→旧读通过后才冻结final04。已修QA映射且check-only预检通过，输入测试改为v3键盘确认、等6s不能绕过、明确damage fixture移除敌人后真实E；实际战斗另由正常全链证明。old_producer首次外部SceneTree过早编译autoload失败，已终止精确所属PID；第二次延迟load成功。没用focus/unpause/无敌/直接damage修正常实战路线。
- 原始个人档hash+mtime、外部两原包hash保留；没有commit/push/upload/换模/再联作者/子代理。目标active，下一批优先既有哨卡潜入与断电后突围、首小时真人节奏，不加新章节/菜单/刷物资计时。规划与报告docs/CAMPUS_POWER_2026-10-20.md及validation JSON。

## 当前接续 2026年10月20日 最大的那只桶返营人物短场

- 前轮水塔街为实际progress；本轮继续新增人物内容《最大的那只桶》，不是只扩菜单／测试。原主角真实双手搬桶进场，选放下休息或往门口走，被沈砚霜叫回，降低桶约8cm落在凳上、松手、再走到长凳坐下。院子／水车有水与空桶不同开场，名字／花／接人的玩笑有回调；三MC仍无线电字幕，不冒充新NPC／新配音。站走坐沿用Quaternius，双手为旋转接触适配，不新增付费动作或改主角。默认十二动作仍在旧独立试装，Arcana仍等用户自己联系。
- 新入口在安全完整供水结果页可选「带桶上楼」，先原子保存后开scene；普通Return按钮不改。Rest左下新「最大的那只桶」可重看，供水旧档也能进。不完整撤退／死亡的结果页不提供新入口；早退／重看／两种反应都不写profile、奖励、关系或seen字段。profile11/checkpoint6不变。保存失败留在debrief可重试，16项事务夹具与真实正常输入分别证明，不要用夹具制造已赚进度。
- 权威源码 `D:/tmp/bunny_bucket_20261020_final01`，110测试场景／172headless类别全部通过，只有2条旧FBX警告。运行时、测试和导出工具的所有非文档源码与当前Root／新build逐项匹配，本轮无上轮QA loader修复例外。新构建 `D:/tmp/bunny_bucket_20261020_build01`：64类全过；独立中文路径ZIP10类＋5个CMD全过。原生F+中文／Compat英文实际7→送水8→新结算入口→两反应／重看／Rest／早退，各55checks并独立读回；普通7→水→哨卡→核心→尾声→自由行动完整3路线也过。不是人类读剧情或五小时证明。
- 新ZIP `D:/tmp/bunny_bucket_20261020_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，245163558B，SHA256 b3a817e5189fee6eda22d3ad83c4053f3c2cde60ce3b04f1a8c0ece104de5827。未预玩的交付解压 `D:/tmp/小兔试玩 最大的桶 20261020 02/LOCAL_ONLY_DO_NOT_UPLOAD`。四入口：正常试玩；继续后半程（实际7次返营）；尾声（实际10）；预览最大的桶（本包实际8次返营，继续→Rest→最大的桶）。四独立APPDATA／LOCALAPPDATA，不覆盖已有档。01解压已被QA推进，交付ZIP或02，勿发01当初始预览。
- PCK1438条逐项MD5／范围全过；含bucket scene+script，原v1/v2水塔也都在。无作者工程／Arcana／CombatGirls／local_motion。881旧资产／98旧场景／1525旧译文保持，新译文1555，正式个人档hash+mtime、外部两个源hash保持。没有commit/push/upload／作者操作／agent，所有本批引擎进程已核对终止；原生测试串行，不禁焦点暂停、不抢焦点；观察超时不是失败、不可重启代替等待。
- 新文件脚本bucket_return.gd继承seat_moment，只复用已有旋转式_palm/_reach_arm和UI组件；有自己的搬桶、转向、门口／返回、place／sit状态。把手最初离身体太远，unit01误差6–7cm失败；实际缩近／提高桶，不拉骨骼。曾出现桶到场就搁凳上的视觉假动作，现持有中心.94与支撑中心.86分开，并断言真实降低>.07。最终两个renderer各四组合最大palm误差.01357254m、骨长误差约2.1e-7m，rest/pose位移/scale不改；手指／衣物全帧和重载物理没有宣称达标。物件为演出道具，不加仓库水资源或载重系统。
- 新tests/bucket_return_test、bucket_result_test；新tools/bucket_return_run继承正常故事驱动，SourceFull／ExportFull从刚实际完成救援的7次档复制独立userdata给它，后续普通故事仍用原始7次档不互相污染。QA loader增加bucket_moment/result/route，预先check-only解析通过；工具完整拷贝／重写到local_qa。机器记录 `docs/bucket_return_2026-10-20_validation.json`，报告 `docs/BUCKET_RETURN_2026-10-20.md`。独立读取capture用不同目录，不能覆盖完整路线证据。
- 目标保持active。5h真实时长、正式美术、许可与80%口碑未完成。已有工坊、留座、桶、尾声，下一轮优先既定校园／哨卡的独特现场遭遇和首小时节奏，不再加新章节／关系条／刷物资计时。结果页仍显示并行旧基地建设合约0/2，和已完成校园叙事不是同一套，后续统一／标明可选，别把旧计数当主线事实。没有听感、低配、干净VM或陌生玩家验收。

## 当前接续 2026年10月20日 水塔街现场送水扩展

- 本轮为实际progress：原有水塔街新出击改用v2地图，选阀门不再立刻给任务／奖励。院子可绕旁通轮或真实射击红锁扣，压力区实际伤害；供水后两名匿名CC0成年住户实际走向水龙头。水车需升门、侧面松手刹并实际向北14米到院，门闭则停、车头有人则停，车身挡射线，非驾驶座／血条护送／全交通AI。两条路线择一，南退始终可用，有限2名选线增援，没有无限刷怪。
- 主角、默认动作未换；十二付费动作仍在独立试装。没有代联作者、commit/push/upload。五小时和80%真实好评仍active，未实测达成。下一步补既定校园／哨卡独特现场内容及人物行动，不开新章节，不拿计时与重玩分支填时长。
- 权威游戏／测试源码 `D:/tmp/bunny_water_v2_20261020_final04`：108场景／168headless类通过；正常真实救援7返营档能经新版水塔街、哨卡、核心和尾声到10，独立读回通过。源码后唯一差异为导出专用 `tools/local_build_probe.gd` 字典语法修复，单独check-only与最终60构建类覆盖；所有游戏运行时和测试源字节一致。详情 `docs/WATER_DELIVERY_2026-10-20.md`、同名validation JSON。
- 新构建 `D:/tmp/bunny_water_v2_20261020_build02`：60类全过；独立ZIP中文解压13类（串行native原生中文F+／英文Compat／旁通／实弹／水车／正常BOOT完整后半程与独立读回）＋4个CMD检查全过。PCK1422逐项MD5／边界，无作者工程、Arcana、CombatGirls、local_motion。881旧资产／97旧场景／1495旧译文保持，新译文1525；个人档hash与mtime、两个外部源hash未变。没有听感、低配或干净VM证明。
- ZIP `D:/tmp/bunny_water_v2_20261020_build02/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，245133407B，SHA256 d91b2ef253045a3b2b42dced34b3a78af9dda6a68cc0291fa7eff95d1c8cc6fa。未预玩的交付解压目录 `D:/tmp/小兔试玩 水塔街送水 20261020 02/LOCAL_ONLY_DO_NOT_UPLOAD`，优先「继续后半程.cmd」→继续游戏→继续主线。测试过的01解压目录已被CMD推进至结尾，不能作为初始预览；ZIP／02示例为原始种子。三APPDATA／LOCALAPPDATA各自独立、已有档不覆盖。
- profile11/checkpoint6不变，Session/Outcome新增可选waterworks字典；旧缺字段用原waterworks_district.tscn，字节未改，保留旧阀门即完成规则。AreaDefinition默认v2，Battle传Session给AreaLoader选图。v2事实严格交叉校验，车进度／手刹、锁扣HP、住户位置、增援、奖励与恢复一致。旧版游戏代码冻结副本复制到 `D:/tmp/bunny_water_legacy_20261020_producer01`，实际正常BOOT／7返营档／真实战斗2秒安装得到旧map1半装检查点，新EXE续接通过；不是手造旧flags。
- 新生成器author_waterworks_v2只写新scene，不import／execute旧生成器，也不重写旧WAV。Nav1m格需.95边距，早期.5会卡掩体角；异步Nav启用link不能假设2帧，QA现最多600物理帧等待实际可达端点，绝不强开门或写进度。水车旧灌水stream已隐藏避免离车后浮空。已检查住户、喷流、车移动／到达、英文UI及原主角尾声六张实际native图；升门与车等仍明显程序化灰盒，不冒充正式美术。
- final01／03因冷导入普通完整故事导航过早查路失败；final02因补视觉／近距离手刹断言而明确superseded停止，仅停止精确核对的本任务隔离进程；build01因QA loader语法失败。均保留DO_NOT_DELIVER。不要交付或当全套通过。当前所有引擎测试进程须确认已结束后才开Codex面板；观察超时不是失败，不启动第二个native、不禁焦点暂停、不抢焦点。

# Bunny Team — Current Project Handoff

## 当前接续 2026年10月20日 主线终局与回家尾声

- 上轮有救援关卡实质进展；本轮继续做出维护区第二场地“最后一声咔哒”、主线接续与“都回家了”双人尾声。固定通道预警/实移动电弧/蓝灯窗口、保住L-02A、两馈线任选先后、停机、实体北门/有限增援/实际撤离。原主角未换；许棠仍是已有CC0女性占位，三MC仍电台字幕，无新配音。不是五小时或70分钟章节完成。
- 总览继续主线按真实水源记忆、哨卡安全返营、救援事实选任务；仅点击才改选，旧沙盒哨卡可保存不强绑教学。profile11/checkpoint6；旧10默认不猜哨卡与终局。停机完成且安全结算后才记maintenance_closed；返营自动接尾声，跳过/重看/让位站坐/捧杯/结束卡/回自由行动都不再写进度或赠奖励。
- 权威冻结源码 `D:\tmp\bunny_finale_20261020_final02`：107场景／162headless类别全过，2条旧FBX导入警告。新构建 `D:\tmp\bunny_finale_20261020_build02`：54类通过；独立中文路径ZIP12类＋4个CMD入口通过。原生F+中文/Compatibility英文完整水源→哨卡→终局→尾声/跳过/重开/结束卡/自由行动各67上下检查，独立读回真实十次返营。另受控视觉2例实际看到移动电弧及真实受伤，不冒充正常路线或真人验收。
- 新ZIP `D:\tmp\bunny_finale_20261020_build02\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，245,029,772B，SHA256 `48dc363ac20d6f3c243fc225d379dbde537b140457239a57efedc9463db18a34`。解压 `D:\tmp\小兔试玩 终局与回家 20261020 02\LOCAL_ONLY_DO_NOT_UPLOAD`：运行本地试玩.cmd（新档）、继续后半程.cmd（真实旧7次返营档）、预览回家尾声.cmd（当前导出实际10次完成档，继续→休息室→重看尾声）。三个APPDATA/LOCALAPPDATA目录隔离，不覆盖已有进度。本机解压目录做过验收；首次示例从ZIP新目录开始。
- PCK1404条逐项MD5/范围校验，旧881资产/95场景/1400译文不改，新增95到1495。个人正式档/hash/mtime、Arcana/付费归档hash、示例输入hash/mtime保留。默认包没有付费动作/Arcana/local_motion；十二动作另在旧试装。无新许可、作者操作、commit/push/upload或agent。
- QA修正：maintenance_run/seat_return的英文临时设置改为保存隔离语言偏好，story_finish还断言BOOT真实locale。尾声单位测试等待physics_frame，不能把高帧率600process帧冒充足够时间。最早TSCN小数前导零/辅助脚本类型推断/从同侧接近交互点已修；final01/build01因保留旧沙盒合法胜利的约束调整被替换，留目录不交付。core可玩机理与ending原型通过，不宣称正式特效/角色美术。
- 注意native的--read若复用同一个capture目录，会覆盖helper的story_finish.json；完整证据以新ZIP portable_story_forward和portable_story_compat_en两个未被reader覆盖的JSON、独立read目录和原始日志为准。build/headless主线原日志也保留。全部native显式Dummy，不是听感/干净机器/最低硬件/真人时长与口碑。
- 下一轮补既定四区的独特遭遇、路线后果和三MC人物行动，不另开第六章/新大系统、不再拖延结局。五小时内容与真实80%好评目标保持active，见 docs/FINALE_2026-10-20.md 与机器记录。

## 当前接续 2026年10月20日 维护区实体救援和新Windows本地包

- 本轮有实际关卡进展，不是等待许可或只增加HUD测试。新增维护区三道实体门、真实跟随／等候的许棠、4+2+2有限敌人、北侧带人撤离和南侧退路。校园六请求完成后作战室可选进入；不是完整70分钟章节、终局或五小时成品。
- 原主角未替换；许棠用已有CC0成年女性参考占位，不冒充正式美术。三位联系人仍是电台字幕，十二付费动作仍在独立试装、未进默认包。profile10/checkpoint6，旧schema9默认未救援；只在真实完成救援并安全结算后记录。
- 冻结源码 `D:\tmp\bunny_maintenance_20261020_final03`：105测试场景／155无图形类别通过。新构建 `D:\tmp\bunny_maintenance_20261020_build02`：47类通过；中文路径独立ZIP解压14类＋3个CMD入口通过。PCK1370条目逐项MD5，881旧资产／94旧场景／1344旧译文、个人档／Arcana／付费归档hash不变。新增56译文至1400。
- 新交付ZIP `D:\tmp\bunny_maintenance_20261020_build02\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，244,945,030B，SHA256 `ad49ae32e6c4650bf09645d1410ce7a5e8ecc980ee91e642995fbc707f3c7409`。解压 `D:\tmp\小兔试玩 维护区救援 20261020 02\LOCAL_ONLY_DO_NOT_UPLOAD`，优先用运行本地试玩.cmd或预览维护区救援.cmd（继续→作战室→可选维护区）。预览是真实完成校园六请求、共安全返营六次的schema9档，独立读回完成第七次救援；启动不覆盖已有预览。
- 修复出生点组、动态门签名、门洞中途保存恢复、反复同目标重规划导致的门洞／拐角来回退步，以及救援结算被旧基地合同覆盖。旧操作数量／schema9断言已按第五项／10精确更新；早期失败final01/02与被替换build01保留，不能交付。
- 注意 tools/maintenance_run 的 --english 临时设定会被无已存偏好BOOT重设中文；额外独立EXE两例用真实language.cfg=en并检查英文作战室文本后才算英文。受控中英UI另跑；不按参数名假报语言。初次WASAPI初始化失败回退，后续native显式Dummy；没有听感、真人平衡、最低硬件或干净VM验收。
- 下一轮继续维护区后段、终局与人物行动，不开新大系统、不靠计时或重复刷图凑五小时。目标保持active；没有commit/push/upload、没有代联作者、没有换主角。完整范围见 docs/MAINTENANCE_2026-10-20.md 与机器记录。

## 当前接续 2026年10月20日 返营人物短场和新Windows本地包

- 上轮为progress：十二动作真实本地接入。这轮转向实际人物内容，默认游戏新增《给你留的位置》，入口为Q01安全返营后的Rest可选按钮，不强制播放。原主角真实走到长凳、坐／起／被叫回／捧杯；两种选择、提前退出和重看，不加奖励／关系条／seen字段，不换模型。三联系人仍电台字幕，无新3D NPC或配音。详见 `docs/SEAT_MOMENT_2026-10-20.md` 和 `docs/seat_moment_2026-10-20_validation.json`。五小时与真实好评目标仍active，未获新许可、未上传。
- 权威源码只认 `D:/tmp/bunny_seat_20261020_final03`，104场景／150headless类别全过，2条旧FBX警告；另9类专项全部通过，中英F+/Compatibility、两分支、真实Q01档正常BOOT／继续／Rest／早退／重开／演出／返营及各独立读回。不是人类或完整175+原生全矩阵。当前所有非文档源码与执行副本对应，仅隔离应用名例外；不再沿用01/02 helper例外。
- 新构建 `D:/tmp/bunny_seat_20261020_build02`：40类全过；ZIP独立解压9类+三个launcher检查全过，原生窗口串行，PATH仅Windows系统目录，EXE等于官方release template hash。新PCK1327条逐项校验，含seat.gdc和scene remap，无作者工程／Arcana／CombatGirls／local_motion。没有把授权伴随文件当成许可闭合，也不冒充干净机器／低配／听感验收。
- ZIP `D:/tmp/bunny_seat_20261020_build02/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,404,893字节，SHA256 `9f59d2036d0c9905af8a50dea02a43e5877078f3429d29d1c51dff85bea1932e`。本机解压 `D:/tmp/小兔试玩 给你留的位置 20261020 02/LOCAL_ONLY_DO_NOT_UPLOAD`。`运行本地试玩.cmd`用portable_userdata，`预览返营短场.cmd`用seat_preview_userdata；首次仅目标不存在时复制已赚取的Q01示例档，后续不覆盖。预览：继续→休息室→给你留的位置。脚本实际headless执行和独立读回已验，不要双击EXE误用旧默认原型存档位置。
- 杯子／桌子为程序化道具，坐起仍既有Quaternius，rotation-only手臂与两掌接触，不拉骨骼或换衣服。原881资产／93旧场景／1321译文逐项保留，新1场景与23译文到1344；个人正式档／Arcana／CombatGirls归档、Q01输入原件hash与mtime不变。所有源码／构建和ZIP额外文件清单见机器记录。
- Q01输入为 `D:/tmp/bunny_campusentry_20261019/baseline03/userdata/Godot/app_userdata/Neon Bastion Local Prototype`，实际成功返营2次、Q02未结。正常基地首次会给2个尚未布局的UUID排仓位；旧QA从BOOT前比到短场后误报，现严格只容许基地区间stash_layout差异，其余进度不变。Rest以后场景精确保持profile字节不变，不改库存／存档生产规则。
- 负例保留：dev seat01杯子过低／远约6.3cm，公共global-pose solver会改local origins；新旋转求解+把实物桌杯移入臂展，同阈值不放松。重看旧seat height_offset跳动已在明确重置边界清除。final01/02与build01虽结构全绿，但人工结尾图发现done重置line_index=0；ending_negative两分支失败，done保留ENDING[-1]，final03/build02全新重跑后才交付。record01仅报告脚本log-key读取错，未生成最终记录，不能冒充游戏失败或成功。
- 付费十二动作仍是单独试装 `D:/tmp/bunny_combat12_20261020_final03`，未把数据混进本次默认源码／包；旧frozen目录不改。此轮新增人物行动，不宣称已有三十分钟或五小时实测。下一优先维护区／终局灰盒与有辨识度的现场遭遇，继续补人物互动，不又把HUD或测试数量当主要内容。
- 作者联系仍用户自行发送再转告；无页面／登录／验证码／私信／轮询，不重复催授权。未commit/push、无上传、未换主角、未开新线程或子代理。所有本批引擎／构建／矩阵进程终止后才交付，不能仅凭active_case旧文件猜进程活着。

## 当前接续 2026年10月20日 十二动作正常战斗本地试装

- 本轮progress：从三动作扩到十二动作，52骨（22主骨+30指骨）到140骨驱动再到原52骨主角；原模型保留，数据在仓库外，默认源码动作未换。说明 `docs/COMBAT12_2026-10-20.md`，机器记录 `docs/combat12_2026-10-20_validation.json`。公开发行、五小时与真实好评目标仍active，无新许可或上传。
- 最终只认 `D:/tmp/bunny_combat12_20261020_final03`。译文／冷导入2类通过，仅2条旧FBX警告；专项10类全部通过：原工坊／训练室、16组合headless/F+/Compatibility、正常新档首战headless/F+/Compatibility各92项、两个原生升级档独立读回。实际结果：actual_forward 14发／3击杀／实际受伤1次／生命257.12；actual_compat 14发／3击杀／实际受伤1次／生命257.12。真实撤离／核心升级／工坊／下一委托。合成输入与视口点击，不是人类、五小时或全原生校园链。
- 十二段全部到真实状态／信号：Idle/RWalk/Run/AimIdle/精确前走后退/Shoot/Reload/Hit/Evade/Take/Put。上身射击0.28秒、受击0.55秒；原0.16秒闪避取源前0.2秒再短收势。V纯表现收枪，原释放／取枪时点控制可见；开火、换弹、闪避和受伤取消，不改弹药／速度／伤害／AI。没有背部挂枪模型。自由手源指骨、握持时原接触、收枪恢复用既有Quaternius，不把它算第13个付费动作。
- 主要画面修正：跑动前倾时枪身穿脸→降低整枪；Put末端过渡T姿势→原idle手臂恢复；全速收枪原先强迫慢走→按速度切Run。姿态取值在修改器回调测量，外部读取会被Godot恢复为FK。挂枪未获首个有效控制器姿态前不求接触，诊断的1.07m原点拟合不再污染正常最大值。原库rest／骨长严格检查不放宽。
- 默认运行时只新增一行幅值修正：移动速度乘Input.get_vector.length，小幅摇杆不再全速；原键盘／斜向／闪避不变。analog负例和正例在dev01。默认独立源码 `D:/tmp/bunny_combat12_20261020_base01` **103场景、149headless类别全过**，包括Q01→Q02真实库存／正常购药→relay/recorder→power→supply连续链与读回。当前175类含native目标矩阵未跑；不能将149+10乱称175。
- 最终3760非文档文件与1425默认运行时源核对。执行副本仅隔离名称+两处安装hook；881原资产／93原场景／个人正式档／Arcana／CombatGirls归档hash不变。主仓库没有生成付费动作TRES；无新EXE/PCK/ZIP，最新独立包仍旧工坊build02。脚本安装器仍拒绝Git工作区和覆盖既有候选。
- Launcher `D:/tmp/bunny_combat12_20261020_final03/运行十二动作本地试装.cmd` 仅使用现有Godot，独立play_userdata/play_localdata，未自动启动。同目录正侧GIF来自真实引擎受控PNG，不冒充战斗录像。完整矩阵、manifest、GIF源帧hash在最终目录与机器记录。
- 失败保留：dev controlled01/02脚本QA错误、04类型遗漏；native_review01虽结构绿仍穿脸/Tpose；controlled06错误在pipeline外量姿态；actual03诊断找出未初始化原点。final01仅冷导入未安装；final02虽10项全过但漏收枪全速步态，不交付；final03补16组合与真实全速输入后重跑10类。没有观察超时重启，无GUI重叠；旧frozen三动作final03不改。
- 五小时预算仍300分钟：25序章+55校园+50水街+50哨卡+70维护区+25尾声+25分散人物短场。规划现在标明十二段为本地完成，下一优先人物行动短场和完整维护区／终局灰盒，再扩既有区域，不靠刷材料凑时长；仍缺真人首小时／4至6小时校准、完整动作中断保存矩阵、音画低配与分发许可。
- 作者联系仍用户自行发草稿再转告；无代发／页面／登录／验证码／轮询，不重复询问。没有commit/push/公开上传，不擅换主角或开新线程／子代理。

## 当前接续 2026年10月20日 持枪三动作真实本地接入

- 上轮为progress：实际盘清39源FBX、只有3段预览/未接游戏，收束五小时制作范围。这轮进入实际适配。说明 `docs/RIFLE_MOTION_2026-10-20.md`，机器记录 `docs/rifle_motion_2026-10-20_validation.json`；完整目标仍active，未发布、无真实评分、无新许可。
- 原主角保留。CombatGirls R_Idle/R_AimWalk_F/R_Reload.fbx内Rifle_Reload在隔离源码试装真正驱动Idle/精确Walk/Reload；左手相对轨迹约19.5cm，站立全身、移动只覆盖上身，保留腿步态；正常Shift动作选精确行走。源22主骨到140骨驱动再到原52骨显示，手指沿用现有握持，不冒充包里逐指mocap。不是12段全做完、不是新NPC/家具剧情。主仓库默认运行时仍原动作，付费数据未进repo/PCK。
- 最终只认 `D:/tmp/bunny_rifle_20261020_final03`，源码/译文构建与冷导入2类（只2条旧FBX警告）、9专项全部通过：工坊和训练室headless、受控四组合的headless/F+/Compatibility、正常首战F+/Compatibility各73项与各独立读回。正常BOOT/菜单/装备/战斗/原AI/实际TAKE/原撤离/扣核心升级/工坊/下一委托，无new_profile/传送/直接伤害/禁AI/赠物；合成输入和视口点击，不是人类、完整校园原生全链或五小时。
- 实际正常战斗计数：F+ Idle904/Walk1057/Reload194；Compatibility Idle887/Walk1054/Reload194。最终档各首胜1、升级true、credits2100，无失败/挂起。首战物理hash仍bdcfc65416908d80105ab4a6b91e68efbd9b1fae401fc1ebdd9b7defa6481333。其他枪型、完整中断/保存矩阵和自然移动换弹仍需验收；moving reload是受控组合，不冒充真人验收。拟合会移动真实枪口，原掩体规则不改但未广测所有交点。
- 3749非文档源、1425默认运行时源核对，冻结实际副本仅应用名和两处本地挂接例外：player.tscn切到local_motion/player.gd，副本player_controller的rig路径切到local_motion/rig.gd。原根目录这两文件未改。881原资产/93原场景文件、个人正式档/Arcana/CombatGirls归档hash不变。全部局部生成文件hash在local_motion_manifest.json。没有重跑174源码广回归，没有新独立EXE/PCK/ZIP；最新已交付独立包仍为工坊build02（下节路径/hash）。
- 新authoring tools：sample_rifle_motion.gd在仓库外导入源工程采样安全骨骼轨道；bake_rifle_trial.gd在本项目隔离副本烘焙3动作，统一源模型rest不能用每个动作第一帧作rest；setup_local_rifle_trial.py拒绝Git工作区/覆盖旧候选并只装两处挂接。local_rifle_trial_{player,rig,hands,axis,gaze}.gd是代码模板，没有动作数据；local_rifle_review.tscn/gd只在已安装的隔离工程运行。不得在真实主项目导入付费生成TRES或直接运行试装安装器。
- 数据在 `D:/tmp/bunny_motion_20261020_dev01/source_motion.json` 与其project/local_motion/driver04.tres；正式03从后者复制到自己的local_motion/library.tres，SHA在安装清单。dev01明确是可变实验副本，不把它的早期图片/代码混称03冻结版本。源包原型仍 `D:/tmp/combatgirls_trial_20261019`；只增加了采样脚本，原FBX/归档未改。角色/贴图/Unity C#与布料物理未迁移。
- 失败都保留：sample01漏Animations路径引发明确脚本异常后，只停命令行核对的自有卡住进程；bake01/02早期autoload编译错，02即使打印PASS仍判废，03/04才干净。pose01-04左手误差最多12.8cm，改为上身修改器后校整枪，不能在其前猜肩位置。逐骨新断言使final01在上胸压缩4.5cm失败；local axis只反射旋转、按原骨偏移重建，未放宽断言。final02全部9结构项通过但真实图仍低头看脚；final03用模型中性朝向而非骨本地-Z修视线并再次验证。不是观察超时重启，01/02都不覆盖。原生矩阵从旧协调器终止后才启动下一版，无GUI重叠。
- 最终受控骨长误差约6.03e-7m、两掌<0.02m、rest逐项不变；视线方向约1.0但保留源动作侧倾，不是所有姿势自然/全帧脚底锁定证明。只人工看机器记录列出的6张真实图。正侧GIF是原生PNG缩放/量化/编码，非实战录像或生成证据。
- Q02 QA实际已修：使用回仓真实库存，缺敷料时正常店铺按显示价购买；布料最多三次真实搜刮，允许实际返程数>=6，Q01常规guard仍1->2。900模拟秒是新增最多3出击的预算，不是因等待误报盲加时间；其他校园阶段仍300。正例 `D:/tmp/bunny_motion_20261020_dev01/q02_positive02` 从原baseline03的真实Q01档copy2，30项、实际购买1敷料后交付，原件hash/mtime不变；第二/三布料出击未触发。初wrapper错误路径未复制到档，guard拒绝，负例保留。不称174全套已恢复或当前新原生校园全链已过。
- 试玩入口 `D:/tmp/bunny_rifle_20261020_final03/运行持枪动作试装.cmd`，使用现有E:/Godot GUI可执行，独立play_userdata/play_localdata，未自动启动。不是不装引擎可运行的新发行包。正侧GIF在该目录 rifle_actions_front.gif / rifle_actions_side.gif，可显示给用户；数据保持本地，不commit/push/上传。
- 作者联系仍用户自行发送草稿再转告，助手无代发/页面/登录/验证码/轮询，无新许可文本。许可核对不阻止其余开发。下一优先继续十二动作（跑动/斜向/射击/收放枪）及三十分钟有实际人物行动的切片，再推进五小时维护区/终局。不要下一轮又把更多HUD或测试矩阵当主要内容，也不要把这3段本地试装说成默认发行集成完成。


## 当前接续 2026年10月20日 五小时发行规划与动作优先

- 用户新增明确要求：善用已买资源包动作，之后可能再买近战人物包；从能在itch发行的完整游戏判断缺口，目标首次正常通关约5小时。正式制作入口改为 `docs/FIVE_HOUR_RELEASE_PLAN.md`，不是同时实现旧十二章／八Boss／五结局，也不是更多HUD和回归数量的交付。
- CombatGirls此前仅仓库外审查，源39动画FBX，只看过R_Idle/R_AimIdle/R_AimWalk_F三段；未接生产／PCK／Git。现有战斗主要UnityChan适配，基地Quaternius站走坐加程序化训练／工坊接触。不能说资源包动作已投入游戏。下一内容重点先R_Idle/R_AimWalk_F/R_Reload本地重定向试点，再十二动作真实状态链及三十分钟人物切片；保留原主角，不擅自换Arcana。包仍有贴图引用、Unity约束/布料迁移问题；原先3段预览不是整包适配完成。
- 五小时是待真人校准的300分钟预算：序章25、校园55、水塔街50、哨卡50、维护区70、撤离尾声25、分散基地短场25。四正式区域+序章/基地，三核心联系人、完整本地结局；仅维护区/终局是明确新增区，现有小地图还须实际扩展，不靠计时、掉率或重复交单凑长度。近战包到手先做一种可读近战威胁，不立刻开连招/弹反/处决/耐力四套系统。
- 本轮校园接续WIP记录 `docs/campus_entry_2026-10-20_wip.json`。生产只改出口铭牌具名、真实条件和两句初次观察的留椅子/擦三遍短字幕，两译文新增6到1321；不改门规则、奖励、库存、AI、模型、schema9/checkpoint6。Q01控制单元79项通过，另三文件QA及入口/构建接线都在未提交工作区。
- `D:/tmp/bunny_campusentry_20261019_final02`源码终止113项：112通过，campus_entry_q02失败；`D:/tmp/bunny_campusentry_20261019_build02`39构建类通过，但原生portable从未启动，无新ZIP交付。不要运行该目录预写的record_campus.py/update_handoff.py：它们以174/39/53全部通过为前置，现不成立。前文期望174不是实际通过174。所有原进程和等待协调器已终止，不盲重启未知任务。
- 新失败是QA硬要求单局随机药房/宿舍就拿齐两敷料和两布料；实际布料2/敷料0。游戏支持真实仓库交付和购买，不据此改掉率、捏造任务物资或判定生产软锁。下次先修QA用实际仓库库存、按显示价商店补缺药，布料不足时允许有界的再次普通出击并按真实次数记返程；不要继续硬断言所有路线正好6返程。该修复尚未写入代码。
- 早一候选final01主动停止在58通过，build01为29通过/1个Q02失败。失败是合法合堆后源UUID消失而QA误报；已仅修测试为实际picked_up信号/源消费或释放/数量精确增加，stack_positive01包含真实合堆通过。生产库存未动，负例和停止原因在仓库外superseded_candidates.json保留。新02随机物资失败是第二个独立QA假设，不混称同一已修问题。
- 改动前基线从上一真实工坊独立包首胜升级档copy2，实际普通控制/菜单/E/TAKE/工作/购买交付，已按Q01/Q02+CampusChapter中继/录音/断电/补给连续到完成，6次安全返程，所有输入原件hash/mtime不变；只有Q01另做native，其余基线headless。当前正式新包完整native六链尚未验收。旧NarrativeSlice Q03—Q06仍false是正确的，别为了六个请求置位。中继和录音同局合法，普通streets_recon已有对应行动点。
- 当前冻结/执行/构建3731非文档源核对，全部1425运行时同版本，881原资产/93原场景文件不变，1315旧译文保留；PCK1315项checksum，676资源/23普通/29伴随许可。只是候选审计，不是全绿或授权。最新已交付仍为上一工坊build02，路径/hash看下节。正式个人档/Arcana/CombatGirls原包复核未改，无commit/push/上传。
- 用户自行发Arcana作者草稿再转告，助手未代发/操作/轮询作者页，不再问登录或验证码；尚无新许可。许可与开发并行，源包保持仓库外。旧工坊那次未知部署等待失败仍未知，不用新测试成功解释旧根因。
- 下一步顺序：先关闭Q02自动路线错误假设，再进行三动作适配/实际首小时人物内容。新鲜全套和独立包验证要在真实修订后另建证据目录，别覆盖失败日志。五小时/陌生玩家/自然失败恢复全链/最低硬件听感/资产分发/真实发布与80%评价均未达成，目标active。

## 当前接续 2026年10月19日 多出来的一颗／工坊归来

- 上轮progress是首战输入历史／换弹准入修复与两路线到首次升级。本轮新增实际3D家具互动短场，不只是HUD或更多回归。说明 `docs/WORKSHOP_HOMECOMING_2026-10-19.md`，机器记录 `docs/workshop_homecoming_2026-10-19_validation.json`。
- `workshop_moment.tscn/gd` 复用原compact环境／原主角／既有idle步态适配。走到工作台，暂时收好或敲备用螺丝，握工具装配，三位联系人仅电台／门外字幕拌嘴和催饭，没有新增NPC模型或配音。两反应只是动作／台词差异，同一收尾，不伪造持久选择、好感或奖励。
- 仍由原FirstMissionPreparation交易先保存再发布，再打开短场；失败保存不扣材料或放片。只在成功首次升级后进入；旧已升级档仅有工坊重看按钮，不强制播放。任何阶段可返回工坊，结尾可进普通Operations或Rest，不代接委托／自动出击。profile9/checkpoint6，无新字段或第二次保存／奖励。原训练室、校园、水塔街、广播车和主角保持。
- 局部旋转／双骨骼手臂接触，未改骨长／骨平移／scale。开发unit01-04保留超臂展、到达默认朝向和多余inverse-rest导致约5cm误差；修实际动作不是放宽断言。unit05接触及unit06整段手势通过。gui01虽结构绿但暗字／裁头，后改浅面板、补光和中景，实际复看；不要用getter绿冒充画面完美。dev01明确是可变探针副本；广回归认final01，当前独立包认build02（两个QA差异如后文）。
- 广回归冻结源码 `D:/tmp/bunny_fitting_20261019_final01`（其后仅有下述两处QA更新）：102场景／168类别逐项有完成记录；构建 `D:/tmp/bunny_fitting_20261019_build02`：33类；中文ZIP解压去Godot PATH后47类串行。**源码首轮155通过、first_sortie_return_gui在进入首战前等待失败，原因未知；没有状态快照，不推断必然失焦或已修。** `D:/tmp/bunny_fitting_20261019/observe_route01`只读观察协调器完成整条native路线，未复现暂停／等待失败。随后同一冻结源码和原协调器的13项native补充在 `final01/native_followup` 完成；初始results.json原失败保留，source_completion.json明确fresh_complete_suite_passed=false。不要宣称一次新鲜全套全绿；复走成功不是根因解释，不盲重启活进程或关掉失焦暂停。
- 补充矩阵和独立EXE的F+／Compatibility×首战两路线均正常BOOT、实际武器AI／TAKE／终端／撤离／扣核心升级后，运行短场两反应并到Operations；记录fitting_branch/profile_unchanged_by_fitting/fitting_exit_section。精确合成动作／视口按钮，不是真人或OS鼠标，不是校园六委托全链。后续再遇过渡失败应先记当前scene、paused/FlowMenu.mode、window_focused与elapsed，不盲加时限或关闭暂停。
- 3723当前非文档源／本次构建副本核对；旧广回归冻结／执行副本各自核对清单。广回归后只改tests/first_sortie_run.gd与tests/normal_start_test.gd两个QA：先走车辆北侧两道路点再取变动尸体箱，并在超时记录scene/paused/FlowMenu/焦点/elapsed。不加等待时限、不关失焦暂停或自动恢复。1425全部运行时文件与广回归版本完全一致，当前QA／私有生成副本核对并由本次33／47构建／解压类别覆盖；不是旧源码所有文件与当前逐字相同。881原资产、92原场景、1296旧译文保留，新增19至1315。PCK1303项checksum，670资源／23普通文件／29伴随许可；个人正式档与Arcana原件不变。原首战布局hash仍bdcfc65416908d80105ab4a6b91e68efbd9b1fae401fc1ebdd9b7defa6481333。
- build01原33构建通过，但第40项portable compat_first_return因QA直线走箱子撞到原车辆车道而停下；39项通过、失败原日志／坐标／图片保留。改QA实走路点后新建build02（生产不改），本次包与验证只认02。初次想用外部脚本验证导出包的PowerShell GUI调用分离成PID35420，无截图／完成标记，精确身份核对后只停止该自有探针，不算测试成功。不要复用那条命令或把失败文件抹掉。
- 上一真实独立包首胜升级档副本独立读回；额外 `D:/tmp/bunny_fitting_20261019/actual_old_profile_exits01/result.json` 13项从实际旧档出发，不new_profile或改已完成标志，确认不强制开片、可重看、approach／choice跳过与done去Rest。旧原档hash/mtime保留，非所有历史档保证。
- 最新ZIP `D:\tmp\bunny_fitting_20261019_build02\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,352,933字节，SHA256 `2c1a4a725913c603f4a35a1520254ecb3faeaca5359ddfee305528b180c43ac9`。EXE `D:\tmp\小兔试玩 工坊归来 20261019 02\LOCAL_ONLY_DO_NOT_UPLOAD/NeonBastion.exe`。仍LOCAL_ONLY_DO_NOT_UPLOAD，无commit/push/上传，没有新资产许可。用户自发草稿后转告回复；本轮助手未操作／轮询作者页，别重新请求登录、验证码或代发。
- 下一步优先从实际完成升级档继续普通Q01／Q02与校园六委托；人的卡点、剧情反应、目标硬件／听感和真实80%评价仍缺。工坊突然回商店／暗字幕及稳定机位裁头已处理，但实际正常路线立即入结尾的过渡帧仍可能短暂把耳尖放在横栏后，未做全帧无遮挡保证；以后可细化focus/FOV过渡。程序化手腕／手指不是最终动作捕捉品质。完整目标active且未完成。

## 当前接续 2026年10月19日 首战两路线实走与输入历史

- 上轮progress是开场/锁定信标修复与只到MOVE的正常入口证明。本轮继续正常入口实际战斗，两条路线均走完到第一次升级。原模型/训练室/剧情策略不变。说明 `docs/FIRST_SORTIE_2026-10-19.md`，机器记录 `docs/first_sortie_2026-10-19_validation.json`。
- 实测原版：正常BOOT后先瞄准/开两枪再移动3米，之后不再转向/开火却到了PMC stage3；负例 `D:/tmp/bunny_firstsortie_20261019/baseline_gate01/normal_start.json`。现在进入AIM重新记当前方向，进入FIRE/RELOAD清掉之前历史；保持旧方向90物理帧仍AIM stage1，新转向后FIRE仍等新射击。普通输入/计时/AI/数值/目标不改。
- 扩展查到“清历史”不能强迫不可能的换弹：有效满匣/无兼容备用弹两夹具原先卡RELOAD，`...dev01/admission_negative.log`两项失败；现在没有进行中的换弹且can_reload=false时继续已赚到的搜刮，不设reload_seen、不补弹/跳终端/给胜利。ongoing reload仍等完成；有弹可换时历史reload不跳课。两夹具正例 `admission_positive.log`；控制单元与真实输入路线明确分开。
- 新 `tests/first_sortie_run.gd` 继承normal_start_test。无new_profile/改任务/传送/直接伤害/禁AI/无敌/赠弹；动作输入、仅已观察LOS敌人的精准auto-aim及原生视口按钮，真实巡逻/TAKE/原门/8秒调查/两路线/8秒撤离/结算/一核心升级。source和独立EXE各4原生矩阵（F+与Compatibility×直接返程/额外搜刮），另两路线独立重读3项。不是Windows物理鼠标或真人手感，更不是完整首小时；headless的UI是回调。输出各case captures/normal_start.json，含shots/kills/health/实际核心ID/最终进度。
- 最终源码 `D:/tmp/bunny_firstsortie_20261019_final03`：101/101场景、164/164类；构建 `D:/tmp/bunny_firstsortie_20261019_build03`：32/32；中文ZIP解压去Godot PATH后43/43串行。3717非文档源/冻结/执行/构建一致（隔离名及私有QA例外）；881原资产、92原场景、1296原译文保留。PCK1295项checksum，666资源/23普通文件/29伴随许可。profile9/checkpoint6、物理hash仍bdcfc65416908d80105ab4a6b91e68efbd9b1fae401fc1ebdd9b7defa6481333；旧实际包挂起档继续读回，正式档/Arcana原件未变。
- 最新ZIP `D:\tmp\bunny_firstsortie_20261019_build03\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,328,509字节，SHA256 `1004849b7df613115179721b66cc846055d0ce88b9c7167bc503f602b17dc5cf`。EXE `D:\tmp\小兔试玩 首战实走 20261019 03\LOCAL_ONLY_DO_NOT_UPLOAD/NeonBastion.exe`。仍LOCAL_ONLY_DO_NOT_UPLOAD，无commit/push/公开上传，不把测试绿称作公开许可。
- final01/build01是早期普通路线绿但缺后查换弹边界的候选，未交付；发现真实负例后主动停止旧快照源码套件以免GUI重叠，目录保留。最终使用03。早期外部探针dev_run01漏Vector3类型/dev_run02读已释放的巡逻节点，已各保留日志；仅修探针，未改生产敌人生命周期。旧进程均有命令行校验后只停本测试的进程，不重启未知任务。
- final02/build02保留了换弹边界修复与32项构建通过，但源码Compatibility在部署等待误报：600渲染帧只1369ms，部署动画才到0.86s；独立诊断继续等到6944ms正常入场。仅把normal_start_test等待改成15秒墙钟截止并核对实际场景/过渡；不改游戏部署时长/流程，不盲重试失败结果。02未交付，便携测试未启动，最终03从新快照重验；诊断 `D:/tmp/bunny_firstsortie_20261019/wait_diagnostic01/diagnostic.log`。
- 用户最新明确选择「我自行发送草稿，再转告回复」。授权联系交由用户；助手未代发，不再操作/轮询作者页，不再请求登录或验证码。尚无作者许可原文，不把联系意向等同于已发送或已授权。短稿 `D:/tmp/arcana_trial_20261019/contact_20261019/permission_request_short_zh.txt` 保留，作者页交接保留。
- 下一步优先首战继承美术与校园观感落差、陌生玩家实际卡点，以及从这次真实升级后的profile继续正常Q01/Q02/校园六委托，而不是再造完成标志夹具。不要把精准控制器满血结果当作难度太低/人类喜欢的证据。整体公开发布/真实80%好评仍active且未达成。
- 人工仅看机器记录中5张本批截图；额外核心真实拿空、结算可读。首次升级后当前回到联系人交易页（仍选中工坊），没有专用完成卡；真实保存/扣核心通过，不等于体验已打磨。此点与继承首战美术一起留待后续，不为补一张getter断言就宣布解决。

> **最新授权联系安排（覆盖下方历史登录交接）：** 用户已选择「我自行发送草稿，再转告回复」。助手未代发，不再操作或轮询作者页，也不再请求登录/验证码。尚未收到作者许可原文；不推断已发送或已授权。短稿 `D:/tmp/arcana_trial_20261019/contact_20261019/permission_request_short_zh.txt` 保留。游戏继续使用现有模型，本地验证照常。

## 当前接续 2026年10月19日 正常开场与首战信标

- 上轮属于progress：水塔街6段返营对白真实入包。本轮先复核作者页，仍有未登录/验证码，重新markHandoff；没有新消息/授权、未收到手动登录完成答复，不重复问或代做验证。随后从正常BOOT而非跳关夹具观察新用户入口。
- 基线 `D:/tmp/bunny_firstlook_20261019/baseline03`：实际启动/菜单/基地/作战室/确认出击到first_mission MOVE。发现旧开场24秒三句设定说明、未开放大蓝撤离标识遮出生角色且提前叫调查终端。本批改三张现有开场卡为三人九句对话；不改24秒/跳过/旧seen偏好。只把首战专用撤离可视/焦点派生于原can_extract gate，开放后小字恢复；无新存档/奖励，战斗与8秒防守不改。
- 新 `tests/normal_start_test.gd` 不new_profile/改任务状态/传送/禁敌，走正常BOOT和按钮到初始移动教学；headless是回调，native是真viewport点击，严等生产转场结束与入场镜头结束。不是实际首战战斗，更不是完整真人首小时。首战专用提取组件表现改动；其他地图退出点不变。
- 源码 `D:/tmp/bunny_firstlook_20261019_final01`：100/100场景、156/156类别；构建 `D:/tmp/bunny_firstlook_20261019_build01`：28/28；中文ZIP独立解压去Godot PATH后37/37串行。正常初次41项、英文42、独立重启20，另实际改动前源码正常部署初始首战挂起档21项；原档未变（不是旧导出包来源）。旧真实独立包校园/广播车/拆铃档仍过。受控首战原生199项检查锁定/真实终端解锁后视觉与交互恢复，含直接处理敌人的夹具，不冒充真人。
- 首战物理/导航hash仍 `bdcfc65416908d80105ab4a6b91e68efbd9b1fae401fc1ebdd9b7defa6481333`；profile9/checkpoint6，旧已看偏好不强制重播。3714非文档源/冻结/实际执行/构建一致（隔离名和私有QA例外），881原资产/92原场景/1290原译文保留，新增6条至1296。PCK1291逐项checksum、664资源/23普通文件/29伴随许可，正式个人档与Arcana原文件不改。
- 最新ZIP `D:\tmp\bunny_firstlook_20261019_build01\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,317,503字节，SHA256 `6609bdab861660f51f8c6a1a265e789f95002d19c58306827ec01548c56a1766`。EXE `D:\tmp\小兔试玩 开场与首战 20261019 01\LOCAL_ONLY_DO_NOT_UPLOAD/NeonBastion.exe`。说明 `docs/FIRST_IMPRESSION_2026-10-19.md`／机器记录 `docs/first_impression_2026-10-19_validation.json`。
- 失败诊断留存：baseline01按钮getter源文/译文错误，baseline02没等转场覆盖结束，不是游戏坏；dev01仅stash_layout在合法背景初始化变动，观察卡片快照改为初始化后、headless回调用途与原生输入明确区分。额外首战原生外层wrapper错把完成标记空格当冒号；引擎本身0退出199项全过，`first_gate_source_validation.json`保留原hash与说明。勿为凑测试去改生产转场、仓库或输入。
- 下一步：真正沿正常首战移动/瞄准/交战/搜刮/终端/撤离/第一次升级跑，现有prototype route从Hanger跳过新手，不是这个流程；本批只到MOVE。留意移动前的鼠标位置是否让AIM步骤一闪而过（待实际验证，别先改），以及首战继承平面几何与后续校园观感落差；别继续开新地图或堆HUD替代首小时。真人卡点、作者手动登录、新许可与真实80%好评仍缺。
- 原模型、训练室、Arcana/CombatGirls策略不变，无commit/push/公开上传；完整目标仍active。

## 当前接续 2026年10月19日 水塔街返营对白

- 本批增加6段51句中英返营回想（三位联系人×两条供水路线），按最后一次实际安全撤离结算的water_public／water_tanker选取。作为委托页第二张可选重听卡保留校园原对话；没有好感、额外奖励、强制弹窗或模型替换。见 [剧情与本地包](docs/WATERWORKS_RETURN_2026-10-19.md)。
- Profile schema9新增waterworks_memory，checkpoint6不变；失败、放弃、早退、无关远征不更新/擦除既有成功记忆，保存失败不发布，重复旧结算不回滚。旧schema1-8默认空，不从弹药/药品或settled IDs猜旧分支。旧校园地图3/4与原挂起机制保持。
- 最终源码 `D:\tmp\bunny_waterreturn_20261019_final02`：99/99场景、150/150类别；构建 `D:\tmp\bunny_waterreturn_20261019_build02`：25/25；中文空格路径ZIP解压去Godot PATH后32/32串行（F+、Compatibility）。新对白专项561逻辑／699原生、8独立读回；实际两条移动/AI交战/阀门/撤离追加正常落盘记忆检查。不是真人首小时/听感/口碑。
- 实际上一包schema8挂起档副本迁移/独立进程schema9重读，按既有JSON数字类型/浮点写出精度规范比较全部旧字段。原始档hash和mtime未变。初版精确Dictionary比较在5处数字类型上误报，诊断canonical JSON一致；仅修测试，不改生产数字序列化器。dev01诊断、final01全绿与build01错误preflight均保留且非最终包。
- 最新ZIP `D:\tmp\bunny_waterreturn_20261019_build02\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,309,388字节，SHA256 `83e6ccba92e108540b97abb7750e042c5c752962784376e708fe44aaa54a6b92`。解压EXE `D:\tmp\小兔试玩 水塔街返营 20261019 02\LOCAL_ONLY_DO_NOT_UPLOAD/NeonBastion.exe`。PCK1287逐项checksum；662资源/23普通文件/29伴随许可。3711非文档源码与实际执行/构建副本一致（仅隔离名及私有QA autoload）；881原资产、92原场景、1233原译文保留，新增57至1290。正式个人档、Arcana原文件未变。机器记录 `docs/waterworks_return_2026-10-19_validation.json`。
- 作者页本轮只读复核仍是未登录/验证码，继续handoff；没有发送私信/新许可，未收到手动完成确认，不重复催问。浏览器tab和短稿详见下一节。用户爱给付费下载仍仅登记来源。原模型保留，Arcana/CombatGirls不入包，无commit/push/上传。
- 下一批优先真人正常BOOT首小时卡点和这批对白的实际反应／作者登录交接，不把更多HUD、回归数或文本句数当作好评证据。公开发布与真实80%好评目标仍active。

## 当前接续 2026年10月19日 作者联系已到登录交接

- 本轮不再改游戏代码，重新推进用户优先要求的 Arcana 作者联系。便捷封装调用创建主页超时，但新inventory确认已建立作者tab2，不能把超时当成创建失败。通过已公开的浏览器API `browser.tabs.get("2")` 加 `playwright.domSnapshot()` 后续成功读取主页，不是绕过登录或验证码。当前作者名乌龙woOlong、UID3690978254784736与原视频归档相符；页面实际有「发消息」入口。
- 页面显示未登录并弹出点选验证码，已截图核实。**没有发送私信、没有操作验证码、没有尝试登录，也没有取得授权。** 已把作者tab标为handoff保留；新的异步问题只请用户手动完成这一新观察到的登录门槛，旧授权状态／试玩卡点问题不重复催问。
- 当前浏览器ID2、tabID2、providerTabId `browser-use:5299ad7f-833c-44bd-97d7-f26082c8c0b1`。Cua调用已进入Browser直接API；便捷封装为何超时尚未确定，勿重复创建作者标签。先用当前inventory确认；不要改用Sky／原生自动化绕过禁用，不要从磁盘提取登录凭据或用接口绕过验证码。
- 证据和交接图：`D:\tmp\arcana_trial_20261019\contact_recheck\contact_status.json`、`author_login_verification.png`。短稿仍为 `D:\tmp\arcana_trial_20261019\contact_20261019\permission_request_short_zh.txt`。本节是历史交接；用户后续已决定自行发送并转告回复，助手不再查看作者会话或代发。非绑定询问不等于接受条款或取得许可，身份对应也不是完整权利链核验。
- 最新游戏包仍是下节cutaway build02；本轮没有新包，不把作者主页已打开说成已联系成功。Arcana原文件hash未变，资产策略不变，未commit／push／公开发布，完整目标仍active。

## 当前接续 2026年10月19日 兼容渲染室内剖面

- 已修上一批实际宿舍截图中的 Compatibility 屋顶挡主角问题。实例transparency在该渲染器被忽略，旧属性断言不足；新camera_cutaway_test直接采样绿色代理体，旧实现4项像素失败。非Forward+对遮挡渲染实例剖开，Node.visible／材质／物理不改；恢复尊重外部hide，纯装饰顶棚不闪烁。Forward+渐隐照旧，实际主角的独立包宿舍路线已看图。见 [修复与新包](docs/CAMERA_CUTAWAY_2026-10-19.md)。
- 接线箱world label／灯／地图共用状态与颜色，响过的地图点不再写4秒。新地图3状态断言加入原专项，71 headless／73原生；渲染专项25结构／83原生，两导出渲染器实际23帧采样及恢复检查均通过，不以getter值替代画面。
- 权威 `D:\tmp\bunny_cutaway_20261019_final02`：98/98场景、147/147类别；`D:\tmp\bunny_cutaway_20261019_build02`：23/23构建、27/27独立解压串行。实际执行／构建副本除已记录隔离配置外与冻结源相同；3707非文档文件清单一致，881原资产／92原场景／1233译文不变。profile8、checkpoint6、校园map4／旧挂起map3不变；上版实际部分拆线及安静快传两档也成功读回，原档未改。
- ZIP `D:\tmp\bunny_cutaway_20261019_build02\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,296,430字节，SHA256 `b83c30f8e0943fc66926f14737e5264d7990a2e82ec2ef22b8aacb163c4a6d21`。PCK1282条目全checksum，660资源／22普通文件，许可伴随29份不等于许可闭合。证据 `docs/camera_cutaway_2026-10-19_validation.json`。
- 首轮final01在98场景完成后，广播车原生closed_path断言失败一次；独立诊断三跑两次iteration2有路、一次iteration1空路。只给测试补导航端点同步前提，原绕行断言保留，未修改生产导航。final01／build01淘汰保留；初始代理颜色阈值误判12%透色、视觉RID API拼错的开发日志也保留。不将补测冒充首轮全绿。
- 当前室内与已响地图两项问题已修，别再重复当作未修根因。下一步仍应核对正常BOOT后的实际首小时和有辨识度内容／真人卡点，并推进作者联系；不连续以HUD／测试数量替代游戏体验。现有异步授权状态和试玩问题未获新回复，不重复催问。仅此机器F+／Compatibility，不冒充最低硬件、Mobile设备、听感或真人验收。
- 原模型／Arcana／CombatGirls策略不变，无commit／push／上传，个人档未改。公开发布及真实80%好评目标仍active。

## 当前接续 2026年10月19日 校园拆铃路线

- 新增实物警铃接线箱，四个档案点各一配套位置；4秒靠近操作、小范围工具声、受伤／离开／墙体中断。先拆再快传，或在25秒报警倒数内绕去拆；同刻铃先响，响过不能消除记忆。只取消警铃，不改枪声等听觉、出口或奖励。苏弥／沈砚霜短无线电已接入。不是新章节，不换角色。见 [玩法与本地包](docs/RECORDS_ISOLATION_2026-10-19.md)。
- 新校园地图revision4有实体碰撞；旧revision3校园挂起保留原几何，无新箱，继续保存也不转换布局。profile8／checkpoint6不变。确实从上一独立包读回一份真实校园档，存后再第二进程读回，旧布局签名相同；原档未变。不是所有历史档保证。
- 权威源码 `D:\tmp\bunny_records_20261019_final02`：97/97场景、144/144类别；构建 `D:\tmp\bunny_records_20261019_build03`：22/22；解压24/24串行。源码／执行／构建3704非文档文件一致，881原资产、90旧场景及1218旧译文保留。新专项68逻辑／70原生两渲染器，8跨进程；实际AI路线seed907为3发／1击杀／生命260／0中断，不冒充正常BOOT加六委托真人通关。
- ZIP `D:\tmp\bunny_records_20261019_build03\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,287,415字节，SHA256 `d1ef4825a2e0dd4d94a43ddf2d1efe7bf3ec351cf0fd2ef8786e23de6a7f181a`。PCK1278条目逐项校验，仍选定导出658资源／22普通文件。机器记录 `docs/records_isolation_2026-10-19_validation.json`。
- 首次全量final01在97场景通过后，原警铃跨进程读回确实失败4项。实测`2.0 in [2,3]`为false而直接数值相等为true；规范化已验证阶段为int，增加安静快传真实落盘读回及无效JSON状态测试。原失败档复制重放12项通过。build01 QA场景Node／Node3D错误、build02未含最终修复的窄通过候选保留但淘汰。勿将它们冒充最终全绿。
- 下一批优先核对 Compatibility 实际宿舍档案路线截图的屋顶遮主角问题，以及警铃响过后的地图标识仍显示4秒；证据 `...build03/compat_isolation_route_captures/isolation_run_records.png`。不是未检出的抽象风险，别又跳去加第三张地图。真人首小时卡点、听感、低配与许可仍需继续。
- LOCAL_ONLY；无commit／push／上传，正式个人档未改。Arcana／CombatGirls仍在包外；作者联系状态等已有异步问题答复，不重复问。公开发布和真实80%好评目标仍active。

## 当前接续 2026年10月19日 本地导出依赖与作者联系

- 当前权威本地包为 `D:\tmp\bunny_export_20261019_build03\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，239,262,601字节，SHA256 `50239975733891aa1be35b41e87c1f4fbe9669ee78439a7614337990ee6d5c15`。玩法／模型未改；1,418运行时文件与上一可玩包源清单一致。详见 [本轮说明](docs/RUNTIME_EXPORT_2026-10-19.md)及 [机器记录](docs/runtime_export_2026-10-19_validation.json)。
- 构建工具新增引擎依赖目录、脚本全局类／字面路径／有界动态族追踪、选定导出及完整许可资料伴随包。652资源／22普通文件，15单元测试，19构建类别、16串行独立解压类别均通过。PCK245,520,020字节／1266项，逐项checksum及源缓存对应核验；未用VRM、女性审查模型和37份缓存未导出，源文件未删除。build01反向测试路径自污染、build02字典索引笔误失败保留，勿交付旧失败目录。
- 本轮没有重跑95场景／140类别全源码套件；那是上一玩法批结果。新实际包覆盖清单全解码、默认启动、菜单、两渲染器广播车／路线／训练室及一份实际旧包挂起档；已看截图。正式存档、旧挂起原档、Arcana原文件未变。不是干净VM、最低硬件、真实听感或真人通关验收。
- 作者联系两次绑定B站标签页超时重置，网页读取受阻，本轮没有发送。短草稿 `D:\tmp\arcana_trial_20261019\contact_20261019\permission_request_short_zh.txt`，原长稿保留。等待已有异步问题的用户答复，不重复询问，不宣称已登录／已联系／已许可。用户的爱给网付费下载只登记来源，不作原作者授权证据。
- 仍LOCAL_ONLY，Arcana／CombatGirls不入仓库或PCK；当前原型模型权利也未闭合。未commit／push／上传，公开发布和真实80%好评目标仍active。下一批不要再以工具／HUD／测试数替代可玩内容或真实反馈；许可、正常首小时卡点、目标硬件仍需继续。

## 当前接续 2026年10月19日 广播车可读性与联动闸口

- 不是新地图／新章节：把上一轮广播车的状态、命中、断电和通路做实。新BlockadeReadout屏幕卡以真实阶段／时间和HP显示，仅在玩家视线、无遮挡及屏幕内可见；警戒落点环、原创锁定／散热短音效、翻杆／线灯、装甲与散热伤害提示已接入，所有控件不抢输入。详见 [本批与最新本地包](docs/BLOCKADE_POLISH_2026-10-19.md)。
- 旧Concrete5中央障碍现在是随Van.destroyed派生的抬升车行闸，实体和画面一起升高，NorthGateLink同步开放；不新增保存门状态。原闭合碰撞／静态nav签名与旧导出档完全相同，地图revision1、profile8、checkpoint6不变。旧档从实际上一轮导出程序复制读回，新EXE通过，原文件未改。两侧仍可绕行，北撤仍需击败车辆。
- 修复PlayerVisibility.aim_trace将hostile_emplacements当作可观察合法目标而非普通掩体，未观察到不暴露精确瞄点；真实建筑仍挡弹。HUD声音类型补齐gunshot／alarm／mechanism，保留旧gunfire和movement。旧71项观察回归及新专项覆盖。
- 权威 `D:\tmp\bunny_blockade_polish_20261019_final03`：95/95场景、140/140类别；`D:\tmp\bunny_blockade_polish_20261019_build03`：构建15/15、ZIP中文空格解压／无Godot PATH串行15/15，0 ERROR、冷导入仅两条旧FBX警告。专项headless66、原生／导出Forward+／Compatibility各72；训练室和真实AI射击／撤离仍通过。PCK1511条目，3692份非文档清单一致，旧美术场景除本关外967份、旧译文1210条保留，现1218条。
- ZIP `D:\tmp\bunny_blockade_polish_20261019_build03\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，278,122,331字节，SHA256 `a434e2003220be7fa2ababcdaeaa3d03b01376dfa88509739e7e13e05f9c228e`。机器记录 `docs/blockade_polish_2026-10-19_validation.json`；原生夹具截图不是实战录像。first import／浮点断言失败保留，final01／02主动淘汰的partial结果和SUPERSEDED.json保留，不当完整通过。以final03／build03为准。
- 沿用旧角色／服装／比例，不分发Arcana或CombatGirls。未commit/push/公开上传，正式个人存档不变，目标active。车辆仍固定关卡几何、粗碰撞；真人体验、听感、低配、许可和真实口碑未验收，不能用测试通过率代替80%好评。

## 当前接续 2026年10月19日 封街广播车遭遇

- 新独立可选任务 `blockade_run`、区域 `blockade_checkpoint`，完成首任务后从作战室正常选择，不伪装成整章C02。固定可编辑车辆加3个原感染者，红线1.5s预警、锁定点四连射、2.3s散热窗口、闭甲18%伤害、结构360；西巷广播独立断电，现有声音系统调查声源，不无限刷新敌人。北门需瘫痪车辆，南撤一直开放。唐葵／苏弥／沈砚霜短对白与结果收尾已接入。见 [实现与边界](docs/BLOCKADE_2026-10-19.md)。
- 车辆继承 DestructibleWorldObject，保留残车实体掩体；不冒充EnemyDefinition新兵种或人形击杀。checkpoint6／profile8不变，新增节点字段只影响新地图；保存原锁定点、阶段计时、结构值和PA供电，恢复不重复发任务奖励。新增区域／任务配对验证，旧图字节未改。
- 权威源码 `D:\tmp\bunny_blockade_20261019_final01`：94/94场景、138/138类别，0 ERROR、2条旧FBX冷导入警告；构建 `D:\tmp\bunny_blockade_20261019_build01` 14/14，解压12/12串行，两渲染器实战与训练室、独立进程中途预警读回均通过。非文档清单3682份一致，配置隔离差异核验，旧美术／场景967份和旧译文1181条不变，现译文1210条。PCK1501条目逐一校验。
- ZIP `D:\tmp\bunny_blockade_20261019_build01\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，278,091,117字节，SHA256 `acc2bda2e1bf5a78bc0ff6e9029a0e39291b0aaba00d7aa0d7f2953723470308`。机器记录 `docs/blockade_2026-10-19_validation.json`；原始开发导入／标签／导航卡点失败保留，不冒充全部初试通过。最终完整回归全绿，无需要覆盖失败的串行补测。
- 沿用既有模型、服装、尺寸，Arcana与CombatGirls未入项目或PCK。角色授权未闭合，LOCAL_ONLY不可上传。未commit/push，未触碰正式个人存档；目标仍active，不代表公开发布／80%好评达成。下一步优先陌生玩家可读性、车体美术和有操作变化的内容；别把仅测试或菜单当新增内容。

## 当前接续 2026年10月19日 休勤训练室

- 用户要求美少女游戏增加3D体操与家具动作，已实现独立训练室，不替换生产角色/Arcana、不改模型服装比例。入口为基地Rest的OpenTrainingRoom，正常过渡到训练室，再返回Rest；无战利品/数值/存档字段变化。见 [本批实现与本地包](docs/TRAINING_ROOM_2026-10-19.md)。
- 4个项目：原创举臂体侧伸展16s循环、复用CC0快走的跑步机、坐站循环、坐着休息。沿器材后方走道和坡道到位，坐姿切换先起身；复用hideout_idle的52骨映射，展示禁用战斗/主武器驱动，不改变骨骼平移/缩放。器材是固定可编辑环境，不是生成的人物。
- 全身/手动/自动绕转、暂停动作、0.5/1/1.25倍速、结束返回垫边、Tab藏界面。首次实机画面暴露遮住手脚的问题已修。没有IK/物理接触认证，衣服沿用原型，不冒充高级健身动画或换装。
- 最终源`D:\tmp\bunny_training_20261019_final03`：92/92场景通过、133类分项最终通过（含串行补测），2条旧FBX警告；新套件headless170、导出后Forward+/Compatibility各182均首次通过。包构建12项、中文空格ZIP解压且移除Godot PATH后13类最终通过。源03旧对白鼠标首次10错误、包03运水车原生首轮停在起点，原始失败保留；后续串行复查及未运行末项另存serial_rechecks.json。源02旧反馈原生8错误也保留。失焦暂停是路线排查方向，未证明两类问题根因，不冒充修复生产代码。源/当前/构建3662份非Markdown文档清单一致，实际3661份字节一致，project.godot仅核验过的隔离名/QA差异；先前965美术与场景不变，1152旧译文值保留（现1181）。
- ZIP `D:\tmp\bunny_training_20261019_build03\LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，278,044,947字节，SHA256 `03beffa69afdb5e08d4f67b38d5175285f9efacd3bcee2d408217fd9256066c7`；34s真实渲染动图 `D:\tmp\bunny_training_20261019_preview03\training_preview.gif`。包PCK1477条目/原始数据缓存排除核验通过，LOCAL_ONLY不可上传。记录见 [机器验证](docs/training_2026-10-19_validation.json)。
- 保留dev01失败与修复证据，最终final03/build03为权威。未commit/push/公开上传、未触碰个人正式存档；完整公开发布/真实80%好评目标仍active。已安装的Coding-Solo MCP没有在本批冒充使用，实际由隔离CLI与原生渲染验证。

## 当前接续 — 2026-10-19 水塔街新增可玩内容

- 用户明确批评“内容不增加的话也太少了”。本批新增独立水塔街远征，不再以HUD/测试数量为主要交付；完整公开发布/真实80%好评目标active，未换生产模型/Arcana候选，未commit/push或上传。见 [玩法与进入方法](docs/WATERWORKS_2026-10-19.md)。
- 正常入口：首任务后基地作战室的MissionChoice新增`waterworks_run`，部署到独立`waterworks_district`而非校园，固定黎明；不要求校园六委托完成、不补造其进度。约80×68m原生可编辑地图，修理铺/背街院落/广播广场/东泵站；4枪手+1重型无人机+3感染者，使用原有艺术家角色和战术，不是8种新敌人或程序人形。
- 固定8kg实物电池→8s可中断安装→明确确认居民水桶或运水车，开放西院/北装卸口及2份独立敷料/90普通弹的实际拾取；南口退路始终可用。广播一次引现有听觉调查广场，不刷怪/报玩家位置。拾取、携行损失、原子回仓走原系统。带电池提前撤后，下次水塔出击会正常装包同一ID，死亡会失去；不是只能积在仓库的死任务物品。
- 中文/英文现场短对白、争执、两个结果回应已接入；不增善恶/好感或终局事实。新增1物品/1任务/1区域/2loot表/原创合成PA提示音；当前37定义、5任务、4区域、9loot表、3敌人类型，1152译文（旧1085值保留）。旧profile8/checkpoint6不变，新分支用本任务目标事实并拒绝双选伪造。旧校园几何与角色原资产未改。
- 正式新包`D:/tmp/bunny_waterworks_20261019_build03/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，278,023,840字节，SHA256 `96f88402c0a975062cc0e6d5663a47df3487be3b87de8b4053a815547d4ce975`。构建11项、中文/空格ZIP解压且清掉Godot PATH后11项均通过；Forward+与Compatibility包内新图专项各81项。实际正常AI原生路线居民31发/8击杀/生命257.12撤离，运水车28发/7击杀/生命260撤离；是生成移动/瞄准与交互API，不是陌生玩家或实体手柄。
- 新图两进程源运行验证：写出部分安装、结束进程，再读同ID电池/剩6s并完成安装与实际运水车选择，2/2通过。新包另复制读取上版近战独立包实际生成的校园挂起档，生命137/资金1777恢复，原档hash未变；不是所有历史档/新图导出崩溃覆盖。PCK1465文件表与逐项checksum/排除审计通过，无Arcana。
- 首份全量在补电池再携行后主动停止（不是观测超时），build01保留但淘汰；final02确实91/131完成，build02被原生画面发现的塔下过暗替代。作者环境光改为COLOR=2，Final03/build03是最终权威。另一次enum诊断漏--path命中工作区旧导入缓存，未保存/恢复个人档，个人profile/.bak修改时间仍2026-10-17；实际验证均隔离APPDATA。
- 最终全量`D:/tmp/bunny_waterworks_20261019_final03/`已exit0：**91/91场景、131/131结果通过，0 ERROR，仅2条既有冷导入FBX warning**。源码/执行快照/构建源除文档外3720文件hash一致，全部日志hash复核，962原美术/旧场景字节不变；见 [机器记录](docs/waterworks_2026-10-19_validation.json)。正式交付build03，不再等待已结束的进程。规则78项、原生含3捕获81项。
- 下一批继续扩充可玩的区域/具名遭遇或小Boss、把人物关系落到行动后果，不要又连续几轮只做菜单/HUD/音频修补。本远征不是完整C02章节、车辆护送或已验证时长；原型美术、真人首小时/平衡、最低硬件/真实听感、许可、正式平台与真实评分仍未达成。以下旧节按当时范围理解。

## 当前接续 — 2026-10-19 校园近战与包间升级

- 用户完整公开发布/真实80%好评目标继续active；`main @ 891171e`加既有WIP，本批未commit/push、未公开上传、未换生产角色或Arcana候选、未触碰个人存档。见 [近战与本地包](docs/CAMPUS_MELEE_2026-10-19.md)。
- 感染者原先只在落拳时检查当前视线/距离，半径内侧移仍会被追拳。干净baseline02明确复现；现锁定既有`_shot_aim_point`，抬手时刹住追击、面向原点，落拳加入90度扇区。沿用1.65m/8伤害/2.7追击/0.38s抬手/1.8s间隔；受击推力、距离、墙体与观察仍生效。
- 短暂橙色地面扇区只给已观察敌人，边缘按墙体/视野裁剪，跟随原计时暂停/恢复，落空与死亡收起。提示为派生表现，无新存档字段，profile8/checkpoint6不变；资源、模型、地图、剧情与1085译文未改。
- 感染者39项检查含半径内侧移/原地实际扣血、不可叠加、角度半径几何和墙前裁剪；真实校园Battle有部分抬手的持久保存/恢复、遮挡过滤、同时运行玩家/攻击者物理的生成移动输入、死亡取消。其余敌人冻结/演员明确布置，不冒充陌生玩家首小时或六委托通关。
- 新本地Release ZIP：`D:/tmp/bunny_melee_20261019_build01/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`，277,945,235字节，SHA256 `eb7ab9accf89480832045523466ebe83118b8d3631555cbe02f83ad58092da3f`。旧包保留。构建8/8；ZIP解压到中文空格路径、清理Godot PATH后7/7（含默认启动/真实写读、Forward+菜单/近战/校园交战及Compatibility近战），两个包内原生近战各39项通过，已看实际截图。仅LOCAL_ONLY，不可上传。
- 新EXE另从上版release build04的smoke_userdata复制实际生成的校园挂起档，成功读回生命137/资金1777，原档hash不变；这是一次实际包间更新，不是全历史存档或旧版中断近战的兼容矩阵。证据`...build01/previous_build_upgrade.json`。PCK1433项逐文件checksum和排除审计通过；审计区分art_source备份`.import`指向合法assets缓存与真正制作资料缓存，不误把生产依赖当泄漏。
- 首次全量`D:/tmp/bunny_melee_20261019_final/`在campus_voice_gui停止：125行中124通过，该行5个逐句/重听断言失败；不能称首轮全绿。无捕获/带捕获的加日志重放未复现。仅测试夹具增加等待frame_post_draw后进入新process_frame，再注入一次原生鼠标；每次点击断言恰好触发一次，并带语言/阶段/联系人上下文，无自动重试、不改对白生产逻辑。专项1245项通过；不据此宣称已找到/修复生产漏点根因。
- 最终新快照`D:/tmp/bunny_melee_20261019_final02/`：**89/89场景、127/127结果通过，0 ERROR，仅2条冷导入FBX warning**，进程exit0。3,696非文档文件与工作区/执行快照hash匹配，全部日志hash复核；其中1,060资产/场景/资源/本地化项与改动前一致。包运行代码/资源与新快照一致；包冻结后唯一非文档差异是未导出的`tests/campus_voice_test.gd`输入夹具加强，无须把该测试塞进用户包。最终记录：[机器证据](docs/campus_melee_2026-10-19_validation.json)。
- 下一步继续正常启动的新档校园六委托和遭遇体验，收真实玩家卡点/喜好；作者许可、完整历史升级、干净VM/最低硬件、真实听感、正式平台发布与真实评分均未达成，不以新包/测试比例代替80%好评。以下旧节按各批当时范围理解。

## 当前接续 — 2026-10-19 本地独立包与退出修复

- `main @ 891171e` 加既有WIP和本批改动，未commit/push。完整公开发布/真实80%好评目标继续，未发布、未换模型、未碰个人存档。
- 已实际生成Windows x64 **Release**独立EXE/PCK与277,932,102字节ZIP：`D:/tmp/bunny_release_20261019_build04/LOCAL_ONLY_DO_NOT_UPLOAD_windows_x64.zip`。仅本地、不可上传；QA autoload只注入构建副本，默认启动不运行QA；app名Local Prototype隔离原型存档。见 [包与范围](docs/LOCAL_WINDOWS_BUILD_2026-10-19.md)。
- 官方4.7.2模板完整归档SHA256核对后只装Windows x64到APPDATA/Godot/export_templates/4.7.2.stable，保留旧4.6.1。模板元数据与下载日志在 `D:/tmp/bunny_release_20261019/`；EXE hash与官方release模板一致，不用debug模板冒充。
- 正式AudioDirector._exit_tree补混音停止排空（原来只有shutdown_for_test排空）；旧Main三跑两次AudioStreamPlaybackWAV/AudioStreamWAV泄漏，新候选三跑及music/effects/paused正式退出夹具均零警告。新回归不调用测试专用预清理，Main警告现在失败门禁，不再放过旧ObjectDB warning。未改声音素材、音量或游戏内时序。
- 独立包暴露PresentationProfile依赖addons/neon_content/asset_review，现将同一SceneState脚本检查移到scripts/data/scene_safety供运行时/编辑器共用；asset_review委托调用，根/子节点脚本拒绝和原校验保留。游戏数值、AI、地图、schema8/checkpoint6与1085译文不变。
- 最终源码快照 `D:/tmp/bunny_release_20261019_final/`：**89/89场景、126/126结果通过，0 ERROR，仅2条冷导入FBX warning**。3,696非文档文件与工作区、实际执行快照及私包构建源一致，全部日志hash已复核。见 [机器记录](docs/local_windows_2026-10-19_validation.json)。
- 私包构建7项通过：导入/导出、真实BOOT菜单、实际挂起写入/另一进程读回生命137和资金1777、schema2夹具迁移、包内正常AI校园交战撤离；另复制到中文/空格路径、清掉Godot PATH后默认启动/读回、Forward+和Compatibility原生菜单及Forward+原生校园路线5项通过。ZIP再解压、三文件hash一致、EXE读回通过。渲染截图已看；默认无QA参数也验证过。此为同版移目录，不是跨版本升级、干净VM、实体手柄、真实听感或最低硬件验收。
- PCK导出表1,429项审计：无制作资料/编辑器插件/开发工具原文件及其导入缓存，无Arcana名称条目。实际源manifest **36项定义**，旧31注记不准，本批没有新增物品；包按完整stable-ID集合及23段对白JSON全hash核对，而非沿用旧数字。
- 失败保留：build01 CRLF误判及编辑器依赖编译失败；build02 Release不支持--script（确认--help后停自有进程，不是超时重启）；build03误用31库存。最终build04修正后全通过。没有将失败包当最终包。
- 模型授权仍待用户联系作者，暂不换Arcana候选/生产资产；包不准公开。下一步用真正可启动的包检验正常新档首小时/校园六委托与遭遇、收具体卡点和玩家反馈，继续授权/最低硬件/正式发行流程，不将可运行ZIP或测试通过率偷换成80%好评。以下旧节按其当时范围理解。

## 当前接续 — 2026-10-19 交战反馈批

- `main @ 891171e` 加此前WIP与本批修改，未commit/push。完整公开发布/真实80%好评目标仍 active；生产模型、Arcana、原始资产、个人存档不变。
- 新只读CombatFeedback：实际玩家正伤害且目标可见才确认命中/击倒，包含初始、增援、感染者与火箭路径；不显示隐藏目标/血量/伤害数值。受伤箭头仅保存冲量方向快照，最多四个方向，不引用/跟踪攻击者。受击层30在普通HUD/补给箱25之上，暂停200之下，开箱时文字放箱体上方。暂停冻结，死亡/撤离清空。见 [本批说明](docs/COMBAT_FEEDBACK_2026-10-19.md)。
- 最终 `D:/tmp/bunny_combat_feedback_20261019_final02/`：**89/89场景、123/123结果通过，0 ERROR**。3,689非文档文件与工作区及实际执行快照一致，结果日志hash已复核；新套件55逻辑/55 Forward+，Compatibility同套件55（不是全量回退验收）。见 [机器记录](docs/combat_feedback_2026-10-19_validation.json)。
- 真实AI接触夹具玩家与攻击者物理均运行，生命260→255.05，原计伤5；随后明确控制目标位置/冻结AI的武器、视野、爆炸、增援、开箱受伤、暂停、实际死亡/撤离与checkpoint数据相等检查。不冒充陌生玩家/实体手柄/真实音频验收。
- 正常AI校园自动路线改动前后原生运行均9发/一次换弹/3击杀/回收1物资/成功撤离，撤离生命260；并非正常BOOT六委托通关。另一个原有原型路线本次23发/0击杀/0受伤、任务未完成，两者不能混说。
- 保留冷导入2个既有FBX warning及Main强退1条ObjectDB warning。verbose Main本次复现AudioStreamPlaybackWAV/AudioStreamWAV各一个未释放引用；类型已定位，不称根因修复。AudioDirector已有_exit_tree stop_all，shutdown_for_test另有混音周期排空等待，可供下一批调查；不要掩掉原日志。
- 最初夹具放到建筑内、开箱警告与标题重叠、原生布局未等渲染的失败均保留；旧 `..._final/` 主动因最终时序断言修正而SUPERSEDED/停止。不是观测超时重启。最终源码与测试在final02冻结，不继续在该快照内修改。
- 1082条译文原样保留，新增3条到1085。人物剧情数据、物品数、profile8/checkpoint6、战斗数值/AI/地图规则未改。Arcana许可仍等用户联系作者，暂不换模型，未发布含模型构建。
- 下一步不要继续只堆HUD/菜单测试：优先完整新档校园路线/遭遇和真实体验、音频及正常退出清理、匹配模板的独立构建；资产许可、最低硬件、平台页面与真实评分均未达成。以下旧“当前”均按当时批次理解。

## 当前接续 — 2026-10-19 补给箱操作批

- `main @ 891171e` 加既有对白、指引和本批本地WIP，未commit/push。完整发布/80%好评目标仍 active，不以测试全绿替代。
- 补给箱默认焦点、行导航、Tab约束、自动滚动、重建/语言切换焦点恢复、深色焦点框、逐堆负重差额和操作提示已实装。复用原整堆拿取/交换，无库存、经济或schema改变。见 [实现](docs/CACHE_INPUT_2026-10-19.md)。
- 当前运行时内置UI动作没有手柄事件，ControlBindings补A/B/十字键，不覆盖键盘事件、玩法手柄或用户配置，重复初始化不重复添加。A同时绑定翻滚，交互输入占用时禁止启动该翻滚；走动、受伤、换弹与计时仍工作，关箱恢复。不要只用禁用角色物理的夹具验收这个冲突。
- 最终 `D:/tmp/bunny_cache_20261019_final02/`：**88/88场景、121/121结果通过，0 ERROR**；仅2条冷导入FBX warning。3,684个非文档文件与工作区及实际执行快照一致，全部日志hash复核。补给箱97逻辑/98 Forward+事件检查，Compatibility同套件98（非全量回退），操作设置50/独立进程读回3。见 [机器记录](docs/cache_input_2026-10-19_validation.json)。
- 开箱无焦点、选择器丢焦点、真实A事件无绑定、A误翻滚均有失败日志；旧 `..._final/` 因后期发现物理输入漏洞被主动标记SUPERSEDED并终止，不能当作完整通过。测试API/类型错误日志也保留。
- 本次Main无ObjectDB warning，不代表上一批偶发根因已修复。正常AI原型路线7发/0击杀/0受伤、任务未完成；不能宣称校园六委托正常AI通关。新输入夹具显式布置物品、敌人停用，仅A交换/关闭后翻滚阶段保留角色物理；不是实体手柄硬件或陌生玩家体验认证。
- 原1079条译文完整保留，新增3条到1082。生产资产、人物故事数据、玩家存档与Arcana原文件未改；作者授权仍待用户联系，暂不换模型。godot-mcp已另装仓库外并做独立协议测试，当前工具目录未出现新原生namespace，未伪称通过它调用了游戏。
- 下一步继续真实战斗/搜刮/撤离与完整六委托正常路线，准备可安装发行构建并处理授权；不要继续以菜单/对白/回归数量替代可玩内容、陌生玩家反馈与真实发布。以下旧“当前”按当时批次理解。

## 当前接续 — 2026-10-19 出击指引与新手路径批

- `main @ 891171e` 加上一批对白WIP和本批修改，未commit/push。用户完整公开发布/80%好评目标继续，不替换模型，不触碰个人存档。
- 主HUD优先显示居民委托与下一步；可选出击行动含已完成项可展开。基地总览、作战室、地图共用只读SortieGuidance；有警报时危险倒计时不被新指引盖住。Q02/最后装备交付可从作战室直达实际联系人，不强迫出击。见 [本批说明](docs/SORTIE_GUIDANCE_2026-10-19.md)。
- 两站实际修完→取记录器或先撤；实物拿到→带回；实际断电→撤离；物资未齐→回基地交货；旧挂起局保留原合同/地点。任务/奖励/AI/地图/profile8/checkpoint6与23段人物对白原数据未改。
- 修复英文长简报入树前未配置换行导致375/347px溢出，增加真实横向/高度边界检查；初始无交互时不显示空白纸条；英文基地入口本批改为翻译键。
- **最终88/88场景、121/121 runner结果通过，0 ERROR**，1737个运行/测试/资源文件与执行快照一致。新套件234逻辑/258 Forward+输入检查，Compatibility同套件258检查（非全量回退验收）；全部九种基地阶段另有304项额外布局/跳转诊断。见 [机器记录](docs/sortie_guidance_2026-10-19_validation.json)。
- warning必须保留：冷导入2个既有FBX；Main强制帧数退出1条两实例ObjectDB warning。新环境verbose复跑未复现，不代表根因修复。原正常退出子进程与实际AI原型路线通过，后者14发/0击杀/0受伤、任务未完成，不能说校园正常AI通关。
- 源码权威最终验证为 `D:/tmp/bunny_guidance_20261019_final02/`。旧 `..._final/` 在补空提示修正后主动终止，SUPERSEDED说明与部分日志保留；开发期类型/节点查找和英文溢出失败亦保留。
- 旧节的“下一批修主HUD/英文委托入口”已在本批处理。下一步继续新玩家正常操作下的搜刮、交战和撤离反馈/完整路线；不要继续堆对白或用自动测试数量代替试玩。正常新档六委托真人体验、最低配置/音频、独立构建、资产授权、真实发布与玩家评分仍未达成。Arcana授权仍待用户联系作者，暂不换模型。

## 当前接续 — 2026-10-19 校园人物对白与公开试玩方向

- 基线 `main @ 891171e`，本轮本地WIP，未commit/push，未改原始模型或玩家存档。新长期目标是可公开发布的游戏及真实80%好评，不把本批收口当作完成。见 [完整目标与发布门槛](docs/PUBLIC_PLAYTEST_TARGET.md)。
- 实装23段、113句双语可跳过/重听的联系人短对话；任务简报与操作条件分开，三个现场故事文本重写；按既有事实派生场景，无新增存档字段、好感值或奖励。详见 [本批说明](docs/CAMPUS_VOICE_2026-10-19.md)。
- 最终全新隔离快照 **87/87场景、119/119 runner结果PASS，0 ERROR**，仅冷导入2个既有FBX warning；1732个源码/测试/工具/资源文件与执行快照hash匹配。新对白场景1144检查，Forward+真实Control输入1156检查；另有Compatibility同对白套件1156检查，不是回退渲染器全量验收。见 [机器证据](docs/campus_voice_2026-10-19_validation.json)。
- 首次全量因4处Q01固定中文子串断言停止，改为完整的当前语言状态相等，保留原事实校验，最终全量重跑通过。补充中文Battle截图也有一次未取到record信息的探针失败；原日志和固定帧诊断重跑保留，不能说所有尝试首轮通过。
- Arcana本地用户文件在Downloads，试装/截图/来源响应/未发送的授权询问信在 `D:/tmp/arcana_trial_20261019/`，不入Git。用户明确**优先联系作者，暂不换模型**。已查到B站分享者乌龙woOlong、UID3690978254784736，文件作者Wulong；不等于已确认全部权利或获授权。VRM内禁止商业/暴力/再分发标记未被新许可覆盖，未上传含模型构建。视频说明VRM不含演示中的MagicaCloth裙摆/斗篷物理。
- 下一批具体问题：实际校园主HUD仍把可选档案行动放第一行，校园委托仅次行，易误导新玩家；英文Hideout顶部“委托记录”按钮仍硬编码中文。先做正常新玩家路径的任务优先级/指引与真实战斗体验，再扩展核心遭遇和后续内容。不要只加对白数量或继续重放相同自动路线来冒充体验提升。
- 未完成：正常新档完整六委托真人体验、剧情喜好反馈、风险收益/听感/最低配置、可分发资产、4.7.2独立导出与实际平台发布及玩家评分。下方更早“当前”按历史批次理解。

## 当前接续 — 2026-10-17 自动化测试收口

- `main @ e940cd1` 加既有本地WIP；本轮没有commit/push、重置存档或更换角色资产。
- 最终隔离快照 **86/86场景、117/117 runner结果项PASS，0 ERROR**；仅冷导入2个既有FBX警告。另在同一最终快照完成Compatibility图形4/4与生产内容审计。详见 [收口报告](docs/TEST_CLOSEOUT_2026-10-17.md)、[机器记录](docs/test_closeout_2026-10-17_validation.json)。
- runner库存82→86，补AP/仓库旋转跨进程读回、4类新增测试最终完成标记、3项图形UI输入检查。新增3项Python翻译构建检查，作为runner的一行结果。
- 修复中文源与运行资源漂移：保留现行888条译文，将104条缺失/109条不同步文本回写JSON；显式UTF-8构建并归一化资源格式。实际译文映射、游戏规则与schema8/checkpoint6不变。
- 未关闭的体验/发布项：英文委托页仍有中文硬编码；原型密集物品夹具存在世界标签重叠；完整六委托正常BOOT连续试玩、音频、最低配置与角色商业许可仍需独立验收。自动路线不等于真人完整Alpha。
- 以下10-15及更早“当前/最新”、数量与未完成列表均按其历史批次理解，不覆盖本节。

> 2026-10-15试玩收口进行中：修复记录器与委托地点不符，补地图阶段/中断提示/确认焦点及真实输入路线回归；80/80场景、103/103结果项通过，0 ERROR；本轮未提交推送。详见 [试玩收口](docs/CAMPUS_PLAYTEST_POLISH.md)。下方79/102是此前已推送批次的验证记录。

> 2026-10-15最新：校园第二批维修、唯一记录器、L-02B断开/保留L-02A、备用护甲与60普通弹收尾已接入；当前定义31、测试库存79、schema8/checkpoint6。用法与限制见 [校园第二批](docs/CAMPUS_BATCH2_IMPLEMENTATION.md)。下方70/72/75/77等数量及“仍待第二批”是历史阶段记录，不能作为当前状态。

> 2026-10-15真实内容批：快装/消声/观察镜3种可回收与购买的实物套件已接入单武器安装、携行损失和保存链；定义30、测试库存77。用法见 [套件交付](docs/FITTING_KITS_IMPLEMENTATION.md)。后续校园任务仍未完成，下方旧数量保留阶段历史。

## 当前接续 — 校园第二批

- 最新接口：profile8、checkpoint6；定义31（3实物改装套件+1固定记录器），测试场景79。旧schema/任务/男女原骨架兼容不回退。
- **79/79场景、102/102结果项通过，0 ERROR；2个既有FBX警告仅冷导入。** [验证记录](docs/campus_batch2_2026-10-15_validation.json)。
- 本轮冻结范围是内容制作工具、男女/主角动作、小批实际道具及校园六委托，不含整个十二章Alpha。参看 [第二批实施](docs/CAMPUS_BATCH2_IMPLEMENTATION.md) 和验证JSON。
- 剩余发布门槛：真人连续游玩/路线与手柄、真实音频、最低配置；Artoria/UCL商业许可仍需独立审查。验证时为本地WIP；本次提交交付上述内容，最终推送状态以Git为准。
- 以下“目标仍在进行/第二批未交付”等段落仅为10-14及前序批次接续历史。

## 历史接续 — 2026-10-15 模型与动作批

- 新增独立编辑器模型/动画审查Window/SubViewport、成年男/女65骨骼各7clip配置；男性受试者接入新出击，女性暂为可复用预览/动作参考，不随机替换出生点。
- 主角按用户确认的「年轻成年女性，自然轻盈、战斗实用」作实际关键帧样式适配；原Artoria/UnityChan资产、枪械手掌约束不改。来源不伪称年龄核实的女性mocap。
- 混合骨架checkpoint与旧感染者原rig/pose兼容；schema7、checkpoint5和布局签名保留。库存75；本批用法与完整证据见 [模型动作制作](docs/MODEL_ANIMATION_AUTHORING.md)。
- 整个目标仍在进行：3–5件真实内容与校园第二批未交付。原先“审查台/独立外观未交付”段落是10-14阶段记录；无commit/push。

## 接续开发 — 2026-10-14 内容制作仍进行中

- 已补只读内容/引用检查、模板物品向导与隔离CLI。新资源须预览并明确确认后才注册；原始资产、现有定义数值和schema7保留。
- 新增2个测试，库存72；菜单确认、不同UID、编辑器退出后读回已在隔离工程验证。当前状态与完整回归证据见 [接续进度](docs/CONTENT_AUTHORING_PROGRESS.md)。
- 尚未交付3–5件真实用途新物品、通用模型/动画审查、感染者独立外观或校园第二批。不能将基础工具通过当作整个后续目标完成。无commit/push。

## 当前工具交付 — 2026-10-14 本地 WIP

- `main @ 68076ae` 上已实现校园真源 `static_world.tscn`、YARD 1.3.1 三个 stable-ID 目录、生产武器/动作/靶场工作台和原生 CC0 维修室模板。入口为编辑器顶部 Neon Tools；用法见 [工具说明](docs/CONTENT_TOOLS_IMPLEMENTATION.md)。
- 原有碰撞/导航布局签名保持一致；固定几何不再在 `_ready()` 重建。原生导航烘焙另在隔离副本验证，不自动重烘焙生产地图。
- runner 对齐70个场景并补长时间测试预算；完整测试/跨进程恢复/图形路线及编辑器操作结果见 [验证记录](docs/content_tools_2026-10-14_validation.json)。YARD 启动强制图标重导入有最小兼容补丁，失败日志保留。
- 游戏数据、存档schema7、Artoria/Unity-Chan原始资产、新故事第一批范围均保留。维修室样例未注册成新剧情内容；不宣称任意模型/动画自动导入已完成。
- 未 commit/push；完整 Alpha、真人/听感与最低硬件验收仍未完成。下方为同日**实施前**记录。

## 实施前交接 — 2026-10-14 同步与内容工具审计

- 干净 `main @ c1cebae` 已快进同步至 `68076ae`，再次pull确认已最新。用户提供VPN端口7897，仅命令级代理，无全局Git配置改动。
- 校园/联系人/近战感染者及新版校园第一批已入库。Q01侦察出口、Q02医疗交付开放；旧药房观察前置取消，旧Q04保留历史。新版维修、记录器、L-02支路控制及战备交付未实现。profile schema **7**，NarrativeSlice version **4**。
- 生产主角仍是Artoria临时模型；原创主角流程已准备但未交付模型。基地Quaternius过渡与走动代码已存在；10-05“无过渡”是历史限制。许可/来源限制保留。
- 实际66测试场景，原runner固定62；本轮原样runner冷导入通过后数量门禁退出。仓库外派生runner只对齐库存并保留全部断言，结果见 [现状审计](docs/PROJECT_STATUS_2026-10-14.md)。旧59/79不覆盖新HEAD。
- 建议保留Resource/ContentDB、实例所有权与原子保存，分批做内容检查/物品向导、模型动画审查台、敌人presentation模板及任务/遭遇制作；现成工具与来源见 [路线图](docs/CONTENT_PIPELINE_ROADMAP.md)。本轮只改文档，无插件安装、新内容、源码/测试修改或commit/push。
- 完整Alpha仍 **IN PROGRESS**；无本轮真人10–15局/2–4小时、图形或最低硬件验收。下方报告是历史，当前制作以 [校园六任务稿](docs/narrative/DEVELOPMENT_STATUS_AND_TASK_STORY.md)为准。

### 2026-10-14后续选型补充

- 已隔离实测：校园scene保存结构1节点/0网格，入树生成2901节点/2042网格；不是编辑器缺功能。武器模型/握点已有保存节点，主要缺生产姿态预览。无需直接给整个Battle/Player加@tool。
- 补入2026维护/发布证据：YARD1.3.1（10-08）、DataTables1.0.0（Godot4.7+）、GoSheets0.1.2（开发中/GPLv3）、Asset Placer1.6.0（08-25）、Scene Builder及FPS武器射击场参考。近期不等于稳定，未在主项目启用插件。
- 现成scene包与裸模型包、免费Standard与带Godot项目Source版本已区分；自定义许可包不能自动提交公开仓库。最新建议先做静态地图可见/可编辑层，再数据编辑与武器台。详见 [补充报告](docs/EDITOR_WORKFLOW_AND_CURRENT_TOOLS.md)和 [证据](docs/editor_tooling_2026-10-14_evidence.json)。本轮未改运行源码/资产/测试，无commit/push。

## 历史交接 — 2026-10-05 集成检查点

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
