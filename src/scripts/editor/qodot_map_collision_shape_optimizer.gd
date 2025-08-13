tool
class_name QodotMapCollisionShapeOptimizer
extends QodotMapPostProcess

export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var optimize := false setget set_optimize
export var export_save_guard_end : bool = true setget set_export_save_guard_end

var _is_saving := false

func set_export_save_guard_start(val):
	if val == false:
		return
	_is_saving = true


func set_export_save_guard_end(val):
	if val == false:
		return
	_is_saving = false


func set_optimize(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
		
	var map = _qodot_map
	if map == null:
		return
	
	for body in map.get_children():
		if !(body is StaticBody):
			continue
		
		for collision_shape in body.get_children():
			if !(collision_shape is CollisionShape):
				continue
			if !(collision_shape.shape is ConvexPolygonShape):
				continue
			if !_try_convert_to_box_shape(collision_shape):
				# See: https://github.com/godotengine/godot/issues/27427
				# Bullet Physics applies big margin on ConvexPolygonShape
				# So we offset that by reduce the size
				var convex_shape = ConvexHull.create_convex_shape(collision_shape.shape.points, -collision_shape.shape.margin)
				collision_shape.shape = convex_shape
				print_debug("Offset ConvexpolygonShape of %s" % collision_shape)


func _try_convert_to_box_shape(collision_shape : CollisionShape) -> bool:
	if collision_shape == null:
		return false
	
	if !(collision_shape.shape is ConvexPolygonShape):
		return false
	
	var points = collision_shape.shape.points
	if points.size() != 8:
		return false
	
	var centroid = ConvexHull.get_centroid(points)
	var abs_coord = (points[0] - centroid).abs()
	var epsilon = 0.05
	
	for i in range(1, 8):
		if ((points[i] - centroid).abs() - abs_coord).length_squared() > epsilon * epsilon:
			return false
	
	var box_shape = BoxShape.new()
	box_shape.extents = abs_coord
	
	collision_shape.shape = box_shape 
	collision_shape.position = centroid
	
	print_debug("Converted %s from ConvexShape to BoxShape" % collision_shape.name)
	return true


# Override
func do_stuff():
	set_optimize(true)
