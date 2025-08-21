class_name PhysicalObjectComponent
extends Component

static func get_component_name() -> String:
	return "PhysicalObjectComponent" 


func get_physical_object() -> RigidBody:
	return owner as RigidBody


func apply_force(apply_position : Vector3, apply_direction : Vector3, apply_force : float) -> void:
	var physical_obj = get_physical_object()
	var local_point = physical_obj.to_local(apply_position)
	physical_obj.apply_impulse(local_point, apply_direction * apply_force)


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
