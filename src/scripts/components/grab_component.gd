## Require a AutoPushComponent from the player to detect collision
## between the player and the holding object
## Require ViewModelActionController to call this
class_name GrabComponent
extends Spatial

enum Axis {
	RIGHT = 0,
	LEFT = 1,
	UP = 2,
	DOWN = 3,
	BACK = 4,
	FORWARD = 5,
}

signal object_released

export var _drop_distance : float = 1.0
export var _max_distance : float = 2.0
export var _max_speed : float = 5.0
export var _follow_speed : float = 10.0
export var _angular_follow_speed : float = 10.0
export var _min_time_before_drop_check : float = 1.0
export(int, LAYERS_3D_PHYSICS) var _pin_joint_pin_mask : int = 0
export var _ammo_collector_path : NodePath = ""

onready var _raycast : RayCast = $RayCast
onready var _grab_position : Spatial = $GrabPosition
onready var _pin_joint: PinJoint = $GrabPosition/PinJoint
onready var _pin_join_pin: KinematicBody = $GrabPosition/PinJointPin

var _current_physical_comp : PhysicalObjectComponent = null
var _grab_start_time : float = 0.0
var _auto_push_component : AutoPushComponent = null
var _ammo_collector : AmmoCollector = null


func _ready() -> void:
	_raycast.cast_to = Vector3.FORWARD * _max_distance
	_pin_joint.set_node_a(_pin_joint.get_path_to(_pin_join_pin))
	_ammo_collector = get_node(_ammo_collector_path) as AmmoCollector


func toggle_grabbing():
	if _current_physical_comp != null:
		_release_object()
		_current_physical_comp = null
	else:
		_try_grab_object()


func is_grabbing():
	return _current_physical_comp != null


func _try_grab_object() -> bool:
	_raycast.force_raycast_update()
	
	if !_raycast.is_colliding():
		return false
	
	var collider = _raycast.get_collider()
	# See if AmmoCollector recognize this object as a WeaponDrop
	if _ammo_collector.try_collect(collider):
		return false
	
	
	if !(collider is RigidBody):
		return false
	
	var physical_comp = Component.find(collider, PhysicalObjectComponent.get_component_name()) as PhysicalObjectComponent
	if physical_comp == null:
		return false
	
	var physical_obj = physical_comp.get_physical_object()
	var physical_obj_position = physical_obj.global_position
	_current_physical_comp = physical_comp
	_current_physical_comp.set_physical_object_gravity(false)
	
	_grab_start_time = FrameTime.process_time()
	
	physical_obj.global_position = _pin_joint.global_position
	
	_pin_join_pin.set_as_toplevel(true)
	_pin_join_pin.global_position = _grab_position.global_position
	_pin_join_pin.add_collision_exception_with(physical_obj)
	_pin_join_pin.collision_mask = _pin_joint_pin_mask
	_pin_joint.set_node_b(_pin_joint.get_path_to(physical_obj))
	
	physical_obj.global_position = physical_obj_position
	
	return true


func _physics_process(delta: float) -> void:
	global_transform = _get_player().get_camera_global_transform()
	
	if _current_physical_comp == null:
		return
	# Lazy load this component since we were ready before Player was 
	if _auto_push_component == null:
		_auto_push_component = _get_player_auto_push_component()
	
	var cur_pin_pos = _pin_join_pin.global_position
	var cur_phys_obj_pos = _current_physical_comp.get_physical_object_position()
	
	if FrameTime.process_time() - _grab_start_time >= _min_time_before_drop_check:
		var distance_squared = (_grab_position.global_position - cur_phys_obj_pos).length_squared()
		if distance_squared >= _drop_distance * _drop_distance:
			_release_object()
			return
	
	var target_veloc = (_grab_position.global_position - cur_pin_pos) * _follow_speed
	
	var physical_obj = _current_physical_comp.get_physical_object()

	if _auto_push_component.will_on_top_of(physical_obj, target_veloc * delta):
		_release_object()
		return
	
	if !_auto_push_component.will_colliding_with(physical_obj, cur_pin_pos - cur_phys_obj_pos):
		_pin_join_pin.move_and_slide(target_veloc, Vector3.UP)
	
	var target_ang_veloc = Vector3.ZERO
	if !_current_physical_comp.is_colliding_with_others():
		target_ang_veloc = _orientate_physical_object()
	_current_physical_comp.set_physical_object_angular_velocity(target_ang_veloc * _angular_follow_speed)


