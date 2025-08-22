tool
class_name DecalProjection
extends ImmediateGeometry

const __Z_FIGHTING_OFFSET = 0.01
const MIN_ANGLE_DOT = 0.5

export var projection_extents: Vector3 = Vector3(1, 1, 1) # Half-extents of the box
export var project_on_start : bool = false
export var debug : bool = false

export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var preview := false setget set_preview
export var clipping_replay_step := -1 setget set_clipping_replay_step
export var clipping_replay_redraw := false setget set_clipping_replay_redraw
export var export_save_guard_end : bool = true setget set_export_save_guard_end

# onready var shapecast : ShapeCast = $ShapeCast
onready var _raycast : RayCast = $RayCast
onready var _shapecast : ShapeCast = $ShapeCast

var _decal_aabb : AABB = AABB()
var _planes : Array = []
var _all_norms : Array = []
var _all_verts : Array = []
var _box_edges : Array = []

var _is_saving := false
var clipping_replay : Array = []

class ClippingStep:
	var local_triangle = PoolVector3Array()
	var extra_local_triangle = PoolVector3Array()
	var next_local_triangle = PoolVector3Array()
	var current_plane = Plane()
	var included_verts = PoolVector3Array()
	var outside = false


func _ready():
	_box_edges = get_box_edges()
	_planes = Geometry.build_box_planes(projection_extents)
	if project_on_start:
		perform_projection()


func clear_all():
	_all_verts.clear()
	_all_norms.clear()
	clear()


func fast_perform_projection(collider : CollisionObject, shape_id : int):
	clear_all()
	var collision_shape = collider.shape_owner_get_owner(collider.shape_find_owner(shape_id))
	var added_collision_shapes = []
	add_surfaces_from_collision_shape(collision_shape, added_collision_shapes)
	
	if added_collision_shapes.size() > 0:
		render_surfaces()


func perform_projection():
	clear_all()
	
	if _raycast == null:
		_raycast = $RayCast
	_raycast.force_raycast_update()
	
	if !_raycast.is_colliding():
		return
	if _shapecast == null:
		_shapecast = $ShapeCast
	_shapecast.force_shapecast_update()
	if !_shapecast.is_colliding():
		return
	
	var collision_point = _raycast.get_collision_point()
	global_position = collision_point
	
	var added_collision_shapes = []
	for i in _shapecast.get_collision_count():
		var collider = _shapecast.get_collider(i)
		var shape_id = _shapecast.get_collider_shape(i)
		var collision_shape = collider.shape_owner_get_owner(collider.shape_find_owner(shape_id))
		add_surfaces_from_collision_shape(collision_shape, added_collision_shapes)
	
	if _planes.empty():
		_planes = Geometry.build_box_planes(projection_extents)
	if _box_edges.empty():
		_box_edges = get_box_edges()
	
	if added_collision_shapes.size() > 0:
		render_surfaces()


func add_surfaces_from_collision_shape(collision_shape : CollisionShape, added_collision_shapes : Array) -> void:
	if !_add_surfaces_from_collision_shape(collision_shape):
		return
	added_collision_shapes.push_back(collision_shape)
	
	# Adding adjacent collision shapes too, so decal won't be cut off from one's edge to another's face
	if collision_shape.has_meta(GlobalData.Ref.ADJACENT_COLLISION_SHAPES_META_NAME):
		var adjacents = collision_shape.get_meta(GlobalData.Ref.ADJACENT_COLLISION_SHAPES_META_NAME)
		for adjacent_path in adjacents:
			var adjacent_collision_shape = collision_shape.get_node_or_null(adjacent_path) as CollisionShape
			if _add_surfaces_from_collision_shape(adjacent_collision_shape):
				added_collision_shapes.push_back(adjacent_collision_shape)


func _add_surfaces_from_collision_shape(collision_shape : CollisionShape):
	if collision_shape == null || collision_shape.get_child_count() == 0:
		return false
	
	if !_check_for_overlap(collision_shape):
		return false
	
	var mesh_instance = collision_shape.get_node_or_null(GlobalData.Ref.DECAL_MESH_INSTANCE_NAME) as MeshInstance
	if mesh_instance == null:
		return false
	
	if  mesh_instance.mesh.get_surface_count() == 0:
		return false
	
	var arrays = mesh_instance.mesh.surface_get_arrays(0)
	# If does not have array indices defined, create our own
	if arrays[ArrayMesh.ARRAY_INDEX] == null:
		# If vertices not divisable by 3, ignore this mesh
		if arrays[ArrayMesh.ARRAY_VERTEX].size() % 3 != 0:
			return false
		arrays[ArrayMesh.ARRAY_INDEX] = range(arrays[ArrayMesh.ARRAY_VERTEX].size())
	
	add_surfaces(mesh_instance, arrays[ArrayMesh.ARRAY_VERTEX], arrays[ArrayMesh.ARRAY_NORMAL], arrays[ArrayMesh.ARRAY_INDEX])
	return true


