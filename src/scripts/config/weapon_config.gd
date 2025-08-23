class_name WeaponConfig

const config : Dictionary = {
	# Weapon scenes that will used by Player
	"weapons": {
		"pistol": preload("res://src/scenes/weapons/pistol.tscn"),
		"smg": preload("res://src/scenes/weapons/smg.tscn"),
		"shotgun": preload("res://src/scenes/weapons/shotgun.tscn"),
	},
	# Weapon stats resources
	"weapon_stats": {
		"pistol": preload("res://src/resources/weapon/pistol_weapon_stats.tres"),
		"smg": preload("res://src/resources/weapon/smg_weapon_stats.tres"),
		"shotgun": preload("res://src/resources/weapon/shotgun_weapon_stats.tres"),
	}
}
