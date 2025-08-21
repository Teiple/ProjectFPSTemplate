class_name WeaponProjectileComponent
extends Component

onready var _aim_raycast : RayCast = $AimRayCast

func launch(attack_origin_info : AttackOriginInfo) -> void:
	var projectile_pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.BULLET_PROJECTILE) as Pool
	if projectile_pool == null:
		return
	
	var start = attack_origin_info.fire_from
	var target = _get_randomized_target(
		attack_origin_info.aim_from,
		attack_origin_info.base_direction,
		attack_origin_info.max_distance,
		attack_origin_info.spread_angle_degrees,
		attack_origin_info.collision_mask)
	
	var direction = (target - start).normalized()
	
	# Modified for clearer direction here
	attack_origin_info.direction = direction
	
	var speed = attack_origin_info.projectile_speed
	var max_distance = attack_origin_info.max_distance
	var collision_mask = attack_origin_info.collision_mask
	
	projectile_pool.take_from_pool("set_up", [attack_origin_info])


func _get_randomized_target(from_position : Vector3, direction : Vector3, max_distance : float, angle_degrees : float, collision_mask : int) -> Vector3:
	_aim_raycast.global_position = from_position
	Utils.lookat_direction(_aim_raycast, direction)
	
	# Randomize cast angle
	var cast_to = Vector3.FORWARD * max_distance
	cast_to = cast_to.rotated(Vector3.UP, _get_random_spread_angle_radians(angle_degrees))
	cast_to = cast_to.rotated(Vector3.RIGHT, _get_random_spread_angle_radians(angle_degrees))
	
	_aim_raycast.cast_to = cast_to
	_aim_raycast.collision_mask = collision_mask
	_aim_raycast.force_raycast_update()
	
	if !_aim_raycast.is_colliding():
		return to_global(cast_to)
	
	return _aim_raycast.get_collision_point()


func _get_random_spread_angle_radians(angle_deg : float) -> float:
	var angle_rad = deg2rad(angle_deg)
	return rand_range(-angle_rad, angle_rad)


func _get_randomized_direction(direction : Vector3, angle_degrees : float) -> Vector3:
	var base_up = Vector3.UP
	if abs(direction.dot(base_up)) > 0.95:
		base_up = Vector3.RIGHT
	
	var up = direction.cross(base_up).normalized()
	var right = direction.cross(up).normalized()
	var angle_radians = deg2rad(angle_degrees)
	var rotated_direction = direction.rotated(up, rand_range(-angle_radians, angle_radians))
	rotated_direction = rotated_direction.rotated(right, rand_range(-angle_radians, angle_radians))
	return rotated_direction
	
