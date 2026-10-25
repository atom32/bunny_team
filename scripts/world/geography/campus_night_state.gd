extends RefCounted
## Independent night-operation ledger. Only extraction commits backpack loot.
const ITEMS := {
	"ammo":{"name":"步枪弹","weight":0,"value":0},
	"med":{"name":"急救包","weight":0,"value":0},
	"scrap":{"name":"合金碎料","weight":1,"value":20},
	"parts":{"name":"精密备件","weight":2,"value":70},
	"drive":{"name":"离线存储盘","weight":3,"value":130}
}
const CAPACITY := 12
var path := "user://campus_night_ledger_v1.json"
var bank: Dictionary={"scrap":0,"parts":0,"drive":0}
var extractions := 0
var error := ""
var active := false
var stage := 0
var powered := false
var bag: Dictionary={"scrap":0,"parts":0,"drive":0}
var magazine := 30
var reserve := 90
var meds := 2

func _init(storage := "user://campus_night_ledger_v1.json") -> void:
	path=storage

func load_ledger() -> bool:
	if not FileAccess.file_exists(path):return true
	var f:=FileAccess.open(path,FileAccess.READ)
	if not f or f.get_length()>8192:error="夜线仓库无法读取，原文件保留。";return false
	var parser:=JSON.new()
	if parser.parse(f.get_as_text())!=OK:error="夜线仓库损坏，只读保护；不能开始新的回收。";return false
	var data: Variant=parser.data
	if not valid(data):error="夜线仓库损坏，只读保护；不能开始新的回收。";return false
	bank=data.bank.duplicate();extractions=int(data.extractions);return true

func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version")!=1 or not data.get("bank") is Dictionary:return false
	if not data.get("extractions") is float and not data.get("extractions") is int:return false
	if data.extractions<0 or data.extractions>1000000 or data.extractions!=floor(data.extractions):return false
	for id: String in bank:
		var v: Variant=data.bank.get(id)
		if not (v is float or v is int) or v<0 or v>1000000 or v!=floor(v):return false
	return true

func begin() -> bool:
	if active or not error.is_empty():return false
	active=true;stage=0;powered=false
	bag={"scrap":0,"parts":0,"drive":0};magazine=30;reserve=90;meds=2
	return true

func weight() -> int:
	var total:=0
	for id: String in bag:total+=int(bag[id])*int(ITEMS[id].weight)
	return total

func add(id: String, count: int) -> int:
	if not active or not ITEMS.has(id) or count<=0:return 0
	if id=="ammo":
		var accepted:=mini(count,240-reserve);reserve+=accepted;return accepted
	if id=="med":
		var accepted:=mini(count,4-meds);meds+=accepted;return accepted
	var accepted:=mini(count,floori(float(CAPACITY-weight())/ITEMS[id].weight))
	bag[id]+=accepted;return accepted

func discard(id: String) -> bool:
	if not active or not bag.has(id) or bag[id]<=0:return false
	bag[id]-=1;return true

func commit() -> Error:
	if not active or stage!=3 or not error.is_empty():return ERR_INVALID_DATA
	var next:=bank.duplicate()
	for id: String in bag:next[id]+=bag[id]
	var data: Dictionary={"version":1,"bank":next,"extractions":extractions+1}
	if not valid(data):return ERR_INVALID_DATA
	var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not f:return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data,"  "));f.flush();var result:=f.get_error();f.close()
	if result!=OK:return result
	if not valid(JSON.parse_string(FileAccess.get_file_as_string(path+".tmp"))):return ERR_FILE_CORRUPT
	result=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
	if result==OK:bank=next;extractions+=1;active=false;bag={"scrap":0,"parts":0,"drive":0}
	return result

func abandon() -> void:
	active=false;bag={"scrap":0,"parts":0,"drive":0}