func _check_for_overlap(collision_shape : CollisionShape) -> bool:
	if !collision_shape.has_meta(GlobalData.Ref.COLLISION_SHAPE_AABB_META_NAME):
		return true
	var aabb = collision_shape.get_meta(GlobalData.Ref.COLLISION_SHAPE_AABB_META_NAME)
	if aabb.has_point(global_position):
		return true
	var radius_sqr = (projection_extents * 2.0).length_squared() / 4.0
	
	return Utils.intersects_sphere_radius_sqr(aabb, global_position, radius_sqr)
 

func add_surfaces(base : Spatial, vertices : PoolVector3Array, normals : PoolVector3Array, indices : PoolIntArray):
	for i in range(0, indices.size(), 3):
		var n0 = normal_to_new_base(base, self, normals[indices[i]])
		if n0.dot(Vector3.FORWARD) > MIN_ANGLE_DOT:
			var n1 = normal_to_new_base(base, self, normals[indices[i + 1]])
			var n2 = normal_to_new_base(base, self, normals[indices[i + 2]])
			var v0 = point_to_new_base(base, self, vertices[indices[i]])
			var v1 = point_to_new_base(base, self, vertices[indices[i + 1]])
			var v2 = point_to_new_base(base, self, vertices[indices[i + 2]])

			_all_verts.append_array([v0, v1, v2])
			_all_norms.append_array([n0, n1, n2])
	# push_out_vertices_outwards()


# This is very expensive. Since we aimed to optimize by using dedicated decal meshes to project on
# We can just make those meshes grow instead
func __push_out_vertices_outwards():
	# Improved from Mizizizi code, avoid recompue the average normal for the same vertex again
	# ... Don't really know if this is faster thou
	var averaged_normals = {}
	var verts_to_norms = {}
	
	# Collect all normals per unique vertex
	for i in _all_verts.size():
		var index = vec3_to_index(_all_verts[i])
		if !verts_to_norms.has(index):
			verts_to_norms[index] = {}
		var normal = _all_norms[i]
		var normal_index = vec3_to_index(normal)
		verts_to_norms[index][normal_index] = normal

	# Compute averaged normals once per unique vertex
	for index in verts_to_norms.keys():
		var norms = verts_to_norms[index].values()
		var sum_of_normals = Vector3()
		for norm in norms:
			sum_of_normals += norm
		sum_of_normals /= norms.size()
		averaged_normals[index] = sum_of_normals

	# Apply offset using precomputed average normal
	for i in _all_verts.size():
		var index = vec3_to_index(_all_verts[i])
		_all_verts[i] += averaged_normals[index] * __Z_FIGHTING_OFFSET


func normal_to_new_base(from_base : Spatial, to_base : Spatial, norm : Vector3):
	var global_dir = from_base.global_transform.basis.xform(norm)
	return to_base.global_transform.basis.xform_inv(global_dir)


func point_to_new_base(from_base : Spatial, to_base : Spatial, vert : Vector3):
	return to_base.to_local(from_base.to_global(vert))


func render_surfaces():
	begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(0, _all_verts.size(), 3):
		var vert0 = _all_verts[i]
		var vert1 = _all_verts[i+1]
		var vert2 = _all_verts[i+2]
		var vert_count = verts_in_area(vert0, vert1, vert2)
		if vert_count == 3:
			var norm0 = _all_norms[i]
			var norm1 = _all_norms[i+1]
			var norm2 = _all_norms[i+2]
			
			var uv0 = get_uv_from_vert(vert0)
			var uv1 = get_uv_from_vert(vert1)
			var uv2 = get_uv_from_vert(vert2)
			
			set_normal(norm0)
			set_uv(uv0)
			add_vertex(vert0)
			
			set_normal(norm1)
			set_uv(uv1)
			add_vertex(vert1)
			
			set_normal(norm2)
			set_uv(uv2)
			add_vertex(vert2)
		elif vert_count > 0 || area_overlaps_tri(vert0, vert1, vert2):
			var clipped_verts = []
			clip_tri_to_area(_all_verts[i], _all_verts[i+1], _all_verts[i+2], clipped_verts)
			for vert in clipped_verts:
				var norm = _all_norms[i]
				var uv = get_uv_from_vert(vert)
				set_normal(norm)
				set_uv(uv)
				add_vertex(vert)
	
	end()


func get_uv_from_vert(vert : Vector3) -> Vector2:
	var uv = Vector2(
		-vert.x / projection_extents.x,
		-vert.y / projection_extents.y
	)
	uv = uv * 0.5 + Vector2(0.5, 0.5)
	uv.x = clamp(uv.x, 0.0, 1.0)
	uv.y = clamp(uv.y, 0.0, 1.0)
	return uv


