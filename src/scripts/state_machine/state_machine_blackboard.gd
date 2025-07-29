class_name StateMachineBlackboard
extends Node

var _blackboard : Dictionary = {}

func set_entry(key : String, value):
	_blackboard[key] = value

func get_entry(key: String):
	return _blackboard.get(key, null)
