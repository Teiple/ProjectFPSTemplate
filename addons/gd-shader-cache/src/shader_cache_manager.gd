extends Spatial

signal compiled(cache_path)

var _camera : Camera = null
var _compiled_cache_paths = []


func load_and_compile(cache_path):
	var cache_packed_scene = load(cache_path)
	compile(cache_packed_scene)


func compile(cache_packed_scene):
	var cache_path = cache_packed_scene.resource_path
	if is_compiled(cache_path):
		return
	
	var cache_scene = spawn_cache(cache_packed_scene)
	cache_scene.connect("compiled", self, "_on_cache_compiled", [cache_path, cache_scene])


func spawn_cache(cache_packed_scene):
	var cache_scene = cache_packed_scene.instance()
	var active_camera = get_active_camera()
	active_camera.add_child(cache_scene)
	cache_scene.global_position = active_camera.global_position - active_camera.global_transform.basis.z * 20.0
	cache_scene.geometry_scale = Vector3.ONE * 0.01
	
	return cache_scene


func is_compiled(cache_path):
	return cache_path in _compiled_cache_paths


func _on_cache_compiled(cache_path, cache_scene):
	_compiled_cache_paths.push_back(cache_path)
	if _camera != null:
		_camera.queue_free()
	else:
		cache_scene.queue_free()
	emit_signal("compiled", cache_path)


func get_active_camera():
	var active_camera = get_viewport().get_camera()
	if active_camera == null:
		_camera = Camera.new()
		add_child(_camera)
		_camera.current = true
		active_camera = _camera

	return active_camera
