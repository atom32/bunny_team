class_name CampusFieldworkJournal
extends RefCounted
## A separate campus chapter journal. Never grants legacy items or edits Profile.
const DEFAULT_PATH := "user://campus_fieldwork_v1.json"
const Spaces := preload("res://scripts/world/geography/campus_spaces.gd")
const FLAGS := ["accepted","catalogue","archive_power","archive","diagram","relay","shelter_power","delivered","reported","youth_sample","jingye_sample"]
const TITLES := {"dispatch":"接取 / 雨前接力","catalogue":"阅读值班目录","archive_power":"恢复档案柜电源","archive":"封装防汛档案与备用熔芯","diagram":"阅读支路图","relay":"更换检修熔芯","isolate":"只隔离试验支路 B","blackout":"断开总闸（应急支路也将断电）","restore":"恢复总闸","deliver":"交付档案并确认应急供电","report":"向东门值守台回报","youth_sample":"记录青年湖水尺","jingye_sample":"记录敬业湖排水口"}
const NOTES := {
	"dispatch":"值守员：雨要到了。图书馆还留着旧排水图。取回档案和备用熔芯，去九教只隔离试验支路 B；活动中心的应急支路 A 必须保留。最后送到补给站，再回来报平安。",
	"catalogue":"值班目录：防汛档案在北侧档案室，需先恢复柜电源。目录附有柜钥匙；封装盒内备有一枚检修熔芯。",
	"archive_power":"档案柜指示灯恢复，封装锁已释放。",
	"archive":"防汛档案已封装，备用熔芯已领取。下一站：九教检修间。",
	"diagram":"电路图：A → 活动中心应急照明与冷藏；B → 试验设备。先更换熔芯，再隔离 B。总闸同时控制两路，不要拿总闸代替支路隔离。",
	"relay":"熔芯更换完成。现在可操作支路 B；总闸仍保持合闸。",
	"isolate":"B 已隔离，A 应急供电保留。活动中心补给站已可接收档案。",
	"blackout":"总闸已断开：应急支路 A 也失电。补给站暂停接收；回到总闸恢复供电后，重新隔离 B。此操作可恢复，不会锁死任务。",
	"restore":"总闸已恢复。两路均带电；请重新确认只隔离 B。",
	"deliver":"补给站签收：档案和熔芯检修记录已收到，应急冷藏与照明在线。回东门值守台结束接力。",
	"report":"雨前接力已完成。校园任务日志已归档；可继续调查湖岸或自由探索室内。不会向旧主线发放货币或物资。",
	"youth_sample":"青年湖水尺已记录（剧情调查装置，非实时水文观测）。该记录将附入本次接力档案。",
	"jingye_sample":"敬业湖排水口已检查（游戏设计点位）。格栅无堵塞，记录已附入接力档案。"
}
var flags: Dictionary={}
var blackout := false
var history: Array[String]=[]
var path := DEFAULT_PATH
var load_error := ""
var space_notes: Array[String]=[]

func _init(storage_path := DEFAULT_PATH) -> void:
	path=storage_path
	for key: String in FLAGS:flags[key]=false

func load_progress() -> bool:
	if not FileAccess.file_exists(path):return true
	var file:=FileAccess.open(path,FileAccess.READ)
	if not file or file.get_length()>32768:load_error="任务日志无法读取；原文件保留，本次进度仅在内存中。";return false
	var parser:=JSON.new()
	if parser.parse(file.get_as_text())!=OK:load_error="任务日志格式损坏；原文件保留，本次进度仅在内存中。";return false
	var data: Variant=parser.data
	if not _valid(data):load_error="任务日志格式损坏或版本不支持；原文件保留，本次进度仅在内存中。";return false
	flags=data.flags.duplicate();blackout=data.blackout
	history.assign(data.history)
	space_notes.assign(data.get("space_notes",[]))
	return true

func _valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version")!=1 or not data.get("flags") is Dictionary or not data.get("blackout") is bool or not data.get("history") is Array:return false
	for key: String in FLAGS:
		if not data.flags.get(key) is bool:return false
	if data.history.size()>64:return false
	for entry: Variant in data.history:
		if not entry is String or not NOTES.has(entry):return false
	# Reject impossible completion states rather than silently accepting a skip.
	for pair: Array in [["catalogue","accepted"],["archive_power","catalogue"],["archive","archive_power"],["relay","archive"],["shelter_power","relay"],["delivered","shelter_power"],["reported","delivered"]]:
		if data.flags[pair[0]] and not data.flags[pair[1]]:return false
	if data.blackout and data.flags.shelter_power:return false
	var notes: Variant=data.get("space_notes",[])
	if not notes is Array or notes.size()>Spaces.ROOMS.size():return false
	for id: Variant in notes:
		if not id is String or not Spaces.ROOMS.has(id):return false
	return true

