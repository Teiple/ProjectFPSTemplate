class_name WeaponController
extends Spatial

signal weapon_changed
signal weapon_changed_immediate
signal auto_reload_requested

const MAX_SLOTS : int = 4 

export var _weapons_path : NodePath = ""
export var _ammo_inventory_path : NodePath = ""
export var _auto_equip_new_weapon : bool = true
export var _auto_reload : bool = true
export var _precise_shot_cool_down : float = 0.5

# onready var aim_raycast : RayCast = $AimRayCast
export(int, LAYERS_3D_PHYSICS) var aim_layer_mask : int = 0

onready var _projectile_start_point_check_raycast: RayCast = $ProjectileStartPointCheckRaycast

var _weapons_node : Spatial = null
var _current_weapon : Weapon = null
var _ammo_inventory : AmmoInventory = null


func _ready() -> void:
	_weapons_node = get_node(_weapons_path)
	_ammo_inventory = get_node(_ammo_inventory_path)
	
	# Intialize first weapon
	_cycle_weapon(1)


func _unhandled_input(event):
	if event.is_action_pressed("next_weapon"):
		_cycle_weapon(1)
	elif event.is_action_pressed("previous_weapon"):
		_cycle_weapon(-1)
	
	for i in MAX_SLOTS:
		if event.is_action_pressed("weapon_slot_" + str(i+1)):
			select_weapon(i+1)


func get_available_weapons() -> Array:
	var weapon_arr = []
	for weapon in _weapons_node.get_children():
		# In case of weapons are freed due to loading, here is an is_instance_valid check
		if is_instance_valid(weapon) && weapon is Weapon:
			weapon_arr.push_back(weapon)
	return weapon_arr


func get_available_slots() -> Array:
	var weapon_slot_arr = []
	for weapon in get_available_weapons():
		if weapon is Weapon:
			var wp_slot = weapon.get_weapon_stats().weapon_slot
			weapon_slot_arr.push_back(wp_slot)
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
func check_and_handle_rapid_fire_attempt() -> bool:
	if _current_weapon == null || !_current_weapon.get_weapon_stats().allow_rapid_fire:
		return false
	# Player usually fires their last shot and continues spamming the fire button.
	# This prevents playing the empty click sound right before auto-reload.
	var can_auto_reload = _can_auto_reload_now()
	if _current_weapon.get_current_ammo() == 0:
		if !can_auto_reload:
			_current_weapon.play_empty_click()
		else:
			emit_signal("auto_reload_requested")
		return false
	
	if can_auto_reload:
		return false
	
	return true


func select_weapon(weapon_slot : int, immediate : bool = false):
	var wp_changed_signal = "weapon_changed_immediate" if immediate else "weapon_changed"
	
	# -1 for unarmed
	if weapon_slot == -1:
		if _current_weapon != null:
			_current_weapon = null
			emit_signal(wp_changed_signal)
		return
	
	if weapon_slot < 0 || weapon_slot >= MAX_SLOTS:
		return
	
	# Don't choose the same weapon again
	if is_instance_valid(_current_weapon) && _current_weapon.get_weapon_stats().weapon_slot == weapon_slot:
		return
	
	var weapon = _find_weapon_at_slot(weapon_slot)
	if weapon == null:
		return
	
	# Hide other weapons
	for wp in get_available_weapons():
		#wp.visible = wp == weapon
		wp.set_deferred("visible", wp == weapon)
	
	# Set relative transform
	weapon.transform = weapon.get_weapon_stats().view_model_relative_transform_from_hand
	
	_current_weapon = weapon
	emit_signal(wp_changed_signal)


func _find_weapon_at_slot(slot_number : int) -> Weapon:
	for wp in get_available_weapons():
		if wp is Weapon && wp.get_weapon_stats().weapon_slot == slot_number:
			return wp as Weapon
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


func add_new_weapon(new_weapon : Weapon):
	if new_weapon == null:
		return
	_weapons_node.add_child(new_weapon)
	var new_slot = new_weapon.get_weapon_stats().weapon_slot
	if _auto_equip_new_weapon:
		select_weapon(new_slot)


func replace_weapon(new_weapon : Weapon) -> void:
	var replaced_slot = new_weapon.get_weapon_stats().weapon_slot
	var old_weapon = _find_weapon_at_slot(replaced_slot)
	
	if old_weapon == null:
		return
	
	_weapons_node.remove_child(old_weapon)
	_weapons_node.add_child(new_weapon)
	
	if _auto_equip_new_weapon:
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
	return _auto_reload && _current_weapon != null && _current_weapon.get_current_ammo() == 0 && _ammo_inventory.can_reload_weapon(_current_weapon) 


# Check if weapon is ready to fire, if weapon has no ammo, an empty click sound is played 
func check_and_handle_fire_attempt() -> bool:
	if _current_weapon == null || !is_current_weapon_firing_cool_down_over():
		return false
	# Player usually fires their last shot and continues spamming the fire button.
	# This prevents playing the empty click sound right before auto-reload.
	var can_auto_reload = _can_auto_reload_now()
	if _current_weapon.get_current_ammo() == 0:
		if !can_auto_reload:
			_current_weapon.play_empty_click()
		else:
			emit_signal("auto_reload_requested")
		return false
	
	if can_auto_reload:
		return false
	
	return true


func can_reload() -> bool:
	if _current_weapon == null:
		return false
	return _ammo_inventory.can_reload_weapon(_current_weapon)


# Assuming weapon is ready to reload: weapon's current ammo is not at mag size and has reserve ammo (see can_reload())
func reload() -> void:
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
func mark_fire() -> void:
	if _current_weapon == null:
		return
	_current_weapon.mark_fire()


