tool
class_name QodotMapDecalMeshBuilder
extends Node

export var qodot_map_path : NodePath = ""
export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var build_decal_meshes := false setget set_build_decal_meshes
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


func set_build_decal_meshes(val):
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
			var shape = collision_shape.shape as ConvexPolygonShape
			var debug_mesh = shape.get_debug_mesh() as ArrayMesh
			var mesh_arrays = debug_mesh.surface_get_arrays(0)
			for i in mesh_arrays.size():
				print_debug(mesh_arrays[i])
			print_debug("--")


func get_qodot_map() -> QodotMap:
	return get_node_or_null(qodot_map_path) as QodotMap


func _on_map_build_completed():
	print_debug("done building.")
