class_name RenderProfile
extends RefCounted
## Shared scene lighting and post processing. Materials remain authored asset data.
## Forward+ is the desktop profile; Compatibility remains a launch-time fallback.

static func create_environment(background: Color) -> Environment:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = background
	var forward := RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d3d7dd") if forward else Color("66645f")
	environment.ambient_light_energy = 0.36 if forward else 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX if forward else Environment.TONE_MAPPER_FILMIC
	if forward:
		# Neutral broad environment reflection restores readable PBR metal/gloss.
		# The background stays the authored scene color.
		var sky := Sky.new()
		var sky_material := ProceduralSkyMaterial.new()
		sky_material.sky_top_color = Color("919eaf")
		sky_material.sky_horizon_color = Color("b2b4b9")
		sky_material.ground_bottom_color = Color("252a32")
		sky_material.ground_horizon_color = Color("747a85")
		sky_material.sun_angle_max = 0.0
		sky.sky_material = sky_material
		environment.sky = sky
		environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		environment.ssao_enabled = true
		environment.ssao_radius = 0.65
		environment.ssao_intensity = 0.65
		environment.ssao_light_affect = 0.0
		environment.glow_enabled = true
		environment.glow_intensity = 0.2
		environment.glow_hdr_threshold = 1.8
	return environment
