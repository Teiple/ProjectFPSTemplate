class_name WeaponController
extends Node

signal weapon_changed
signal auto_reload_requested

enum {
	WEAPON_ID_DUPLICATION,
	WEAPON_SLOT_DUPLICATION,
	WEAPON_NO_DUPLICATION,
	WEAPON_ERROR_DUPLICATION,
}

const MAX_SLOTS : int = 4

export var weapons_path : NodePath = ""
export var ammo_inventory_path : NodePath = ""
export var auto_equip_new_weapon : bool = true
export var auto_reload : bool = true
export var precise_shot_cool_down : float = 0.5

onready var aim_raycast : RayCast = $AimRayCast

var _weapons_node : Spatial = null
var _current_weapon : Weapon = null
var _ammo_inventory : AmmoInventory = null


func _ready():
	_weapons_node = get_node(weapons_path)
	_ammo_inventory = get_node(ammo_inventory_path)
	
	# Intialize first weapon
	_cycle_weapon(1)


func _unhandled_input(event):
	if event.is_action_pressed("next_weapon"):
		_cycle_weapon(1)
	elif event.is_action_pressed("previous_weapon"):
		_cycle_weapon(-1)
	
	for i in MAX_SLOTS:
		if event.is_action_pressed("weapon_slot_" + str(i+1)):
			select_weapon(i)


func get_available_weapons() -> Array:
	var weapon_arr = []
	for weapon in _weapons_node.get_children():
		if weapon is Weapon:
			weapon_arr.push_back(weapon)
	return weapon_arr


func get_available_slots() -> Array:
	var weapon_slot_arr = []
	for weapon in _weapons_node.get_children():
		if weapon is Weapon:
			weapon_slot_arr.push_back(weapon.get_weapon_stats().weapon_slot)
	weapon_slot_arr.sort()
	return weapon_slot_arr


# Return null if unarmed
func get_current_weapon() -> Weapon:
	return _current_weapon


func get_current_weapon_current_ammo() -> int:
	if _current_weapon == null:
		return 0
	return _current_weapon.get_current_ammo()


func get_current_weapon_reserve_ammo() -> int:
	if _current_weapon == null:
		return 0
	var weapon_id = _current_weapon.get_weapon_stats().weapon_id
	return _ammo_inventory.get_reserve_ammo(weapon_id)


# Return empty string if unarmed
func get_current_weapon_id() -> String:
	return _current_weapon.get_weapon_stats().weapon_id if _current_weapon != null else "" 


# Rapid fire will ignore firerate and fire whenever it is possible
func can_rapid_fire_or_play_empty_click() -> bool:
	if _current_weapon == null || !_current_weapon.get_weapon_stats().allow_rapid_fire:
		return false
	# Player usually fires their last shot and continues spamming the fire button.
	# This prevents playing the empty click sound right before auto-reload.
	var can_auto_reload = _can_auto_reload_now()
	if _current_weapon.get_current_ammo() == 0 && !can_auto_reload:
		_current_weapon.play_empty_click()
		return false
	
	if can_auto_reload:
		return false
	
	return true


func select_weapon(weapon_slot : int):
	# -1 for unarmed
	if weapon_slot == -1:
		_current_weapon = null
		emit_signal("weapon_changed")
		return
	
	if weapon_slot < 0 || weapon_slot >= MAX_SLOTS:
		return
	
	var weapon = _find_weapon_at_slot(weapon_slot)
	if weapon == null:
		return
	
	# Hide other weapons
	for wp in _weapons_node.get_children():
		#wp.visible = wp == weapon
		wp.set_deferred("visible", wp == weapon)
	
	_current_weapon = weapon
	emit_signal("weapon_changed")


func _find_weapon_at_slot(slot_number : int) -> Weapon:
	for weapon in _weapons_node.get_children():
		if weapon is Weapon && weapon.get_weapon_stats().weapon_slot == slot_number:
			return weapon as Weapon
	return null


