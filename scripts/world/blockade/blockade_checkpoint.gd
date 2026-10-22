extends Node3D

func _ready() -> void:
	set_meta("sortie_brief", "CHECKPOINT / REMAIN CALM")
	GameLanguage.language_changed.connect(refresh_blockade)
	get_node("Van").state_changed.connect(_apply_hardware)
	var layer := CanvasLayer.new();layer.name = "BlockadeReadoutLayer";layer.layer = 6;add_child(layer)
	var readout := preload("res://scripts/world/blockade/blockade_readout.gd").new()
	readout.van = get_node("Van");layer.add_child(readout)
	refresh_blockade()

func refresh_blockade() -> void:
	get_node("Van").refresh()
	for entry in [["Radio","RADIO / TANG KUI"],["PASwitch","CUT PA SUPPLY / WEST ALLEY"]]:
		get_node(entry[0]).get_node("WorldLabel").text = tr(entry[1])
	for entry in [["NorthExit","NORTH / CHECKPOINT EXIT"],["Retreat","SOUTH / RETREAT"]]:
		for label in get_node(entry[0]).find_children("*","Label3D",true,false): label.text = tr(entry[1])

func _apply_hardware() -> void:
	var van: BlockadeVan = get_node("Van")
	# Derived from the authoritative vehicle state, never a second saved door flag.
	# Closed transforms and nav are identical to the previous released local build.
	get_node("Concrete5").position.y = 4.3 if van.destroyed else .85
	get_node("Concrete5Body").position.y = 4.3 if van.destroyed else .85
	get_node("NorthGateLink").enabled = van.destroyed
	get_node("PASwitch/Lever").rotation.x = .4 if van.speaker_enabled else -.85
	get_node("PASwitch/PowerOn").visible = van.speaker_enabled
	get_node("PASwitch/PowerOff").visible = not van.speaker_enabled
	get_node("PowerIndicators").visible = van.speaker_enabled
	get_node("Van/GunActive").visible = not van.destroyed
	get_node("Van/DisabledMark").visible = van.destroyed
