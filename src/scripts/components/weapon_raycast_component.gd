class_name WeaponRaycastComponent
extends Component


export var physics_body_margin_offset : float = 0.038

onready var _raycast : RayCast = $RayCast

static func get_component_name() -> String:
	return "WeaponRaycastComponent"


func cast(attack_origin_info : AttackOriginInfo) -> AttackResultInfo:
	_raycast.global_position = attack_origin_info.from

	# Randomize cast angle
	var cast_to : Vector3 = _raycast.to_local(attack_origin_info.from + attack_origin_info.direction * attack_origin_info.max_distance)
	cast_to = cast_to.rotated(Vector3.UP, _get_random_spread_angle_radians(attack_origin_info.spread_angle_degrees))
	cast_to = cast_to.rotated(Vector3.RIGHT, _get_random_spread_angle_radians(attack_origin_info.spread_angle_degrees))
	
	_raycast.cast_to = cast_to
	_raycast.collision_mask = attack_origin_info.collision_mask
	_raycast.force_raycast_update()
	
	var result : AttackResultInfo = null
	if _raycast.is_colliding():
		result = AttackResultInfo.new()
		result.from = _raycast.global_position
		result.hit_point = _raycast.get_collision_point()
		result.hit_normal = _raycast.get_collision_normal()
		result.hit_object = _raycast.get_collider()
		result.impact_force = attack_origin_info.impact_force

		_play_bullet_trail(attack_origin_info, result.hit_point)
		_spawn_impact_effects(result.hit_point, result.hit_normal, result.hit_object)
	else:
		var global_dir =( _raycast.to_global(cast_to) - _raycast.global_position).normalized()
		var furthest_point = attack_origin_info.from + global_dir * attack_origin_info.max_distance
		_play_bullet_trail(attack_origin_info, furthest_point)
	
	return result


func _play_bullet_trail(origin_info: AttackOriginInfo, end_point: Vector3) -> void:
	var bullet_trail_pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.HITSCAN_BULLET_TRAIL)
	var start_point = origin_info.from
	if  origin_info.use_visual_origin:
		start_point = origin_info.visually_from
		var direction = end_point - start_point
		# Don't spawn bullet trail it goes the opposite direction
		# For example when the hitpoint is closer to player's camera than the muzzle position
		if origin_info.attacker_forward.dot(direction) < 0:
			return
	bullet_trail_pool.take_from_pool("set_up", [start_point, end_point])


func _get_random_spread_angle_radians(angle_deg : float) -> float:
	var angle_rad = deg2rad(angle_deg)
	return rand_range(-angle_rad, angle_rad)


func _spawn_impact_effects(hit_position : Vector3, hit_normal : Vector3, hit_object : Spatial):
	var pos = hit_position - hit_normal * physics_body_margin_offset
	var impact_pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_IMPACT_EFFECT) as Pool
	if impact_pool != null:
		impact_pool.take_from_pool("set_up", [pos, hit_normal])
	
	var decal_pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_BULLET_HOLE_DECAL) as Pool
	if decal_pool != null:
		if hit_object is RigidBody:
			decal_pool.take_from_pool("set_up", [pos, hit_normal, hit_object])
		else:
			decal_pool.take_from_pool("set_up", [pos, hit_normal, decal_pool])
