# Neon Bastion 本地试玩

**整校园已加入可选战斗回收行动“断电夜线”。** 实走到东门值守台按 **N** 接取：食堂回收熔芯 → 网络中心复电/下载 → 活动中心交付 → 东门撤离；另有泳池设备层可选物资。9台有限巡检机、6件可破坏箱/木障、实际夜间月光与局部工作灯、路面/地图导引、有限弹药/换弹/急救、12容量loot取舍与独立撤离入库。白天探索及“雨前接力”保留；新仓库不接旧经济，尚无交易/合成/永久升级，本轮无新EXE。见[进入方法、规则与验证](docs/streets/WEIJIN_NIGHT_2026-10-24.md)。

**可进入空间已从3块扩展到12栋、21块设计楼层/功能区。** 新增教室、宿舍多房间、两处食堂、泳池环道、更衣区、健身/器材间、实验教学与网络机房；9组可走楼梯平台连接上下层。按 **O** 打开目录标记真实校园入口，按E进楼/换层，M看当前楼层图。新增21份环境记录可独立保存，原“雨前接力”与旧主线存档保留。原生普通输入已走遍约8.3公里、21区域。室内仍是游戏设计，不是真实测绘；本轮未导出新EXE。见[开放清单与实机验证](docs/streets/WEIJIN_SPACES_2026-10-23.md)。

**整校园现已加入三处设计室内与“雨前接力”任务。** 从主菜单／基地的“整校园 1:1 / 室内任务”进入，实走到东门值守台按 E 接取；图书馆取档案、九教检修与支路选择、活动中心签收、返回回报，另有两处湖岸调查。E交互、M校园/楼层图、J日志；独立自动保存，不改旧主线、装备和经济。室内是游戏设计，不是真实楼内测绘，其余楼体未全部开放。见[玩法、验证与边界](docs/streets/WEIJIN_INTERIORS_2026-10-23.md)。本轮未导出新EXE。

**整校园美术细化已实装。** 按现有二次元角色＋半写实旧校园方向统一建筑、实体门窗、分型屋顶、近景叶片、湖岸与生活设施；真实比例和原碰撞未变。源码主菜单/基地行动页进入地理勘察，Tab收起面板。原生合成输入完成约4公里、8区域回路。见[本轮范围与验证](docs/streets/WEIJIN_ART_2026-10-23.md)；仍未迁移旧主线或重建真实室内。

**整校园 1:1 地理重建第一阶段已落地。** 源码主菜单或基地行动页进入整校园入口（现名“整校园 1:1 / 室内任务”）；可查看、实走约1.40×0.91公里真实路网、四湖和楼群轮廓。尚不是最终建筑/室内复刻，旧主线未迁移。见[入口、精度与验证](docs/streets/WEIJIN_GEOGRAPHY_2026-10-23.md)。

**2026-10-23：UI/UX remake 源码版已完成。** 统一主菜单、基地、整备仓库、联络交易、战斗 HUD／地图、搜刮背包、结算、暂停恢复与叙事／训练界面；保留现有战斗与存档规则。35 组相关无界面回归、原生双语界面与完整首战返营／独立读档验证通过。当前项目运行即可体验；旧 Windows EXE 未因此自动更新，不将 UI 完成等同于游戏正式发行或五小时真人验收。见 [逐项完成审计与实机截图](docs/UI_REMAKE_COMPLETION.md)。

2026-10-22 当前状态：已有无需 Godot 的独立 Windows 本地包，包含实际 16 段 CombatGirls 持枪动作。最近交付与进入方法见 [便携警铃](docs/PORTABLE_ALARM_2026-10-22.md)。本轮源码补首战空弹拦截、失败后直达补给，以及不联网的本地试玩反馈；验证和新包以对应记录为准。仍非公开发行版，五小时真人首通及 80% 平台好评尚未验证。

以下为历史迭代记录；其中“当前／最新”“未包含动作”“需要本机 Godot”等说法仅描述当时批次，不代表上述当前状态。

可玩优先版已准备：双击 `D:/tmp/bunny_backup_only_20261021_dev01/开始游戏.cmd`；想跳过首战可用同目录 `快速进入校园.cmd`。含16动作与孤立备份恢复修正，独立存档，不覆盖旧进度。按用户要求停止额外完整回归（87项已过，未宣称251完成），只保留必要首战／撤离返营／读档检查；非关键打磨后置。这是需本机已有Godot的本地版，不是新的独立Windows或公开发行版。

本地源码修正版已就绪：结算正文有不透明底板和18px字，北门近景采用400字重。源码127场景／251类全过（4092非文档输入匹配），修正版双渲染器近景／原失败checkpoint恢复及读档六项通过，亲看8图接受局部目标；俯视世界字仍偏灰，不是全游戏画面验收。新入口 `D:/tmp/bunny_readability_20261021_dev01/运行可读性与十六动作本地版.cmd`；独立校园预览为同目录 `预览修正版校园北门.cmd`。两入口分离存档、不覆盖旧试装或个人进度，沿用本机16动作；需现有Godot，不是独立Windows包。新Windows内部候选已实际导出149类通过；独立ZIP无界面37／96、实际CMD30次／16隔离组及备份保护30次版本调用已过，余59项原生或依赖检查待验。此Windows为默认动作、不含付费16库，尚未新交付；不增加游玩时长或宣称五小时完成。

