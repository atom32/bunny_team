extends Node3D
## Real-scale geographic campus, with an independent authored interior chapter.
## Surveyed exterior data and designed floorplans remain clearly distinguished.
const Geo := preload("res://scripts/world/geography/campus_geodata.gd")
const Map := preload("res://scripts/world/geography/campus_survey_map.gd")
var geo: Geo
var camera: Camera3D
var actor: PlayerController
var screen: Control
var route_map: Control
var inspector: Label
var coordinates: Label
var walk_button: Button
var landmarks: Array[Dictionary] = []
var focus := Vector3.ZERO
var target_focus := Vector3.ZERO
var distance := 1750.0
var target_distance := 1750.0
var yaw := 0.0
var pitch := 1.05
var walk_pitch := 1.0
var dragging := false
var walking := false
var details_visible := true
var selected_site := "全校园 / 卫津路校区"
var return_scene := "res://scenes/presentation/slice/boot.tscn"
var fieldwork: Node3D
var fieldwork_path := "user://campus_fieldwork_v1.json"
var night_operation: Node3D
var night_ledger_path := "user://campus_night_ledger_v1.json"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return_scene=GameState.get_meta("campus_geography_return",return_scene)
	if GameState.has_meta("campus_geography_return"):GameState.remove_meta("campus_geography_return")
	geo = Geo.new()
	camera = Camera3D.new()
	camera.name = "GeographicCamera"
	camera.far = 4500.0
	camera.near = .2
	camera.fov = 54.0
	add_child(camera)
	camera.make_current()
	_landmarks()
	actor = preload("res://scenes/player/player.tscn").instantiate()
	actor.set_script(preload("res://scripts/world/geography/survey_player.gd"))
	# No initialize_session call: exploration can neither spend carried items
	# nor mutate the active sortie/profile. Normal collision/movement is reused.
	add_child(actor)
	actor.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
	actor.set_physics_process(false)
	actor.hide()
	_build_ui()
	fieldwork=preload("res://scripts/world/geography/campus_fieldwork.gd").new()
	add_child(fieldwork)
	fieldwork.setup(self,fieldwork_path)
	night_operation=preload("res://scripts/world/geography/campus_night_operation.gd").new()
	night_operation.ledger_path=night_ledger_path
	add_child(night_operation);night_operation.setup(self)
	_update_camera(0)
	AudioDirector.set_music_context(&"hideout")

