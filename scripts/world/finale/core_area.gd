extends Node3D

func _ready() -> void:
	set_meta("sortie_brief","BACKUP POWER / THE LAST CLICK")
	GameLanguage.language_changed.connect(refresh_core)
	# The authored closed door is signed before a suspended world's facts apply.

func refresh_core() -> void:
	var session:=SortieRuntime.get_current_session()
	var stopped:=FinaleStory.done(session,FinaleStory.STOP)
	$NorthGate.position.y=5 if stopped else 0
	$NorthLink.enabled=stopped
	$ShelterBridge.rotation.y=PI/2 if FinaleStory.done(session,FinaleStory.BRIDGE) else 0
	$BackupLamp.visible=not stopped
	if stopped:$Sweep.phase=FinaleSweep.Phase.OFF;$Sweep.remaining=0;$Sweep.hit_cooldown=0
	$Sweep.refresh()

func create_route_map(player: Node3D) -> void:
	var layer:=CanvasLayer.new();layer.layer=5;layer.name="CoreMap";add_child(layer)
	var map:=preload("res://scripts/world/finale/core_map.gd").new();map.actor=player;map.area=self;layer.add_child(map)