源码／本地试装：校园北门可以沿墙绕到外侧按E拔门栓（不耗弹、不触发门口增援），或打断红链（消耗实弹、一次触发两名守卫）。开门不自动查看铭牌/结算、不发额外奖励；另一条无条件撤离路线保留，旧中途档不补门。修正版双渲染器原生普通路线／返营／读档八项与当前源码127场景／250类通过，4091个Root非文档输入匹配；两轮旧Q01单位用例失败保留，修为实际拔栓后重跑全量。新“北门＋十六动作”入口在 `D:/tmp/bunny_campus_exit_gate_20261021_dev01`，有独立新档和真实首战返营档的校园预览，不覆盖上一十六动作入口或个人进度。世界小字、斜近景链字局部遮挡、未贴栓动作及灰盒仍待打磨，只作本地试装。**没有新Windows包，不代表五小时游玩或可公开发行。**

候选WIP：[减少档案室连续空跑](docs/RECOVERED_ARMS_2026-10-21.md)。当前没有改装枪时，新档案室箱保证有一把；已有则保持35%。完整源码126场景／242类、新候选02实际导出140项通过；原六连空档副本也在新EXE及独立解压中实际找枪、带回、装备再战与读回过。内部ZIP无界面32项、累计40／87、CMD28次／15组通过；原生及其依赖检查仍缺，未交付新试玩包。

本轮动作优先：[最新内容十六动作本地版](docs/COMBAT12_2026-10-20.md)。原十二段已迁到最新内容并加四个斜向瞄准步态，两种渲染器普通首战／读回通过，使用独立新档；默认Windows旧包尚未换动作。付费数据在仓库外，仅干净可选适配代码入源码。维护区修正版近景与独立ZIP互助路线也已复查，当前40／87，余47项；不是新交付或五小时证明。

源码WIP：[维护区互助开箱](docs/MAINTENANCE_SHARED_2026-10-21.md)。许棠实际走到另一侧帮忙，带回现有改装工具包；手部贴合与标签源码修正已通过11项隔离检查，修正版基本接触与标签原生目标复查通过，整体画面仍待完善。本次新全量126场景／242类已覆盖它与空跑修正；此前126场景／242类是修正前基线，不在下方Windows包中。

当前本地 Windows 试玩：[维修仓背架与二选一改装](docs/CARRIER_WINDOWS_2026-10-21.md)。实际带回后选择轻便27kg或重载47kg，带同一配置再出击搜取并返营；编译133、独立ZIP72、CMD26次／14组通过，提供未预玩目录。仍LOCAL_ONLY，不代表五小时或公开发行完成。

上一版 Windows 试玩：[改装收获与主次结算](docs/RECOVERED_WINDOWS_2026-10-21.md)。档案室有机会带回消音AR、快装SMG或观察镜R7，收益/代价与仓库配件标识可见；实际“找到→带回→装备→再战→返回”及读回已通过。新包独立ZIP 60项、CMD 22次成功启动与十二组隔离档验收完成，未预玩目录和入口见说明。仍LOCAL_ONLY，不代表五小时或公开发行完成。

源码详情：[可带回的改装武器](docs/RECOVERED_ARMS_2026-10-21.md)与[主线/可选结算分离](docs/DEBRIEF_GUIDANCE_2026-10-21.md)，两者均已进入本批 Windows。玩家反馈“搜刮和成长缺乏惊喜”，本批是第一步，不将测试数量或刷取次数当成长内容/游玩时长。

上一版本地 Windows：[校园广播与战备引导](docs/CAMPUS_WINDOWS_2026-10-20.md)。原交付目录与ZIP保留不覆盖；其120/50/20项为历史包证明，不冒充本批验收。

本包保留此前药房、宿舍、南市、救援和尾声。个人存档未改，玩家35/60存档只作外置隔离测试输入，未随包提供；未换主角，未加入Arcana或付费动作。试玩入口与未预玩目录见上方说明。

上一版本地试玩：[药房白袋截取](docs/MEDICAL_INTERCEPTION_2026-10-20.md)。原药房包与交付目录保留，不被新包覆盖。

上一批本地试玩：[校园宿舍南窗接应](docs/CAMPUS_HANDOFF_2026-10-20.md)。前院交战、已备装备交接与实际撤离已进入新Windows包，另含全部既有南市、救援短场和尾声。118场景／213类源码、105类编译、19类独立ZIP与16次CMD通过；仍LOCAL_ONLY，未证明五小时或公开发行条件。

上一批本地试玩：[水塔街南市与可选维修仓](docs/WATER_MARKET_2026-10-20.md)。两条市场通路、断铃或响铃开仓、重物搜刮和仓内北门近路已进入新的独立包，另含 [门先别关](docs/RESCUE_RETURN_2026-10-20.md) 返营短场。仍LOCAL_ONLY，未证明五小时首通或公开发行条件。