func _landmarks() -> void:
	for entry: Dictionary in geo.data.water:
		var rect := Geo.rect(Geo.polygon(entry.points))
		landmarks.append({"name":String(entry.name),"point":rect.get_center(),"osm_id":entry.osm_id,"kind":"湖岸 / 原始 OSM 节点，未简化","height":"水位、驳岸剖面为表现估算，非实测"})
	for entry: Dictionary in geo.data.buildings:
		if not ("第9教学楼" in String(entry.name) or String(entry.osm_id)=="way/891012679"): continue
		landmarks.append({"name":String(entry.name),"point":Geo.rect(Geo.polygon(entry.points)).get_center(),"osm_id":entry.osm_id,"kind":"建筑 / 真实平面轮廓","height":"高度："+("源数据楼层推导" if entry.height_source=="osm_levels" else "估算，待测量")})
	for entry: Dictionary in geo.data.points:
		if String(entry.name) in ["天津大学东门","天津大学西门"]:
			landmarks.append({"name":String(entry.name),"point":Vector2(entry.point[0],entry.point[1]),"osm_id":entry.osm_id,"kind":"校门 / 源数据实点","height":"位置按 WGS84 投影，不混用 GCJ-02 偏移"})

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GeographicUI"
	add_child(layer)
	screen = SliceUI.root(layer)
	screen.theme = FieldManualStyle.theme()
	OperationUI.block(screen,Vector2(18,16),Vector2(1244,74),OperationUI.DARK)
	OperationUI.eyebrow(screen,"GEOGRAPHIC RECONSTRUCTION / 01",Vector2(36,24),true)
	OperationUI.text(screen,"卫津路校区 · 整校园 1:1",Vector2(34,44),24,Color.WHITE).name="CampusHeading"
	OperationUI.text(screen,"1,396 × 905 m / WGS84 / N ↑",Vector2(536,44),14,Color("c0c8bd")).name="CampusScale"
	var detail_toggle:=OperationUI.action(screen,"场景 / TAB",Vector2(988,31),Vector2(140,44),toggle_details)
	detail_toggle.name="ToggleSceneDetails"
	var leave := OperationUI.action(screen,"返回",Vector2(1140,31),Vector2(104,44),_leave)
	leave.name="LeaveCampusSurvey"
	var panel := OperationUI.block(screen,Vector2(962,106),Vector2(300,510),FieldManualStyle.PAPER)
	panel.name="GeographicInspector"
	OperationUI.eyebrow(panel,"REAL GEOMETRY / DATA LIMITS",Vector2(18,12))
	OperationUI.text(panel,"地理定位",Vector2(18,35),26,FieldManualStyle.INK,true)
	for i in landmarks.size():
		var site := landmarks[i]
		var button := OperationUI.action(panel,site.name,Vector2(18,82+i*34),Vector2(264,30),func():select_landmark(site))
		button.name="Landmark%d"%i
		button.add_theme_font_size_override("font_size",13)
	inspector=OperationUI.text(panel,"真实：校界、路网、四湖、楼群轮廓。\n估算：多数楼高、道路宽度、立面与植被。\n高程：约30m级区域DEM，非校园测绘。\nO：12栋/21空间；J：接力任务。室内为设计。",Vector2(18,372),12,FieldManualStyle.MUTED)
	inspector.size=Vector2(264,112)
	inspector.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	route_map=Map.new()
	route_map.survey=self
	screen.add_child(route_map)
	route_map.hide()
	# Controls sit above the optional map, with no interaction through its body.
	var bar := OperationUI.block(screen,Vector2(18,634),Vector2(1244,68),FieldManualStyle.PAPER)
	walk_button=OperationUI.action(bar,"实走 / 从东门进入",Vector2(16,10),Vector2(216,46),toggle_walking,true)
	walk_button.name="WalkRealCampus"
	var map_button := OperationUI.action(bar,"地图 / M",Vector2(244,10),Vector2(128,46),toggle_map)
	map_button.name="ToggleGeographicMap"
	var terrain := CheckButton.new()
	terrain.text="区域高程"
	terrain.position=Vector2(800,596)
	terrain.add_theme_font_size_override("font_size",12)
	terrain.toggled.connect(func(value: bool):route_map.contours=value;route_map.queue_redraw())
	screen.add_child(terrain)
	terrain.visible=false
	terrain.name="RegionalElevationLayer"
	var reset := OperationUI.action(bar,"全校园",Vector2(384,10),Vector2(108,46),reset_overview)
	reset.name="FullCampusOverview"
	coordinates=OperationUI.text(bar,"",Vector2(512,6),12,FieldManualStyle.MUTED)
	coordinates.size=Vector2(706,54)
	coordinates.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	OperationUI.block(screen,Vector2(18,596),Vector2(764,30),FieldManualStyle.PAPER).name="GeographicCreditBacking"
	var credit := LinkButton.new()
	credit.name="GeographicCredit"
	credit.text="© OpenStreetMap contributors / ODbL · Mapzen / USGS DEM · 数据与精度说明 ↗"
	credit.position=Vector2(28,602)
	credit.add_theme_font_size_override("font_size",11)
	credit.add_theme_color_override("font_color",FieldManualStyle.MUTED)
	credit.pressed.connect(func():OS.shell_open("https://www.openstreetmap.org/copyright"))
	screen.add_child(credit)

