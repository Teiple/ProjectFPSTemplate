class_name Decal
extends Spatial

export var life_time : float = 2.0

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent

var _start_time : float = 0.0


func set_up(position : Vector3, normal : Vector3):
	global_transform = Transform.IDENTITY
	global_position = position
	
	var dot = Vector3.UP.dot(normal)
	if abs(dot) > 0.95:
		if dot > 0:
			rotation.x = PI * 0.5
		else:
			rotation.x = -PI * 0.5
	else:
		look_at(position + normal, Vector3.UP)
	_start_time = FrameTime.process_time()
	rotate_object_local(Vector3.FORWARD, rand_range(-PI, PI))


func _process(delta):
	if FrameTime.process_time() - _start_time > life_time:
		poolable_node_component.return_to_pool()
