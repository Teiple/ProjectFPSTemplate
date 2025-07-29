class_name PoolableNodeComponent
extends Component

signal return_requested


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
