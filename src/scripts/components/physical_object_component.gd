class_name PhysicalObjectComponent
extends Component

onready var contact_check: ShapeCast = $ContactCheck

static func get_component_name() -> String:
	return "PhysicalObjectComponent" 


func get_physical_object() -> RigidBody:
	return owner as RigidBody


func apply_impulse(apply_position : Vector3, apply_direction : Vector3, apply_force : float) -> void:
	var physical_obj = get_physical_object()
	physical_obj.apply_impulse(apply_position - global_position, apply_direction * apply_force)


func apply_force(apply_position : Vector3, apply_direction : Vector3, apply_force : float) -> void:
	var physical_obj = get_physical_object()
	physical_obj.add_force(apply_direction * apply_force, apply_position - global_position)


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


func set_physical_object_continuous_detection(enabled : bool):
	var physical_object = get_physical_object()
	
	physical_object.continuous_cd = enabled


func set_physical_object_gravity(enabled : bool) -> void:
	var physical_obj = get_physical_object()
	physical_obj.gravity_scale = 1.0 if enabled else 0.0


func set_physical_object_linear_velocity(velocity : Vector3) -> void:
	var physical_obj = get_physical_object()
	physical_obj.linear_velocity = velocity


func set_physical_object_angular_velocity(velocity : Vector3) -> void:
	var physical_obj = get_physical_object()
	physical_obj.angular_velocity = velocity


func get_physical_object_linear_velocity() -> Vector3:
	var physical_obj = get_physical_object()
	return physical_obj.linear_velocity


func get_physical_object_angular_velocity() -> Vector3:
	var physical_obj = get_physical_object()
	return physical_obj.angular_velocity


func get_physical_object_position() -> Vector3:
	var physical_obj = get_physical_object()
	return physical_obj.global_position


func is_colliding_with_others() -> bool:
	var physical_obj = get_physical_object()
	
	contact_check.add_exception(physical_obj)
	
	for child in physical_obj.get_children():
		var collision_shape = child as CollisionShape
		if collision_shape == null:
			continue
		
		contact_check.global_transform = collision_shape.global_transform
		contact_check.shape = collision_shape.shape
		contact_check.force_shapecast_update()
		if contact_check.is_colliding():
			return true
	
	return false
