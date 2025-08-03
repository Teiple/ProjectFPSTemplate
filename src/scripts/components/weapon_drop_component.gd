class_name WeaponDropComponent
extends Component

export var _weapon_id : String = "pistol"
export var _current_ammo : int = 10 

var _weapon_stats : WeaponStats = null


func _ready():
	_weapon_stats = GameConfig.get_config_value(GlobalData.ConfigId.WEAPON_CONFIG, ["weapon_stats", _weapon_id], null)


# Override
static func get_component_name() -> String:
	return "WeaponDropComponent"


func get_weapon_stats() -> WeaponStats:
	return _weapon_stats


# Return the actual ammo can take 
func take_all_ammo() -> int:
	var take_amount = _current_ammo
	_current_ammo = 0
	# Please don't reference me after this point
	owner.call_deferred("queue_free")
	return take_amount


# Delete this then create a player version of the weapon
func player_take_weapon() -> Weapon:
	var wp_packed_scene = GameConfig.get_config_value(GlobalData.ConfigId.WEAPON_CONFIG, ["weapons", _weapon_id], null) as PackedScene
	if wp_packed_scene == null:
		return null
	var wp = wp_packed_scene.instance() as Weapon
	if wp == null:
		wp.queue_free()
		return null
	wp.set_current_ammo(_current_ammo)
	# Please don't reference me after this point
	owner.call_deferred("queue_free")
	return wp
