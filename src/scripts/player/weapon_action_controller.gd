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
	
	playback.travel(to)


func set_immediate_state(to : String):
	var animation_tree = _weapon_controller.get_current_weapon_animation_tree()
	if animation_tree == null:
		return
	var playback_path = "parameters/playback"
	var playback : AnimationNodeStateMachinePlayback = animation_tree[playback_path] as AnimationNodeStateMachinePlayback
	
	playback.start(to)
