class_name Pool
extends Node

export var max_pool_size : int = 0
export(Array, PackedScene) var source_scenes : Array = []
export(GlobalData.PoolCategory) var pool_category : int = GlobalData.PoolCategory.HITSCAN_BULLET_TRAIL
export var reusable : bool = false

var _hits : int = 0
var _misses : int = 0
var _overflows : int = 0

# Array of PoolableNodeComponent
var _pool : Array = []
var _in_use : Array = []


func _ready():
	if source_scenes.size() == 0:
		return
	
	for i in max_pool_size:
		var poolable_node_component = _new_pooled_node()
		# If source scene does not have PoolableNodeComponent, it is not poolable
		if poolable_node_component == null:
			return
		_pool.push_back(poolable_node_component)


func _get_random_source_scene() -> PackedScene:
	return source_scenes.pick_random()


func _new_pooled_node() -> PoolableNodeComponent:
	var instance = _get_random_source_scene().instance()
	add_child(instance)
	
	var poolable_node_component : PoolableNodeComponent = Component.find_component(instance, PoolableNodeComponent.get_component_name()) as PoolableNodeComponent
	if poolable_node_component == null:
		remove_child(instance)
		instance.queue_free()
		return null
	
	poolable_node_component.disable_pooled_node()
	poolable_node_component.connect("return_requested", self, "_on_return_requested", [instance, poolable_node_component])
	
	return poolable_node_component


func _on_return_requested(node : Node, poolable_node_component : PoolableNodeComponent):
	if node == null || poolable_node_component == null:
		return
	
	if !is_instance_valid(node) || !is_instance_valid(poolable_node_component):
		push_error("how could this happen?")
		return
	
	if _pool.has(poolable_node_component):
		return
	
	var in_use_index = _in_use.find(poolable_node_component)
	if in_use_index >= 0:
		# If non-reusable, then order isn't important
		# It's faster to swap it with the last element and pop_back()
		if !reusable:
			var last = _in_use.back()
			_in_use[in_use_index] = last
			_in_use.pop_back()
		else:
			_in_use.remove(in_use_index)
	
	node.get_parent().remove_child(node)
	# Destroy node if the pool is full
	if _pool.size() == max_pool_size:
		if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
			if _pool.has(poolable_node_component):
				print_debug("overflow deleted: ", poolable_node_component)
		node.queue_free()
		_overflows += 1
		return
	
	poolable_node_component.disable_pooled_node()
	
	# Add back to pool
	add_child(node)
	_pool.push_back(poolable_node_component)
	if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
		print_debug("push back: ", poolable_node_component)


func take_from_pool(method : String = "", binds : Array = [], out_poolable_comp = null) -> Node:
	var poolable_node_component : PoolableNodeComponent = null
	
	var new_node = false
	# Create new node if the pool is empty/depleted 
	if _pool.size() == 0:
		if reusable && _in_use.size() == max_pool_size && _first_in_use_node_valid_or_pop_front():
			var least_recently_used = _in_use.pop_front()
			poolable_node_component = least_recently_used
			_hits += 1
		else:
			# The node will be used right away, don't add it too the pool
			poolable_node_component = _new_pooled_node()
			_misses += 1
			new_node = true
	else:
		if !_back_pool_node_valid_or_pop_back():
			# This shouldn't happen. The way it could happen
			# is to have a "sleeping" pooled node destroyed itself,
			# which I didn't remember being done to any of the pooled node
			if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
				print_debug("how could this happen?")
			return null
		if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
			print_debug("popped back: ", _pool.back())
		poolable_node_component = _pool.pop_back()
		_hits += 1
	
	poolable_node_component.enable_pooled_node()
	_in_use.push_back(poolable_node_component)
	
	var pooled_node = poolable_node_component.get_pooled_node()
	
	if method != "":
		pooled_node.callv(method, binds)
	
	if out_poolable_comp is Array:
		out_poolable_comp.push_back(poolable_node_component)
	
	return pooled_node


func get_efficiency() -> float:
	var total = _hits + _misses
	return 1.0 if total == 0 else float(_hits) / float(total)


func get_pool_category() -> int:
	return pool_category


func serialize_state() -> Dictionary:
	var state = {"active_nodes" : []}
	for poolable_node_comp in _in_use:
		if !is_instance_valid(poolable_node_comp):
			continue
		poolable_node_comp = poolable_node_comp as PoolableNodeComponent
		if poolable_node_comp == null:
			continue
		
		var node_data = poolable_node_comp.serialize()
		state["active_nodes"].push_back(node_data)
	return state


func _free_all_in_use():
	if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
		print_debug("_in_use: ", _in_use)
	for poolable_node_comp in _in_use:
		if !is_instance_valid(poolable_node_comp):
			continue
		poolable_node_comp = poolable_node_comp as PoolableNodeComponent
		if poolable_node_comp == null:
			continue
		
		var node = poolable_node_comp.get_pooled_node()
		if node == null:
			continue
		
		if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
			print_debug("freed: ", poolable_node_comp)
		
		node.queue_free()
	
	_in_use.clear()


# Ensure front of _in_use is valid.
# pop_front() is very inefficient, so ensure
# they are explicitly returned to the pool instead of self-freeing.
func _first_in_use_node_valid_or_pop_front() -> bool:
	if _in_use.empty():
		return false
	if is_instance_valid(_in_use.front()):
		return true
	_in_use.pop_front()
	return false


func _back_pool_node_valid_or_pop_back() -> bool:
	if _pool.empty():
		print_debug("it's just empty, don't worry")
		return false
	if is_instance_valid(_pool.back()):
		return true
	if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
		print_debug(_pool)
	_pool.pop_back()
	return false


func deserialize_state(state : Dictionary):
	if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
		print_debug("deserialize")
	if state.empty():
		return
	var active_nodes = state.get("active_nodes", [])
	if !(active_nodes is Array):
		return
	
	if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
		print_debug(_pool)
		print_debug("free")
	
	_free_all_in_use()
	
	var poolable_arr : Dictionary = {}
	
	for i in active_nodes.size():
		var out_poolable_node_comp : Array = []
		take_from_pool("", [], out_poolable_node_comp)
		if out_poolable_node_comp.empty():
			continue
		var poolable_node_comp = out_poolable_node_comp[0]
		if poolable_node_comp == null:
			continue
		
		# Deserialization must be done later to not conflict with take_from_pool()
		poolable_arr[poolable_node_comp] = active_nodes[i]
	
	if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
		print_debug("end first loop")
	
	for poolable in poolable_arr:
		poolable.deserialize(poolable_arr[poolable])
	
	if pool_category == GlobalData.PoolCategory.BULLET_PROJECTILE:
		print_debug("end deserialize")


func get_info_str() -> String:
	return "eff: %.2f;\nhits: %d;\nmisses: %d;\novers: %d" % [get_efficiency(), _hits, _misses, _overflows]