上一批内容更新：[维护区场景与蒸汽表现](docs/MAINTENANCE_PRESENTATION_2026-10-20.md)。新增检修区地坪、病房细节、管线、阀轮、地面路标与透明喷雾；碰撞、导航和旧蒸汽档签名保持。仍仅本地测试，未达五小时发行验收。

# Neon Bastion

> **2026-10-20 新增返营人物短场《最大的那只桶》。** 送水后可选带桶上楼，原主角真实双手搬桶、往门口走又被叫回、落桶再坐下。两种反应、提前退出和休息室重看不发奖励或改主线；三位联系人仍为电台字幕。见 [内容与本地体验](docs/BUCKET_RETURN_2026-10-20.md)。默认主角和付费动作状态不变，五小时和发行目标继续制作。

> **2026-10-20 水塔街现场送水。** 院子线可绕西侧旁通轮或用实弹释放卡死锁扣，供水后住户实际走向水龙头；水车线需升门、松手刹，让实体车抵达北院。选线不再直接赠完成与奖励，旧水塔街中途档仍走原地图。见 [玩法、保存与本地包](docs/WATER_DELIVERY_2026-10-20.md)。这是区域内容扩展，不是50分钟章节或五小时达标；默认主角与动作不换。

> **2026-10-20 新增终局行动与回家尾声。** 总览“继续主线”串起水塔街、哨卡、救援与备用动力室；避开预警电弧，保住安置点供电、停机并撤离后，原主角和许棠实际回到桌边，有让位坐起、捧杯与结束卡，再回到自由行动。主线灰盒可到结尾，但五小时内容、正式美术和发行条件仍未完成。见 [新Windows本地包、后半程与尾声预览](docs/FINALE_2026-10-20.md)。仍LOCAL_ONLY，十二付费动作未混入默认包。

> **2026-10-20 新增封闭维护区救援灰盒《别挂电话》。** 校园六请求完成后从作战室可选进入；实际泄压开门、释放许棠、带她穿过北门并安全返营。同行者可等候／跟随，不瞬移、不设可被枪击的护送血条；原主角未换，CC0同行者仅占位。见 [本地独立包、快速预览与范围](docs/MAINTENANCE_2026-10-20.md)。这是首段救援，不是70分钟章节或五小时全篇；新Windows包仍LOCAL_ONLY，付费十二动作仍在独立试装。

> **2026-10-20 新增返营人物短场《给你留的位置》。** 校园出口侦察返营后，从休息室可选进入。原主角走到长凳、坐下；也可起身帮忙后被叫住，再坐下捧起温水。可跳过／重看，不加奖励或新存档字段；三位联系人仍是电台字幕。见 [本地独立包、快速预览与范围](docs/SEAT_MOMENT_2026-10-20.md)。本批已生成新的Windows本地包，无须Godot；仍LOCAL_ONLY，未公开上传，五小时全篇继续制作。

> **2026-10-20 十二段持枪动作本地接入。** 原主角本地试装扩到待机、慢走、跑动、精确站走／后退、射击、换弹、受击、闪避和收放枪；通过正常开局与原AI实际战斗，修正冲刺穿脸、收枪末端T姿势及全速收枪错误步态。见 [本地入口、动图与范围](docs/COMBAT12_2026-10-20.md)。默认动作仍未直接替换，付费数据在仓库外，没有新独立包；五小时内容与人物切片继续按 [发行规划](docs/FIVE_HOUR_RELEASE_PLAN.md) 推进。

> **2026-10-20 上一批三动作本地接入。** CombatGirls 的待机、持枪行走和换弹已在原主角的隔离试装中驱动正常开局／首战，两渲染器完成首胜、升级和工坊返营，并独立读回。移动换弹另查上身覆盖与腿部步态；修正短臂握持、胸段压缩和视线朝向。见 [试装入口、动图和范围](docs/RIFLE_MOTION_2026-10-20.md)。只有3段，不是12段全部完成；默认仓库动作和正式模型未换，付费动作数据留在仓库外，没有新EXE/PCK或公开上传。

> **2026-10-20 五小时发行目标与动作资源使用。** 制作范围收束为约五小时首次通关的完整小体量游戏，四个正式作战区加序章、三位核心联系人和完整收尾，不同时兑现旧十二章大纲。规划形成时CombatGirls 的39个动画FBX只有隔离审查，其后十二动作本地接入见上方；下一制作重点是人物行动切片与维护区／终局。见 [缺口、时长预算与分阶段规划](docs/FIVE_HOUR_RELEASE_PLAN.md)。当时校园接续候选因Q02随机搜齐的QA假设失败，现已修正并在103场景／149类无图形回归中通过校园连续链；该规划初稿时尚未交付新独立包，当时最新为下方工坊版；当前以顶部最新批次为准，仍LOCAL_ONLY。

> **2026-10-19 工坊归来：多出来的一颗。** 首次升级保存后，原主角走到工作台，收起／敲敲备用螺丝，继续装配，听三人的拌嘴和催饭；不再突然跳回商店。可跳过、重看、查看下一委托或去休息；旧档不强制播放，不赠奖励或另加存档字段。见 [新短场与本地包](docs/WORKSHOP_HOMECOMING_2026-10-19.md)。仍LOCAL_ONLY，不把自动测试当作真人口碑。

