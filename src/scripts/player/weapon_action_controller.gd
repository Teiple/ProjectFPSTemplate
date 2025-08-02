class_name WeaponActionController
extends Node


export var weapon_controller_path : NodePath = ""

var _weapon_controller : WeaponController = null


func _ready():
	_weapon_controller = get_node(weapon_controller_path)


func set_travel_to_state(to : String):
	var animation_tree = _weapon_controller.get_current_weapon_animation_tree()
	if animation_tree == null:
		return
	var playback_path = "parameters/playback"
	var playback : AnimationNodeStateMachinePlayback = animation_tree[playback_path] as AnimationNodeStateMachinePlayback
	
	# In case of loading, animation tree won't have starting point
	# so it cannot travel
	if playback.is_playing():
		playback.travel(to)
	else:
		playback.start(to)


func set_immediate_state(to : String):
	var animation_tree = _weapon_controller.get_current_weapon_animation_tree()
	if animation_tree == null:
		return
	var playback_path = "parameters/playback"
	var playback : AnimationNodeStateMachinePlayback = animation_tree[playback_path] as AnimationNodeStateMachinePlayback
	
	playback.start(to)
