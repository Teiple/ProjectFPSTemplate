extends Node

func resolve(attack_result_info : AttackResultInfo):
	var collider = attack_result_info.collider
	
	if collider == null:
		return
	
	var hit_normal = attack_result_info.hit_normal
	var hit_point = attack_result_info.hit_point
	var impact_force = attack_result_info.impact_force
	var hit_direction = attack_result_info.hit_direction
	
	# Decals
	var decal_pool : Pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_BULLET_HOLE_DECAL) as Pool
	if decal_pool != null:
		decal_pool.take_from_pool("set_up", [hit_point, hit_normal, collider])

	# Impact effect
	var impact_pool : Pool = PoolManager.get_pool_by_category(GlobalData.PoolCategory.DEFAULT_IMPACT_EFFECT)
	if impact_pool != null:
		impact_pool.take_from_pool("set_up", [hit_point, hit_normal])

	# Impact on physical objects
	if collider is RigidBody:
		var physical_comp = Component.find(collider, PhysicalObjectComponent.get_component_name()) as PhysicalObjectComponent
		if physical_comp != null:
			physical_comp.apply_impulse(hit_point, hit_direction, impact_force)
