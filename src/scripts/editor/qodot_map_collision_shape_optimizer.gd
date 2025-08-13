tool
class_name QodotMapCollisionShapeOptimizer
extends Node

export var qodot_map_path : NodePath = ""
export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var optimzie := false setget set_optimize
export var export_save_guard_end : bool = true setget set_export_save_guard_end

var _is_saving := false

func _ready():
	if !Engine.editor_hint:
		queue_free()
		return
	var map = get_qodot_map()
	if !map.is_connected("build_complete", self, "_on_map_build_completed"):
		map.connect("build_complete", self, "_on_map_build_completed")


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
		
	var map = get_qodot_map()
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
			
			var points = collision_shape.shape.points
			if points.size() != 8:
				return
			
			var centroid = _get_centroid(points)
			var abs_coord = (points[0] - centroid).abs()
			var epsilon = 0.05
			var is_a_box = true
			
			for i in range(1, 8):
				if ((points[i] - centroid).abs() - abs_coord).length_squared() > epsilon * epsilon:
					is_a_box = false
					break
			
			if !is_a_box:
				continue
			
			var box_shape = BoxShape.new()
			box_shape.extents = abs_coord
			
			collision_shape.shape = box_shape 
			collision_shape.position = centroid
			print_debug("Converted %s from ConvexShape to BoxShape" % collision_shape.name)


func _get_centroid(points : Array) -> Vector3:
	if points.empty():
		return Vector3.ZERO
	var centroid = Vector3.ZERO
	for p in points:
		centroid += p
	return centroid / points.size()
	


func get_qodot_map() -> QodotMap:
	return get_node_or_null(qodot_map_path) as QodotMap


func _on_map_build_completed():
	set_optimize(true)
