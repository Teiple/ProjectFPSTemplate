class_name AutoPushComponent
extends Component

export var margin : float = 0.1
export var push_force : float = 2.0

onready var _touching_check: ShapeCast = $TouchingCheck
onready var _ground_check: ShapeCast = $GroundCheck

var _is_crouching : bool = false

# Override
static func get_component_name() -> String:
	return "AutoPushComponent"


func _process(delta: float) -> void:
	var player = _get_player()
	if _touching_check.shape == null || player.is_crouching() != _is_crouching:
		_is_crouching = player.is_crouching()
		_touching_check.position = player.get_collision_shape().position
		_touching_check.shape = player.get_collision_shape().shape


func _physics_process(delta: float) -> void:
	var player = _get_player()
	if !player.is_moving() || _touching_check.shape == null:
		return
	_touching_check.force_shapecast_update()
	for i in _touching_check.get_collision_count():
		var collider = _touching_check.get_collider(i)
		if !(collider is RigidBody):
			continue
		var collision_point = collider.global_position #_touching_check.get_collision_point(i)
		var collision_direction = (collision_point - player.global_position).normalized()
		var physical_comp = Component.find(collider, PhysicalObjectComponent.get_component_name()) as PhysicalObjectComponent
		if physical_comp != null:
			physical_comp.apply_force(collision_point, collision_direction, push_force)


func _get_player() -> Player:
	return owner as Player 


func will_colliding_with(collision_obj : CollisionObject, motion : Vector3) -> bool:
	var old_position = _touching_check.global_position
	var old_mask = _touching_check.collision_mask
	_touching_check.global_position -= motion
	_touching_check.collision_mask = collision_obj.collision_layer
	_touching_check.force_shapecast_update()
	for i in _touching_check.get_collision_count():
		var collider = _touching_check.get_collider(i)
		if collider == collision_obj:
			_touching_check.global_position = old_position
			_touching_check.collision_mask = old_mask
			return true
	_touching_check.global_position = old_position
	_touching_check.collision_mask = old_mask
	return false


func will_on_top_of(collision_obj : CollisionObject, motion : Vector3) -> bool:
	if _ground_check.shape == null:
		_ground_check.shape = SphereShape.new()
		var base_radius = _get_player().get_collision_shape().shape.radius
		_ground_check.shape.radius = base_radius - 0.02
		_ground_check.position.y = base_radius - 0.04
	
	var old_position = _ground_check.global_position
	var old_mask = _ground_check.collision_mask
	_ground_check.global_position -= motion
	_ground_check.collision_mask = collision_obj.collision_layer
	_ground_check.force_shapecast_update()
	for i in _ground_check.get_collision_count():
		var collider = _ground_check.get_collider(i)
		var col_point = _ground_check.get_collision_point(i)
		if collider == collision_obj:
			_ground_check.collision_mask = old_mask
			_ground_check.global_position = old_position
			return true
	_ground_check.collision_mask = old_mask
	_ground_check.global_position = old_position
	
	return false
