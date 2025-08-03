class_name AttackOriginInfo

var attacker = null
var damage : float = 10.0
var damage_type : int = GlobalData.AttackType.BULLET
var from : Vector3 = Vector3.ZERO
# Direction before applying spread angle
var base_direction : Vector3 = Vector3.ZERO
# Direction before applying spread angle
var direction : Vector3 = Vector3.ZERO
var max_distance : float = 10.0
var collision_mask : int = 1
var spread_angle_degrees : float = 1.0

# Extra argument for effects
var use_visual_origin : bool = false
var visually_from : Vector3 = Vector3.ZERO
var attacker_forward : Vector3 = Vector3.ZERO

# Projectile
var projectile_speed : float = 10.0

# Physical Impacts
var impact_force : float = 0.0
