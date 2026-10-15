extends StaticBody3D
## Workbench-local target; no enemy, reward, inventory or sortie ownership.
var total_damage := 0.0
var hits := 0

func receive_damage(packet: DamagePacket) -> float:
	total_damage += packet.base_damage
	hits += 1
	return packet.base_damage

func reset() -> void:
	total_damage = 0.0
	hits = 0
