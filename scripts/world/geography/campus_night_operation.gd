extends Node3D
## A finite, opt-in campus combat sortie, separate from the rain-relay journal
## and legacy economy. Source exteriors + explicitly designed interior combat.
const State := preload("res://scripts/world/geography/campus_night_state.gd")
const Enemy := preload("res://scripts/world/geography/campus_night_enemy.gd")
const Prop := preload("res://scripts/world/geography/campus_night_prop.gd")
const Spaces := preload("res://scripts/world/geography/campus_spaces.gd")
const Route := preload("res://scripts/world/geography/campus_fieldwork_route.gd")
const POWERED_LIGHT := 2.2
const TASKS := [
	{"site":"canteen_north","room":"canteen_prep","id":"relay_crate","text":"01 备件回收 / 学一食堂设备箱","hint":"从食堂楼梯到备餐层，击碎黄色绑带箱，E 拾取任务熔芯。"},
	{"site":"network","room":"network_control","id":"terminal","text":"02 恢复通讯 / 网络中心值班层","hint":"从机房楼梯上层；E 安装熔芯复电，再保持停留下载记录。"},
	{"site":"activity","room":"activity","id":"handover","text":"03 交付记录 / 活动中心补给站","hint":"交付离线记录与复电凭证；保留背包战利品，到东门撤离才入库。"},
	{"site":"dispatch","room":"","id":"extract","text":"04 带出战利品 / 返回东门","hint":"回到东门夜线撤离灯，停留 4 秒撤离。途中仍有巡检机，死亡会丢失本局 loot。"}
]
var survey: Node3D
var field: Node3D
var state: RefCounted
var world: Node3D
var roots: Dictionary={}
var enemies: Array[Node3D]=[]
var props: Array[Node3D]=[]
var pickups: Array[Dictionary]=[]
var stations: Array[Dictionary]=[]
var grids: Dictionary={}
var outdoor_route: RefCounted
var button: Button
var status: Label
var compass: Label
var guide_root: Node3D
var guide_clock:=0.0
var old_environment: Environment
var old_sun: Dictionary={}
var night_environment: Environment
var indoor_environment: Environment
var work: Dictionary={}
var remaining:=0.0
var last_room := "!"
var last_stage:=-1
var heal_remaining:=0.0
var failed:=false
var result_text := ""
var shots_fired:=0
var killed:=0
var broken:=0
var ledger_path := "user://campus_night_ledger_v1.json"

func setup(owner_survey: Node3D) -> void:
	survey=owner_survey;field=survey.fieldwork;name="CampusNightOperation"
	state=State.new(ledger_path);state.load_ledger()
	button=OperationUI.action(survey.screen,"夜线行动 / N",Vector2(250,226),Vector2(198,39),toggle_panel);button.name="OpenCampusNight"
	var backing:=OperationUI.block(survey.screen,Vector2(18,275),Vector2(430,79),Color("191d1ee8"));backing.name="CampusNightStatus"
	status=OperationUI.text(backing,"",Vector2(14,10),15,Color("f4e8c9"));status.size=Vector2(404,60)
	compass=OperationUI.text(survey.screen,"",Vector2(458,193),17,Color("e8e894"));compass.size=Vector2(790,42)
	backing.hide();compass.hide()
	survey.actor.night_operation=self
	survey.actor.damage_received.connect(_on_damage)
	survey.actor.died.connect(_on_death)
	survey.actor.weapon_fired.connect(func(_strength: float):shots_fired+=1)
	_make_environments()

func running() -> bool:
	return state.active and not failed and survey.walking and not field.panel.visible and not survey.route_map.visible and not survey.actor.is_dead

func label(parent: Node3D, text: String, at: Vector3, color: Color) -> Label3D:
	var node:=Label3D.new();node.font=UIFactory.FONT;node.text=text;node.font_size=36;node.pixel_size=.006
	node.position=at;node.modulate=color;node.outline_size=5;node.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.visibility_range_end=38
	parent.add_child(node);return node

