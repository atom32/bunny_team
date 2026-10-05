import pathlib,shutil,hashlib,json,re
root=pathlib.Path(r'D:/bunny_team');base=pathlib.Path(__file__).parent
backup=base/'integration_backup';assert not backup.exists();backup.mkdir()
for rel in ['scripts/presentation/slice/hideout.gd','tests/hideout_idle_test.gd']:
 d=backup/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/rel,d)
hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'assets/characters/artoria_bunny').rglob('*') if p.is_file()}
(base/'character_before.json').write_text(json.dumps(hashes,indent=2))
p=root/'scripts/presentation/slice/hideout.gd';s=p.read_text()
s=s.replace('const KIT := "res://assets/environment/kenney_space_station_kit/"','const ENVIRONMENT := preload("res://scenes/presentation/compact_hideout/environment.tscn")\nconst STANDING_ANCHOR := Vector3(-0.55,0,-0.1)\nconst SEAT_ANCHOR := Vector3(2.12,0.045,0.9)')
s=s.replace('camera.fov = 32.0','camera.fov = 65.0')
s=s.replace('\t\trelaxed_preview.bind(hanger.preview_character)','\t\tif relaxed_preview.actor != hanger.preview_character:\n\t\t\thanger.preview_character.position = STANDING_ANCHOR\n\t\trelaxed_preview.bind(hanger.preview_character)')
s=s.replace('Vector3(9.4,0,2.2)','SEAT_ANCHOR')
start=s.index('func _menu_camera()');end=s.index('func show_section(',start)
s=s[:start]+'''func _menu_camera() -> void:
	# The imported compact room replaces the display stage; actor geometry is unchanged.
	camera.position = Vector3(0.35 + sin(elapsed * 0.10) * 0.025, 1.6, 1.82)
	camera.look_at(Vector3(-1.0, 1.05, -0.45))

func _build_rooms() -> void:
	# Hanger keeps equipment/save ownership. Disable only its legacy presentation shell.
	for item in hanger.get_children():
		if item is MeshInstance3D or item is Light3D: item.hide()
		if item is WorldEnvironment: item.environment = null
	for node_name in ["Floor", "BackWall", "MaintenanceBackground"]:
		var old_shell := hanger.get_node_or_null(node_name) as Node3D
		if old_shell: old_shell.hide()
	var room := ENVIRONMENT.instantiate()
	room.name = "CompactEnvironment"
	add_child(room)
	camera.fov = 65.0

''' +s[end:]
start=s.index('\tvar destination :=',s.index('func show_section'));end=s.index('\tif camera_tween',start)
s=s[:start]+'''	var destination := Vector3(0.35,1.6,1.82)
	var focus := Vector3(-0.85,1,-0.45)
	if value == "Hanger":
		destination = Vector3(0.1,1.55,1.82)
		focus = Vector3(-0.55,1.05,-0.1)
	elif value == "Operations":
		destination = Vector3(-1.4,1.5,1.65)
		focus = Vector3(-1.05,1,-1.4)
	elif value == "Workshop":
		destination = Vector3(-0.6,1.65,1.65)
		focus = Vector3(-1.8,0.95,-1.37)
	elif value == "Rest":
		destination = Vector3(0.45,1.6,1.72)
		focus = Vector3(2.12,0.95,0.9)
''' +s[end:]
p.write_text(s)
# New physical stool uses an existing mesh, not a procedural chair.
p=root/'scenes/presentation/compact_hideout/environment.tscn';s=p.read_text()
id=re.search(r'path="[^"]*metal_stool_01.gltf" id="([^"]+)"',s).group(1)
# Existing imported stool bound is centered; authored 0.62 scale gives ~0.547m top.
s+='\n[node name="RestSeat" parent="." instance=ExtResource("'+id+'") ]\nposition = Vector3(2.12,-0.00001178,0.90006138)\nscale = Vector3(0.62,0.62,0.62)\n'
# Move trunk away from the stool and front foot-contact region.
start=s.index('[node name="PersonalTrunk"');end=s.find('[node ',start+1)
block=s[start:end];block=re.sub(r'position = Vector3\([^\n]+\)','position = Vector3(1.6067307,0.0000063,1.7843091)',block);block=block.replace('scale = Vector3(0.65,0.65,0.65)','scale = Vector3(0.38,0.38,0.38)');s=s[:start]+block+s[end:]
p.write_text(s)
p=root/'tests/hideout_idle_test.gd';s=p.read_text().replace('is_equal_approx(player.position.x,9.4)','is_equal_approx(player.position.x,hub.SEAT_ANCHOR.x)').replace('is_equal_approx(preview.actor.position.x,9.4)','is_equal_approx(preview.actor.position.x,hub.SEAT_ANCHOR.x)')
s=s.replace('var equipment_position := player.position','check(hub.has_node("CompactEnvironment/RestSeat"), "compact imported environment has authored physical rest seat")\n\tcheck(player.position.is_equal_approx(hub.STANDING_ANCHOR), "base preview uses floor-level compact room anchor")\n\tvar equipment_position := player.position')
p.write_text(s)
print('INTEGRATED scoped shell/camera/anchors; UI and save callbacks untouched')
