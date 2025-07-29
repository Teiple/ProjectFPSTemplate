tool
class_name ViewModelAnimationSpace
extends Spatial

# Prevent running other setters/getters when saving this script
export var editor_save_guard_start : bool = true setget _set_editor_save_guard_start

export var view_model_scene : PackedScene = preload("res://src/scenes/player/view_model.tscn")
export var save_animation_player : bool = false setget _set_save_animation_player
# Insert loop mode and callbacks of animations from old override animation player 
export var insert_changes : bool = false setget _set_insert_changes
export var clear_callbacks : bool = false setget _set_clear_callbacks
export var reimport_view_model : bool = false setget _set_reimport_view_model
export var config_resource : Resource = null

# Prevent running other setters/getters when saving this script
export var editor_save_guard_end : bool = true setget _set_editor_save_guard_end

var _is_script_saving : bool = false

class MethodTrack:
	var animation : String = ""
	var track_idx : int = 0
	var path : String = ""
	var keys : Array = []
	var key_times : Dictionary = {}
	var methods : Dictionary = {}
	var params : Dictionary = {}


func _set_editor_save_guard_start(val):
	# If you are trying to turn this off manually, it won't count 
	if val == false:
		return
	_is_script_saving = true


func _set_editor_save_guard_end(val):
	# If you are trying to turn this off manually, it won't count 
	if val == false:
		return
	_is_script_saving = false


func _set_reimport_view_model(val):
	if !Engine.editor_hint || !is_node_ready() || _is_script_saving:
		return
	
	var old_view_model = get_node_or_null("ViewModel")
	if old_view_model != null:
		old_view_model.free()
	
	var view_model = view_model_scene.instance()
	add_child(view_model, true)
	_make_local(view_model)
	
	print_debug("Reimported.")


func _get_saving_directory() -> String:
	return GameConfig.get_config_value(GlobalData.ConfigId.ANIMATION_CONFIG, ["animation_player", "saving_directory"], "")


func _get_saving_name() -> String:
	return GameConfig.get_config_value(GlobalData.ConfigId.ANIMATION_CONFIG, ["animation_player", "saving_name"], "")


func _make_local(node : Node):
	for child in node.get_children():
		_make_local(child)
	node.filename = ""
	node.owner = self

func _set_clear_callbacks(val):
	if !Engine.editor_hint || !is_node_ready() || _is_script_saving:
		return
	
	var animation_player = get_animation_player()
	
	var path = _get_saving_directory() + "/" + _get_saving_name()
	if !ResourceLoader.exists(path):
		push_error("Replacer doesn't exists.")
		return
	
	var animation_arr = Array(animation_player.get_animation_list())
	
	var tracks_removed = 0
	for animation_name in animation_arr:
		var animation = animation_player.get_animation(animation_name)
		for track_idx in animation.get_track_count():
			if animation.track_get_type(track_idx) == Animation.TYPE_METHOD:
				animation.remove_track(track_idx)
				tracks_removed += 1
	
	print_debug("%d track(s) removed." % tracks_removed)


# Hope you understand this, future me.
func _set_insert_changes(val):
	var animation_player = get_animation_player()
	
	if !Engine.editor_hint || !is_node_ready() || _is_script_saving || animation_player == null:
		return
	
	var path = _get_saving_directory() + "/" + _get_saving_name()
	if !ResourceLoader.exists(path):
		push_error("Replacer doesn't exists.")
		return
	
	var override_animation_player_scene = ResourceLoader.load(path) as PackedScene
	var override_animation_player = override_animation_player_scene.instance() as AnimationPlayer
	var animation_arr = Array(override_animation_player.get_animation_list())
	
	var method_tracks = []
	
	for animation_name in animation_arr:
		var animation = override_animation_player.get_animation(animation_name)
		for track_idx in animation.get_track_count():
			if animation.track_get_type(track_idx) != Animation.TYPE_METHOD:
				continue
			
			var method_track = MethodTrack.new()
			method_track.animation = animation_name
			method_track.track_idx = track_idx
			method_track.path = animation.track_get_path(track_idx)
			
			# Didn't know why animation.method_track_get_key_indices(track_idx, 0, animation.length) didn't work
			var keys = range(animation.track_get_key_count(track_idx))
			method_track.keys = Array(keys)
			
			for key_idx in keys:
				var params = animation.method_track_get_params(track_idx, key_idx)
				method_track.params[key_idx] = params
				method_track.key_times[key_idx] = animation.track_get_key_time(track_idx, key_idx)
				method_track.methods[key_idx] = animation.method_track_get_name(track_idx, key_idx)
			
			method_tracks.push_back(method_track)
	
	var tracks_added = 0
	for track in method_tracks:
		var animation = animation_player.get_animation(track.animation)
		if animation == null:
			continue
		
		var duplicated = false
		for t in animation.get_track_count():
			if animation.track_get_type(t) == Animation.TYPE_METHOD && animation.track_get_path(t) == track.path:
				duplicated = true
				break
		if duplicated:
			print_debug("Skip duplicated track '%s' in animation '%s'" % [track.path, track.animation])
			continue
		
		var target_track_idx = animation.add_track(Animation.TYPE_METHOD)
		
		for key_idx in track.keys:
			animation.track_set_path(target_track_idx, track.path)
			animation.track_insert_key(target_track_idx, track.key_times[key_idx], {
				"method": track.methods[key_idx],
				"args": track.params[key_idx]
			} )
		
		tracks_added += 1
	
	override_animation_player.queue_free()
	print_debug("%d track(s) added." % tracks_added)
	
	# Apply loops
	for animation in animation_arr:
		if animation_player.has_animation(animation):
			var anim_player_loop = animation_player.get_animation(animation).loop
			var override_anim_player_loop = override_animation_player.get_animation(animation).loop
			if anim_player_loop != override_anim_player_loop:
				animation_player.get_animation(animation).loop = override_animation_player.get_animation(animation).loop
				print_debug("Set loop mode of '" + animation + "' to " + str(override_anim_player_loop))


func _set_save_animation_player(val):
	var animation_player = get_animation_player()
	
	if !Engine.editor_hint || !is_node_ready() || _is_script_saving || animation_player == null:
		return
	
	var animation_player_packed = PackedScene.new()
	animation_player_packed.pack(animation_player)
	
	var path = _get_saving_directory() + "/" + _get_saving_name()
	
	var error = ResourceSaver.save(path, animation_player_packed)
	if error != OK:
		push_error("Cannot save.")
		return
	
	print_debug("Saved.")


func get_animation_player() -> AnimationPlayer:
	 return get_node_or_null("ViewModel/AnimationPlayer") as AnimationPlayer