func _make_environments() -> void:
	night_environment=Environment.new();night_environment.background_mode=Environment.BG_COLOR;night_environment.background_color=Color("182b3c")
	night_environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;night_environment.ambient_light_color=Color("9cb7d1");night_environment.ambient_light_energy=.32
	night_environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;night_environment.fog_enabled=true;night_environment.fog_light_color=Color("243c4c");night_environment.fog_density=.0015
	night_environment.ssao_enabled=true;night_environment.ssao_radius=.9
	indoor_environment=night_environment.duplicate();indoor_environment.background_color=Color("101f28");indoor_environment.fog_enabled=false;indoor_environment.ambient_light_energy=.25

func objective() -> Dictionary:
	return TASKS[clampi(state.stage,0,3)]

func toggle_panel() -> void:
	if field.panel.visible:field.close_panel();return
	cancel_work();field.cancel_work();field._clear_panel();field.panel.show();field.choice="night";field._pause(true)
	var panel: Control=field.panel_body
	OperationUI.heading(panel,"NIGHT LINE / INDEPENDENT SORTIE","断电夜线 · 回收行动",Vector2(24,15))
	var description: String="夜间巡检机失控：回收熔芯，恢复离线通讯，再带着物资撤离。\n固定警戒区、有限敌人；不无限刷怪。任务袋不占 loot 容量。"
	if state.active:description=objective().text+"\n"+objective().hint
	if not result_text.is_empty():description=result_text
	OperationUI.text(panel,description,Vector2(24,93),16,FieldManualStyle.INK).size=Vector2(812,65)
	OperationUI.text(panel,"01 食堂备件 → 02 网络复电 → 03 活动中心交付 → 04 东门撤离\n可选：泳池设备层高价值箱；主路更安全，入口与设备区更危险。",Vector2(24,170),15)
	OperationUI.text(panel,"局内战利品 / %d · %d 容量"%[state.weight(),State.CAPACITY],Vector2(24,231),19)
	var i:=0
	for id: String in state.bag:
		var spec: Dictionary=State.ITEMS[id]
		OperationUI.text(panel,"%s ×%d / %d容量"%[spec.name,state.bag[id],spec.weight],Vector2(24+i*268,268),15)
		var item_id: String=id
		var discard:=OperationUI.action(panel,"丢弃一件",Vector2(24+i*268,301),Vector2(170,32),func():
			state.discard(item_id);field.close_panel();toggle_panel())
		discard.name="DiscardNight_"+id;discard.disabled=not state.active or state.bag[id]==0;i+=1
	var stored: Array[String]=[]
	for id: String in state.bank:stored.append(State.ITEMS[id].name+" ×"+str(state.bank[id]))
	OperationUI.text(panel,"已带出 %d 次 / 独立仓库：%s"%[state.extractions," · ".join(stored)],Vector2(24,356),14,FieldManualStyle.MUTED)
	OperationUI.text(panel,"鼠标瞄准 / 左键射击 · R换弹 · H急救(1.8秒) · E交互 · M路图 · N任务/背包\n退出或失败丢失本局未带出物资；不花费、不发放旧主线装备或货币。",Vector2(24,386),14)
	if not state.error.is_empty():OperationUI.text(panel,state.error,Vector2(24,432),14,Color("a23d30"))
	OperationUI.action(panel,"继续 / N",Vector2(24,465),Vector2(170,38),field.close_panel,true)
	if not state.active:
		var start:=OperationUI.action(panel,"从东门接取夜线",Vector2(524,465),Vector2(300,38),begin,true);start.name="BeginCampusNight"
		start.disabled=not state.error.is_empty() or not _at_dispatch()
		if not _at_dispatch():OperationUI.text(panel,"需在实走东门值守台旁接取；N不传送。",Vector2(346,434),14,FieldManualStyle.MUTED)
	else:
		OperationUI.action(panel,"放弃本局…",Vector2(604,465),Vector2(220,38),confirm_abandon).name="AbandonCampusNight"

func _at_dispatch() -> bool:
	return survey.walking and field.inside.is_empty() and Vector2(survey.actor.position.x,survey.actor.position.z).distance_to(field.sites.dispatch.point)<6

func begin() -> void:
	if not _at_dispatch() or not state.begin():return
	field.close_panel();field.cancel_work();field.tracked_site="";failed=false;result_text="";shots_fired=0;killed=0;broken=0
	survey.actor.health=survey.actor.max_health;survey.actor.health_changed.emit(survey.actor.health,survey.actor.max_health)
	world=Node3D.new();world.name="NightLineWorld";add_child(world)
	guide_root=Node3D.new();guide_root.name="NightGuidance";add_child(guide_root)
	_spawn_outdoor();_apply_night();last_room="!";last_stage=-1
	survey.walk_button.text="夜线进行中 / N"
	AudioDirector.set_music_context(&"battle")
	field.message("夜线已接取：30/90发 · 急救×2。黄色箱可破坏；任务件独立装袋。N查看路线与背包。",10)

