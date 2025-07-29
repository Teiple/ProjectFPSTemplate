extends Node

# Process and Physics process time in seconds
var _process_time := 0.0
var _physics_process_time := 0.0
var _frame_count := 0


func _process(delta):
	_process_time += delta
	_frame_count += 1


func _physics_process(delta):
	_physics_process_time += delta


func frame_count():
	return _frame_count


func process_time():
	return _process_time


func physics_process_time():
	return _physics_process_time
