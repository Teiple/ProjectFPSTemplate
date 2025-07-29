extends Node
class_name ViewModelMotionController

export var mouse_sensitivity := 0.001
export var sway_smooth_speed := 5.0
export var sway_max_x_angle := 2.0
export var sway_max_y_angle := 2.0
export var head_bob_max_y := 0.005


var _mouse_x := 0.0
var _mouse_y := 0.0
var _bob_y := 0.0
var _bob_reset_speed := 1.0
var _view_model : Spatial = null
var _player : Player = null
var _view_model_initial_position : Vector3 = Vector3.ZERO


func _ready():
	_player = Global.get_game_world().get_player()
	_view_model = owner.get_node_or_null("ViewModel") as Spatial
	_view_model_initial_position = _view_model.position


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_mouse_x = event.relative.x * mouse_sensitivity
		_mouse_y = event.relative.y * mouse_sensitivity


func _process(delta):
	if _player.is_player_on_floor() && _player.is_moving():
		_bob_y += _player.get_real_velocity().length() * 3.0 * delta
	else:
		if _bob_y > TAU:
			_bob_y -= int(_bob_y / TAU) * TAU
		_bob_y = lerp(_bob_y, PI/2, _bob_reset_speed * delta)
	var max_x_rad = deg2rad(sway_max_x_angle)
	var max_y_rad = deg2rad(sway_max_y_angle)
	_view_model.rotation.y = clamp(lerp(_view_model.rotation.y, -_mouse_x, sway_smooth_speed * delta), -max_y_rad, max_y_rad)  
	_view_model.rotation.x = clamp(lerp(_view_model.rotation.x, -_mouse_y, sway_smooth_speed * delta), -max_x_rad, max_x_rad)
	_view_model.position.y = _view_model_initial_position.y + sin(_bob_y) * head_bob_max_y - head_bob_max_y