func _apply_night() -> void:
	var exterior: Node3D=survey.get_node("WeijinGeographicWorld")
	old_environment=exterior.get_node("CampusDaylight").environment
	var sun: DirectionalLight3D=exterior.get_node("Sun")
	old_sun={"energy":sun.light_energy,"color":sun.light_color,"rotation":sun.rotation}
	sun.light_energy=.38;sun.light_color=Color("a9c5e0");sun.rotation_degrees=Vector3(-28,-52,0)
	exterior.get_node("CampusDaylight").environment=night_environment

func _root(room: String) -> Node3D:
	if not roots.has(room):
		var node:=Node3D.new();node.name="Night_"+("Outdoor" if room.is_empty() else room);world.add_child(node);roots[room]=node
	return roots[room]

func _safe_outdoor(site_id: String,normal_offset: float,side_offset: float) -> Vector3:
	var site: Dictionary=field.sites[site_id]
	var desired: Vector2=site.point+site.get("normal",Vector2.LEFT)*normal_offset+site.get("tangent",Vector2.DOWN)*side_offset
	var point: Vector2=field._safe_near(desired)
	assert(is_finite(point.x),"Night encounter lacks safe source-ground placement: "+site_id)
	return survey.geo.mesh_at3(point,.12)

func _spawn_outdoor() -> void:
	for site: String in ["canteen_north","network"]:
		for i in 2:
			var start:=_safe_outdoor(site,18,(-1 if i==0 else 1)*7)
			var end:=_safe_outdoor(site,25,(-1 if i==0 else 1)*7)
			_spawn_enemy("outside_"+site+str(i),"",start,end,"guard" if i==0 else "patrol")
		_crate("supply_"+site,"",_safe_outdoor(site,9,8),{"ammo":30,"scrap":2})
		_practical(_root(""),_safe_outdoor(site,5,-4),false)
	var extract: Vector3=survey.geo.mesh_at3(field.sites.dispatch.point+Vector2(-4,0),.06)
	_station("extract","撤离 / 东门夜线",extract,"",4)
	_practical(_root(""),extract,true)
	label(_root(""),"N 夜线接取 / E 任务后撤离",extract+Vector3.UP*3,Color("b3dab8"))
	for id: String in ["activity","swim"]:_practical(_root(""),_safe_outdoor(id,5,-4),true)

func _spawn_enemy(id: String,room: String,point: Vector3,end: Vector3,role: String) -> void:
	var enemy:=Enemy.new();enemy.operation=self;enemy.id=id;enemy.room=room;enemy.role=role
	enemy.home=point;enemy.patrol=PackedVector3Array([point,point if role=="guard" else end]);enemy.position=point;enemy.last_seen=point
	_root(room).add_child(enemy);enemy.rotation.y=atan2(point.x-survey.actor.position.x,point.z-survey.actor.position.z)
	enemy.destroyed.connect(_enemy_destroyed);enemies.append(enemy)

func _crate(id: String,room: String,point: Vector3,contents: Dictionary,kind := "crate") -> void:
	var prop:=Prop.new();prop.owner_operation=self;prop.id=id;prop.room=room;prop.contents=contents;prop.kind=kind
	prop.position=point;_root(room).add_child(prop);prop.broken.connect(_prop_broken);props.append(prop)

func _prop_broken(prop: Node3D) -> void:
	broken+=1
	grids.erase(prop.room)
	_drop(prop.id,prop.room,prop.global_position,prop.contents)

func _enemy_destroyed(enemy: Node3D) -> void:
	killed+=1
	# Stable varied drops per authored enemy, not a reroll every time a floor loads.
	var loot: Dictionary={"ammo":18,"scrap":1} if String(enemy.id).hash()%2==0 else {"med":1,"parts":1}
	_drop("drop_"+enemy.id,enemy.room,enemy.global_position,loot)