func select_landmark(site: Dictionary) -> void:
	if night_operation and night_operation.state.active:
		fieldwork.message("夜线进行中，不能切换到航拍；N可查看任务或显式放弃本局。");return
	if fieldwork and not fieldwork.inside.is_empty():return
	_set_walking(false)
	var point: Vector2=site.point
	target_focus=geo.at3(point)
	target_distance=220.0 if site.kind.begins_with("建筑") else 350.0
	selected_site=site.name
	inspector.text="%s\n%s\n%s\n%s\n\n实走始终从东门进入，不瞬移玩家。"%[site.name,site.kind,site.osm_id,site.height]

func reset_overview() -> void:
	if night_operation and night_operation.state.active:
		night_operation.toggle_panel();return
	if fieldwork and not fieldwork.inside.is_empty():return
	_set_walking(false)
	target_focus=Vector3.ZERO
	target_distance=1750
	yaw=0
	pitch=1.05
	selected_site="全校园 / 卫津路校区"

func toggle_map() -> void:
	if night_operation:night_operation.cancel_work()
	if fieldwork:
		if fieldwork.panel.visible:return
		fieldwork.cancel_work("查看地图，工作已中断；回到装置可重新开始。")
	route_map.visible=not route_map.visible
	actor.aim_input_captured=route_map.visible or not walking
	actor.set_physics_process(walking and not route_map.visible)
	if route_map.visible: actor.velocity=Vector3.ZERO
	screen.get_node("RegionalElevationLayer").visible=route_map.visible and (not fieldwork or fieldwork.inside.is_empty())
	route_map.queue_redraw()

func toggle_details() -> void:
	if fieldwork and not fieldwork.inside.is_empty():return
	details_visible=not details_visible
	screen.get_node("GeographicInspector").visible=details_visible


func toggle_walking() -> void:
	if night_operation and night_operation.state.active:
		if not walking:_set_walking(true)
		else:night_operation.toggle_panel()
		return
	if fieldwork and (not fieldwork.inside.is_empty() or fieldwork.panel.visible):return
	if not walking:
		var gate := geo.project(117.1724566,39.1070776)
		var start := gate+Vector2(-6,0)
		# Reject invalid source/start placements, not an arbitrary teleport fallback.
		if not geo.safe_walk_point(start):
			inspector.text="东门落点被几何占用，不能进入；请检查源数据。"
			return
		actor.position=geo.at3(start,1.0)
		actor.velocity=Vector3.ZERO
		focus=actor.position
		target_focus=focus
	_set_walking(not walking)
	route_map.hide()
	screen.get_node("RegionalElevationLayer").hide()

func _set_walking(value: bool) -> void:
	walking=value
	actor.visible=value
	actor.set_physics_process(value)
	actor.aim_input_captured=not value
	walk_button.text="返回航拍" if value else "实走 / 从东门进入"
	if value:
		details_visible=false
		screen.get_node("GeographicInspector").hide()
		yaw=0; pitch=1.0; distance=23; target_distance=23
		walk_pitch=1.0

func _input(event: InputEvent) -> void:
	if night_operation and night_operation.handle_input(event):get_viewport().set_input_as_handled();return
	if fieldwork:
		if fieldwork.handle_input(event):get_viewport().set_input_as_handled();return
		if fieldwork.panel.visible:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_M:
			toggle_map(); get_viewport().set_input_as_handled()
		elif event.physical_keycode==KEY_TAB:
			toggle_details();get_viewport().set_input_as_handled()
		elif event.physical_keycode==KEY_ESCAPE:
			if route_map.visible:toggle_map()
			else:_leave()
			get_viewport().set_input_as_handled()
	if route_map.visible: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT: dragging=event.pressed and not walking
		if event.pressed and not walking and get_viewport().get_mouse_position().x<944:
			if event.button_index==MOUSE_BUTTON_WHEEL_UP: target_distance=maxf(45,target_distance*.86)
			if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: target_distance=minf(1900,target_distance/ .86)
	if event is InputEventMouseMotion and dragging:
		yaw-=event.relative.x*.005
		pitch=clampf(pitch+event.relative.y*.004,.30,1.50)

