extends Node

var _pools : Dictionary = {}

func _ready():
	for pool in get_children():
		if pool is Pool:
			var category = pool.get_pool_category()
			_pools[category] = pool


func get_pool_by_category(category : int) -> Pool:
	return _pools.get(category, null) as Pool


func get_info_str() -> String:
	var info = ""
	for pool in get_children():
		pool = pool as Pool
		if pool == null:
			continue
		
		info += "%s:\n%s\n" % [pool.name, pool.get_info_str()]
	return info
