class_name HealthComponent
extends Component

signal died
signal damaged

export var health_points : float = 100.0


static func get_component_name() -> String:
	return "HealthComponent"


func take_damage():
	pass


func _die():
	print_debug("die")
