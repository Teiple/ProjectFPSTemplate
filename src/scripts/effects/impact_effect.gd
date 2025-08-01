class_name ParticleEffect
extends Spatial

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent

var particle_nodes : Array = []


func _ready():
	for child in get_children():
		if child is PausableParticles:
			particle_nodes.push_back(child)
	
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))


func serialize() -> Dictionary:
	var emissions = []
	for p in particle_nodes:
		emissions.append({
			"is_emitting": p.get_is_emitting(),
			"last_restart_offset": FrameTime.process_time() - p.get_last_restart()
		})
	return {
		"global_position": var2str(global_transform),
		"emissions": emissions
	}


func deserialize(data : Dictionary):
	global_transform = Utils.either(str2var(data.get("global_position")), global_transform)

	var emissions : Array = data.get("emissions", [])
	var has_any_emitting = false

	for i in range(min(emissions.size(), particle_nodes.size())):
		var particle : PausableParticles = particle_nodes[i]
		var entry : Dictionary = emissions[i]

		var is_emitting = entry.get("is_emitting", false)
		particle.set_is_emitting(is_emitting)
		if is_emitting:
			var last_restart = FrameTime.process_time() - max(entry.get("last_restart_offset", 0.0), 0.0)
			particle.set_last_restart(last_restart)
			particle.trigger_restart(true)
			has_any_emitting = true

	if !has_any_emitting:
		poolable_node_component.return_to_pool()


func _process(delta):
	var any_emitting := false
	for p in particle_nodes:
		if p.get_is_emitting():
			any_emitting = true
			break
	if !any_emitting:
		poolable_node_component.return_to_pool()


func set_up(position : Vector3, normal : Vector3):
	global_transform = Transform.IDENTITY
	global_position = position

	var dot = Vector3.UP.dot(normal)
	if abs(dot) > 0.95:
		rotation.x = PI * 0.5 if dot > 0 else -PI * 0.5
	else:
		look_at(position + normal, Vector3.UP)

	for p in particle_nodes:
		p.trigger_restart()
