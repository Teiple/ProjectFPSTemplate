class_name Decal
extends Spatial

export var project_on_start : bool = false
export var life_time : float = 2.0

onready var poolable_node_component : PoolableNodeComponent = $PoolableNodeComponent
onready var decal_projection : DecalProjection = $DecalProjection

var _start_time : float = 0.0


func _ready():
	poolable_node_component.init_serialization_func(funcref(self, "serialize"))
	poolable_node_component.init_deserialization_func(funcref(self, "deserialize"))
	
	if project_on_start:
		decal_projection.perform_projection()


func serialize() -> Dictionary:
	var parent_path = get_parent().get_path()
	return {
		"local_transform": var2str(transform),
		"decal_target": parent_path
	}


func deserialize(data : Dictionary):
	var decal_target = Utils.either(str2var(data.get("decal_target")), null)
	if decal_target != null:
		# Assume decal_target uses global path (with /root/ prefix)
		var new_parent = get_node_or_null(decal_target)
		if new_parent != null:
			get_parent().remove_child(self)
			new_parent.add_child(self)
	
	transform = Utils.either(str2var(data.get("local_transform")), transform)
	
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
