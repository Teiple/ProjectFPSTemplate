tool
class_name ParticlesPreview
extends Node

export var export_save_guard_start : bool = true setget set_export_save_guard_start

export var preview := false setget set_preview

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


func set_preview(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	
	var parent = get_parent()
	if parent == null:
		return
	
	for child in parent.get_children():
		if child is CPUParticles || child is Particles:
			child.restart()
	
