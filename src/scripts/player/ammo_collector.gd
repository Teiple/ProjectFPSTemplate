class_name AmmoCollector
extends Spatial

enum {
	WEAPON_ID_DUPLICATION,
	WEAPON_SLOT_DUPLICATION,
	WEAPON_NO_DUPLICATION,
}

export var _collect_range := 2.0
export var _weapon_controller_path : NodePath = ""
export var _ammo_inventory_path : NodePath = ""

onready var _raycast : RayCast = $RayCast

var _weapon_controller : WeaponController = null
var _ammo_inventory : AmmoInventory = null


func _ready():
	_raycast.cast_to = Vector3.FORWARD * _collect_range
	_weapon_controller = get_node(_weapon_controller_path)
	_ammo_inventory = get_node(_ammo_inventory_path)


func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		_try_collect()


# Assuming new_weapon is not null
func _duplication_check(weapon_id : String, weapon_slot : int) -> int:
	for stats in _weapon_controller.get_available_weapon_stats():
		if weapon_id == stats.weapon_id:
			return WEAPON_ID_DUPLICATION
		elif weapon_slot == stats.weapon_slot:
			return WEAPON_SLOT_DUPLICATION
	
	return WEAPON_NO_DUPLICATION


func _try_collect():
	_raycast.force_raycast_update()
	if !_raycast.is_colliding():
		return
	
	var collider = _raycast.get_collider()
	var collision_point = _raycast.get_collision_point()
	var collision_normal = _raycast.get_collision_point()
	
	var weapon_drop_comp = Component.find_component(collider, WeaponDropComponent.get_component_name()) as WeaponDropComponent
	if weapon_drop_comp == null:
		return
	
	var weapon_drop_stats = weapon_drop_comp.get_weapon_stats()
	if weapon_drop_stats == null:
		return
	
	var weapon_id = weapon_drop_stats.weapon_id
	var weapon_slot = weapon_drop_stats.weapon_slot
	
	var duplication = _duplication_check(weapon_id, weapon_slot)
	
	match duplication:
		WEAPON_ID_DUPLICATION:
			var add_amount = weapon_drop_comp.take_all_ammo()
			_ammo_inventory.add_weapon_ammo(weapon_id, add_amount)
		WEAPON_SLOT_DUPLICATION:
			var weapon_replacment = weapon_drop_comp.player_take_weapon()
			_weapon_controller.replace_weapon(weapon_replacment)
		WEAPON_NO_DUPLICATION:
			var new_weapon = weapon_drop_comp.player_take_weapon()
			_weapon_controller.add_new_weapon(new_weapon)
		_:
			pass
	
	return duplication