> **2026-10-19 首战两路线真实输入闭环。** 从正常BOOT跑到首战交战、拿取核心、终端、撤离、返营与第一次升级，不再从Hanger跳过教学。修复早先瞄准/开枪/换弹抢跑后续提示；满弹匣或无兼容备用弹也不被不可能的换弹锁死，不赠弹药或胜利。两条路线在Forward+与Compatibility完成，保留原资产和存档格式；见 [范围与最新本地包](docs/FIRST_SORTIE_2026-10-19.md)。101场景/164源码类、32构建类、43解压类通过，不冒充真人首小时或80%好评，仍LOCAL_ONLY。

> **2026-10-19 新玩家开场与首战入口。** 三张设定说明改为唐葵、沈砚霜、苏弥的三段拌嘴与牵挂；首次开场仍可跳过，旧的已看偏好不重置。首战未开放的撤离信标不再盖住角色或抢先提示后续步骤，真正解锁后恢复；战斗、8秒撤离与存档结构不改。见 [实际正常入口证据与最新本地包](docs/FIRST_IMPRESSION_2026-10-19.md)。100场景／156源码类、28构建类、37解压类通过，不是真人首小时或80%好评；仍LOCAL_ONLY，未上传。

> **2026-10-19 水塔街的选择带回基地。** 院子放水／支援运水车各有唐葵、沈砚霜、苏弥的返营回想，共6段51句双语对白；按真实安全撤离结算，不挤掉原校园剧情，不加好感条或强制弹窗。原模型与训练室保留，profile9／checkpoint6，旧档不猜分支。见 [新剧情与最新本地包](docs/WATERWORKS_RETURN_2026-10-19.md)。99场景／150类源码、25类构建、32类独立解压运行通过；仍LOCAL_ONLY，未上传，未取得新模型许可。

> **2026-10-19 修复兼容模式室内视野。** 宿舍屋顶不再盖住角色；不支持实例透明度的渲染器使用视觉剖面，碰撞、敌人观察和相机角度不改。警铃地图标识也明确区分已响状态。新增真实像素回归，两渲染器各83项；最终98场景／147类源码、23类构建及27类独立解压运行通过。原角色、训练室和前版存档保留。见 [画面与最新本地包](docs/CAMERA_CUTAWAY_2026-10-19.md)。仍LOCAL_ONLY，未公开发布。

> **2026-10-19 新增校园拆铃路线。** 档案点附近有实体接线箱：先花4秒拆铃线，再快速传档；也能在慢拷贝的报警倒数里绕过去抢时间。受伤／离开会中断，响过的警铃不能让守卫失忆。附苏弥和沈砚霜的短拌嘴；角色和训练室未改。见 [玩法、截图与最新本地包](docs/RECORDS_ISOLATION_2026-10-19.md)。97场景／144类源码、22类构建、24类解压运行通过；旧校园挂起布局保留。仍LOCAL_ONLY，未公开发布。

> **2026-10-19 本地包依赖清理。** 不改玩法、角色或原始资产；排除未用审查模型及缓存，PCK 减少26.31%，ZIP 从278 MB降到239 MB。新清单工具15项、构建19类、中文路径解压独立运行16类通过；含两渲染器训练室／广播车与实际旧挂起档读回。附带依赖 hash 和既有许可原文，仍不是发行授权。见 [最新本地包与范围](docs/RUNTIME_EXPORT_2026-10-19.md)。Arcana 私信本轮因浏览器失败未发送，等待用户联系状态；未换模型、未公开发布。

> **2026-10-19 广播车可读性与实物闸口。** 加入可观察状态卡、真实散热倒计时、落点环、命中差异、广播断电杆／线灯和实际抬起碰撞的车行闸；修复打车误报掩体及广播／机件声被标成移动声。原模型、服装、训练室保留。见 [玩法、原生画面与最新Windows本地包](docs/BLOCKADE_POLISH_2026-10-19.md)。最终95/95场景、140类源码、15类构建及15类解压验证通过；仍LOCAL_ONLY，公开授权和真实80%好评未达成。

> **2026-10-19 新增封街广播车遭遇。** 作战室可选「哨卡／请保持冷静」：红线锁定四连射、蓝色散热窗口反击、西巷切广播、感染者声源调查和北门撤离都已接入；不是只加血量。原主角及训练室保留，车辆仍为固定可编辑简模。见 [进入方法和新版 Windows 本地包](docs/BLOCKADE_2026-10-19.md)。94/94 场景、138 类源码验证、14 类构建和12类解压包验证通过；仍 LOCAL_ONLY，未提交／推送或公开发布，真实80%好评目标继续。

> **2026-10-19 新增休勤训练室。** 基地「休息室→进入训练室」可做举臂体侧伸展、跑步机快走、训练凳坐站或坐着休息；角色会走到器材旁再开始动作。全身/环绕镜头、暂停、倍速与Tab隐藏界面已接入，不消耗物资或改变存档。沿用原模型与服装，未换Arcana。见 [操作、动图与新版本地包](docs/TRAINING_ROOM_2026-10-19.md)。本地WIP，未提交/推送，包不可公开上传；公开发布及真实80%好评目标继续。

