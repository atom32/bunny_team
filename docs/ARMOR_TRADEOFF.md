# Armor / Mobility, Protection, Carry Weight

2026-09-30. Armor selection now changes incoming health damage as well as normal
movement speed. There is no additional armor progression or material purchase.

| Armor | Mobility with AR + Field Pack | Protection | Armor carry weight | HP lost from a 25-damage hit |
| --- | --- | --- | --- | --- |
| Light / Recon Shell | 8.2 m/s | 10% less incoming damage | 3 kg | 22.5 |
| Heavy / Bulwark Plate | 6.2 m/s | 40% less incoming damage | 8 kg | 15 |
| None | 7.7 m/s | 0% | 0 kg | 25 |

Protection reduces the incoming packet's base health damage by a percentage;
it does not add health, boost weapon damage, or change enemy armor penetration.
Heavy armor reduces all incoming health damage by 40%. There is no separate
player plate/penetration system in this version. Runtime protection is clamped
between 0 and 80%, and damage cannot heal the player.

Mobility is normal movement speed for the equipped weapon and backpack. Light
armor adds 0.5 m/s; heavy armor subtracts 1.5 m/s from the existing movement
formula. Precision walking still halves normal speed; dodge behavior is unchanged.
The same calculation powers actual movement and the loadout/HUD readout. Carry
Weight is the armor's contribution to cargo weight, separate from total cargo.
The extra 5kg for heavy armor consumes available space for loot and ammunition.

The equipment screen shows all three values beneath armor selection and updates
when weapon, armor, or backpack changes. Battle HUD shows the currently active
weapon's mobility, incoming damage reduction and equipped armor weight; switching
weapons refreshes the readout. Existing saved armor selections receive the new
stats through their existing content IDs.

Verification: `damage_packet_test` compares actual 25-damage hits, one second of
real physics movement, a saved profile reload followed by deployment, and UI/HUD
readouts. `first_mission_test` also changes armor through the real Hanger handler
and checks that the mission button remains above the hub navigation. Graphical
loadout and HUD captures were inspected. Death, loadout, switching, mission flow,
P0 flow and P0 recovery regressions passed. Evidence is in `armor_tradeoff/`.

Measured normal traversal from rest over 60 physics ticks: light 7.62m, heavy
5.88m (acceleration included); steady movement speeds remain 8.2 and 6.2 m/s.
