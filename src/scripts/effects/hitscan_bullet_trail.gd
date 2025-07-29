class_name HitscanBulletTrail
extends Spatial

export var speed : float = 10
export var length : float = 0.5
export var speed_multiplier_min : float = 0.5
export var speed_multiplier_max : float = 1.0
export var scale_x_multiplier_min : float = 0.5
export var scale_x_multiplier_max : float = 1.0  
export var scale_z_multiplier_min : float = 0.5
export var scale_z_multiplier_max : float = 1.0  

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var mesh_instance : MeshInstance = $MeshInstance

var _start : Vector3
var _end : Vector3
var _direction : Vector3
var _current : Vector3
var _speed : float

func set_up(start : Vector3, end : Vector3):
	_start = start
	_end = end
	_direction = (end - start).normalized()
	
	# Don't show up if the distance is too short 
	if (end - start).length_squared() <= length:
		poolable_node_component.emit_signal("return_requested")
		return
	
	_current = _start + _direction * length
	global_position = _current
	
	if abs(Vector3.UP.dot(_direction)) > 0.8:
		look_at(_end, Vector3.RIGHT)
	else:
		look_at(_end, Vector3.UP)
	
	_speed = rand_range(speed_multiplier_min, speed_multiplier_max) * speed
	scale.x = rand_range(scale_x_multiplier_min, scale_x_multiplier_max)
	scale.z = rand_range(scale_z_multiplier_min, scale_z_multiplier_max)
	

func _process(delta):
	_current = _current.move_toward(_end, _speed * delta)
	global_position = _current
	
	if _current.is_equal_approx(_end):
		poolable_node_component.return_to_pool()