func _drop(id: String,room: String,point: Vector3,contents: Dictionary) -> void:
	var node:=Node3D.new();node.position=point;_root(room).add_child(node)
	VisualFactory.box(node,Vector3(.65,.35,.5),Vector3(0,.19,0),Color("8c9560"),"LootSatchel")
	var caption:=label(node,"E 拾取 / "+_loot_caption(contents),Vector3(0,.95,0),Color("e4e8a0"))
	pickups.append({"id":id,"room":room,"point":point,"contents":contents.duplicate(),"node":node,"label":caption})

func _loot_caption(contents: Dictionary) -> String:
	var text: Array[String]=[]
	for id: String in contents:
		if int(contents[id])<=0:continue
		text.append(("任务熔芯" if id=="relay" else State.ITEMS[id].name)+"×"+str(contents[id]))
	return " · ".join(text)

func _station(id: String,text: String,point: Vector3,room: String,seconds: float) -> void:
	stations.append({"id":id,"label":text,"point":point,"room":room,"seconds":seconds})

func _practical(parent: Node3D,point: Vector3,green: bool) -> void:
	VisualFactory.box(parent,Vector3(.1,3.2,.1),point+Vector3.UP*1.6,Color("3c4c4e"),"NightLampPost")
	var light:=SpotLight3D.new();light.position=point+Vector3.UP*3.1;light.rotation_degrees.x=-90
	light.light_color=Color("c6e4cc") if green else Color("ffd5a0");light.light_energy=2.4;light.spot_range=14;light.spot_angle=66
	light.shadow_enabled=true;light.distance_fade_enabled=true;light.distance_fade_begin=70;light.distance_fade_length=15;parent.add_child(light)
	VisualFactory.box(parent,Vector3(.6,.12,.45),point+Vector3.UP*3.08,Color("d8d7ad"),"NightLampHousing")

func room_ready(room_id: String) -> void:
	if not state.active:return
	var room: Node3D=field.rooms[room_id]
	for light: OmniLight3D in room.room_lights:
		light.light_energy=POWERED_LIGHT if state.powered and room_id in ["network","network_control"] else .28
		light.light_color=Color("d0e8dd") if state.powered and room_id in ["network","network_control"] else Color("fff1d0")
	for child: Node in room.get_children():
		if child is DirectionalLight3D:child.light_energy=.16
	if not roots.has(room_id):
		_root(room_id)
		for offset: Vector2 in [Vector2(-7,-7),Vector2(8,5)]:_practical(_root(room_id),room.position+Vector3(offset.x,0,offset.y),false)
		if room_id=="canteen_prep":
			var p:=_free_point(room_id,Vector2(-10,-10))
			_crate("relay_crate",room_id,p,{"relay":1,"parts":2,"ammo":24})
			_spawn_enemy("prep_guard",room_id,_free_point(room_id,Vector2(8,-8)),_free_point(room_id,Vector2(8,-3)),"guard")
			_spawn_enemy("prep_patrol",room_id,_free_point(room_id,Vector2(-5,-4)),_free_point(room_id,Vector2(5,-4)),"patrol")
		elif room_id=="network":
			_spawn_enemy("rack_guard",room_id,_free_point(room_id,Vector2(10,-9)),_free_point(room_id,Vector2(10,-3)),"guard")
			_crate("rack_cache",room_id,_free_point(room_id,Vector2(-3,-11)),{"parts":2,"drive":1})
		elif room_id=="network_control":
			var p:=_free_point(room_id,Vector2(-8.5,-2.7))
			_station("terminal","复电终端 / E",p,room_id,3)
			VisualFactory.box(_root(room_id),Vector3(1.0,.9,.6),p+Vector3(0,.45,-1.4),Color("637d79"),"NightTerminal")
			label(_root(room_id),"夜线终端 / 熔芯 → 复电 → 下载",p+Vector3(0,2,-1.4),Color("d3df9b"))
			_spawn_enemy("control_guard",room_id,_free_point(room_id,Vector2(8.5,-9)),_free_point(room_id,Vector2(8.5,-3)),"guard")
		elif room_id=="swim_plant":
			_crate("plant_rare",room_id,_free_point(room_id,Vector2(-7,-10)),{"drive":2,"parts":2})
			_spawn_enemy("plant_guard",room_id,_free_point(room_id,Vector2(10,-9)),_free_point(room_id,Vector2(10,1)),"guard")
			_crate("plant_barricade",room_id,_free_point(room_id,Vector2(-7,0)),{"scrap":1},"barricade")
		elif room_id=="activity":
			var p:=_free_point(room_id,Vector2(0,5))
			_station("handover","夜线记录交付",p,room_id,2)
			label(_root(room_id),"夜线签收 / E",p+Vector3.UP*1.8,Color("b4dfb8"))
		# Register only nonoverlapping physical spawn/loot footprints. Never
		# delete or disable authored furniture to fit an encounter.
		grids.erase(room_id)
	_sync_visibility()

