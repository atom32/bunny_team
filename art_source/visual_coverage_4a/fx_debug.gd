extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var world:=Node3D.new();root.add_child(world)
 var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(4,4,6);camera.look_at(Vector3.ZERO);camera.current=true
 var mat=load("res://resources/vfx/soft_smoke.tres")
 var quad:=QuadMesh.new();quad.size=Vector2(2,2)
 var mesh:=MeshInstance3D.new();mesh.mesh=quad;mesh.material_override=mat;world.add_child(mesh)
 await create_timer(.3).timeout
 print("MAT ",mat.transparency," SHADING ",mat.shading_mode," BILLBOARD ",mat.billboard_mode," FILL ",mat.albedo_texture.fill)
 var img=mat.albedo_texture.get_image()
 print("IMAGE ",img.get_pixel(64,64)," EDGE ",img.get_pixel(0,0))
 img.save_png("D:/bunny_team/art_source/visual_coverage_4a/fx/gradient.png")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("D:/bunny_team/art_source/visual_coverage_4a/fx/static_smoke.png")
 mat.albedo_texture=null;mat.albedo_color=Color.RED
 await create_timer(.1).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("D:/bunny_team/art_source/visual_coverage_4a/fx/static_red.png")
 root.get_node("AudioDirector").shutdown_for_test();quit()

