class_name PlayerHud
extends Control

onready var ammo_counter : Control = $AmmoCounter

# To track current weapon's ammo
var _weapon_controller : WeaponController = null

func _ready():
	_weapon_controller = Global.get_game_world().get_player_weapon_controller()


func _process(delta):
	_update_ammo_counter()


func _update_ammo_counter():
	if _weapon_controller == null:
		return
	
	# Weapon id is empty if player is unarmed
	var ammo_label = ammo_counter.get_node("AmmoCounterValue") as Label
	
	if _weapon_controller.get_current_weapon_id() == "":
		ammo_label.text = ""
		return
	
	var ammo_pattern = "%d/%d"
	var weapon_ammo = _weapon_controller.get_current_weapon_current_ammo()
	var reserve_ammo = _weapon_controller.get_current_weapon_reserve_ammo()
	
	ammo_label.text = ammo_pattern % [weapon_ammo, reserve_ammo]
