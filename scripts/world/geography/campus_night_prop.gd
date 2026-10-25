extends StaticBody3D
## Physical breakable cover. A killed prop releases its contents exactly once.
signal broken(prop: Node3D)
var id := ""
var room := ""
var kind := "crate"
var health := 15.0
var destroyed := false
var visual: Node3D
var collider: CollisionShape3D
var owner_operation: Node3D
var contents: Dictionary={}

func _ready() -> void:
	collision_layer=4;collision_mask=0
	visual=Node3D.new();add_child(visual)
	var size:=Vector3(1.5,1.35,1.2) if kind=="crate" else Vector3(3.4,1.7,.24)
	for i in (3 if kind=="barricade" else 1):
		var at:=Vector3(0,.35+i*.52,0) if kind=="barricade" else Vector3(0,.675,0)
		VisualFactory.box(visual,Vector3(3.4,.37,.24) if kind=="barricade" else size,at,Color("806a4c"),"BreakableSlat")
	for x: float in [-.55,.55]:
		VisualFactory.box(visual,Vector3(.10,size.y+.06,size.z+.05),Vector3(x,size.y*.5,0),Color("d6b15e"),"YellowBand")
	var shape:=BoxShape3D.new();shape.size=size
	collider=CollisionShape3D.new();collider.shape=shape;collider.position.y=size.y*.5;add_child(collider)
	owner_operation.label(self,"可破坏 / "+("物资箱" if kind=="crate" else "木障"),Vector3(0,size.y+.4,0),Color("e7c77f"))

func receive_damage(packet: DamagePacket) -> float:
	if destroyed or not owner_operation.running() or room!=owner_operation.field.inside or packet.source_faction!=&"player":return 0
	var amount:=minf(health,packet.structure_damage)
	health-=amount
	if amount>0:
		CombatEffects.hit(get_tree().current_scene,global_position+Vector3.UP*.8,Color("dab375"),.7)
		visual.rotation.z=randf_range(-.06,.06)
	if health<=0:
		destroyed=true;visual.hide();collider.set_deferred("disabled",true)
		for child: Node in get_children():
			if child is Label3D:child.hide()
		for i in 5:
			var shard:=VisualFactory.box(self,Vector3(.55,.09,.18),Vector3((i-2)*.35,.06,(i%2)*.38),Color("7b654c"),"Debris")
			shard.rotation.y=i*1.7
		broken.emit(self)
	return amount
