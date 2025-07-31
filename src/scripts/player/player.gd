class_name Player
extends KinematicBody

const HEAD_OFFSET := 0.5
const STAND_HEIGHT := 1.7
const CROUCH_HEIGHT := 1.3
const CROUCH_SMOOTH_SPEED := 10.0

export var mouse_sensitivity := 0.1
export var move_speed := 4.0
export var gravity := -9.8
export var jump_height := 0.5
export var accel := 5.0
export var decel := 10.0
export var drag := 2.0
export var air_accel := 10.0
export var crouch_speed := 7.0
export var floor_max_angle := 50.0
export var jump_buffer := 0.2
export var coyote_time := 0.3

var _velocity := Vector3.ZERO
var _position_last_frame := Vector3.ZERO
var _rotation_x_degrees := 0.0
var _real_velocity := Vector3.ZERO
var _last_jump_pressed_time := 0.001
var _last_time_on_ground := 0.001
var _is_crouching := false
var _current_height := STAND_HEIGHT

onready var head : Spatial = $Head
onready var player_camera : Camera = $Head/Camera
onready var collision_shape : CollisionShape = $CollisionShape
onready var stand_up_shape_cast : ShapeCast = $StandUpShapeCast


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_rotation_yaw(-event.relative.x * mouse_sensitivity)
		_rotation_x_degrees -= event.relative.y * mouse_sensitivity
		_rotation_x_degrees = clamp(_rotation_x_degrees, -89.0, 89.0)
		head.rotation.x = deg2rad(_rotation_x_degrees)
	if event.is_action_pressed("crouch_toggle"):
		_is_crouching = !_is_crouching
		if !_is_crouching:
			# You can't stand up if something is above you
			stand_up_shape_cast.force_shapecast_update()
			if stand_up_shape_cast.is_colliding():
				_is_crouching = false


func _physics_process(delta):
	_update_crouching(delta)
	
	## Movement
	var direction := Vector3.ZERO

	var forward := -transform.basis.z
	var right := transform.basis.x

	var move_input := Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	direction += forward * move_input.y
	direction += right * move_input.x
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
	
	var h_velocity := Vector3(_velocity.x, 0, _velocity.z)
	var target_h_velocity := Vector3.ZERO
	
	var snap_vector = Vector3(0, -0.1, 0)
	
	if is_on_floor():
		target_h_velocity = direction * move_speed
		if Input.is_action_pressed("jump") || (_last_jump_pressed_time > 0 && FrameTime.physics_process_time() - _last_jump_pressed_time <= jump_buffer):
			_velocity.y = _get_jump_speed()
			snap_vector = Vector3.ZERO
		else:
			_velocity.y = -0.15
		if h_velocity.length_squared() <= 0.25 && target_h_velocity.length_squared() <= 0.01:
			snap_vector = Vector3.ZERO
		# Invalidate jump buffer
		_last_jump_pressed_time = -1
		# Tracking for coyote time
		_last_time_on_ground = FrameTime.physics_process_time()
	else:
		snap_vector = Vector3.ZERO
		# Coyote time allows to jump if you pressed jump a little too lately
		if Input.is_action_pressed("jump") && _velocity.y < 0 && _last_time_on_ground > 0 && FrameTime.physics_process_time() - _last_time_on_ground <= coyote_time:
			_velocity.y = _get_jump_speed()
			_last_time_on_ground = -1
		else:
			# Jump buffer allows you to jump if you pressed jump a little too early
			if Input.is_action_pressed("jump"):
				_last_jump_pressed_time = FrameTime.physics_process_time()
			
			_velocity.y += gravity * delta
			h_velocity *= clamp(1.0 - drag * delta, 0, 1)
			target_h_velocity = h_velocity + direction * air_accel * delta
			if target_h_velocity.length_squared() <= 0.025:
				target_h_velocity = Vector3.ZERO
			if target_h_velocity.length_squared() >= move_speed * move_speed:
				target_h_velocity = target_h_velocity.normalized() * move_speed
	
	if target_h_velocity.length_squared() < 0.025:
		h_velocity = h_velocity.linear_interpolate(Vector3.ZERO, decel * delta)
		if h_velocity.length_squared() < 0.01:
			h_velocity = Vector3.ZERO
	else:
		h_velocity = h_velocity.linear_interpolate(target_h_velocity, accel * delta)
	_velocity = Vector3(h_velocity.x, _velocity.y, h_velocity.z) 
	_position_last_frame = global_position
	
	var was_on_floor = is_on_floor()
	var player_last_pos = global_position
	
	var old_position = global_position
	_velocity.y = move_and_slide_with_snap(_velocity, snap_vector, Vector3.UP, true, 4, deg2rad(floor_max_angle), true).y
	var new_position = global_position
	
	if (new_position - old_position).length_squared() > 1e-8:
		_real_velocity = (new_position - old_position) / delta
	else:
		_real_velocity = Vector3.ZERO


func _update_crouching(delta : float):
	var target_height = CROUCH_HEIGHT if _is_crouching else STAND_HEIGHT
	_current_height = move_toward(_current_height, target_height, crouch_speed * delta)
	_resize_capsule_collision(_current_height)
	head.position.y = lerp(head.position.y, _current_height - HEAD_OFFSET, CROUCH_SMOOTH_SPEED * delta)


func _get_jump_speed() -> float:
	return sqrt(2.0 * jump_height * abs(gravity))


func _rotation_yaw(amount):
	rotation_degrees.y += amount


func _resize_capsule_collision(new_height : float):
	var capsule_shape : CapsuleShape = collision_shape.shape as CapsuleShape
	if capsule_shape == null:
		return
	if abs((capsule_shape.height + capsule_shape.radius * 2.0) - new_height) < 0.0001:
		return
	capsule_shape.height = new_height - capsule_shape.radius * 2.0
	collision_shape.position.y = new_height * 0.5


func get_position_from_last_frame():
	return _position_last_frame


func get_camera_horizontal_fov() -> float:
	var v_fov = deg2rad(player_camera.fov)
	var aspect = get_viewport().size.x / get_viewport().size.y
	var h_fov = 2.0 * atan(tan(v_fov / 2.0) * aspect)
	return h_fov


func get_camera_vertical_fov() -> float:
	return deg2rad(player_camera.fov)


func get_camera() -> Camera:
	return player_camera


func is_player_on_floor() -> bool:
	return is_on_floor()


func is_moving() -> bool:
	return (_real_velocity * Vector3(1, 0, 1)).length_squared() >= 0.01


func get_real_velocity() -> Vector3:
	return _real_velocity


func serialize_state() -> Dictionary:
	return {
		"position": var2str(global_position),
		"rotation_y": rotation.y,
		"rotation_x_degrees": _rotation_x_degrees,
		"velocity": var2str(_velocity),
		"is_crouching": _is_crouching,
		"current_height": _current_height
	}


func deserialize_state(state: Dictionary) -> void:
	global_position = Utils.either(str2var(state.get("position")), global_position)
	rotation.y = state.get("rotation_y", rotation.y)
	_rotation_x_degrees = state.get("rotation_x_degrees", _rotation_x_degrees)
	head.rotation.x = deg2rad(_rotation_x_degrees)
	
	_velocity = Utils.either(str2var(state.get("velocity")), _velocity)
	_is_crouching = state.get("is_crouching", _is_crouching)
	_current_height = state.get("current_height", _current_height)
	head.position.y = _current_height - HEAD_OFFSET
	_resize_capsule_collision(_current_height)
