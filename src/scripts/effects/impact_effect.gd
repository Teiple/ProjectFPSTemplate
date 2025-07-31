class_name ImpactEffect
extends Spatial

const LIFE_TIME_OFFSET := 1.0

export var one_shot : bool = true

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var particles : Particles = $Particles

var _start_time : float = 0.0
var _life_time : float = 0.0
var _normal : Vector3 = Vector3.ZERO

func _ready():
	particles.one_shot = one_shot
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))


func serialize() -> Dictionary:
	return {
		"position": var2str(global_position),
		"normal": var2str(_normal),
	}


func deserialize(data : Dictionary):
	var pos = Utils.either(str2var(data.get("position")), global_position)
	var normal = Utils.either(str2var(data.get("normal")), _normal)
	set_up(pos, normal)


func _process(delta):
	if FrameTime.process_time() - _start_time >= _life_time:
		particles.emitting = false
		poolable_node_component.return_to_pool()


func set_up(position : Vector3, normal : Vector3):
	global_transform = Transform.IDENTITY
	global_position = position
	_normal = normal
	
	var dot = Vector3.UP.dot(normal)
	if abs(dot) > 0.95:
		if dot > 0:
			rotation.x = PI * 0.5
		else:
			rotation.x = -PI * 0.5
	else:
		look_at(position + normal, Vector3.UP)
	
	particles.restart()
	_life_time = particles.lifetime / particles.speed_scale  + LIFE_TIME_OFFSET
	_start_time = FrameTime.process_time()
