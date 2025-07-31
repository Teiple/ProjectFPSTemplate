class_name ViewModelActionController
extends Node

const EVENTS_CONFIG : String = "events"
const ANY_STATE : String= "(any_state)"
const ANY_STATE_EXCEPT_TARGET : String = "(any_state_except_target)"
const INTERMEDIATE_SUFFIX : String = "_intermediate"
const LOCAL_TRANSITIONS : String = "local_animation_transition_subscribers"
const GLOBAL_TRANSITION_TARGET : String = "global_animation_transition_target"

export var weapon_controller_path : NodePath = ""
export var weapon_action_controller_path : NodePath = ""
export var animation_tree_path : NodePath = ""
export var animation_config_resource : Resource = null

var _weapon_controller : WeaponController = null
var _animation_tree : AnimationTree = null
var _weapon_action_controller : WeaponActionController = null
var _is_processing_pulse : bool = false

var _start_press_time : float = 0.0


func _ready():
	_weapon_controller = get_node(weapon_controller_path)
	_weapon_action_controller = get_node(weapon_action_controller_path)
	_animation_tree = get_node(animation_tree_path)
	
	# Process auto reload signal from WeaponController
	_weapon_controller.connect("auto_reload_requested", self, "_on_auto_reload_requested")
	# Process weapon changed signal from WeaponController
	_weapon_controller.connect("weapon_changed", self, "_on_weapon_changed")


func _process(delta):
	if Input.is_action_just_pressed("fire"):
		_start_press_time = FrameTime.process_time()
	
	# short_press determines rapid firing
	var short_press = FrameTime.process_time() - _start_press_time < _weapon_controller.get_current_weapon_fire_rate()
	
	# Rapid fire - fire without cool down due to fire rate
	if Input.is_action_just_released("fire") && short_press && _weapon_controller.can_rapid_fire_or_play_empty_click():
		# Must mark before fire event
		_weapon_controller.mark_fire()
		_trigger_event("fire")
		return
	
	# Reset _start_press_time when player finishes hold-firing
	if Input.is_action_just_released("fire"):
		print_debug("hi")
		_start_press_time = 0.0
	
	if Input.is_action_pressed("fire"):
		if !short_press:
			if _weapon_controller.can_fire_or_play_empty_click():
				# Must mark before fire event. Or else pressing triggers will overlap and anitiomation will always be stuck at the start
				_weapon_controller.mark_fire()
				_trigger_event("fire")
				return
	
	if Input.is_action_pressed("reload") && _weapon_controller.can_reload():
		_trigger_event("reload")
		return


func _on_auto_reload_requested():
	_trigger_event("reload")


func _on_weapon_changed():
	_trigger_event("equip")


func _trigger_event(event_name : String):
	var weapon_id = _weapon_controller.get_current_weapon_id()
	if weapon_id == "": # Empty string for unarmed
		return
	
	var global_playback = _animation_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
	if global_playback == null:
		return
	
	# Allow instant transition between multiple state machines for multiple weapons
	var last_weapon_id = global_playback.get_current_node()
	if last_weapon_id != weapon_id:
		var target = GameConfig.get_config_value(GlobalData.ConfigId.ANIMATION_CONFIG, [EVENTS_CONFIG, event_name, GLOBAL_TRANSITION_TARGET], "")
		if target == "":
			return
		else:
			_global_transition(weapon_id, target)
			return
	
	var transition_arr = GameConfig.get_config_value(GlobalData.ConfigId.ANIMATION_CONFIG, [EVENTS_CONFIG, event_name, LOCAL_TRANSITIONS], [])
	if !(transition_arr is Array) || transition_arr.empty():
		return
	
	for transition in transition_arr:
		if !(transition is String):
			continue
		# E.g: "idle/fire", "equip/idle", etc.
		var parts = transition.split("/")
		if parts.size() != 2:
			continue
		var from = parts[0]
		var to = parts[1]
		
		# Only one transition should be set at a time 
		if _try_local_transition(weapon_id, from, to):
			return


func _try_local_transition(weapon_id : String, from : String, to : String) -> bool:
	var weapon_playback : AnimationNodeStateMachinePlayback = _animation_tree["parameters/%s/playback" % weapon_id] as AnimationNodeStateMachinePlayback
	
	if weapon_playback == null:
		return false
	
	var current_state = weapon_playback.get_current_node()
	
	# Special case: "(any_state)" means doing transition right now
	# Special case: transition from any state other than the next state
	# BUG: There is a bug(?) where traveling into the same state for both parent and sub statemachine prevents sub statemachine from auto-advance
	if from == ANY_STATE || (from == ANY_STATE_EXCEPT_TARGET && current_state != to):
		weapon_playback.travel(to)
		_weapon_action_controller.set_travel_to_state(to)
		return true
	
	if current_state != from:
		return false
	
	if from == to:
		to = from + INTERMEDIATE_SUFFIX
	
	weapon_playback.travel(to)
	_weapon_action_controller.set_travel_to_state(to)
	
	return true


func _global_transition(weapon_id : String, to : String):
	var global_playback : AnimationNodeStateMachinePlayback = _animation_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
	var weapon_playback : AnimationNodeStateMachinePlayback = _animation_tree["parameters/%s/playback" % weapon_id] as AnimationNodeStateMachinePlayback
	
	if global_playback == null || weapon_playback == null:
		return
	
	global_playback.start(weapon_id)
	weapon_playback.start(to)
	_weapon_action_controller.set_immediate_state(to)
