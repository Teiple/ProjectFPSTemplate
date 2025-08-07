class_name BulletProjectile
extends Spatial
 
export var length : float = 0.5

export var scale_x_multiplier_min : float = 0.5
export var scale_x_multiplier_max : float = 1.0  
export var scale_z_multiplier_min : float = 0.5
export var scale_z_multiplier_max : float = 1.0  
export var physics_body_margin_offset : float = 0.04

onready var raycast : RayCast = $RayCast
onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var mesh_pivot : Spatial = $MeshPivot

var _speed : float = 0.0
var _direction : Vector3 = Vector3.ZERO
var _traveled_distance : float = 0.0
var _max_distance : float = 0.0
var _origin_position : Vector3 = Vector3.ZERO
var _impact_force : float = 0.0


func _ready():
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))


func serialize() -> Dictionary:
	return {
		"global_transform": var2str(global_transform),
		"collision_mask": raycast.collision_mask,
		"speed": _speed,
		"direction": var2str(_direction),
		"traveled_distance": _traveled_distance,
		"max_distance": _max_distance,
		"origin_position" : var2str(_origin_position),
	}


func deserialize(data : Dictionary):
	raycast.collision_mask = data.get("collision_mask", 0)
	_speed = data.get("speed", 0)
	_direction = Utils.either(str2var(data.get("direction")), _direction)
	_max_distance = data.get("max_distance", 0.0)
	_traveled_distance = data.get("traveled_distance", 0.0)
	_origin_position = Utils.either(str2var(data.get("origin_position")), _origin_position)
	
	global_transform = Utils.either(str2var(data.get("global_transform")), global_transform)
	
	_randomize_visual()
	if _check_and_collide():
		visible = false
		poolable_node_component.return_to_pool()


func set_up(attack_origin : AttackOriginInfo):
	global_position = attack_origin.from
	_direction = attack_origin.direction
	_speed = attack_origin.projectile_speed
	_max_distance = attack_origin.max_distance
	_traveled_distance = 0.0
	_origin_position = attack_origin.from
	_impact_force = attack_origin.impact_force
	
	raycast.cast_to = Vector3(0, 0, -length)
	raycast.collision_mask = attack_origin.collision_mask
	if abs(Vector3.UP.dot(_direction)) > 0.8:
		look_at(attack_origin.from + _direction, Vector3.RIGHT)
	else:
		look_at(attack_origin.from + _direction, Vector3.UP)
	
	# Randomize visual
	_randomize_visual()
	# Initial check
	if _check_and_collide():
		visible = false
		poolable_node_component.return_to_pool()


func _randomize_visual():
	mesh_pivot.scale.x = rand_range(scale_x_multiplier_min, scale_x_multiplier_max)
	mesh_pivot.scale.z = rand_range(scale_z_multiplier_min, scale_z_multiplier_max)


func _physics_process(delta):
	if _traveled_distance >= _max_distance || _check_and_collide():
		poolable_node_component.return_to_pool()
		return
	global_position += _direction * _speed * delta
	_traveled_distance += _speed * delta


func _check_and_collide() -> bool:
	raycast.force_raycast_update()
	if !raycast.is_colliding():
		return false
	visible = false
	
	var attack_result = AttackResultInfo.new()
	attack_result.hit_point = raycast.get_collision_point()
	attack_result.hit_normal = raycast.get_collision_normal()
	attack_result.hit_direction = _direction
	attack_result.from = _origin_position
	attack_result.impact_force = _impact_force
	
	var collider = raycast.get_collider()
	var collision_normal = raycast.get_collision_normal()
	# StaticBody uses margin while Rigidbody doesn't, what the heck?
	var collision_point_rigid = raycast.get_collision_point()
	var collision_point_static = collision_point_rigid - collision_normal * physics_body_margin_offset
	
	# DebugDraw.draw_sphere(collision_point, 0.02, Color.red, 4.0)
	
	# Decals
	var decal_pool : Pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_BULLET_HOLE_DECAL) as Pool
	if decal_pool != null:
		if collider is RigidBody:
			decal_pool.take_from_pool("set_up", [collision_point_rigid, collision_normal, collider])
		else:
			decal_pool.take_from_pool("set_up", [collision_point_static, collision_normal, decal_pool])
	
	# Impact effect
	var impact_pool : Pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_IMPACT_EFFECT)
	if impact_pool != null:
		# I use static collision point since if it cane be offseted a bit further in all cases
		impact_pool.take_from_pool("set_up", [collision_point_rigid, collision_normal])
	
	# Impact on physical objects
	if collider is RigidBody:
		var physical_comp = Component.find_component(collider, PhysicalObjectComponent.get_component_name()) as PhysicalObjectComponent
		if physical_comp != null:
			physical_comp.apply_force(attack_result)
		
		poolable_node_component.return_to_pool()
	
	return true
