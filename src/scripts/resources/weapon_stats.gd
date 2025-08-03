class_name WeaponStats 
extends Resource

export var weapon_id : String = "pistol"
export var fire_rate : float = 0.1
export var mag_size : int = 10
export var max_distance : float = 100.0
export var max_inventory_size : int = 100
export var ammo_per_shot : int = 1
export var projectiles_per_ammo : int = 1
export var damage_per_projectile : float = 10
export var spread_angle_degrees : float = 2
export var weapon_slot : int = 1 
export(GlobalData.BallisticModel) var ballistic_model : int = GlobalData.BallisticModel.HITSCAN

# Relative to view model origin
export var view_model_relative_transform_from_hand : Transform = Transform.IDENTITY

# Only matter if ballistic_model is Projectile
export var projectile_speed : float = 30.0

export var allow_rapid_fire : bool = false
export(int, LAYERS_3D_PHYSICS) var collision_mask : int = 5

export var impact_force : float = 1.0
