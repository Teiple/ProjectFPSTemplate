class_name ImpactEffect
extends Spatial

export var one_shot : bool = true

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var particles : Particles = $Particles


func _ready():
	particles.one_shot = one_shot


func set_up(position : Vector3, normal : Vector3):
	global_transform = Transform.IDENTITY
	global_position = position
	
	var dot = Vector3.UP.dot(normal)
	if abs(dot) > 0.95:
		if dot > 0:
			rotation.x = PI * 0.5
		else:
			rotation.x = -PI * 0.5
	else:
		look_at(position + normal, Vector3.UP)
	
	particles.restart()
