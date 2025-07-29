tool
class_name ScriptedEffect
extends Spatial

export var export_save_guard_start : bool = true setget _set_export_save_guard_start
export var restart : bool = false setget _set_restart 
export var export_save_guard_end : bool = true setget _set_export_save_guard_end

export var one_shot_effect : bool = true
export var trigger_node_path : NodePath = ""
export var signal_name : String = ""

var  _trigger_node : Node = null
var _is_saving : bool = false

func _ready():
	if Engine.editor_hint:
		return
	_trigger_node = get_node_or_null(trigger_node_path)
	if _trigger_node != null:
		_trigger_node.connect(signal_name, self, "restart")
	if one_shot_effect:
		for child in get_children():
			if child is Particles:
				child.one_shot = true

func _set_restart(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	restart()


func _set_export_save_guard_start(val):
	if val == false:
		return
	_is_saving = true


func _set_export_save_guard_end(val):
	if val == false:
		return
	_is_saving = false


func restart():
	for child in get_children():
		if child is Particles:
			child.restart()
