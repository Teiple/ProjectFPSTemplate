class_name LoadingData

var _mutex : Mutex = null
var _resouce_path : String = ""
var _stage_passed : int = 0
var _stage_count : int = 0
var _result = null


func set_result(result):
	if _mutex == null:
		return
	_mutex.lock()
	_result = result
	_mutex.unlock()


func get_result():
	if _mutex == null:
		return
	_mutex.lock()
	var res = _result
	_mutex.unlock()
	return res


func set_mutex(mutex : Mutex):
	_mutex = mutex


func get_mutex() -> Mutex:
	return _mutex


func set_resource_path(path : String):
	_resouce_path = path


func get_resource_path() -> String:
	return _resouce_path


func set_stage_passed(stage_passed : int):
	if _mutex == null:
		return
	_mutex.lock()
	_stage_passed = stage_passed
	_mutex.unlock()


func get_stage_passed() -> int:
	if _mutex == null:
		return 0
	_mutex.lock()
	var passed = _stage_passed
	_mutex.unlock()
	return passed


func set_stage_count(stage_count : int):
	if _mutex == null:
		return 0
	_mutex.lock()
	_stage_count = stage_count
	_mutex.unlock()


func get_stage_count() -> int:
	if _mutex == null:
		return 0
	_mutex.lock()
	var count = _stage_passed
	_mutex.unlock()
	return count


func get_progress() -> float:
	if _mutex == null:
		return 0.0
	_mutex.lock()
	var progress = float(_stage_passed) / float(_stage_count - 1) if _stage_count > 0 else 0.0 
	_mutex.unlock()
	return progress