> **2026-10-19 上一批内容：水塔街「谁先接这一桶」。** 新增独立地图：修理铺搬八公斤电池、广播广场引敌、泵房交战和两种放水路线。居民水桶开放西院出口/两份敷料；运水车开放北口/九十发普通弹，实物需要拾取并撤离。唐葵与沈砚霜的争执、局内选择和不同收尾已接入。首任务后在「作战室→出击行动」选水塔街；不必先打完校园。见 [玩法、本地包和边界](docs/WATERWORKS_2026-10-19.md)。本地WIP，未提交/推送；模型未换，包不可公开上传，完整发布及真实80%好评目标继续。

> **2026-10-19 上一批：校园感染者近战可读性，本地WIP，未提交/推送。** 抬手后刹住追击并锁定瞄准点，90度地面扇区对应原攻击距离，半径内侧移也能躲开；站着不动仍受伤。提示按观察/掩体裁剪，暂停与挂起恢复保留原计时。新版LOCAL_ONLY独立包已包含此改动；39项专项及实际包间的一份旧挂起档读回通过。最终 **89/89场景、127/127结果通过，0 ERROR，仅2条冷导入FBX警告**；首轮对白原生输入失败记录保留，夹具加强后1245项通过，不冒充生产漏点根因已明。见 [玩法与本地包](docs/CAMPUS_MELEE_2026-10-19.md)。未换模型、未公开发布；授权与真实玩家首小时/80%好评目标仍在进行。

> **2026-10-19 上一批：Windows x64 本地独立试玩包与正式音频退出修复，本地WIP，未提交/推送。** 匹配4.7.2官方模板已校验安装；Release EXE/PCK实际通过启动、跨进程挂起恢复、旧档夹具、中文路径复制/ZIP解压及原生校园交战撤离。包明确为 **LOCAL_ONLY，不可上传**，QA只在构建副本中注入，原型使用独立存档名。退出音频停止请求增加混音排空，模型安全校验移出编辑器插件依赖。最终 **89/89场景、126/126结果通过，0 ERROR**，仅两条既有冷导入FBX警告。当前源清单36个定义，未改内容数据；旧节31不可沿用。见 [本机包与验证范围](docs/LOCAL_WINDOWS_BUILD_2026-10-19.md) 和 [机器记录](docs/local_windows_2026-10-19_validation.json)。授权、首小时陌生玩家体验、跨版本升级/最低硬件、正式发布和真实80%好评仍未完成。

> **2026-10-19 上一批：交战命中与来袭方向反馈，本地WIP，未提交/推送。** 实际可见伤害才确认命中，击倒使用独立提示；受击方向不追踪隐藏敌人，开箱也能看到警告。保持伤害、AI、地图、经济与存档规则。最终隔离 **89/89场景、123/123结果通过，0 ERROR**；保留2条FBX及1条Main强退ObjectDB warning。新套件55逻辑/55 Forward+检查，Compatibility同套件55检查通过；正常AI校园自动交战路线改动前后均9发/3击杀并撤离。见 [本批实现](docs/COMBAT_FEEDBACK_2026-10-19.md) 与 [机器记录](docs/combat_feedback_2026-10-19_validation.json)。不代表陌生玩家六委托通关、真实听感或已发布获评。

> **2026-10-19 上一批：补给箱键盘与手柄操作改善，本地WIP，未提交/推送。** 开箱自动选中、连续拿取保留焦点、长列表随焦点滚动，逐堆预告负重差额；补菜单 A/B/十字键事件，修复 A 确认误触翻滚，战斗与走动仍继续。最终隔离 **88/88场景、121/121 runner结果通过，0 ERROR**；仅2条既有冷导入FBX警告。补给箱97逻辑/98原生窗口检查、Compatibility同套件98检查通过（非全量回退验收）。见 [本批实现](docs/CACHE_INPUT_2026-10-19.md) 与 [验证记录](docs/cache_input_2026-10-19_validation.json)。未换模型、未发布；真人完整路线、资产许可和真实80%好评仍未完成。

> **2026-10-19 上一批：校园出击指引已接入，本地WIP，未提交/推送。** 当前委托成为主目标，基地/作战室/地图同步下一步，作战室可直达负责人；可选行动和撤退规则不变。修复英文简报溢出和初始空提示纸条。最终隔离 **88/88场景、121/121 runner结果通过，0 ERROR**；保留冷导入2个FBX警告及Main强退1条ObjectDB警告。见 [本批实现](docs/SORTIE_GUIDANCE_2026-10-19.md) 与 [验证记录](docs/sortie_guidance_2026-10-19_validation.json)。上一批23段人物对白保留；公开发布、真人体验和80%好评目标仍未完成。下方87/119等为此前批次。

> **2026-10-19：校园人物对白批已接入，本地WIP，未提交/推送。** 联系人委托页新增23段、113句双语短对话，按实际任务进度变化，可跳过/重听；六任务简报与机械条件分离，现场录音/无线电重写。最终隔离 **87/87场景、119/119 runner结果通过，0 ERROR**，仅冷导入2个原有FBX警告。详见 [本批实现](docs/CAMPUS_VOICE_2026-10-19.md) 与 [验证记录](docs/campus_voice_2026-10-19_validation.json)。新长期方向为 [公开试玩与真实80%好评](docs/PUBLIC_PLAYTEST_TARGET.md)，不是已发布或已获好评；Arcana仍仅本地预览，用户明确暂不换模型，公开资产许可和真人体验尚未验收。下方10-17等数量为历史基线。

