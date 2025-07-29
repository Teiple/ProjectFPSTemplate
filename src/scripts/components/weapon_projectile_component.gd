class_name WeaponProjectileComponent
extends Component


func launch(attack_origin_info : AttackOriginInfo):
	var projectile_pool : Pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.BULLET_PROJECTILE) as Pool
	if projectile_pool == null:
		return
	
	var start = attack_origin_info.from
	var direction = _get_randomized_direction(attack_origin_info.direction, attack_origin_info.spread_angle_degrees)
	var speed = attack_origin_info.projectile_speed
	var max_distance = attack_origin_info.max_distance
	var collision_mask = attack_origin_info.collision_mask
	
	projectile_pool.take_from_pool("set_up", [start, direction, speed, max_distance, collision_mask])


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
	