func _process(delta: float) -> void:
	if fieldwork and fieldwork.panel.visible:return
	if fieldwork and not fieldwork.inside.is_empty():
		fieldwork.update_indoor_camera(delta)
		if route_map.visible:route_map.queue_redraw()
		return
	if not walking and not route_map.visible:
		var direction := Input.get_vector("move_left","move_right","move_forward","move_back")
		var horizontal := Vector3(direction.x,0,direction.y).rotated(Vector3.UP,yaw)
		target_focus+=horizontal*distance*.5*delta
		target_focus.x=clampf(target_focus.x,-800,800)
		target_focus.z=clampf(target_focus.z,-530,530)
		focus=focus.lerp(target_focus,1-exp(-delta*7))
	elif walking:
		if route_map.visible: actor.velocity=Vector3.ZERO
		target_focus=actor.position+Vector3.UP*1.0
		focus=focus.lerp(target_focus,1-exp(-delta*9))
	_update_camera(delta)
	var point: Vector3=actor.position if walking else focus
	coordinates.text="%s / E %.1f m · N %.1f m · DEM %.1f m\n%s"%["实走" if walking else selected_site,point.x,-point.z,geo.height_at(Vector2(point.x,point.z))+float(geo.data.dem.datum_m),"WASD 移动 · E 交互 · M 地图 · J 任务 / 校园任务独立存档，无旧主线奖励" if walking else "WASD 平移 · 右键环绕 · 滚轮缩放 · 定位只移动航拍镜头 / J 校园任务"]
	if route_map.visible: route_map.queue_redraw()

func _update_camera(delta: float) -> void:
	distance=lerpf(distance,target_distance,1-exp(-delta*7)) if delta>0 else target_distance
	# Keep the useful view left of the fixed data inspector.
	var center := focus+Vector3(1,0,0).rotated(Vector3.UP,yaw)*distance*(.12 if details_visible else 0.0)
	var effective_pitch:=pitch
	if walking:
		# A 1:1 campus has 13-30m roofs, unlike the old compressed 3m blocks.
		# In exploration only, steepen the view instead of losing the player
		# behind a building or deleting an entire 128m material batch. Heading,
		# input direction, buildings and all collision remain unchanged.
		var safe_pitch:=pitch
		for i in 13:
			var candidate:=center+Vector3(sin(yaw)*cos(safe_pitch),sin(safe_pitch),cos(yaw)*cos(safe_pitch))*distance
			var query:=PhysicsRayQueryParameters3D.create(actor.position+Vector3.UP*1.15,candidate,4)
			query.exclude=[actor.get_rid()]
			var hit:=get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or not String(hit.collider.name).begins_with("Building_"):break
			safe_pitch=minf(1.56,safe_pitch+.05)
		walk_pitch=lerpf(walk_pitch,safe_pitch,1-exp(-delta*14)) if delta>0 else safe_pitch
		effective_pitch=walk_pitch
	var offset := Vector3(sin(yaw)*cos(effective_pitch),sin(effective_pitch),cos(yaw)*cos(effective_pitch))*distance
	camera.position=center+offset
	camera.look_at(center)

func _leave() -> void:
	if fieldwork:
		if fieldwork.panel.visible:fieldwork.close_panel();return
		if not fieldwork.inside.is_empty():fieldwork.exit_room();return
	if night_operation and night_operation.state.active:
		night_operation.toggle_panel();return
	for action: String in ["move_left","move_right","move_forward","move_back"]:Input.action_release(action)
	GameState.present_scene(return_scene,"CAMPUS GEOGRAPHY / EXIT")
