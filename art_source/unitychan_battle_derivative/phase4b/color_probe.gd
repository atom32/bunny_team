extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var world:=Node3D.new();root.add_child(world)
 var cam:=Camera3D.new();world.add_child(cam);cam.position=Vector3(0,0,4);cam.current=true
 var mesh:=MeshInstance3D.new();world.add_child(mesh);mesh.mesh=QuadMesh.new()
 var light:=DirectionalLight3D.new();world.add_child(light);light.rotation.y=PI;light.light_energy=1
 var values := {}
 for mode in ["constant","uniform","standard","light"]:
  if mode=="standard":
   var m:=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.albedo_color=Color(.5,.5,.5);mesh.material_override=m
  else:
   var shader:=Shader.new()
   shader.code="shader_type spatial; render_mode unshaded; void fragment(){ALBEDO=vec3(.5);}" if mode=="constant" else "shader_type spatial; render_mode unshaded; uniform vec4 swatch:source_color;void fragment(){ALBEDO=swatch.rgb;}"
   if mode=="light":shader.code="shader_type spatial;render_mode ambient_light_disabled;void fragment(){ALBEDO=vec3(1);}void light(){DIFFUSE_LIGHT=vec3(.5);}"
   var m:=ShaderMaterial.new();m.shader=shader;m.set_shader_parameter("swatch",Color(.5,.5,.5));mesh.material_override=m
  for i in 4:await RenderingServer.frame_post_draw
  var img:=root.get_texture().get_image();values[mode]=str(img.get_pixel(640,360))
 print(values)
 var f:=FileAccess.open(OS.get_environment("BUNNY_PHASE4B").path_join("color_probe.json"),FileAccess.WRITE);f.store_string(JSON.stringify(values,"  "));f.close()
 root.get_node("AudioDirector").shutdown_for_test();quit()
