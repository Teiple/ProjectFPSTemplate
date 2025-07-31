class_name AmmoInventory
extends Node

# weapon_id : String -> current reserve ammo : int
export var _ammo_pool : Dictionary = {}


func get_reserve_ammo(weapon_id: String) -> int:
	return _ammo_pool.get(weapon_id, 0)


func _add_reserve_ammo(weapon_id: String, amount : int):
	_ammo_pool[weapon_id] = get_reserve_ammo(weapon_id) + amount


# Expecting amount to never exceed the reserve ammo
func _consume_reserve_ammo(weapon_id: String, amount: int) -> int:
	var available = get_reserve_ammo(weapon_id)
	var used = min(available, amount)
	_ammo_pool[weapon_id] = available - used
	return used


func reload_weapon(weapon: Weapon):
	if weapon == null:
		return
	
	var weapon_id = weapon.get_weapon_stats().weapon_id
	var reserve = get_reserve_ammo(weapon_id)
	
	if reserve == 0:
		return # Don't have ammo to reload
	
	var used = weapon.reload(reserve)
	_consume_reserve_ammo(weapon_id, used)


# Take ammo from a free weapon and return the amount it take 
func take_weapon_ammo(weapon : Weapon) -> int:
	if weapon == null:
		return 0
	
	var weapon_id = weapon.get_weapon_stats().weapon_id
	var amount =  weapon.get_current_ammo()
	_add_reserve_ammo(weapon_id, amount)
	return amount


# Fake current ammo provide a simulation of the ability to reload weapon at a specific ammo level.
# Mainly used for auto reload, which does some check before the actual firing.
func can_reload_weapon(weapon : Weapon, fake_current_ammo : int = -1) -> bool:
	if weapon == null:
		return false
	
	var weapon_current_ammo = fake_current_ammo if fake_current_ammo > 0 else weapon.get_current_ammo()
	
	# Weapon is already fully loaded
	if weapon_current_ammo == weapon.get_weapon_stats().mag_size:
		return false
	
	var weapon_id = weapon.get_weapon_stats().weapon_id
	var reload_amount = weapon.get_weapon_stats().mag_size - weapon_current_ammo
	var to_use = min(get_reserve_ammo(weapon_id), reload_amount)
	
	if to_use <= 0:
		return false
	
	return true


func serialize_state() -> Dictionary:
	return _ammo_pool.duplicate()


func deserialize_state(state : Dictionary):
	_ammo_pool = state.duplicate()
