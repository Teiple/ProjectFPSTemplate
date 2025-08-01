class_name Decal
extends Spatial

export var life_time : float = 2.0

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent

var _start_time : float = 0.0


func _ready():
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))


func serialize() -> Dictionary:
	return {
		"global_transform": var2str(global_transform),
	}


func deserialize(data : Dictionary):
	global_transform = Utils.either(str2var(data.get("global_transform")), global_transform)
	_start_time = FrameTime.process_time()


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
	_start_time = FrameTime.process_time()
	rotate_object_local(Vector3.FORWARD, rand_range(-PI, PI))


func _process(delta):
	if FrameTime.process_time() - _start_time > life_time:
		poolable_node_component.return_to_pool()
