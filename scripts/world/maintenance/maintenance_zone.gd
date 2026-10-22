extends Node3D
const GATES={"ServiceGate":&"maintenance_bypass","WardGate":&"maintenance_release","NorthGate":&"maintenance_gate"}
func _ready() -> void:
 set_meta("sortie_brief","SEALED MAINTENANCE / THE VOICE BEHIND THE DOOR")
 # Keep authored collider transforms until Battle captures the layout signature.
 # Suspended objective facts are applied by restore_world only after validation.
 GameLanguage.language_changed.connect(refresh_maintenance)
func refresh_maintenance() -> void:
 var session:=SortieRuntime.get_current_session()
 for name in GATES:
  var open:=MaintenanceStory.done(session,GATES[name])
  get_node(name).position.y=5 if open else 0
  get_node(name+"Link").enabled=open
 for action in find_children("*","MaintenanceAction",true,false):action.refresh()
func create_route_map(player: Node3D) -> void:
 var layer:=CanvasLayer.new();layer.layer=5;layer.name="MaintenanceMap";add_child(layer)
 var map:=preload("res://scripts/world/maintenance/route_map.gd").new();map.actor=player;map.area=self;layer.add_child(map)