> **2026-10-17 自动化测试收口：86/86 场景、117/117 runner结果项通过，0 ERROR；Compatibility补充4项图形检查通过。** 已修复测试库存漂移，并将888条现行中文译文同步回JSON源，补入可重复构建回归。仅冷导入保留2个既有FBX警告；英文委托页仍有中英混排、真人长期体验/听感/最低硬件/发行许可仍未验收。本轮未提交推送。见 [本轮报告](docs/TEST_CLOSEOUT_2026-10-17.md) 和 [验证数据](docs/test_closeout_2026-10-17_validation.json)。

下方2026-10-15及更早数字为历史批次，不覆盖上述当前工作区验证。

> 2026-10-15试玩收口进行中：修复记录器与委托地点不符，补地图阶段/中断提示/确认焦点及真实输入路线回归；80/80场景、103/103结果项通过，0 ERROR；本轮未提交推送。详见 [试玩收口](docs/CAMPUS_PLAYTEST_POLISH.md)。下方79/102是此前已推送批次的验证记录。

A Godot 4.7.2 single-player high-angle urban extraction shooter. The playable loop is `Opening / Menu -> Hideout -> Hanger -> Battle -> Result -> Hideout`. Full Alpha acceptance remains in progress.

## Historical implementation checkpoint — 2026-10-15

`main @ 68076ae` plus local WIP now includes all six campus commissions: exit scouting, medical delivery, two L-02 relay repairs, one physical experiment recorder, explicit L-02B shutdown with L-02A retained, and spare armor/60 standard-round delivery followed by extraction. Legacy Q04 logistics facts/rewards remain history, never fabricated new progress. See [campus rules and migration](docs/CAMPUS_BATCH2_IMPLEMENTATION.md).

**Neon Tools** opens the editable native campus, production-character weapon/target workbench, CC0 service-room sample, read-only content/reference audit, review-before-publish item wizard, and isolated model/animation review. **YARD v1.3.1** uses stable-ID catalogs (7 weapons / 31 items / 3 enemies), keeping ContentDB ownership. See [tool workflow](docs/CONTENT_TOOLS_IMPLEMENTATION.md) and [authoring workflow](docs/CONTENT_AUTHORING_PROGRESS.md).

Adult male/female reference profiles each include seven playable clips; new infected sorties use the independent subject rig while old suspended poses keep their legacy rig. The existing heroine uses the requested young-adult female **natural, light, combat-practical** style with original weapon-contact constraints. These are universal authored references and project-authored heroine adaptation, not verified sex/age-specific mocap. See [model and motion authoring](docs/MODEL_ANIMATION_AUTHORING.md).

Three physical fitting kits can be found/bought, installed on an owned gun, removed, lost with carried equipment and saved: quickloader, suppressor and observation optic. See [actual item rules](docs/FITTING_KITS_IMPLEMENTATION.md). The fixed story recorder is the fourth new item, not an extra loot/trade system.

2026-10-15 verification baseline: profile schema **8**, checkpoint **6**; old profiles and suspended contracts retain their old facts/assets. **79/79 scenes, 102/102 result rows PASS**, zero errors, two existing cold-import FBX warnings; cross-process/crash recovery, Main and Forward+ route regression pass. See [exact verification](docs/campus_batch2_2026-10-15_validation.json). This checkpoint is delivered through Git; validation records retain their original pre-commit WIP status. Human pacing/audio/minimum-hardware and character release clearance are not implied.

The [tool research](docs/CONTENT_PIPELINE_ROADMAP.md) and [earlier project audit](docs/PROJECT_STATUS_2026-10-14.md) preserve historical selection and counts; they do not override this checkpoint.

### Historical integration baseline — 2026-10-05

Integration commit `c1cebae` includes the Alpha progression and compact military Hideout. Menu/base standing and Rest use sourced Quaternius idle/seated animation; equipment keeps its armed preview. The imported 6×4m room is a camera-driven hub. Character geometry and materials are unchanged. See [Hideout integration](scenes/presentation/compact_hideout/INTEGRATION.md).

Historical Windows / Godot 4.7.2 verification for that integration: **59 scene tests, 79/79 checks PASS**, cross-process recovery and quit checks PASS; cold import 0 errors / 2 known FBX warnings. This does not certify the newer campus checkpoint. Full Alpha acceptance still needs human pacing, economy and audio feedback plus minimum-hardware profiling. See [current handoff](Handoff.md) and [acceptance audit](docs/alpha_0_1/ALPHA_ACCEPTANCE.md).

After the tutorial, Operations offers Records Run or [Restore the Relay](docs/alpha_0_1/RELAY_OPERATION.md). Repair two sites under local noise/interruptible 12-second work, then extract; records remain optional for another exit. Both operations can advance the final base contract.

