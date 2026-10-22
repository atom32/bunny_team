class_name BlockadeStreetChain
extends DestructibleWorldObject

func receive_damage(packet: DamagePacket) -> float:
	var session:=SortieRuntime.get_current_session()
	if not session or session.status!=SortieSession.Status.ACTIVE or packet.source_faction!=&"player":return 0
	# Ordinary bullets can cut the chain; the shutter behind it is separate cover.
	var applied:=super.receive_damage(DamagePacket.new(0,0,maxf(packet.base_damage,packet.structure_damage),packet.source_actor,packet.source_weapon,packet.source_faction,packet.hit_position,packet.hit_normal,packet.knockback_impulse))
	if destroyed:
		var passage: BlockadePassage=get_parent().get_node("Passage")
		passage.alarm();passage.refresh_hardware();SortieRuntime.request_checkpoint()
	return applied