func _free_point(room_id: String,desired: Vector2) -> Vector3:
	var room: Node3D=field.rooms[room_id]
	for radius: float in [0,.8,1.6,2.4,3.2,4.8,6.4]:
		for i in 16:
			var p:=desired+Vector2.from_angle(i*TAU/16)*radius
			if _floor_clear(room_id,p,.85):return room.position+Vector3(p.x,.06,p.y)
	assert(false,"No safe indoor encounter point: "+room_id)
	return room.position+room.entry_point

func _floor_clear(room_id: String,p: Vector2,radius := .5,allow_stairs := false) -> bool:
	var room: Node3D=field.rooms[room_id]
	if absf(p.x)>room.extent.x*.5-radius or absf(p.y)>room.extent.y*.5-radius:return false
	for item: Dictionary in room.plan:
		if item.kind=="gate" and field.journal.flags.catalogue:continue
		if allow_stairs and item.kind=="stairs":continue
		if item.rect.grow(radius).has_point(p):return false
	for prop: Node3D in props:
		if prop.room!=room_id or prop.destroyed:continue
		var size: Vector2=Vector2(3.4,.24) if prop.kind=="barricade" else Vector2(1.5,1.2)
		var local: Vector3=prop.position-room.position
		if Rect2(Vector2(local.x,local.z)-size*.5,size).grow(radius).has_point(p):return false
	return true

func path_between(room_id: String,from: Vector2,to: Vector2) -> PackedVector2Array:
	if room_id.is_empty():
		if not outdoor_route:outdoor_route=Route.new(survey.geo)
		return outdoor_route.find_path(from,to)
	var room: Node3D=field.rooms[room_id]
	var origin:=Vector2(room.position.x,room.position.z)
	if not grids.has(room_id):
		var grid:=AStarGrid2D.new();grid.region=Rect2i(-Vector2i(room.extent),Vector2i(room.extent)*2);grid.cell_size=Vector2.ONE*.5
		grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
		for x in range(grid.region.position.x,grid.region.end.x):
			for z in range(grid.region.position.y,grid.region.end.y):grid.set_point_solid(Vector2i(x,z),not _floor_clear(room_id,Vector2(x,z)*.5,.52))
		grids[room_id]=grid
	var grid: AStarGrid2D=grids[room_id]
	var a:=Vector2i(roundi((from.x-origin.x)*2),roundi((from.y-origin.y)*2));var b:=Vector2i(roundi((to.x-origin.x)*2),roundi((to.y-origin.y)*2))
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or grid.is_point_solid(b):return PackedVector2Array()
	if grid.is_point_solid(a):
		# A flat grid cannot describe the actor standing on a physical ramp,
		# or centimetre-scale clearance lost to cell rounding. Attach via a
		# clear short segment; only stairs may be crossed, never walls/props.
		var attached:=false
		for radius: float in [.5,1,1.5,2,3,4,5]:
			for i in 24:
				var local: Vector2=from-origin+Vector2.from_angle(i*TAU/24)*radius
				var cell:=Vector2i(roundi(local.x*2),roundi(local.y*2))
				if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):continue
				var end:=Vector2(cell)*.5;var clear:=true
				for step in range(ceili(radius/.2)+1):
					if not _floor_clear(room_id,(from-origin).lerp(end,float(step)/maxi(1,ceili(radius/.2))),.46,true):clear=false;break
				if clear:a=cell;attached=true;break
			if attached:break
		if not attached:return PackedVector2Array()
	var result:=grid.get_point_path(a,b)
	for i in result.size():result[i]+=origin
	if not result.is_empty() and result[0].distance_to(from)>.2:result.insert(0,from)
	return result

