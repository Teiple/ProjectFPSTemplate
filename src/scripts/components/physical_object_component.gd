class_name PhysicalObjectComponent
extends Component

static func get_component_name() -> String:
	return "PhysicalObjectComponent" 


func get_physical_object() -> RigidBody:
	return owner as RigidBody


func apply_force(attack_result : AttackResultInfo):
	var physical_obj = get_physical_object()
	var hit_point = attack_result.hit_point
	var direction = attack_result.hit_direction
	var force = attack_result.impact_force
	var local_point = physical_obj.to_local(hit_point)
	physical_obj.apply_impulse(local_point, direction * force)


func serialize_state() -> Dictionary:
	var physical_object = get_physical_object()
	return {
		"global_transform": var2str(physical_object.global_transform),
		"linear_velocity": var2str(physical_object.linear_velocity),
		"angular_velocity": var2str(physical_object.angular_velocity),
	}


func deserialize_state(state : Dictionary):
	var physical_object = get_physical_object()
	
	physical_object.global_transform = Utils.either(str2var(state.get("global_transform")), physical_object.global_transform)
	physical_object.linear_velocity =  Utils.either(str2var(state.get("linear_velocity")), physical_object.linear_velocity)
	physical_object.angular_velocity =  Utils.either(str2var(state.get("angular_velocity")), physical_object.angular_velocity)
