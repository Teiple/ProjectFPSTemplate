class_name GameWorld
extends Node

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func get_player_camera() -> Camera:
	var player : Player = get_node_or_null("Player") as Player
	if !player:
		return null
	else:
		return player.get_node_or_null("Head/Camera") as Camera


func get_player_weapon_controller() -> WeaponController:
	var player : Player = get_node_or_null("Player") as Player
	if !player:
		return null
	else:
		return player.get_node_or_null("Head/Arms/WeaponController") as WeaponController


func get_player() -> Player:
	return get_node_or_null("Player") as Player


func get_view_aspect() -> float:
	return get_viewport().size.x / get_viewport().size.y