func _sync_visibility() -> void:
	for id: String in roots:
		roots[id].visible=id==field.inside
		for node: Node in roots[id].get_children():
			# Hidden collision in a different room remains physically distant;
			# only current-room AI and nearby outdoor patrols tick.
			if node is CharacterBody3D:node.set_physics_process(id==field.inside)
	survey.camera.environment=night_environment if field.inside.is_empty() else indoor_environment

func nearest() -> Dictionary:
	if not running():return {}
	var found: Dictionary={};var best:=2.5
	for entry: Dictionary in stations+pickups:
		if entry.room!=field.inside or (entry.has("contents") and entry.contents.is_empty()):continue
		var distance: float=survey.actor.global_position.distance_to(entry.point)
		if distance>best:continue
		var q:=PhysicsRayQueryParameters3D.create(survey.actor.global_position+Vector3.UP*1.1,entry.point+Vector3.UP*1.1,4)
		q.exclude=[survey.actor.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():continue
		found=entry;best=distance
	return found

func interact() -> bool:
	var entry:=nearest()
	if entry.is_empty():return false
	if not work.is_empty():cancel_work();return true
	if entry.has("contents"):
		var taken: Array[String]=[]
		for id: String in entry.contents.keys():
			var count: int=entry.contents[id]
			var added:=0
			if id=="relay":
				if state.stage==0:state.stage=1;added=count
			else:added=state.add(id,count)
			if added>0:
				entry.contents[id]-=added;taken.append(("任务熔芯" if id=="relay" else State.ITEMS[id].name)+"×"+str(added))
			if entry.contents[id]<=0:entry.contents.erase(id)
		entry.label.text="E / "+_loot_caption(entry.contents)
		if entry.contents.is_empty():entry.node.hide()
		field.message(("拾取："+" · ".join(taken) if not taken.is_empty() else "背包或补给已满。N可丢弃战利品；剩余物品留在地上。"),6)
		field.route_target=Vector2(INF,INF);return true
	var required: String=objective().id
	if entry.id!=required:
		field.message("当前目标："+objective().text);return true
	if _danger_near():field.message("附近有警戒中的巡检机，先脱离视线或停机后再操作。");return true
	work=entry.duplicate();remaining=entry.seconds
	field.message("%s / %.0f秒，保持停留；移动、受伤、开图或射击会中断。"%[entry.label,remaining]);return true

func _danger_near() -> bool:
	for enemy: Node3D in enemies:
		if not enemy.dead and enemy.room==field.inside and enemy.alert_left>0 and enemy.global_position.distance_to(survey.actor.position)<16:return true
	return false

func cancel_work() -> void:
	work={};remaining=0;heal_remaining=0
	if field:field.progress.hide()

func _complete_work() -> void:
	var id: String=work.id;work={};remaining=0;field.progress.hide()
	match id:
		"terminal":
			if not state.powered:
				state.powered=true
				for room_id: String in ["network","network_control"]:
					if field.rooms.has(room_id):
						for light: OmniLight3D in field.rooms[room_id].room_lights:light.light_energy=POWERED_LIGHT;light.light_color=Color("d0e8dd")
				field.message("终端已复电，照明恢复。再次 E 下载离线记录（4秒）。",7)
				for entry: Dictionary in stations:
					if entry.id=="terminal":entry.seconds=4;entry.label="下载离线记录"
			else:state.stage=2;field.message("离线记录已放入任务袋。下一站活动中心交付，背包 loot 仍需撤离。",8)
		"handover":state.stage=3;field.message("记录签收。任务尚未结束：带着物资返回东门撤离。",8)
		"extract":
			var weight: int=state.weight();var error: Error=state.commit()
			if error!=OK:field.message("仓库写入失败，仍留在本局，可再次撤离："+error_string(error),12);return
			result_text="撤离成功 / %d容量物资已入独立仓库。\n停机 %d台 · 破坏 %d件 · 开火 %d发。旧主线资产未变。"%[weight,killed,broken,shots_fired]
			_end();toggle_panel()
	field.route_target=Vector2(INF,INF)

func heal() -> void:
	if not running() or state.meds<=0 or survey.actor.health>=survey.actor.max_health:return
	cancel_work();heal_remaining=1.8;field.message("急救中 / 保持停留1.8秒，受伤或移动会取消；完成后消耗1包。")

func _on_damage(_packet: DamagePacket,_amount: float) -> void:
	if state.active:cancel_work()

func _on_death() -> void:
	if not state.active:return
	failed=true;result_text="行动失败 / 本局未带出物资已丢失。\n已入库物资保留；关闭报告后回东门可重新接取。"
	state.abandon();_end();toggle_panel()

func confirm_abandon() -> void:
	field._clear_panel();field.choice="night_abandon"
	OperationUI.heading(field.panel_body,"ABANDON / UNEXTRACTED LOOT LOST","放弃断电夜线？",Vector2(30,35))
	OperationUI.text(field.panel_body,"仅丢弃本局尚未带出的物资与夜线任务进度。\n原雨前接力、空间记录、已带出仓库和旧主线资产不变。",Vector2(30,145),19)
	OperationUI.action(field.panel_body,"确认放弃",Vector2(30,348),Vector2(220,46),func():
		state.abandon();result_text="本局已放弃 / 未带出物资未入库。";_end();field.close_panel())
	OperationUI.action(field.panel_body,"继续行动",Vector2(280,348),Vector2(220,46),field.close_panel,true)

func _end() -> void:
	cancel_work()
	var exterior: Node3D=survey.get_node("WeijinGeographicWorld")
	exterior.get_node("CampusDaylight").environment=old_environment
	var sun: DirectionalLight3D=exterior.get_node("Sun")
	sun.light_energy=old_sun.energy;sun.light_color=old_sun.color;sun.rotation=old_sun.rotation
	for room: Node3D in field.rooms.values():
		for light: OmniLight3D in room.room_lights:light.light_energy=.68;light.light_color=Color("fff1d0")
		for child: Node in room.get_children():
			if child is DirectionalLight3D:child.light_energy=.45
		room.refresh(field.journal)
	if is_instance_valid(world):world.queue_free()
	if is_instance_valid(guide_root):guide_root.queue_free()
	roots.clear();enemies.clear();props.clear();pickups.clear();stations.clear();grids.clear();last_room="!"
	survey.camera.environment=null if field.inside.is_empty() else field.interior_environment
	field.route_target=Vector2(INF,INF);field.route_points.clear()
	# Restore the same actor after the failure report, not an invisible corpse.
	if survey.actor.is_dead:
		survey.actor.is_dead=false;survey.actor.body_visual.show();survey.actor.get_node("Hitbox").set_deferred("disabled",false)
		if not field.inside.is_empty():
			while not field.inside.is_empty():field.exit_room()
		survey.actor.position=survey.geo.mesh_at3(field.sites.dispatch.point,1)
		survey.focus=survey.actor.position+Vector3.UP;survey.target_focus=survey.focus
		survey.actor.health=survey.actor.max_health;survey.actor.health_changed.emit(survey.actor.health,survey.actor.max_health)
		survey.actor.velocity=Vector3.ZERO
	failed=false;AudioDirector.set_music_context(&"hideout")
	survey.actor.night_reload=0
	survey.walk_button.text="返回航拍"

func handle_input(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():return false
	if event is InputEventKey and event.physical_keycode==KEY_N:toggle_panel();return true
	if field.panel.visible:return false
	if state.active:
		if event is InputEventKey and event.physical_keycode==KEY_H:heal();return true
		if event.is_action_pressed("interact") and interact():return true
	return false

func guide_point() -> Vector3:
	var target:=objective()
	if field.inside.is_empty():return survey.geo.mesh_at3(field.sites[target.site].point,.1) if target.id!="extract" else stations[0].point
	var room: Node3D=field.rooms[field.inside]
	if field.inside==target.room:
		if target.id=="relay_crate":
			for prop: Node3D in props:
				if prop.id=="relay_crate":return prop.position+Vector3(0,0,2)
		for entry: Dictionary in stations:
			if entry.id==target.id:return entry.point
	var action: String="stairs_"+target.room if Spaces.partner(field.inside)==target.room else ("exit" if Spaces.ground(field.inside)==field.inside else "stairs_"+Spaces.ground(field.inside))
	for entry: Dictionary in field.stations:
		if entry.room==field.inside and entry.id==action:
			# Guide to the bottom, not through the solid side of a ramp.
			return entry.point-Vector3(0,1.3,5) if action.begins_with("stairs_") else entry.point
	return room.position+room.entry_point

func _update_guide() -> void:
	if not state.active or not survey.walking:return
	var target:=guide_point();var here: Vector3=survey.actor.global_position
	var delta: Vector3=target-here
	var bearing:=fposmod(rad_to_deg(atan2(delta.x,-delta.z)),360)
	compass.text="夜线目标  %03d° / %.0fm · %s"%[roundi(bearing),Vector2(delta.x,delta.z).length(),"M路网 / N详情" if field.inside.is_empty() else "金色引导 / E交互或楼梯"]
	for child: Node in guide_root.get_children():child.queue_free()
	var path:=path_between(field.inside,Vector2(here.x,here.z),Vector2(target.x,target.z))
	if path.is_empty():compass.text+=" / 暂无连通引导，M查看分区"
	var travelled:=0.0;var next_mark:=2.0
	for i in range(1,path.size()):
		var length:=path[i-1].distance_to(path[i])
		while next_mark<travelled+length and next_mark<26:
			var p:=path[i-1].lerp(path[i],(next_mark-travelled)/maxf(length,.01))
			var y: float=survey.geo.mesh_at3(p,.10).y if field.inside.is_empty() else field.rooms[field.inside].position.y+.06
			var mesh:=VisualFactory.box(guide_root,Vector3(.30,.025,.55),Vector3(p.x,y,p.y),Color("d9d38a"),"RouteDash")
			mesh.rotation.y=-path[i-1].direction_to(path[i]).angle()+PI*.5
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			next_mark+=2.5
		travelled+=length
		if travelled>26:break

func _process(delta: float) -> void:
	if not survey:return
	button.visible=not survey.route_map.visible and not field.panel.visible
	status.get_parent().visible=state.active and not field.panel.visible and not survey.route_map.visible
	compass.visible=state.active and not field.panel.visible and not survey.route_map.visible
	if not state.active:return
	if last_room!=field.inside:
		cancel_work()
		if not field.inside.is_empty():room_ready(field.inside)
		last_room=field.inside;_sync_visibility();guide_clock=0
		for enemy: Node3D in enemies:
			if enemy.room==field.inside:enemy.age=0;enemy.telegraph=0
	if state.stage!=last_stage:last_stage=state.stage;field.tracked_site="";field.route_target=Vector2(INF,INF);guide_clock=0
	status.text="HP %.0f/%.0f  ·  AR %d/30 +%d  ·  急救 %d / H\n战利品 %d/12  ·  停机 %d台  ·  R换弹 / N背包"%[survey.actor.health,survey.actor.max_health,state.magazine,state.reserve,state.meds,state.weight(),killed]
	for enemy: Node3D in enemies:
		if enemy.room==field.inside:enemy.set_physics_process(running() and enemy.position.distance_to(survey.actor.position)<90)
	if guide_root:guide_root.visible=running()
	if not running():cancel_work();return
	var moving:=Vector2(survey.actor.velocity.x,survey.actor.velocity.z).length()>.6
	if moving or Input.is_action_pressed("fire"):
		if not work.is_empty() or heal_remaining>0:cancel_work();field.message("操作中断，进度未计入。")
	if not work.is_empty():
		var nearby:=nearest()
		if nearby.is_empty() or nearby.id!=work.id or _danger_near():cancel_work()
		else:
			remaining=maxf(0,remaining-delta);field.progress.show();field.progress.value=1-remaining/float(work.seconds)
			if remaining<=0:_complete_work()
	elif heal_remaining>0:
		heal_remaining=maxf(0,heal_remaining-delta);field.progress.show();field.progress.value=1-heal_remaining/1.8
		if heal_remaining<=0:
			state.meds-=1;survey.actor.health=minf(survey.actor.max_health,survey.actor.health+90);survey.actor.health_changed.emit(survey.actor.health,survey.actor.max_health);field.progress.hide()
	var near:=nearest()
	if not near.is_empty():
		field.prompt.get_parent().show()
		field.prompt.text="E  "+("拾取 / "+_loot_caption(near.contents) if near.has("contents") else String(near.label))
		if not work.is_empty():field.prompt.text+=" / %.1fs"%remaining
	guide_clock-=delta
	if guide_clock<=0:_update_guide();guide_clock=.75
