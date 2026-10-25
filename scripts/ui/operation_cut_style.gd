extends StyleBox
## Real cut-corner geometry, including on transparent scene backgrounds.
@export var fill := Color.WHITE
@export var edge := Color.TRANSPARENT
@export var cut := 9.0

func _draw(canvas_item: RID, rect: Rect2) -> void:
	var a := rect.position
	var b := rect.end
	var points := PackedVector2Array([a, Vector2(b.x,a.y), Vector2(b.x,b.y-cut), Vector2(b.x-cut,b.y), Vector2(a.x,b.y)])
	RenderingServer.canvas_item_add_polygon(canvas_item, points, PackedColorArray([fill]))
	if edge.a > 0:
		points.append(a)
		RenderingServer.canvas_item_add_polyline(canvas_item, points, PackedColorArray([edge]), 1.0, true)
