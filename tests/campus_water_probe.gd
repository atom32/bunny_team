extends Node
## Diagnostic only: isolate lake geometry, shadows and tangent-space shading.
func _ready() -> void:
	await get_tree().process_frame
	var survey:=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	add_child(survey)
	survey.screen.hide();survey.set_process(false)
	survey.focus=survey.geo.at3(Vector2(258,-150),2.5)
	survey.distance=100;survey.target_distance=100;survey.yaw=.7;survey.pitch=.72
	survey._update_camera(0)
	var meshes: Array[MeshInstance3D]=[]
	for node: MeshInstance3D in survey.get_node("WeijinGeographicWorld").find_children("water*","MeshInstance3D",false,false):
		meshes.append(node)
		var array: Array=node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=array[Mesh.ARRAY_VERTEX]
		var minimum:=INF;var maximum:=-INF
		for p: Vector3 in vertices:minimum=minf(minimum,p.y);maximum=maxf(maximum,p.y)
		if String(node.name).begins_with("water2"):print(node.name," y=",minimum,"..",maximum," vertices=",vertices.size())
		if String(node.name).begins_with("water2"):
			var normals: PackedVector3Array=array[Mesh.ARRAY_NORMAL]
			var nmin:=Vector3(INF,INF,INF);var nmax:=Vector3(-INF,-INF,-INF)
			for n: Vector3 in normals:nmin=nmin.min(n);nmax=nmax.max(n)
			print("normal range ",nmin," .. ",nmax)
	for mode in 12:
		if mode==1:
			for node: MeshInstance3D in meshes:
				var material: ShaderMaterial=node.mesh.surface_get_material(0).duplicate()
				var shader:=Shader.new()
				shader.code=material.shader.code.replace("render_mode cull_disabled;","render_mode cull_disabled, shadows_disabled;")
				material.shader=shader
				node.material_override=material
		elif mode==2:
			var material:=StandardMaterial3D.new()
			material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color=Color("226b63")
			for node: MeshInstance3D in meshes:node.material_override=material
		elif mode==3:
			var material:=StandardMaterial3D.new()
			material.albedo_color=Color("226b63");material.roughness=1;material.metallic_specular=0
			for node: MeshInstance3D in meshes:node.material_override=material
		elif mode==4:
			for node: MeshInstance3D in meshes:
				var material: ShaderMaterial=node.mesh.surface_get_material(0).duplicate()
				var shader:=Shader.new()
				shader.code=material.shader.code.replace("SPECULAR=0.4;","SPECULAR=0.0;").replace("METALLIC=0.06;","METALLIC=0.0;")
				material.shader=shader
				node.material_override=material
		elif mode in [5,6,7,8,9,10,11]:
			for node: MeshInstance3D in meshes:
				var material: ShaderMaterial=node.mesh.surface_get_material(0).duplicate()
				var shader:=Shader.new()
				var code: String=material.shader.code
				if mode==5:code=code.replace("render_mode cull_disabled;","render_mode cull_disabled, unshaded;")
				if mode==6:
					var end:=code.rfind("}")
					code=code.substr(0,end)+"ALBEDO=vec3(0.029,0.093,0.081);ROUGHNESS=1.0;SPECULAR=0.0;METALLIC=0.0;\n}"
				if mode==7:
					var lines:=code.split("\n")
					var cleaned:=PackedStringArray()
					for line: String in lines:
						if not line.strip_edges().begins_with("NORMAL="):cleaned.append(line)
					code="\n".join(cleaned)
				if mode>=8:
					code=code.replace("render_mode cull_disabled;","render_mode cull_disabled, unshaded;")
					var expression: String={8:"mix(shallow,vec3(0.029,0.093,0.081),smoothstep(0.3,5.5,bank))",9:"vec3(noise(p*0.028))",10:"vec3(fract(p.x/36.0),fract(p.y/36.0),0.0)",11:"vec3(COLOR.r)"}[mode]
					var end:=code.rfind("}")
					code=code.substr(0,end)+"ALBEDO="+expression+";\n}"
				shader.code=code;material.shader=shader;node.material_override=material
		for i in 15:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("water_diagnostic_%d.png"%mode))
	get_tree().quit()
