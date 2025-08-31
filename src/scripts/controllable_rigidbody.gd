class_name ControlableRigidbody
extends RigidBody

var _target_linear_velocity : Vector3 = Vector3.ZERO
var _target_angular_velocity : Vector3 = Vector3.ZERO
var _control_active : bool = false

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	if !_control_active:
		return
	
	var force = (_target_linear_velocity - state.linear_velocity) / state.step
	
	state.add_central_force(force)
	state.angular_velocity = _target_angular_velocity


func set_target_linear_velocity(value : Vector3) -> void:
	_target_linear_velocity = value


func set_target_angular_velocity(value : Vector3) -> void:
	_target_angular_velocity = value


func set_control_active(value : bool) -> void:
	_control_active = value