func _cycle_weapon(direction : int): 
	var current_slot = -1 if _current_weapon == null else _current_weapon.get_weapon_stats().weapon_slot
	
	# Use weapon slot array since we may not have weapons with their slots in order
	# Ex: slot 1, slot 3, slot 4
	var weapon_slot_arr = get_available_slots()
	if weapon_slot_arr.size() == 0:
		return
	
	# If unarmed, either select the first or last weapon
	if current_slot == -1:
		if direction > 0:
			select_weapon(weapon_slot_arr.front())
		elif direction < 0:
			select_weapon(weapon_slot_arr.back())
		return
	
	var current_index = weapon_slot_arr.find(current_slot)
	var new_index = current_index + direction
	
	if new_index >= weapon_slot_arr.size():
		new_index = 0
	elif new_index < 0:
		new_index = weapon_slot_arr.size() - 1
	
	var new_slot = weapon_slot_arr[new_index]
	select_weapon(new_slot)


# Assuming new_weapon is not null
func _duplicate_check(new_weapon : Weapon) -> int:
	if new_weapon in get_available_weapons():
		return WEAPON_ERROR_DUPLICATION
	
	for weapon in get_available_weapons():
		if new_weapon.get_weapon_stats().weapon_id == weapon.get_weapon_stats().weapon_id:
			return WEAPON_ID_DUPLICATION
		elif new_weapon.get_weapon_stats().weapon_slot == weapon.get_weapon_stats().weapon_slot:
			return WEAPON_SLOT_DUPLICATION
	
	return WEAPON_NO_DUPLICATION


func add_weapon(new_weapon : Weapon):
	if new_weapon == null:
		return 
	
	var duplication = _duplicate_check(new_weapon)
	match duplication:
		WEAPON_ID_DUPLICATION:
			_ammo_inventory.take_weapon_ammo(new_weapon)
		WEAPON_SLOT_DUPLICATION:
			_replace_weapon(new_weapon)
		WEAPON_NO_DUPLICATION:
			_add_new_weapon(new_weapon)
		_, WEAPON_ERROR_DUPLICATION:
			pass


# Assuming new_weapon is not null
func _add_new_weapon(new_weapon : Weapon):
	_weapons_node.add_child(new_weapon)
	var new_slot = new_weapon.get_weapon_stats().weapon_slot
	
	if auto_equip_new_weapon:
		select_weapon(new_slot)


# Assuming new_weapon is not null, weapon with the same slot exists 
func _replace_weapon(new_weapon : Weapon):
	var replaced_slot = new_weapon.get_weapon_stats().weapon_slot
	var old_weapon = _find_weapon_at_slot(replaced_slot)
	_weapons_node.remove_child(old_weapon)
	_weapons_node.add_child(new_weapon)
	
	if auto_equip_new_weapon:
		select_weapon(replaced_slot)


func is_current_weapon_firing_cool_down_over() -> bool:
	if _current_weapon == null:
		return false
	return _current_weapon.is_firing_cooldown_timeout()


# Assumming the current_weapon is not null
# Check if this weapon can reload after firing its shot
func try_auto_load() -> bool:
	var can_auto_reload = _can_auto_reload_now()
	if can_auto_reload:
		emit_signal("auto_reload_requested")
	
	return can_auto_reload


func _can_auto_reload_now() -> bool:
	return auto_reload && _current_weapon != null && _current_weapon.get_current_ammo() == 0 && _ammo_inventory.can_reload_weapon(_current_weapon) 


# Check if weapon is ready to fire, if weapon has no ammo, an empty click sound is played 
func can_fire_or_play_empty_click() -> bool:
	if _current_weapon == null || !is_current_weapon_firing_cool_down_over():
		return false
	# Player usually fires their last shot and continues spamming the fire button.
	# This prevents playing the empty click sound right before auto-reload.
	var can_auto_reload = _can_auto_reload_now()
	if _current_weapon.get_current_ammo() == 0 && !can_auto_reload:
		_current_weapon.play_empty_click()
		return false
	
	if can_auto_reload:
		return false
	
	return true


func can_reload() -> bool:
	if _current_weapon == null:
		return false
	return _ammo_inventory.can_reload_weapon(_current_weapon)


# Assuming weapon is ready to reload: weapon's current ammo is not at mag size and has reserve ammo (see can_reload())
func reload():
	if _current_weapon == null:
		return
	
	# Ammo inventory will take care of the reload logic
	_ammo_inventory.reload_weapon(_current_weapon)


