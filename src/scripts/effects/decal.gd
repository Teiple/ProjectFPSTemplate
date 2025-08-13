class_name Decal
extends Spatial

export var life_time : float = 2.0

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var decal_projection : DecalProjection = $DecalProjection

var _start_time : float = 0.0


func _ready():
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))


func serialize() -> Dictionary:
	var parent_path = get_parent().get_path()
	return {
		"global_transform": var2str(global_transform),
		"decal_target": parent_path
	}


func deserialize(data : Dictionary):
	global_transform = Utils.either(str2var(data.get("global_transform")), global_transform)
	_start_time = FrameTime.process_time()
	
	decal_projection.perform_projection()


func set_up(pos : Vector3, normal : Vector3, target : Node):
	global_transform = Transform.IDENTITY
	global_position = pos
	
	var dot = Vector3.UP.dot(normal)
	if abs(dot) > 0.95:
		if dot > 0:
			rotation.x = PI * 0.5
		else:
			rotation.x = -PI * 0.5
	else:
		look_at(pos + normal, Vector3.UP)
	_start_time = FrameTime.process_time()
	# rotate_object_local(Vector3.FORWARD, rand_range(-PI, PI))
	
	decal_projection.perform_projection()
	
	var parent = get_parent()
	if parent == null:
		return
	var global_xform = global_transform
	parent.remove_child(self)
	target.add_child(self)
	
	global_transform = global_xform


func _process(delta):
	if FrameTime.process_time() - _start_time > life_time:
		poolable_node_component.return_to_pool()
