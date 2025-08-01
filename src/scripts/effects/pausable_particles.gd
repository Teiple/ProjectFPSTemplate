class_name PausableParticles
extends CPUParticles

const LIFE_TIME_OFFSET := 0.1

var _last_restart := 0.0
var _is_emitting := false


func _ready():
	one_shot = true
	add_to_group(GlobalData.Group.PARTICLES)


func pause():
	speed_scale = 0.0


func unpause():
	speed_scale = 1.0


func trigger_restart(should_preprocess : bool = false):
	if should_preprocess:
		preprocess = FrameTime.process_time() - _last_restart
	else:
		preprocess = 0.0
	_last_restart = FrameTime.process_time()
	_is_emitting = true
	set_process(true)
	restart()


func set_last_restart(val : float):
	_last_restart = val


func get_last_restart() -> float:
	return _last_restart


func _process(delta):
	if FrameTime.process_time() - _last_restart >= get_life_time():
		_is_emitting = false
		set_process(false)


func get_is_emitting() -> bool:
	return _is_emitting


func set_is_emitting(val : bool):
	_is_emitting = val


func get_life_time():
	return lifetime + LIFE_TIME_OFFSET