func _release_object() -> void:
	var physical_obj = _current_physical_comp.get_physical_object()
	
	_pin_join_pin.remove_collision_exception_with(physical_obj)
	_pin_join_pin.collision_mask = 0
	_pin_join_pin.set_as_toplevel(false)
	_pin_joint.set_node_b("")
	
	_current_physical_comp.set_physical_object_gravity(true)
	_current_physical_comp = null
	
	emit_signal("object_released")


func _get_player() -> Player:
	return Global.get_game_world().get_player()


func _get_player_auto_push_component() -> AutoPushComponent:
	var player = _get_player()
	var auto_push_comp =  Component.find(_get_player(), AutoPushComponent.get_component_name()) as AutoPushComponent
	if auto_push_comp == null:
		push_error("AutoPushComponent couldn't be found on Player. GrabComponent requires AutoPushComponent to check collisions between them and the holding object.")
		return null
	return auto_push_comp


func _orientate_physical_object() -> Vector3:
	var physical_obj = _current_physical_comp.get_physical_object()
	
	var target_back_axis = _grab_position.global_transform.basis.z
	var target_up_axis = _grab_position.global_transform.basis.y
	
	var axes = {
		Axis.RIGHT : physical_obj.global_transform.basis.x,
		Axis.LEFT : -physical_obj.global_transform.basis.x,
		Axis.UP : physical_obj.global_transform.basis.y,
		Axis.DOWN : -physical_obj.global_transform.basis.y,
		Axis.BACK : physical_obj.global_transform.basis.z,
		Axis.FORWARD : -physical_obj.global_transform.basis.z,
	}
	
	var opposite_axes = {
		Axis.LEFT : Axis.RIGHT,
		Axis.RIGHT : Axis.LEFT,
		Axis.DOWN : Axis.UP,
		Axis.UP : Axis.DOWN,
		Axis.FORWARD : Axis.BACK,
		Axis.BACK : Axis.FORWARD,
	}
	
	var nearest_back_axis = _get_nearest_axis(target_back_axis, axes)
	axes.erase(nearest_back_axis)
	axes.erase(opposite_axes[nearest_back_axis])
	var nearest_up_axis = _get_nearest_axis(target_up_axis, axes)
	axes.clear()
	
	var current_quat = Quat(physical_obj.global_transform.basis)
	
	var new_basis_axes = {
		Axis.RIGHT : null,
		Axis.UP : null,
		Axis.BACK : null,
	}
	
	if nearest_back_axis in [Axis.RIGHT, Axis.UP, Axis.BACK]:
		new_basis_axes[nearest_back_axis] = target_back_axis
	else:
		new_basis_axes[opposite_axes[nearest_back_axis]] = -target_back_axis
	
	if nearest_up_axis in [Axis.RIGHT, Axis.UP, Axis.BACK]:
		new_basis_axes[nearest_up_axis] = target_up_axis
	else:
		new_basis_axes[opposite_axes[nearest_up_axis]] = -target_up_axis
	
	if new_basis_axes[Axis.RIGHT] == null:
		new_basis_axes[Axis.RIGHT] = new_basis_axes[Axis.BACK].cross(new_basis_axes[Axis.UP]).normalized()
	elif new_basis_axes[Axis.UP] == null:
		new_basis_axes[Axis.UP] = new_basis_axes[Axis.BACK].cross(new_basis_axes[Axis.RIGHT]).normalized()
	elif new_basis_axes[Axis.BACK] == null:
		new_basis_axes[Axis.BACK] = new_basis_axes[Axis.RIGHT].cross(new_basis_axes[Axis.UP]).normalized()
	
	var target_quat = Quat(Basis(new_basis_axes[Axis.RIGHT], new_basis_axes[Axis.UP], new_basis_axes[Axis.BACK]))
	
	return (target_quat * current_quat.inverse()).get_euler()


func _get_nearest_axis(target_axis : Vector3, axes : Dictionary) -> int:
	var max_dot = -1.0
	var result = Axis.BACK
	for local_axis in axes.keys():
		var axis = axes[local_axis]
		var dot = target_axis.dot(axis)
		if dot > max_dot:
			result = local_axis
			max_dot = dot
	return result
