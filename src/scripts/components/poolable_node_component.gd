class_name PoolableNodeComponent
extends Component

signal return_requested


var _serialization_func_ref : FuncRef  = null
var _deserialization_func_ref : FuncRef  = null


static func get_component_name() -> String:
	return "PoolableNodeComponent"


func get_pooled_node() -> Node:
	return owner as Node


func disable_pooled_node():
	var node = get_pooled_node()
	if node == null:
		return
	
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_unhandled_input(false)
	
	if node is Spatial:
		node.visible = false


func enable_pooled_node():
	var node = get_pooled_node()
	if node == null:
		return
	
	node.set_process(true)
	node.set_physics_process(true)
	node.set_process_unhandled_input(true)
	
	if node is Spatial:
		node.visible = true


func return_to_pool():
	emit_signal("return_requested")


func init_serialization_func(func_ref : FuncRef):
	_serialization_func_ref = func_ref


func init_deserialization_func(func_ref : FuncRef):
	_deserialization_func_ref = func_ref


func serialize() -> Dictionary:
	if _serialization_func_ref == null:
		return {}
	return _serialization_func_ref.call_func()


func deserialize(data : Dictionary):
	if _deserialization_func_ref == null:
		return {}
	return _deserialization_func_ref.call_func(data)
