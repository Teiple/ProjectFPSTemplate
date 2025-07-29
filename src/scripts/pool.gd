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
	
	if _pool.has(poolable_node_component):
		return
	
	if reusable:
		var in_use_index = _in_use.find(poolable_node_component)
		if in_use_index > 0:
			_in_use.remove(in_use_index)
	
	node.get_parent().remove_child(node)
	# Destroy node if the pool is full
	if _pool.size() == max_pool_size:
		node.queue_free()
		_overflows += 1
		return
	
	poolable_node_component.disable_pooled_node()
	
	# Add back to pool
	add_child(node)
	_pool.push_back(poolable_node_component)


func take_from_pool(method : String = "", binds : Array = []) -> Node:
	var poolable_node_component : PoolableNodeComponent = null
	
	# Create new node if the pool is empty/depleted 
	if _pool.size() == 0:
		if reusable && _in_use.size() > 0:
			var least_recently_used = _in_use.pop_front()
			poolable_node_component = least_recently_used
			_hits += 1
		else:
			# The node will be used right away, don't add it too the pool
			poolable_node_component = _new_pooled_node()
			_misses += 1
	else:
		poolable_node_component = _pool.pop_back()
		_hits += 1
	
	poolable_node_component.enable_pooled_node()
	_in_use.push_back(poolable_node_component)
	
	var pooled_node = poolable_node_component.get_pooled_node()
	pooled_node.callv(method, binds)
	
	return pooled_node


func get_efficiency() -> float:
	var total = _hits + _misses
	return 1.0 if total == 0 else _hits / total


func get_pool_category() -> int:
	return pool_category
