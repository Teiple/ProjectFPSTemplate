class_name BulletProjectile
extends Spatial
 
export var length : float = 0.5

export var scale_x_multiplier_min : float = 0.5
export var scale_x_multiplier_max : float = 1.0  
export var scale_z_multiplier_min : float = 0.5
export var scale_z_multiplier_max : float = 1.0  
export var physics_body_margin_offset : float = 0.038

onready var raycast : RayCast = $RayCast
onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var mesh_pivot : Spatial = $MeshPivot

var _raycast_collision_mask : int = 0
var _speed : float = 0.0
var _direction : Vector3 = Vector3.ZERO
var _traveled_distance : float = 0.0
var _max_distance : float = 0.0


func _ready():
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))


func serialize() -> Dictionary:
	return {
		"global_position": var2str(global_position),
		"collision_mask": _raycast_collision_mask,
		"speed": _speed,
		"direction": var2str(_direction),
		"traveled_distance": _traveled_distance,
		"max_distance": _max_distance
	}


func deserialize(data : Dictionary):
	var col_mask = data.get("collision_mask", 0)
	var speed = data.get("speed", 0)
	var dir = Utils.either(str2var(data.get("direction")), _direction)
	var max_dist = data.get("max_distance", 0.0)
	
	var cur_pos = Utils.either(str2var(data.get("global_position")), global_position)
	
	set_up(cur_pos, dir, speed, max_dist, col_mask)
	
	_traveled_distance = data.get("traveled_distance", 0.0)


func set_up(start : Vector3, direction : Vector3, speed : float, max_distance : float, collision_mask : int):
	global_position = start
	_direction = direction
	_speed = speed
	_max_distance = max_distance
	_traveled_distance = 0.0
	_raycast_collision_mask = collision_mask
	
	raycast.cast_to = Vector3(0, 0, -length)
	raycast.collision_mask = _raycast_collision_mask
	
	if abs(Vector3.UP.dot(_direction)) > 0.8:
		look_at(start + _direction, Vector3.RIGHT)
	else:
		look_at(start + _direction, Vector3.UP)
	
	# Randomzie visual
	mesh_pivot.scale.x = rand_range(scale_x_multiplier_min, scale_x_multiplier_max)
	mesh_pivot.scale.z = rand_range(scale_z_multiplier_min, scale_z_multiplier_max)
	
	# Initial check
	_check_and_collide()


func _physics_process(delta):
	if _check_and_collide():
		return
	if _traveled_distance >= _max_distance:
		poolable_node_component.return_to_pool()
		return
	global_position += _direction * _speed * delta
	_traveled_distance += _speed * delta


func _check_and_collide() -> bool:
	raycast.force_raycast_update()
	if raycast.is_colliding():
		poolable_node_component.return_to_pool()
		var decal_pool : Pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_BULLET_HOLE_DECAL) as Pool
		var impact_pool : Pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_IMPACT_EFFECT)
		
		var normal = raycast.get_collision_normal()
		var pos = raycast.get_collision_point() - normal * physics_body_margin_offset
		
		if decal_pool != null:
			decal_pool.take_from_pool("set_up", [pos, normal])
		if impact_pool != null:
			impact_pool.take_from_pool("set_up", [pos, normal])
		return true
	return false
