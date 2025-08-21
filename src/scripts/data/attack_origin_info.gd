class_name AttackOriginInfo

var attacker = null
var damage : float = 10.0
var damage_type : int = GlobalData.AttackType.BULLET
var aim_from : Vector3 = Vector3.ZERO
# Direction before applying spread angle
var base_direction : Vector3 = Vector3.ZERO
# Direction before applying spread angle
var direction : Vector3 = Vector3.ZERO
var max_distance : float = 10.0
var collision_mask : int = 1
var spread_angle_degrees : float = 1.0
# fire_from is different between projectile and hitscan weapon
# For hitscan, the damage origin is from aim_from, fire_from is used for bullet trails origin
# For projectile, the damage origin is from fire_from, while aim_from is used for determine
# the direction of those projectiles
var fire_from : Vector3 = Vector3.ZERO
var attacker_forward : Vector3 = Vector3.ZERO
# Projectile
var projectile_speed : float = 10.0
# Physical Impacts
var impact_force : float = 0.0
