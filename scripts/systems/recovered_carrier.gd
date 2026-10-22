class_name RecoveredCarrier
extends RefCounted
## One recovered object, two mutually exclusive uses. No unlock flag or currency.
const FRAME := &"material.market_carrier_frame"
const COURIER := &"equipment.courier_sling"
const FREIGHT := &"equipment.freight_frame"
const CONVERSATION := "Su Mi: You brought the whole frame?\nTang Kui: I told her the straps were good.\nSu Mi: They are. For carrying things, not adopting a second water tank.\nTang Kui: ...Make hers light. Mine can stay ugly."
const RECIPES := {
	"carrier_courier": {"name":"REMAKE / COURIER SLING", "detail":"27kg total capacity / +0.55 m/s / 1.20kg pack. Less cargo, faster feet. One frame becomes one pack; equip it in the Hanger.", "inputs":{FRAME:1}, "output":COURIER, "quantity":1},
	"carrier_freight": {"name":"REMAKE / FREIGHT FRAME", "detail":"47kg total capacity / -0.90 m/s / 4.00kg pack. More cargo, slower feet. One frame becomes one pack; equip it in the Hanger.", "inputs":{FRAME:1}, "output":FREIGHT, "quantity":1},
}