func get_current_weapon_fire_rate() -> float:
	if _current_weapon == null:
		return -1.0
	return _current_weapon.get_weapon_stats().fire_rate


func get_current_weapon_animation_tree() -> AnimationTree:
	if _current_weapon == null:
		return null
	return _current_weapon.get_animation_tree()


# Mark the weapon is about to fire next frame
func mark_fire():
	if _current_weapon == null:
		return
	_current_weapon.mark_fire()


# Assuming weapon is ready to fire: has enough ammo and firing cooldown was over
# This is the most complex function of this class, and it seems to be its responsibility.
# I didn't know to off-load it else where.
func fire():
	if _current_weapon == null:
		return
	
	var stats = _current_weapon.get_weapon_stats()
	var weapon_id = _current_weapon.get_weapon_stats().weapon_id
	var arms = owner as Spatial
	var player = Global.get_game_world().get_player()
	
	var ammo_to_fire = min(stats.ammo_per_shot, _current_weapon.get_current_ammo())
	
	var precise_shot = FrameTime.process_time() - _current_weapon.get_last_fire() >= precise_shot_cool_down
	
	for i in ammo_to_fire:
		for j in stats.projectiles_per_ammo:
			
			var attack : AttackOriginInfo = AttackOriginInfo.new()
			
			attack.attacker = player
			attack.damage = stats.damage_per_projectile
			attack.max_distance = stats.max_distance
			attack.collision_mask = stats.collision_mask
			
			if precise_shot:
				attack.spread_angle_degrees = 0.0
			else:
				attack.spread_angle_degrees = stats.spread_angle_degrees
			
			var result : AttackResultInfo = null
			match stats.ballistic_model:
				
				GlobalData.BallisticModel.HITSCAN:
					var weapon_raycast_comp : WeaponRaycastComponent = Component.find_component(arms, WeaponRaycastComponent.get_component_name()) as WeaponRaycastComponent
					
					attack.from = arms.global_position
					attack.direction = -arms.global_transform.basis.z
					attack.use_visual_origin = true
					attack.visually_from = _current_weapon.get_muzzle_position()
					attack.attacker_forward = -arms.global_transform.basis.z
					
					if weapon_raycast_comp != null:
						result = weapon_raycast_comp.cast(attack)
				
				GlobalData.BallisticModel.PROJECTILE:
					var weapon_projectile_comp : WeaponProjectileComponent = Component.find_component(arms, WeaponProjectileComponent.get_component_name()) as WeaponProjectileComponent
					
					aim_raycast.global_position = arms.global_position
					aim_raycast.cast_to = aim_raycast.to_local(_current_weapon.get_muzzle_position())
					aim_raycast.force_raycast_update()
					var can_fire_from_muzzle = _current_weapon.can_fire_from_muzzle(aim_raycast.collision_mask)
					if !aim_raycast.is_colliding() && can_fire_from_muzzle:
						attack.from = _current_weapon.get_muzzle_position()
						
						aim_raycast.global_position = arms.global_position
						var max_target_range = _current_weapon.get_weapon_stats().max_distance
						var furthest_point = arms.global_position - arms.global_transform.basis.z * max_target_range
						aim_raycast.cast_to = aim_raycast.to_local(furthest_point)
						
						aim_raycast.force_raycast_update()
						if aim_raycast.is_colliding():
							var collision_point = aim_raycast.get_collision_point()
							attack.max_distance = (collision_point - attack.from).length()
							attack.direction = (collision_point - attack.from) / attack.max_distance
						else:
							attack.max_distance = (furthest_point - attack.from).length()
							attack.direction = (furthest_point - attack.from) / attack.max_distance
					else:
						attack.from = arms.global_position
						attack.direction = -arms.global_transform.basis.z
					
					attack.projectile_speed = _current_weapon.get_weapon_stats().projectile_speed
					
					if weapon_projectile_comp != null:
						result = weapon_projectile_comp.launch(attack)
	# Calling fire() for the weapon to recalcuate its current weapon
	_current_weapon.fire()
