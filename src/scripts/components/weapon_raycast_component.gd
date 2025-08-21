class_name WeaponRaycastComponent
extends Component

export var physics_body_margin_offset : float = 0.038

onready var _raycast : RayCast = $RayCast


static func get_component_name() -> String:
	return "WeaponRaycastComponent"


func cast(attack_origin_info : AttackOriginInfo) -> void:
	_raycast.global_position = attack_origin_info.aim_from
	Utils.lookat_direction(_raycast, attack_origin_info.base_direction)
	
	# Randomize cast angle
	var cast_to = Vector3.FORWARD * attack_origin_info.max_distance 
	cast_to = cast_to.rotated(Vector3.UP, _get_random_spread_angle_radians(attack_origin_info.spread_angle_degrees))
	cast_to = cast_to.rotated(Vector3.RIGHT, _get_random_spread_angle_radians(attack_origin_info.spread_angle_degrees))
	
	_raycast.cast_to = cast_to
	_raycast.collision_mask = attack_origin_info.collision_mask
	_raycast.force_raycast_update()
	
	if _raycast.is_colliding():
		var attack_result_info = AttackResultInfo.new()
		var randomized_direction = _raycast.global_transform.basis.xform(cast_to).normalized()
		attack_result_info.hit_point = _raycast.get_collision_point()
		attack_result_info.hit_normal = _raycast.get_collision_normal()
		attack_result_info.hit_direction = randomized_direction
		attack_result_info.collider = _raycast.get_collider()
		attack_result_info.impact_force = attack_origin_info.impact_force

		_play_bullet_trail(attack_origin_info, attack_result_info.hit_point)
		AttackResolver.resolve(attack_result_info)
	else:
		var global_dir =( _raycast.to_global(cast_to) - _raycast.global_position).normalized()
		var furthest_point = attack_origin_info.aim_from + global_dir * attack_origin_info.max_distance
		
		_play_bullet_trail(attack_origin_info, furthest_point)


func _play_bullet_trail(origin_info: AttackOriginInfo, end_point: Vector3) -> void:
	var bullet_trail_pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.HITSCAN_BULLET_TRAIL)
	var start_point = origin_info.fire_from
	
	var direction = end_point - start_point
	# Don't spawn bullet trail it goes the opposite direction
	# For example when the hitpoint is closer to player's camera than the muzzle position
	if origin_info.attacker_forward.dot(direction) < 0:
		return
	
	bullet_trail_pool.take_from_pool("set_up", [start_point, end_point])


func _get_random_spread_angle_radians(angle_deg : float) -> float:
	var angle_rad = deg2rad(angle_deg)
	return rand_range(-angle_rad, angle_rad)
