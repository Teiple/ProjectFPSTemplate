tool
class_name WeaponRelativeTransformSaver
extends Node

export var target_path : NodePath = ""
export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var save_relative_transform : bool = false setget set_save_relative_transform
export var export_save_guard_end : bool = true setget set_export_save_guard_end

var _is_saving : bool = false


func set_export_save_guard_start(val):
	if val == false:
		return
	_is_saving = true


func set_export_save_guard_end(val):
	if val == false:
		return
	_is_saving = false


func set_save_relative_transform(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	
	var target = get_node_or_null(target_path) as Weapon
	if target == null:
		push_error("Target path was not valid.")
		return
	# This is discouraged since technically weapon_stats is a "private" variable
	# so I should have used getter, but weapon is not a tool script so its functions couldn't
	# be called from here 
	target.weapon_stats.view_model_relative_transform_from_hand = target.transform
	print_debug("Set relative transform.")