# Assuming weapon is ready to fire: has enough ammo and firing cooldown was over
# This is the most complex function of this class, and it seems to be its responsibility.
# I didn't know to off-load it else where.
func fire() -> void:
	if _current_weapon == null:
		return
	
	var stats = _current_weapon.get_weapon_stats()
	var weapon_id = _current_weapon.get_weapon_stats().weapon_id
	var arms = owner as Spatial
	var player = Global.get_game_world().get_player()
	
	var ammo_to_fire = min(stats.ammo_per_shot, _current_weapon.get_current_ammo())
	
	var precise_shot = FrameTime.process_time() - _current_weapon.get_last_fire() >= _precise_shot_cool_down
	
	for i in ammo_to_fire:
		for j in stats.projectiles_per_ammo:
			
			var attack_origin : AttackOriginInfo = AttackOriginInfo.new()
			
			attack_origin.attacker = player
			attack_origin.damage = stats.damage_per_projectile
			attack_origin.max_distance = stats.max_distance
			attack_origin.collision_mask = stats.collision_mask
			attack_origin.impact_force = stats.impact_force
			
			if precise_shot:
				attack_origin.spread_angle_degrees = 0.0
				# Ok, this needs more dicussion in the future
				# For now, just accept that you can only have one precise projectile
				precise_shot = false
			else:
				attack_origin.spread_angle_degrees = stats.spread_angle_degrees
			
			match stats.ballistic_model:
				GlobalData.BallisticModel.HITSCAN:
					_fire_hitscan_weapon(attack_origin)
				GlobalData.BallisticModel.PROJECTILE:
					_fire_projectile_weapon(attack_origin)
			
	# Calling fire() for the weapon to re-calculate its current ammo
	_current_weapon.fire()


func _fire_hitscan_weapon(attack_origin : AttackOriginInfo) -> void:
	var arms = owner as Spatial
	
	attack_origin.aim_from = arms.global_position
	attack_origin.fire_from = _current_weapon.get_muzzle_position()
	attack_origin.base_direction = -arms.global_transform.basis.z
	attack_origin.attacker_forward = -arms.global_transform.basis.z
	
	var weapon_raycast_comp = Component.find(arms, WeaponRaycastComponent.get_component_name()) as WeaponRaycastComponent
	if weapon_raycast_comp != null:
		weapon_raycast_comp.cast(attack_origin)


func _fire_projectile_weapon(attack_origin : AttackOriginInfo) -> void:
	var arms = owner as Spatial
	
	attack_origin.aim_from = arms.global_position
	attack_origin.base_direction = -arms.global_transform.basis.z
	
	var weapon_can_fire_from_muzzle = _current_weapon.can_fire_from_muzzle(aim_layer_mask)
	_projectile_start_point_check_raycast.collision_mask = attack_origin.collision_mask
	_projectile_start_point_check_raycast.cast_to = _projectile_start_point_check_raycast.to_local(_current_weapon.get_muzzle_position())
	_projectile_start_point_check_raycast.force_raycast_update()
	var is_obstructed = _projectile_start_point_check_raycast.is_colliding()
	
	if !is_obstructed && weapon_can_fire_from_muzzle:
		attack_origin.fire_from = _current_weapon.get_muzzle_position()
	else:
		attack_origin.fire_from = arms.global_position

	attack_origin.projectile_speed = _current_weapon.get_weapon_stats().projectile_speed
	
	var weapon_projectile_comp = Component.find(arms, WeaponProjectileComponent.get_component_name()) as WeaponProjectileComponent
	if weapon_projectile_comp != null:
		weapon_projectile_comp.launch(attack_origin) as AttackResultInfo


func serialize_available_weapons() -> Dictionary:
	var data = {}
	
	for wp in get_available_weapons():
		wp = wp as Weapon
		if wp == null:
			continue
		var wp_data = wp.serialize_weapon()
		var wp_id = wp.get_weapon_stats().weapon_id
		data[wp_id] = wp_data
	
	return data


func _remove_all_weapons():
	for wp in _weapons_node.get_children():
		_weapons_node.remove_child(wp)
		wp.queue_free()


func serialize_state() -> Dictionary:
	var cur_wp_slot = -1
	
	if _current_weapon != null:
		cur_wp_slot = _current_weapon.get_weapon_stats().weapon_slot
	return {
		"weapons" : serialize_available_weapons(),
		"current_weapon_slot" : cur_wp_slot,
	}


func deserialize_state(state : Dictionary):
	var cur_wp_slot = state.get("current_weapon_slot", "")
	var wps_data = state.get("weapons", {})
	
	_remove_all_weapons()
	
	# Must set to null here, or else if select_weapon refuses to change
	# _current_weapon may reference a deleted object
	_current_weapon = null
	
	for wp_id in wps_data:
		var wp_packed_scene = GameConfig.get_config_value(GlobalData.ConfigId.WEAPON_CONFIG, ["weapons", wp_id], null) as PackedScene
		if wp_packed_scene == null:
			continue
		var wp = wp_packed_scene.instance() as Weapon
		if wp == null:
			wp.queue_free()
			continue
		_weapons_node.add_child(wp)
		
		var wp_data = wps_data.get(wp_id, {})
		wp.deserialize_weapon(wp_data)
	
	# Equip and change into idle animation immediately
	select_weapon(cur_wp_slot, true)


func get_available_weapon_stats() -> Array:
	var stats = []
	
	for wp in get_available_weapons():
		stats.push_back(wp.get_weapon_stats())
	
	return stats


func is_current_weapon_allowed_rapid_fire() -> bool:
	return _current_weapon != null && _current_weapon.get_weapon_stats().allow_rapid_fire
