class_name ImpactEffect
extends Spatial

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var particles : PausableParticles = $Particles

func _ready():
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))


func serialize() -> Dictionary:
	return {
		"global_position": var2str(global_transform),
		"is_emitting": particles.get_is_emitting(),
		"last_restart_offset": FrameTime.process_time() - particles.get_last_restart(),
	}


func deserialize(data : Dictionary):
	global_transform = Utils.either(str2var(data.get("global_position")), global_transform)
	
	var is_emitting = data.get("is_emitting", false)
	
	particles.set_is_emitting(is_emitting)
	if !is_emitting:
		poolable_node_component.return_to_pool()
		return
	
	var last_restart = FrameTime.process_time() - max(data.get("last_restart_offset", 0.0), 0.0)
	particles.set_last_restart(last_restart)
	particles.trigger_restart(true)


func _process(delta):
	if !particles.get_is_emitting():
		poolable_node_component.return_to_pool()


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
	
	particles.trigger_restart()
