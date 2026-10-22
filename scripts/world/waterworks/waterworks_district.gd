extends Node3D

func _ready() -> void:
	set_meta("sortie_brief", "WATER TOWER / THE LAST PUMP")
	GameLanguage.language_changed.connect(refresh_waterworks)
	refresh_waterworks()

func refresh_waterworks() -> void:
	var session := SortieRuntime.get_current_session()
	for point in find_children("*","WaterworksAction",true,false): point.refresh()
	for cache in find_children("*","LootSpawnPoint",true,false):
		var index := 0
		for pickup in cache.get_children():
			if pickup is LootPickup:
				pickup.position.x = (index % 3) * .7 - .7
				index += 1
	get_node("WaterFlow").visible = WaterworksStory.done(session, &"water_pump")
	get_node("PublicWater").visible = WaterworksStory.done(session, &"water_public")
	get_node("TankerWater").visible = WaterworksStory.done(session, &"water_tanker")
	for entry in [["Retreat","SOUTH / RETREAT"],["PublicExit","WEST / COURTYARD EXIT"],["TankerExit","NORTH / LOADING EXIT"]]:
		for label in get_node(entry[0]).find_children("*","Label3D",true,false): label.text = tr(entry[1])

func open_reward(branch: String) -> void:
	var cache := get_node("PublicReward" if branch == "public" else "TankerReward") as LootSpawnPoint
	cache.enabled = true
	var rng := RandomNumberGenerator.new(); rng.seed = 1807
	cache.spawn(rng)

func create_route_map(player: Node3D) -> void:
	var layer := CanvasLayer.new(); layer.name = "WaterworksRouteMap"; layer.layer = 5; add_child(layer)
	var map := preload("res://scripts/world/waterworks/route_map.gd").new()
	map.actor = player; layer.add_child(map)
