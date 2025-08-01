class_name Weapon
extends Spatial

signal fired
signal reloaded

export var current_ammo : int = 10
export var weapon_stats : Resource = null

var _weapon_model : Spatial = null
var _weapon_animation_player : AnimationPlayer = null
var _last_fire : float = -1.0

onready var _animation_tree : AnimationTree = $AnimationTree
onready var muzzle_position : Spatial = $MuzzlePosition
onready var muzzle_space_check : ShapeCast = $MuzzlePosition/MuzzleSpaceCheck


func _ready():
	_weapon_model = get_child(0) as Spatial
	_weapon_animation_player = _weapon_model.find_node("AnimationPlayer") as AnimationPlayer


# Return the used amount
func reload(amount : int) -> int:
	var reload_amount = min(get_weapon_stats().mag_size - current_ammo, amount)
	current_ammo += reload_amount
	emit_signal("reloaded")
	return reload_amount


func get_weapon_stats() -> WeaponStats:
	return weapon_stats as WeaponStats


func get_current_ammo():
	return current_ammo


# Ensure firing cool down is over
func is_firing_cooldown_timeout() -> bool:
	var time_passed =  FrameTime.process_time() - _last_fire
	return time_passed > weapon_stats.fire_rate


func mark_fire():
	_last_fire = FrameTime.process_time()


func fire():
	if current_ammo == 0:
		emit_signal("fired")
		return
	
	var ammo_shot = min(weapon_stats.ammo_per_shot, current_ammo)
	current_ammo -= ammo_shot
	
	emit_signal("fired")
	return


func get_animation_tree() -> AnimationTree:
	return _animation_tree


func play_empty_click():
	print_debug("click")


func get_muzzle_position() -> Vector3:
	return muzzle_position.global_position if muzzle_position != null else global_position


func can_fire_from_muzzle(collision_mask : int):
	muzzle_space_check.collision_mask = collision_mask
	muzzle_space_check.force_shapecast_update()
	return !muzzle_space_check.is_colliding()


func get_last_fire() -> float:
	return _last_fire


func serialize_state() -> Dictionary:
	return {
		"last_fire_offset" : FrameTime.process_time() - _last_fire,
		"current_ammo" : current_ammo
	}


func deserialize_state(state : Dictionary):
	_last_fire = FrameTime.process_time() - max(state.get("last_fire_offset", 0.0), 0.0)
	current_ammo = state.get("current_ammo", 0)