Keyboard/mouse bindings can be changed from Main Menu settings or pause, saved per device, and restored to defaults. Live prompts follow the chosen keys; existing controller bindings remain intact. See [controls](docs/alpha_0_1/CONTROLS.md).

Streets records now trigger a visible, pause/save-aware 25-second local alarm: nearby guards investigate the terminal while extraction stays available. See [event rules and verification](docs/alpha_0_1/RECORDS_ALARM.md); audio is still a placeholder, and full Alpha playtesting remains outstanding.

The first sortie now has an authored [First Mission](docs/FIRST_MISSION.md): select Bunny and AR + SMG, learn movement/aim/fire, defeat the first PMC, reload/search, investigate the terminal, choose extra salvage or extraction, then bring materials to Workshop for one permanent AR damage upgrade (20 → 22, +10%) and the second sortie. Its 8–10 minute newcomer pacing target still needs a human timing pass.

Armor now offers a real [mobility/protection tradeoff](docs/ARMOR_TRADEOFF.md): Recon Shell has 10% incoming damage reduction and weighs 3kg; Bulwark Plate has 40% reduction, weighs 8kg and moves slower. Equipment and battle HUD show Mobility, Protection and Carry Weight.

The armory contains a pistol, SMG, assault rifle, shotgun, sniper rifle, LMG and RPG launcher, with modern models, distinct firing/reload behavior and five ammunition calibers. Equip two owned weapons in the Hanger; Operations lets you choose exact ammunition totals including magazines; defaults are three magazines per equipped weapon, while remaining stock stays at base. New profiles receive finite AR/SMG equipment and supplies, not the whole arsenal; existing possessions are preserved without automatic weapon reissue. Workshop supply supports buying, selling and material barter. Death or abandonment loses carried equipment and ammunition, while base stock and credits remain safe. See [the Alpha rules](docs/ALPHA_0_1.md) and [weapon overview](docs/MODERN_ARSENAL.md).

The playable prototype now uses the imported Artoria Bunny Suit with its scarf hidden. The arena includes imported human PMC patrols and KITE drones, including their death presentations. See [the model trial and evidence](docs/ARTORIA_BUNNY_TRIAL.md) for visual and licensing limits.

The [original narrative production package](docs/narrative/README.md) contains twelve chapters, eight bosses, eight important adult women, eighteen key scenes, five relationship scenes, five endings and a complete first-chapter script. This is a design deliverable; those campaign chapters are not implemented in the current demo.

Recovery includes safe save replacement with backups, corrupt-save recovery and a shared pause/abandon/return/quit flow. Magazines consume carried ammunition and count toward weight. **Suspend** saves the current sortie; **Resume Sortie** restores its ammo, loot, enemies and mission state after restarting. Automatic checkpoints occur every two simulation seconds; the current profile envelope is schema **9**, with legacy migration and narrative compatibility data. See [recovery behavior and historical validation](docs/alpha_0_1/SUSPEND.md) and [current status](docs/PROJECT_STATUS_2026-10-14.md).

Medical supplies are actual carried items: buy dressings/medkits in Workshop or find them in Streets containers, then choose how many to pack in Operations. `H` uses a dressing (up to 40 HP / 2.5s); `J` uses a medkit (up to 100 HP / 5s). Remain still: movement, combat, damage or interaction interrupts treatment without consuming the dose. Completion spends one item and releases its carry weight. Pending treatment survives suspend/resume. See [medical rules and evidence](docs/alpha_0_1/MEDICAL.md).

Hideout Overview now has a five-step [persistent contract chain](docs/alpha_0_1/CAMPAIGN.md) after First Mission: recon extractions, material deliveries and survival-confirmed kills unlock medkit assembly, AP ammunition crafting and an equipment purchase discount. Claims consume actual warehouse materials and save rewards atomically; failure keeps previously earned progress/facilities, not carried gear. Result shows a preview until Return settles it. The final contract has an explicit endpoint while free sorties remain available. This is not yet the full Alpha content/pacing target.

Desktop rendering now uses Forward+ with 4× MSAA, a shared AgX lighting/reflection profile and restrained SSAO/glow. A Compatibility fallback remains available with `--rendering-method gl_compatibility`. Artoria remains a temporary model; its original textures/geometry were not rewritten by this rendering pass.

## Controls

Enemy perception now uses facing/range/line-of-sight and an acquisition delay. Walls and closed doors block sight even when camera occlusion makes them transparent. Footsteps, gunfire, doors, explosions and alarms create localized hearing observations; Shift precision walking is quieter. Enemies investigate, search last-known locations, then return to local patrol instead of tracking hidden players forever. Perception and footstep cadence persist with the sortie. See [rules and validation](docs/alpha_0_1/PERCEPTION.md). Streets now assigns guards, patrols, flankers and pressure units: they hold territory, choose reachable side firing positions or close distance using observed information, not stat buffs. Duties and flank plans survive suspend/resume. See [tactical roles](docs/alpha_0_1/TACTICS.md). Coordinated squads and sustained human balancing remain pending.

