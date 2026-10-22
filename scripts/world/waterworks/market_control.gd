extends Node3D
@export_enum("breaker","shutter","back_bar","notice") var kind:="shutter"

func _ready() -> void:
	add_to_group("interactable")

func interact(actor: Node3D,current: SortieSession) -> Dictionary:
	var market:=get_parent().get_node("Market") as WaterMarket
	if not market.available(actor,current,self):return {"success":false,"message":"Move closer to the market equipment."}
	if kind=="notice":
		var hint:=market.carrier_hint()
		return {"success":true,"message":"South market / repair depot","information":tr(WaterMarket.INTRO)+("\n\n"+hint if not hint.is_empty() else "")}
	return market.operate(kind,actor,current,self)

func get_interaction_prompt(_actor: Node3D,current: SortieSession) -> String:
	if not current or current.status!=SortieSession.Status.ACTIVE:return ""
	var market:=get_parent().get_node("Market") as WaterMarket
	var prompt:=""
	if kind=="notice":prompt="MARKET ROUTES / OPTIONAL DEPOT"
	elif kind=="breaker" and market.mode==0 and not market.isolated:prompt="DISCONNECT DEPOT BELL / WEST STALLS"
	elif kind=="shutter" and market.mode==0:prompt="OPEN DEPOT / BELL DISCONNECTED" if market.isolated else "OPEN DEPOT / BELL WILL RING"
	elif kind=="back_bar" and market.progress==1 and not market.back_open:prompt="LIFT NORTH BAR / INSIDE DEPOT"
	return ControlBindings.label("interact")+"  "+tr(prompt) if not prompt.is_empty() else ""
