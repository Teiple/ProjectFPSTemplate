tool
class_name QodotMapPostProcessPipeline
extends Node

export var qodot_map_path : NodePath = ""

export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var rerun_all_post_processes := false setget set_rerun_all_post_processes
export var export_save_guard_end : bool = true setget set_export_save_guard_end

var _is_saving := false


func set_export_save_guard_start(val) -> void:
	if val == false:
		return
	_is_saving = true


func set_export_save_guard_end(val) -> void:
	if val == false:
		return
	_is_saving = false


func set_rerun_all_post_processes(val) -> void:
	_on_map_build_completed()


func _ready() -> void:
	if !Engine.editor_hint:
		queue_free()
		return
	
	var map = get_qodot_map()
	if map != null && !map.is_connected("build_complete", self, "_on_map_build_completed"):
		map.connect("build_complete", self, "_on_map_build_completed")


func get_qodot_map() -> QodotMap:
	return get_node_or_null(qodot_map_path) as QodotMap


func _on_map_build_completed() -> void:
	var map = get_qodot_map()
	if map == null:
		return
	for child in get_children():
		var post_process = child as QodotMapPostProcess
		if post_process != null:
			post_process.set_qodot_map(map)
			post_process.do_stuff()
