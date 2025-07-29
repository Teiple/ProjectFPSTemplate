tool
extends Node
class_name AnimationStateMachineGenerator

enum Target {
	PLAYER_ANIMATION,
	WEAPON_ANIMATION,
}

export var export_save_guard_start : bool = true setget _set_export_save_guard_start

export var weapon_id : String = "pistol"
export(Target) var target : int = Target.PLAYER_ANIMATION
export var create_animation_state_machine : bool = false setget _set_create_animation_state_machine

export var export_save_guard_end : bool = true setget _set_export_save_guard_end

var  _is_script_saving : bool = false


func _set_export_save_guard_start(val):
	if val == false:
		return
	_is_script_saving = true


func _set_export_save_guard_end(val):
	if val == false:
		return
	_is_script_saving = false


func _set_create_animation_state_machine(val):
	if !Engine.editor_hint || !is_node_ready() || _is_script_saving:
		return
	
	_create_state_machine(weapon_id, target)


func _get_config_value(path : Array, default_value):
	return GameConfig.get_config_value(GlobalData.ConfigId.ANIMATION_CONFIG, path, default_value)


func _create_state_machine(weapon_id: String, target : int):
	var state_machine = AnimationNodeStateMachine.new()
	
	var animation_config : Dictionary = _get_config_value(["state_machine", "animations"], null)
	var saving_directory : String = ""
	var saving_name : String = ""
	
	if animation_config == null:
		push_error("Animation config didn't have 'state_machine/animations' configuration.")
		return
	
	match target:
		Target.PLAYER_ANIMATION:
			saving_directory = _get_config_value(["state_machine", "saving_directory", "player"], "")
			saving_name = _get_config_value(["state_machine", "saving_name", "player"], "")
		Target.WEAPON_ANIMATION:
			saving_directory = _get_config_value(["state_machine", "saving_directory", "weapon"], "")
			saving_name = _get_config_value(["state_machine", "saving_name", "weapon"], "")
	
	saving_name = saving_name.replace("$(weapon_id)", weapon_id)
	
	if saving_directory.empty() || saving_name.empty():
		push_error("Saving path is invalid.")
		return
	
	for name in animation_config:
		if !(name is String) || name.empty():
			continue
		
		var node = AnimationNodeAnimation.new()
		
		match target:
			Target.PLAYER_ANIMATION:
				node.animation = name + "_" + weapon_id
			Target.WEAPON_ANIMATION:
				var fallback = _get_config_value(["animation_fallbacks", weapon_id, name], "")
				if !fallback.empty():
					node.animation = "weapon_" + fallback + "_" + weapon_id
				else:
					node.animation = "weapon_" + name + "_" + weapon_id
			_:
				node.animation = ""
		
		state_machine.add_node(name, node, animation_config[name]["pos"])
	
	for from in animation_config:
		for transition in animation_config[from]["transitions"]:
			var trans_node = AnimationNodeStateMachineTransition.new()
			match transition["mode"]:
				"immediate":
					trans_node.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
				"at_end":
					trans_node.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
					trans_node.auto_advance = true
			
			if from == transition["to"]:
				var intermediate_node = AnimationNodeAnimation.new()
				intermediate_node.animation = from + "_intermediate"
				
				state_machine.add_node(from + "_intermediate", intermediate_node, animation_config[from]["pos"] + Vector2(100, 0))
				
				state_machine.add_transition(from, from + "_intermediate", trans_node)
				
				var next_trans_node = AnimationNodeStateMachineTransition.new()
				next_trans_node.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
				next_trans_node.auto_advance = true
				
				state_machine.add_transition(from + "_intermediate", transition["to"], next_trans_node)
			else:
				state_machine.add_transition(from, transition["to"], trans_node)
	
	var path = saving_directory + "/" + saving_name
	
	var error = ResourceSaver.save(path, state_machine)
	if error != OK:
		push_error("Couldn't save.")
		return
	
	print_debug("Saved.")
