extends Node

const SHADER_CACHE_SCENE : PackedScene = preload("res://src/scenes/shader_cache.scn")

var _loading_thread : Thread = null
var _is_loading : bool = false
var _loading_mutex : Mutex = null
var _loading_data : LoadingData = null

var _current_scene : Node = null

var _any_key_pressed : bool = false
var _last_any_key_pressed : float = 0.0

onready var fps_label : Label = $"%FPSLabel"
onready var pool_info_label : Label = $"%PoolInfoLabel"


func get_game_world() -> GameWorld:
	return _current_scene as GameWorld


func _unhandled_input(event) -> void:
	if event is InputEventKey && event.is_pressed():
		_any_key_pressed = true
		_last_any_key_pressed = FrameTime.process_time()


func _ready() -> void:
	# Let this node run even when the tree is paused
	pause_mode = Node.PAUSE_MODE_PROCESS 
	
	var last_idx = get_tree().root.get_child_count() - 1
	_current_scene = get_tree().root.get_child(last_idx)
	
	_loading_thread = Thread.new()
	_loading_mutex = Mutex.new()


func _process(delta) -> void:
	fps_label.text = str(int(Engine.get_frames_per_second()))
	pool_info_label.text = PoolManager.get_info_str()


func load_scene(path : String):
	var packed_scene = ResourceLoader.load(path)
	call_deferred("_load_scene", packed_scene, true)


func _load_scene(packed_scene : PackedScene, no_shader_cache : bool = false):
	# Unload current scene
	if _current_scene == null:
		return
	_current_scene.queue_free()
	
	if packed_scene == null:
		return
	var scene = packed_scene.instance()
	if scene == null:
		return
	
	_current_scene = scene
	if no_shader_cache:
		var shader_cache = _current_scene.get_node_or_null("ShaderCache")
		shader_cache.queue_free()
	# Add this last since some _ready() methods may reference _current_scene
	get_tree().root.add_child(scene)


func load_scene_async(scene_path : String) -> void:
	if _is_loading:
		push_error("Loading thread is busy. Couldn't load resouce at path '%s'" % scene_path)
		return
	
	_is_loading = true
	
	_loading_data = LoadingData.new()
	_loading_data.set_resource_path(scene_path)
	_loading_data.set_mutex(_loading_mutex)
	
	_loading_thread.start(self, "_load_scene_interactive")


func cache_shaders() -> void:
	ShaderCacheManager.compile(SHADER_CACHE_SCENE)


func _load_scene_interactive() -> void:
	var interactive_loader : ResourceInteractiveLoader = ResourceLoader.load_interactive(_loading_data.get_resource_path())
	_loading_data.set_stage_count(interactive_loader.get_stage_count())
	# I'm using a custom stage counter here instead of ResourceInteractiveLoader.get_stage() because ResourceInteractiveLoader.get_stage() will never exceed interactive_loader.get_stage_count() - 1
	var stage = 0
	while stage <= interactive_loader.get_stage_count() - 1:
		print_debug("Stage: %d" % stage)
		_loading_data.set_stage_passed(stage)
		interactive_loader.poll()
		stage += 1
	print_debug("Completed.")
	_is_loading = false
	
	_loading_data.set_result(interactive_loader.get_resource())


func load_pending_scene():
	if _loading_data == null:
		return
	call_deferred("_load_scene", _loading_data.get_result())


func _exit_tree():
	if _loading_thread != null && _loading_thread.is_active():
		_loading_thread.wait_to_finish()


func get_loading_progress() -> float:
	if _loading_data == null:
		return 0.0
	return _loading_data.get_progress()


func is_loading_complete() -> bool:
	return !_is_loading && _loading_data != null && _loading_data.get_result() != null


func quit(exit_code : int = -1):
	get_tree().quit(exit_code)


func set_tree_pause(paused : bool):
	get_tree().paused = paused
	# Set pausing for particles
	for particles in get_tree().get_nodes_in_group(GlobalData.Group.PARTICLES):
		particles = particles as PausableParticles
		if particles == null:
			return
		if paused:
			particles.pause()
		else:
			particles.unpause()


func is_tree_paused() -> bool:
	return get_tree().paused


func save_everything():
	var saveables = get_tree().get_nodes_in_group(GlobalData.Group.SAVEABLE)
	var save = {}
	
	for state_comp in saveables:
		state_comp = state_comp as GameStateComponent
		if state_comp == null:
			continue
		var state_data = state_comp.save_state()
		var section = GlobalData.SAVE_SECTION_MAP.get(state_comp.save_section_id, "")
		var label = state_comp.get_label()
		if section == "":
			if label == "":
				continue
			else:
				save[label] = state_data
		else:
			if label == "":
				save[section] = state_data
			else:
				if !save.has(section): 
					save[section] = { label: state_data }
				else:
					save[section][label] = state_data
	
	GameState.write_save(save, GameState.SLOT_NEW)


func load_everything():
	if Global.is_tree_paused():
		push_error("Cannot load while the game is paused. Deserialization may immediately return nodes without a frame delay and causes reuse conflicts.")
		return
	
	var saveables = get_tree().get_nodes_in_group(GlobalData.Group.SAVEABLE)
	var save = GameState.load_save(GameState.SLOT_LATEST)
	
	for state_comp in saveables:
		state_comp = state_comp as GameStateComponent
		if state_comp == null:
			continue
		var section = GlobalData.SAVE_SECTION_MAP.get(state_comp.save_section_id, "")
		var label = state_comp.get_label()
		var state_data = {}
		if section == "":
			if label == "":
				continue
			else:
				state_data = save.get(label, {})
		else:
			if label == "":
				state_data = save.get(section, {})
			else:
				state_data = save.get(section, {}).get(label, {})
		
		if state_data.empty():
			continue
		
		state_comp.load_state(state_data)
