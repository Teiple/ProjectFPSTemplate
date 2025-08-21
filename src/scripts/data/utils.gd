class_name Utils
extends Node


static func either(a, b):
	if a == null:
		return b
	return a


static func lookat(node : Spatial, lookat_position : Vector3):
	lookat_direction(node, (lookat_position - node.global_position).normalized())


static func lookat_direction(node : Spatial, direction : Vector3):
	# Godot use -Z for forward
	var z = -direction
	
	var used_node_x = false
	var u = Vector3.UP
	var dot = z.dot(Vector3.UP) 
	if abs(dot) > 0.98:
		u = node.global_transform.basis.x
		used_node_x = true
	
	var v = z.cross(u).normalized()
	u = z.cross(v).normalized()
	
	var basis = null
	if used_node_x:
		basis = Basis(u, v, z)
	else:
		basis = Basis(v, u, z)
	
	node.global_transform = Transform(basis, node.global_position)


static func is_adjacent(a: AABB, b: AABB) -> bool:
	var a_min = a.position
	var a_max = a.end
	var b_min = b.position
	var b_max = b.end

	# Check X-adjacency (touching on X, overlapping on Y && Z)
	if a_max.x == b_min.x || b_max.x == a_min.x:
		if a_min.y < b_max.y && b_min.y < a_max.y && a_min.z < b_max.z && b_min.z < a_max.z:
			return true

	# Check Y-adjacency (touching on Y, overlapping on X && Z)
	if a_max.y == b_min.y || b_max.y == a_min.y:
		if a_min.x < b_max.x && b_min.x < a_max.x && a_min.z < b_max.z && b_min.z < a_max.z:
			return true

	# Check Z-adjacency (touching on Z, overlapping on X && Y)
	if a_max.z == b_min.z || b_max.z == a_min.z:
		if a_min.x < b_max.x && b_min.x < a_max.x && a_min.y < b_max.y && b_min.y < a_max.y:
			return true

	return false


static func intersects_sphere(aabb : AABB, sphere_center : Vector3, sphere_radius : float) -> bool:
	return intersects_sphere_radius_sqr(aabb, sphere_center, sphere_radius * sphere_radius)


static func intersects_sphere_radius_sqr(aabb : AABB, sphere_center : Vector3, sphere_radius_sqr : float) -> bool:
	var c = sphere_center
	var r_sqr = sphere_radius_sqr
	# Calculate the closest point to the box
	var c_x = max(aabb.position.x, min(aabb.end.x, c.x))
	var c_y = max(aabb.position.y, min(aabb.end.y, c.y))
	var c_z = max(aabb.position.z, min(aabb.end.z, c.z))
	
	var d_sqr = (c.x - c_x) * (c.x - c_x) + (c.y - c_y) * (c.y - c_y) + (c.z - c_z) * (c.z - c_z)
	if d_sqr <= r_sqr:
		return true
	
	return false