func get_triplanar_uv(vert: Vector3, normal: Vector3) -> Vector2:
	var local_pos = vert
	var uv: Vector2
	
	# Pick exact axis by normal direction (6 possibilities)
	if abs(normal.x) >= abs(normal.y) && abs(normal.x) >= abs(normal.z):
		if normal.x > 0.0:
			# +X facing: YZ plane
			uv = Vector2(local_pos.z, local_pos.y)
		else:
			# -X facing: flipped YZ plane
			uv = Vector2(-local_pos.z, local_pos.y)
	elif abs(normal.y) >= abs(normal.x) && abs(normal.y) >= abs(normal.z):
		if normal.y > 0.0:
			# +Y facing: XZ plane
			uv = Vector2(local_pos.x, local_pos.z)
		else:
			# -Y facing: flipped XZ plane
			uv = Vector2(local_pos.x, -local_pos.z)
	elif abs(normal.z) >= abs(normal.x) && abs(normal.z) >= abs(normal.y):
		if normal.z < 0.0: 
			# -Z facing: flipped XY plane
			uv = Vector2(local_pos.x, local_pos.y)
		else:
			# +Z facing: XY plane
			uv = Vector2(-local_pos.x, local_pos.y)
	
	# Normalize to 0..1 space using decal extents
	uv = Vector2(
		-uv.x / projection_extents.x,
		-uv.y / projection_extents.y
	)
	
	# Center in 0..1 space
	uv = uv * 0.5 + Vector2(0.5, 0.5)
	
	# Clamp to avoid sampling outside
	uv.x = clamp(uv.x, 0.0, 1.0)
	uv.y = clamp(uv.y, 0.0, 1.0)
	
	return uv



func verts_in_area(vert0, vert1, vert2):
	var num_of_verts_in_area = 0
	if area_contains_vert(vert0):
		num_of_verts_in_area += 1
	if area_contains_vert(vert1):
		num_of_verts_in_area += 1
	if area_contains_vert(vert2):
		num_of_verts_in_area += 1
	return num_of_verts_in_area


func area_contains_vert(vert: Vector3) -> bool:
	return (
		abs(vert.z) < projection_extents.z &&
		abs(vert.x) < projection_extents.x &&
		abs(vert.y) < projection_extents.y
	)


func get_box_edges() -> Array:
	var f = projection_extents.z
	var x = projection_extents.x
	var y = projection_extents.y
	
	var front = Vector3(0, 0, f)
	var back = Vector3(0, 0, -f)
	var right = Vector3(x, 0, 0)
	var left = Vector3(-x, 0, 0)
	var top = Vector3(0, y, 0)
	var bot = Vector3(0, -y, 0)
	
	var corners = {
		"ftr": front + top + right,
		"ftl": front + top + left,
		"fbr": front + bot + right,
		"fbl": front + bot + left,
		"btr": back + top + right,
		"btl": back + top + left,
		"bbr": back + bot + right,
		"bbl": back + bot + left
	}
	
	return [
		[corners.btr, corners.ftr], [corners.btl, corners.ftl], [corners.bbr, corners.fbr], [corners.bbl, corners.fbl],
		[corners.ftl, corners.ftr], [corners.fbl, corners.fbr], [corners.btl, corners.btr], [corners.bbl, corners.bbr],
		[corners.ftr, corners.fbr], [corners.ftl, corners.fbl], [corners.btr, corners.bbr], [corners.btl, corners.bbl]
	]


func area_overlaps_tri(vert0 : Vector3, vert1 : Vector3, vert2 : Vector3):
	# Check if any edge of the box intersects the triangle.
	# This covers cases where the box is partially or fully inside the triangle.
	for edge in _box_edges:
		if Geometry.segment_intersects_triangle(edge[0], edge[1], vert0, vert1, vert2):
			return true
	
	# Check if any edge of the triangle intersects the convex area (box).
	# This covers cases where the triangle is partially or fully inside the box.
	if Geometry.segment_intersects_convex(vert0, vert1, _planes).size() != 0:
		return true
	if Geometry.segment_intersects_convex(vert1, vert2, _planes).size() != 0:
		return true
	if Geometry.segment_intersects_convex(vert2, vert0, _planes).size() != 0:
		return true
	
	# If no intersection is found in either direction, there is no overlap.
	return false



