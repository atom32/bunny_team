extends SceneTree
var dir := OS.get_environment("BUNNY_PHASE4B")
var body:Node3D
var camera:Camera3D
var key:DirectionalLight3D
var env:Environment
var original := {}
var settings:Dictionary
func _initialize(): run.call_deferred()
func apply(mode:String):
 var old_shader=load(dir.path_join("before/anime_surface.gdshader"))
 var subset=load(dir.path_join("uts_subset.gdshader"))
 var shared := {}
 for mesh in original:
  for i in original[mesh].size():
   var source=original[mesh][i]
   var name:String=source.resource_name
   if mode=="production" and not name in ["Battle_face3_main","Battle_Unity2016_C_Skin","Battle_Unity2016_C_Hair_Spow"]:
    mesh.set_surface_override_material(i,source);continue
   if not settings.has(name):continue
   if not shared.has(name):
    var mat:=ShaderMaterial.new();mat.shader=old_shader if mode=="production" else subset
    if mode=="production":
     mat.set_shader_parameter("base_color",source.albedo_color)
     if source.albedo_texture:mat.set_shader_parameter("base_texture",source.albedo_texture)
    else:
     for param in settings[name]:
      var value=settings[name][param]
      if param.ends_with("_texture"):value=load(value)
      elif param.ends_with("_color"):value=Color(value[0],value[1],value[2],value[3])
      mat.set_shader_parameter(param,value)
     mat.set_shader_parameter("bound_game_lights",mode=="reconstructed")
    shared[name]=mat
   mesh.set_surface_override_material(i,shared[name])
func shot(label:String):
 for i in 4:await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(dir.path_join("controlled/"+label+".png"))
func run():
 settings=JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("source_profile.json")))
 var world:=Node3D.new();root.add_child(world);current_scene=world
 body=load("res://assets/characters/unitychan_battle/battle_presentation.glb").instantiate();world.add_child(body)
 for mesh in body.find_children("*","MeshInstance3D",true,false):
  original[mesh]=[]
  for i in mesh.mesh.get_surface_count():original[mesh].append(mesh.get_active_material(i))
 env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("72777d")
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.12
 env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 var we:=WorldEnvironment.new();we.environment=env;world.add_child(we)
 key=DirectionalLight3D.new();world.add_child(key);key.position=Vector3(-2,3,-4);key.look_at(Vector3(0,1.3,0));key.light_energy=1;key.shadow_enabled=true
 camera=Camera3D.new();world.add_child(camera);camera.fov=32;camera.current=true
 for view in ["front","three_quarter","side"]:
  camera.position={"front":Vector3(0,1.4,-1.0),"three_quarter":Vector3(.7,1.4,-.9),"side":Vector3(1.0,1.4,0)}[view]
  camera.look_at(Vector3(0,1.32,0))
  for mode in ["production","source_semantics","reconstructed"]:
   apply(mode);await shot(view+"_"+mode)
 # Same camera, lighting-only controls before any material edits.
 camera.position=Vector3(0,1.4,-1);camera.look_at(Vector3(0,1.32,0));apply("production")
 key.light_energy=.25;await shot("lighting_only_low_key")
 key.light_energy=0;env.ambient_light_energy=.8;await shot("lighting_only_ambient")
 root.get_node("AudioDirector").shutdown_for_test();quit()
