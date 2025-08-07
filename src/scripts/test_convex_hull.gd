tool
extends Node

export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var preview := false setget set_preview
export var preview_this_step := false setget set_preview_this_step
export var step := 0 setget set_step
export var export_save_guard_end : bool = true setget set_export_save_guard_end

var _is_saving := false
var _verts := []


func _ready():
	if Engine.editor_hint:
		return
	_verts = get_randomized_verts(20)
	p()


func get_randomized_verts(n : int) -> Array:
	var res = []
	for i in n:
		res.push_back(Vector3(
			rand_range(-10.0, 10.0),
			rand_range(-10.0, 10.0),
			rand_range(-10.0, 10.0)
		))
	return res

func set_export_save_guard_start(val):
	if val == false:
		return
	_is_saving = true


func set_export_save_guard_end(val):
	if val == false:
		return
	_is_saving = false


func set_preview(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	_verts = get_randomized_verts(20)
	p()


func set_preview_this_step(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	p()


func set_step(val):
	step = max(val, 0)
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	p()


func p():
#	for v in _verts:
#		DebugDraw.draw_sphere(v, 0.1, Color.green, 5.0)
	get_mesh_ins().mesh = ConvexHull.create_convex_mesh(_verts, step)


func get_mesh_ins():
	return $MeshInstance