func clip_tri_to_area(vert0 : Vector3, vert1 : Vector3, vert2 : Vector3, returned_verts : Array):
	var remainders = []
	
	var outside = false
	var cur_tri = [vert0, vert1, vert2]
	
	for plane in _planes:
		var clipped_poly = Geometry.clip_polygon(cur_tri, plane)
		#### <<Debug
		var clipping_step = null
		if debug:
			clipping_step = ClippingStep.new()
			clipping_step.current_plane = plane
			clipping_step.local_triangle = PoolVector3Array(cur_tri)
		#### Debug>>
		if clipped_poly.size() == 3:
			cur_tri = clipped_poly
			#### <<Debug
			if debug:
				clipping_step.next_local_triangle = PoolVector3Array(cur_tri)
			#### Debug>>
		elif clipped_poly.size() == 4:
			var extra_tri = [clipped_poly[0],clipped_poly[1],clipped_poly[2]]
			remainders.append_array(extra_tri)
			#### <<Debug
			if debug:
				clipping_step.extra_local_triangle = PoolVector3Array(extra_tri)
			#### Debug>>
			cur_tri = [clipped_poly[0], clipped_poly[2], clipped_poly[3]]
			#### <<Debug
			if debug:
				clipping_step.next_local_triangle = PoolVector3Array(cur_tri)
			#### Debug>>
		else:
			outside = true
			#### <<Debug
			if debug:
				clipping_step.outside = true
			#### Debug>>
		
		#### <<Debug
		clipping_replay.push_back(clipping_step)
		#### Debug>>
		
		if outside:
			break
	
	var tris = []
	if !outside:
		tris = cur_tri
	
	# Process extra triangles
	for i in range(0, remainders.size(), 3):
		clip_tri_to_area(remainders[i], remainders[i+1], remainders[i+2], returned_verts)
	#### <<Debug
	if debug:
		var clipping_step = ClippingStep.new()
		clipping_step.included_verts = tris
		clipping_replay.push_back(clipping_step)
	#### Debug>>
	returned_verts.append_array(tris)


func vec3_to_index(v3):
	var round_amnt = 1000
	return "(" + str(int(v3.x * round_amnt)) + "," + str(int(v3.y * round_amnt)) + "," + str(int(v3.z * round_amnt)) + ")"

# Tool functions
func set_export_save_guard_start(val):
	if val == false:
		return
	_is_saving = true


func set_export_save_guard_end(val):
	if val == false:
		return
	_is_saving = false


func set_preview(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	perform_projection()


func set_clipping_replay_redraw(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	_clipping_replay_redraw(clipping_replay_step)


func set_clipping_replay_step(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	clipping_replay_step = max(val, 0)
	_clipping_replay_redraw(clipping_replay_step)


func to_global_verts(verts : PoolVector3Array) -> PoolVector3Array:  
	var global_verts = []
	for v in verts:
		global_verts.push_back(to_global(v))
	return global_verts


func _clipping_replay_redraw(step_index : int):
	var duration = 0.5
	
	if step_index < clipping_replay.size():
		var step = clipping_replay[step_index] as ClippingStep
		var color = Color.red if step.outside else Color.green 
		
		if step.current_plane != Plane():
			DebugDraw.draw_arrow_line(global_position, to_global(step.current_plane.normal), Color.cyan, 0.05, true, duration)
			DebugDraw.draw_square(to_global(step.current_plane.normal * step.current_plane.d), 0.01, Color.cyan, duration)
			
			var pos = to_global(step.current_plane.normal * step.current_plane.d)
			var normal = (to_global(step.current_plane.normal * (step.current_plane.d + 1.0)) - global_position).normalized()
			
			$CutPlane.global_position = pos
			var dot = Vector3.UP.dot(normal)
			if abs(dot) > 0.95:
				if dot > 0:
					$CutPlane.rotation.x = PI * 0.5
				else:
					$CutPlane.rotation.x = -PI * 0.5
			else:
				$CutPlane.look_at(pos + normal, Vector3.UP)
		
		if !step.local_triangle.empty():
			var triangle_loop = to_global_verts(step.local_triangle)
			triangle_loop.append(triangle_loop[0])
			DebugDraw.draw_point_path(triangle_loop, 0.002, color, color, duration)
		
		if !step.next_local_triangle.empty():
			var next_triangle_loop = to_global_verts(step.next_local_triangle)
			next_triangle_loop.append(next_triangle_loop[0])
			DebugDraw.draw_point_path(next_triangle_loop, 0.002, Color.blue, Color.blue, duration)
		
		if !step.extra_local_triangle.empty():
			var extra_triangle_loop = to_global_verts(step.extra_local_triangle)
			extra_triangle_loop.append(extra_triangle_loop[0])
			DebugDraw.draw_point_path(extra_triangle_loop, 0.002, Color.yellow, Color.yellow, duration)
		
		if !step.included_verts.empty():
			var global_verts = to_global_verts(step.included_verts)
			for v in global_verts:
				DebugDraw.draw_sphere(v, 0.005, Color.purple, duration)
