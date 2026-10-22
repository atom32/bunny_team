class_name CampusExitChain
extends DestructibleWorldObject

func receive_damage(packet: DamagePacket) -> float:
	var gate:=get_parent() as CampusExitGate
	if gate.is_open() or not gate.available(SortieRuntime.get_current_session()) or packet.source_faction!=&"player" or not is_instance_valid(packet.source_actor) or not packet.source_actor is PlayerController or packet.source_actor.is_dead:return 0
	var applied:=super.receive_damage(DamagePacket.new(0,0,maxf(packet.base_damage,packet.structure_damage),packet.source_actor,packet.source_weapon,packet.source_faction,packet.hit_position,packet.hit_normal,packet.knockback_impulse))
	if destroyed:gate.open_gate(2,packet.source_actor)
	return applied