func save_progress() -> Error:
	if not load_error.is_empty():return ERR_FILE_CORRUPT
	var data: Dictionary={"version":1,"flags":flags,"blackout":blackout,"history":history,"space_notes":space_notes}
	if not _valid(data):return ERR_INVALID_DATA
	var temporary:=path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if not file:return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data,"  "));file.flush()
	var error:=file.get_error();file.close()
	if error!=OK:return error
	if not _valid(JSON.parse_string(FileAccess.get_file_as_string(temporary))):return ERR_FILE_CORRUPT
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))

func unavailable(id: String) -> String:
	if id=="dispatch":return "本次接力已接取；打开 J 查看日志。" if flags.accepted else ""
	if not flags.accepted:return "先到东门值守台接取“雨前接力”。"
	if id in ["youth_sample","jingye_sample","diagram"]:return "已记录；可在 J 日志重读。" if flags[id] else ""
	if id=="catalogue":return "目录已读，柜钥匙已领取。" if flags.catalogue else ""
	if id=="archive_power":return "档案柜电源已恢复。" if flags.archive_power else ("先阅读前台值班目录，领取柜钥匙。" if not flags.catalogue else "")
	if id=="archive":return "档案已封装，不会重复领取。" if flags.archive else ("档案柜未供电；先操作档案室电源。" if not flags.archive_power else "")
	if id=="relay":return "熔芯已更换。" if flags.relay else ("先去图书馆取回档案和备用熔芯。" if not flags.archive else "")
	if id in ["isolate","blackout","restore"]:
		if flags.delivered:return "已完成交付，检修控制已封签；应急供电保持在线。"
		if id=="restore":return "" if blackout else "总闸已合闸，无需恢复。"
		if id=="blackout":return "总闸已断开，请先恢复供电。" if blackout else ""
		if not flags.relay:return "先更换检修熔芯。"
		if blackout:return "总闸未恢复，不能确认支路供电。"
		return "B 已隔离，A 保持供电。" if flags.shelter_power else ""
	if id=="deliver":
		if flags.delivered:return "补给站已签收；向东门回报即可。"
		return "档案未取回，或应急支路尚未保留供电。" if not flags.archive or not flags.shelter_power or blackout else ""
	if id=="report":return "本次接力已归档，可继续探索。" if flags.reported else ("先将档案交到活动中心补给站。" if not flags.delivered else "")
	return "未知任务操作。"

func perform(id: String) -> bool:
	if not unavailable(id).is_empty():return false
	match id:
		"dispatch":flags.accepted=true
		"isolate":flags.shelter_power=true
		"blackout":blackout=true;flags.shelter_power=false
		"restore":blackout=false
		"deliver":flags.delivered=true
		"report":flags.reported=true
		_:flags[id]=true
	if id not in history:history.append(id)
	return true

func objective() -> Dictionary:
	if not flags.accepted:return {"site":"dispatch","text":"到东门值守台接取“雨前接力”","action":"dispatch"}
	if not flags.catalogue:return {"site":"library","text":"图书馆 / 阅读前台目录，领取柜钥匙","action":"catalogue"}
	if not flags.archive_power:return {"site":"library","text":"图书馆 / 恢复北侧档案室柜电源","action":"archive_power"}
	if not flags.archive:return {"site":"library","text":"图书馆 / 封装档案与备用熔芯","action":"archive"}
	if not flags.relay:return {"site":"main_hall","text":"九教 / 在检修间更换熔芯","action":"relay"}
	if blackout:return {"site":"main_hall","text":"九教 / 恢复总闸，再隔离 B 支路","action":"restore"}
	if not flags.shelter_power:return {"site":"main_hall","text":"九教 / 只隔离 B，保留应急 A","action":"isolate"}
	if not flags.delivered:return {"site":"activity","text":"活动中心 / 将档案交到补给站","action":"deliver"}
	if not flags.reported:return {"site":"dispatch","text":"返回东门值守台回报","action":"report"}
	return {"site":"","text":"接力完成 / 可继续湖岸调查与室内探索","action":""}

func cargo_text() -> String:
	if flags.delivered:return "交付已签收 / 任务携带物已清空"
	if not flags.archive:return "任务携带物：无（与旧背包分开）"
	return "携带：防水档案包"+(" · 备用熔芯 ×1" if not flags.relay else " · 熔芯已用于九教检修")
