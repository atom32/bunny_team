extends RefCounted
## Reuse the game's authored branch/leaf language, bake shared near meshes,
## and reserve clustered volumes for far LOD only. No source tree is modified.
const TreeSource := preload("res://scripts/world/streets/courtyard_tree.gd")
var b: RefCounted

func build(builder: RefCounted) -> void:
	b=builder
	for variant in 4:
		var tree:=TreeSource.new()
		tree.build(8201+variant*197)
		var near_mesh:=_near_mesh(tree)
		var far_mesh:=_far_mesh(variant)
		var transforms: Array[Transform3D]=[]
		for i in range(variant,b.tree_positions.size(),4):
			var at: Vector3=b.tree_positions[i]
			var scale:=Vector3(1.45+sin(i*2.17)*.17,1.55+sin(i*1.23)*.22,1.45+sin(i*1.37)*.17)
			transforms.append(Transform3D(Basis(Vector3.UP,i*2.399963)*Basis.from_scale(scale),at))
			if i%2==0:_soil_patch(at,1.45)
		b._instances("IllustrativeDetailedTrees%d"%variant,near_mesh,transforms,0,160)
		b._instances("IllustrativeTreeLOD%d"%variant,far_mesh,transforms,160,2600)
		if variant==0:_shrubs(near_mesh)
		tree.free()
	b.stats.foliage_variants=4
	b.stats.foliage_near_cutoff_m=160
	b.stats.tree_style_source="courtyard_tree.gd / branch + geometric leaf; illustrative positions"
	b=null

func _shrubs(mesh: ArrayMesh) -> void:
	var transforms: Array[Transform3D]=[]
	var positions: Array[Vector2]=[]
	for entry: Dictionary in b.geo.data.landcover:
		var poly:=CampusGeodata.polygon(entry.points)
		var bounds:=CampusGeodata.rect(poly)
		for i in 8:
			var p:=bounds.get_center()+Vector2(sin(i*2.399963),cos(i*2.399963))*bounds.size*.36
			if not Geometry2D.is_point_in_polygon(p,poly) or not b.geo.safe_walk_point(p) or b.geo.is_building(p,1.5) or b.geo.road_blocks(p,1.2) or b.geo.sports_blocks(p,1.2):continue
			positions.append(p)
			transforms.append(Transform3D(Basis(Vector3.UP,i*.71)*Basis.from_scale(Vector3(.55,.31,.55)),b.geo.mesh_at3(p)))
	b._instances("IllustrativeGardenShrubs",mesh,transforms,0,95)
	b.stats.garden_shrubs=transforms.size()
	b.world.set_meta("shrub_art_placements",positions)

func _near_mesh(tree: Node3D) -> ArrayMesh:
	var result:=ArrayMesh.new()
	var branches:=SurfaceTool.new()
	branches.begin(Mesh.PRIMITIVE_TRIANGLES)
	branches.set_material(b.materials.bark)
	# Repeated source node names are auto-renamed by Godot (often @...@), so
	# matching TaperedBranch* silently retained only the first trunk segment.
	for node: MeshInstance3D in tree.get_node("CameraCanopy").find_children("*","MeshInstance3D",true,false):
		branches.append_from(node.mesh,0,node.transform)
	branches.commit(result)
	var source: MultiMesh=tree.get_node("CameraCanopy/CanopyLeaves").multimesh
	var arrays: Array=source.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var leaves:=SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material:=ShaderMaterial.new()
	material.shader=preload("res://resources/materials/streets/geographic_foliage.gdshader")
	leaves.set_material(material)
	# Half the original leaves, shared over the whole campus, is enough at the
	# existing battle camera scale; the silhouette remains individual leaves.
	for i in range(0,source.instance_count,2):
		var transform:=source.get_instance_transform(i)
		var color:=source.get_instance_color(i)
		for j in vertices.size():
			leaves.set_color(color)
			leaves.set_normal((transform.basis*normals[j]).normalized())
			leaves.add_vertex(transform*vertices[j])
	leaves.commit(result)
	return result

func _far_mesh(variant: int) -> ArrayMesh:
	var result:=ArrayMesh.new()
	var bark:=SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	bark.set_material(b.materials.bark)
	var trunk:=CylinderMesh.new()
	trunk.top_radius=.08;trunk.bottom_radius=.17;trunk.height=2.8;trunk.radial_segments=6
	bark.append_from(trunk,0,Transform3D(Basis.IDENTITY,Vector3(0,1.4,0)))
	bark.commit(result)
	var leaves:=SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	leaves.set_material(b._plain(["74885b","6a8154","7d8b5c","6c8555"][variant]))
	var sphere:=SphereMesh.new()
	sphere.radius=.94;sphere.height=1.65;sphere.radial_segments=10;sphere.rings=5
	for i in 7:
		var angle: float=i*TAU/7+variant*.4
		var at:=Vector3(cos(angle)*1.18,2.85+i*.13,sin(angle)*1.18)
		leaves.append_from(sphere,0,Transform3D(Basis.IDENTITY,at))
	leaves.commit(result)
	return result

func _soil_patch(at: Vector3, radius: float) -> void:
	var p:=Vector2(at.x,at.z)
	var a: Vector3=b.geo.mesh_at3(p+Vector2(-radius,-radius),.036)
	var c: Vector3=b.geo.mesh_at3(p+Vector2(-radius,radius),.036)
	var d: Vector3=b.geo.mesh_at3(p+Vector2(radius,radius),.036)
	var e: Vector3=b.geo.mesh_at3(p+Vector2(radius,-radius),.036)
	b._tri("soil",a,c,d,Vector2.ZERO,Vector2(0,1),Vector2.ONE)
	b._tri("soil",a,d,e,Vector2.ZERO,Vector2.ONE,Vector2(1,0))
