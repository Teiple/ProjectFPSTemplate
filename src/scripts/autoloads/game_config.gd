class_name GameConfig

const _config_list : Dictionary = {
	GlobalData.ConfigId.ANIMATION_CONFIG : AnimationConfig.config,
	GlobalData.ConfigId.WEAPON_CONFIG : WeaponConfig.config,
}


static func get_config(config_id : int) -> Dictionary:
	return _config_list.get(config_id)


static func get_config_value(config_id : int, path : Array, default_value = null):
	var config_ref = _config_list.get(config_id)
	
	if config_ref == null || config_ref.empty():
		return default_value
	
	if !(path is Array) || path.size() == 0 || config_ref == null:
		return default_value
	
	var path_stack = path.duplicate()
	path_stack.invert()
	var current_value = config_ref
	
	while current_value != null && path_stack.size() > 0:
		if !(current_value is Dictionary):
			return default_value
		current_value = current_value.get(path_stack.pop_back(), null)
	
	if current_value == null:
		return default_value
	else:
		return current_value
