class_name AutoPushComponent
extends Spatial

export var margin : float = 0.1
export var push_force : float = 2.0

onready var _shapecast: ShapeCast = $ShapeCast

var _is_crouching : bool = false


func _process(delta: float) -> void:
	var player = _get_player()
	if _shapecast.shape == null || player.is_crouching() != _is_crouching:
		_is_crouching = player.is_crouching()
		_shapecast.position = player.get_collision_shape().position
		_shapecast.shape = _get_grown_shape(player.get_collision_shape().shape)


func _physics_process(delta: float) -> void:
	var player = _get_player()
	if !player.is_moving() || _shapecast.shape == null:
		return
	_shapecast.force_shapecast_update()
	for i in _shapecast.get_collision_count():
		var collider = _shapecast.get_collider(i)
		if !(collider is RigidBody):
			continue
		var collision_point = collider.global_position #_shapecast.get_collision_point(i)
		var collision_direction = ((collision_point - player.global_position) * Vector3(1, 0, 1)).normalized()
		var physical_comp = Component.find(collider, PhysicalObjectComponent.get_component_name()) as PhysicalObjectComponent
		if physical_comp != null:
			physical_comp.apply_force(collision_point, collision_direction, push_force)


func _get_player() -> Player:
	return owner as Player 


func _get_grown_shape(shape : CapsuleShape) -> CapsuleShape:
	if shape == null:
		return null
	var grown_shape = shape.duplicate()
	grown_shape.radius += margin
	return grown_shape
