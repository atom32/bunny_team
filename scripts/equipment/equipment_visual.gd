extends Node3D

@export_enum("light_armor", "heavy_armor", "standard_pack", "thruster_pack") var equipment_id := "light_armor"


func _ready() -> void:
	set_meta("equipment_id", equipment_id)
	match equipment_id:
		"light_armor":
			_build_light_armor()
		"heavy_armor":
			_build_heavy_armor()
		"standard_pack":
			_build_standard_pack()
		"thruster_pack":
			_build_thruster_pack()


func _build_light_armor() -> void:
	VisualFactory.box(self, Vector3(0.24, 0.055, 0.035), Vector3(0.0, 0.07, 0.01), Color("26343d"), "CollarPlate")
	VisualFactory.box(self, Vector3(0.055, 0.13, 0.035), Vector3(-0.15, 0.0, 0.01), Color("5c6c75"), "SidePlateL")
	VisualFactory.box(self, Vector3(0.055, 0.13, 0.035), Vector3(0.15, 0.0, 0.01), Color("5c6c75"), "SidePlateR")
	var accent := VisualFactory.box(self, Vector3(0.11, 0.025, 0.045), Vector3(0.0, 0.07, 0.04), Color("35f2ef"), "Accent")
	accent.material_override = VisualFactory.material(Color("237782"), 0.35, 0.3, Color("35f2ef"), 1.5)


func _build_heavy_armor() -> void:
	VisualFactory.box(self, Vector3(0.56, 0.3, 0.12), Vector3(0.0, -0.02, 0.0), Color("263746"), "TorsoPlate")
	VisualFactory.box(self, Vector3(0.2, 0.12, 0.16), Vector3(-0.35, 0.12, 0.0), Color("b83f4a"), "PauldronL")
	VisualFactory.box(self, Vector3(0.2, 0.12, 0.16), Vector3(0.35, 0.12, 0.0), Color("b83f4a"), "PauldronR")
	VisualFactory.box(self, Vector3(0.32, 0.07, 0.14), Vector3(0.0, -0.19, 0.02), Color("728592"), "BeltPlate")
	var core := VisualFactory.box(self, Vector3(0.13, 0.08, 0.15), Vector3(0.0, 0.02, 0.08), Color("80f3ff"), "Core")
	core.material_override = VisualFactory.material(Color("2c7781"), 0.4, 0.2, Color("54f5ff"), 2.5)


func _build_standard_pack() -> void:
	VisualFactory.box(self, Vector3(0.58, 0.72, 0.3), Vector3(0.0, -0.05, 0.15), Color("30475a"), "Pack")
	VisualFactory.box(self, Vector3(0.42, 0.13, 0.08), Vector3(0.0, 0.36, 0.01), Color("75d6dd"), "Handle")
	for side in [-1.0, 1.0]:
		var canister := VisualFactory.cylinder(self, 0.1, 0.56, Vector3(0.36 * side, -0.04, 0.17), Color("465c69"), "Canister")
		canister.material_override = VisualFactory.material(Color("465c69"), 0.55, 0.28)


func _build_thruster_pack() -> void:
	VisualFactory.box(self, Vector3(0.54, 0.58, 0.27), Vector3(0.0, 0.03, 0.12), Color("202b3b"), "ThrusterCore")
	for side in [-1.0, 1.0]:
		var thruster := VisualFactory.cylinder(self, 0.16, 0.58, Vector3(0.32 * side, -0.1, 0.15), Color("42546a"), "Thruster")
		thruster.material_override = VisualFactory.material(Color("42546a"), 0.5, 0.3)
		var glow := VisualFactory.cylinder(self, 0.105, 0.08, Vector3(0.32 * side, -0.42, 0.15), Color("55f2ff"), "Glow")
		glow.material_override = VisualFactory.material(Color("2b8f9b"), 0.3, 0.15, Color("55f2ff"), 3.5)
