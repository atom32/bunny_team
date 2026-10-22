class_name WaterPublicLatch
extends DestructibleWorldObject

func receive_damage(packet: DamagePacket) -> float:
	if packet.source_faction!=&"player" or not WaterworksJourney.pending(SortieRuntime.get_current_session(),"public"):return 0
	var applied:=super.receive_damage(packet)
	if destroyed:get_parent().complete_delivery("public","shot")
	return applied

func valid_checkpoint(entry: Dictionary,session: SortieSession) -> bool:
	return entry.destroyed==(session.waterworks.public_fix=="shot") and (session.waterworks.branch=="public" or entry.current_structure_health==max_structure_health)