Player observation is independent of the high-angle camera: unobserved enemies, their markers and origin VFX are hidden behind real walls/doors or outside the aim-facing field of view. Heard shots/movement provide a short approximate bearing, not a live target marker. Amber reticle feedback shows centerline cover interception. A barrel crossing cover cannot start a shot behind that cover; firing still spends ammunition. See [visibility rules and evidence](docs/alpha_0_1/VISIBILITY.md).

- `WASD` / left stick: move
- Hold `Shift`: precision walk; sniper extends the observation view
- Mouse / right stick: aim independently
- Left mouse / right trigger: fire
- `R`: reload
- `Q`: switch primary / secondary weapon
- `H` / `J`: use carried dressing / medkit; press again to cancel treatment
- `E`: interact / extract
- `Space` / gamepad south button: dodge
- `Esc`: close loot/settings first, otherwise pause/resume; choose suspend/menu/quit to keep the current sortie, or explicitly abandon to accept carried-item loss
- `F11`: toggle fullscreen
- `M`: show/hide the street district route map

Display settings are available from Menu → Settings → Display and Esc → Display.
Windowed resolution options are 1280×720, 1600×900, 1920×1080, 2560×1440 and
3840×2160; fullscreen uses the desktop resolution. Preferences persist in
`user://display.cfg`, independently of the player save. The UI keeps its 1280×720
design scale and expands its anchors for taller/wider aspect ratios.

The playable UI supports Simplified Chinese and English. New main-menu launches
default to Chinese unless a language preference was saved. Switch from Settings
→ Language or Esc → Language; changes take effect immediately and persist in
`user://language.cfg`. Menu, loadout, tutorial, HUD, interaction countdowns, street
map, looting, Workshop and debrief text are localized. Item and mission IDs and
player saves remain language-independent. Noto Sans SC is bundled for Chinese
glyphs. Edit `localization/zh_CN.json`, then run `python3 tools/build_localization.py`
to rebuild the Godot translation resource and validate formatting placeholders.

Combat HUD now places vitals and the active weapon in the bottom corners; the
inactive weapon is a small switch hint. The first-mission tutorial and its route
choice sit along the left edge, and world tutorial markers use a small arrow.
Alert banners expire after three seconds. Street route details appear on the M
map rather than in a permanent large assignment panel.

Open `project.godot` in Godot 4.7.2 or run:

```powershell
& 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\bunny_team' --editor
```

The standard runner snapshots the project and isolates its profile for translation-build checks, cold import, all **86 reviewed test scenes**, quit and cross-process recovery checks. Use `--route` to include rendered base/backpack/stash input checks and the normal-AI prototype route. The current runner passed 117 result rows with Forward+ on 2026-10-17; these are not 117 scene tests or human playtesting. Windows example:

```powershell
& 'C:\Python314\python.exe' -X utf8 tools/verify_migration.py --godot 'E:\Godot\Godot_v4.7.2-stable_win64_console.exe' --output '<new-directory-outside-repository>' --route
```

The output directory must not already exist. Weapon source and licensing records are linked from `THIRD_PARTY_ASSETS.md`.

### Spatial warehouse

The Hanger warehouse now uses a 12-column grid with item footprints, thumbnails baked from the equipped weapon/equipment scenes, and selected-item details. Drag items to free cells; press **R** while dragging or select **Rotate**. Double-click gear to equip, or drop it onto a compatible equipment selector. Drag the selector's **item icon** back into the warehouse to unequip; drag between occupied weapon slots to swap. Clicking the selector name still opens the equipment list. **Sort** repacks unequipped items.

Positions and orientation are part of the existing profile save. Older saves receive positions on opening; stale or overlapping positions are repaired without changing item ownership. Equipped instances remain owned by the same inventory and are displayed only in the equipment area. The warehouse grid grows vertically for recovered loot; the existing 1000 kg inventory limit remains the capacity rule. No nested containers or additional progression systems are introduced.

Validation: `godot --path . tools/stash_probe.tscn` drives mouse drags, R rotation, weapon swaps, armor equip, English/Chinese switching, save/reload and layout at 1280×720, 1920×1080 and 1440×900. Re-bake model thumbnails with `godot --path . tools/stash_icons.tscn`, then reimport assets.

After restoring the campaign workbench, Workshop offers [instance-owned weapon fittings](docs/alpha_0_1/FITTINGS.md): faster reload versus weight, or reduced enemy gunshot hearing versus weight/slower reload. Fits cost materials, persist with the exact gun and are lost with it; they are not permanent account buffs. This does not complete the full Alpha.

[Exact ammunition packing](docs/alpha_0_1/PACKING.md) is now part of normal deployment: partial stacks split atomically with the sortie checkpoint so loss never consumes the base remainder. Production UI-to-battle quantity and restart/loss checks pass. Full Alpha remains in progress.

Streets now has [regional supply pools](docs/alpha_0_1/REGIONAL_LOOT.md): pharmacy medicines, apartment fabric, office electronics/data and repair-shop parts. The M map shows tendencies, not actual loot or hidden actors. Existing sites and layout remain unchanged.

[Streets exit choices](docs/alpha_0_1/EXIT_CHOICES.md) now connect a site objective to retreat planning: one assigned exit always permits early retreat, the other opens after recovering the current records. The map explains both conditions. Human multi-sortie balance remains outstanding.
