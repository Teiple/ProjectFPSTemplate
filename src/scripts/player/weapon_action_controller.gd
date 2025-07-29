class_name WeaponActionController
extends Node


export var weapon_controller_path : NodePath = ""

var _weapon_controller : WeaponController = null


func _ready():
	_weapon_controller = get_node(weapon_controller_path)


func __set_transition(from : String, to : String):
	var animation_tree = _weapon_controller.get_current_weapon_animation_tree()
	if animation_tree == null:
		return
	var playback_path = "parameters/playback"
	var playback : AnimationNodeStateMachinePlayback = animation_tree[playback_path] as AnimationNodeStateMachinePlayback
	#if playback.get_current_node() != from:
	#	push_warning("Weapon animation is out of sync: View model: %s; Weapon: %s" % [from, playback.get_current_node()])
	if from == to:
		playback.travel(from + "_intermediate")
	else:
		playback.travel(to)


func set_travel_to_state(to : String):
	var animation_tree = _weapon_controller.get_current_weapon_animation_tree()
	if animation_tree == null:
		return
	var playback_path = "parameters/playback"
	var playback : AnimationNodeStateMachinePlayback = animation_tree[playback_path] as AnimationNodeStateMachinePlayback
	
	playback.travel(to)


func set_immediate_state(to : String):
	var animation_tree = _weapon_controller.get_current_weapon_animation_tree()
	if animation_tree == null:
		return
	var playback_path = "parameters/playback"
	var playback : AnimationNodeStateMachinePlayback = animation_tree[playback_path] as AnimationNodeStateMachinePlayback
	
	playback.start(to)
