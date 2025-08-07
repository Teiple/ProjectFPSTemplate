tool
class_name DecalProjectionDebug
extends ImmediateGeometry

const Z_FIGHTING_OFFSET = 0.01
const MIN_ANGLE_DOT = 0.0
const MESH_INSTANCE_NAME_FILTER := "DecalMeshPreference"

export var debug : bool = false
export var projection_extents: Vector3 = Vector3(1, 1, 1) # Half-extents of the box
export var project_on_start : bool = false

export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var preview := false setget set_preview
export var clipping_replay_step := -1 setget set_clipping_replay_step
export var clipping_replay_redraw := false setget set_clipping_replay_redraw
export var export_save_guard_end : bool = true setget set_export_save_guard_end

var _planes : Array = []
var _all_norms = []
var _all_verts = []
var _verts_to_norms = {}

var _is_saving := false
var clipping_replay : Array = []
var _added_verts : Array = []
var _precomputed_box_edges : Array = []

class ClippingStep:
	var local_triangle = PoolVector3Array()
	var extra_local_triangle = PoolVector3Array()
	var next_local_triangle = PoolVector3Array()
	var current_plane = Plane()
	var included_verts = PoolVector3Array()
	var outside = false


func _ready():
	_precomputed_box_edges = get_box_edges()
	init_planes()


func _process(delta):
	if Engine.editor_hint:
		return
	if project_on_start:
		perform_projection()
	set_process(false)


func clear_all():
	if debug:
		clipping_replay.clear()
	_all_verts.clear()
	_all_norms.clear()
	clear()


func perform_projection():
	var start_time = Time.get_ticks_msec()
	
	clear_all()
	if _planes.empty():
		init_planes()
	var shapecast = get_node_or_null("ShapeCast")
	if shapecast == null:
		return
	shapecast.force_shapecast_update()
	
	var mesh_instances = []
	for i in shapecast.get_collision_count():
		var collider = shapecast.get_collider(i)
		if collider.get_child_count() > 0:
			var mesh_instance = collider.get_node_or_null(MESH_INSTANCE_NAME_FILTER) as MeshInstance
			if mesh_instance != null:
				mesh_instances.push_back(mesh_instance)
	
	if mesh_instances.empty():
		return
	
	for mesh_instance in mesh_instances:
		if  mesh_instance.mesh.get_surface_count() == 0:
			continue
		var arrays = mesh_instance.mesh.surface_get_arrays(0)
		# If does not have array indices defined, create our own
		if arrays[ArrayMesh.ARRAY_INDEX] == null:
			# If vertices not divisable by 3, ignore this mesh
			if arrays[ArrayMesh.ARRAY_VERTEX].size() % 3 != 0:
				continue
			arrays[ArrayMesh.ARRAY_INDEX] = range(arrays[ArrayMesh.ARRAY_VERTEX].size())
		add_surfaces(mesh_instance, arrays[ArrayMesh.ARRAY_VERTEX], arrays[ArrayMesh.ARRAY_NORMAL], arrays[ArrayMesh.ARRAY_INDEX])
	render_surfaces()
	
	var end_time = Time.get_ticks_msec()
	print_debug("processed time: %d" % (end_time - start_time))
	#area.queue_free()


func add_surfaces(base, vertices, normals, indices):
	var dir = global_transform.basis.z
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
	push_out_vertices_outwards()


func push_out_vertices_outwards():
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
		_all_verts[i] += averaged_normals[index] * Z_FIGHTING_OFFSET


func __push_out_vertices_outwards():
	_verts_to_norms.clear()
	# Compile all normals corresponding to each vertice, since there are many duplicates
	for i in _all_verts.size():
		var index = vec3_to_index(_all_verts[i])
		if !_verts_to_norms.has(index):
			_verts_to_norms[index] = {}
		var normal = _all_norms[i]
		var normal_index = vec3_to_index(normal)
		_verts_to_norms[index][normal_index] = normal
	
	# Push the vertices along their normals to prevent zfighting with existing geometry
	for i in _all_verts.size():
		var index = vec3_to_index(_all_verts[i])
		var norms = _verts_to_norms[index].values()
		var sum_of_normals = Vector3()
		for norm in norms:
			sum_of_normals += norm
		sum_of_normals /= norms.size() # Normalize it
		_all_verts[i] += sum_of_normals * Z_FIGHTING_OFFSET # Push out the vert


func normal_to_new_base(from_base, to_base, norm):
	var global_dir = from_base.to_global(norm) - from_base.global_transform.origin
	return to_base.to_local(to_base.global_transform.origin + global_dir)


func point_to_new_base(from_base, to_base, vert):
	return to_base.to_local(from_base.to_global(vert))


func render_surfaces():
	begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(0, _all_verts.size(), 3):
		var vert0 = _all_verts[i]
		var vert1 = _all_verts[i+1]
		var vert2 = _all_verts[i+2]
		var vert_count = verts_in_area(vert0, vert1, vert2)
		if vert_count == 3:
			set_normal(_all_norms[i])
			#set_uv(__get_uv_from_vert_and_normal(_all_verts[i], _all_norms[i]))
			set_uv(get_uv_from_vert(_all_verts[i]))
			add_vertex(_all_verts[i])
			set_normal(_all_norms[i+1])
			set_uv(get_uv_from_vert(_all_verts[i+1]))
			#set_uv(__get_uv_from_vert_and_normal(_all_verts[i+1], _all_norms[i+1]))
			add_vertex(_all_verts[i+1])
			set_normal(_all_norms[i+2])
			set_uv(get_uv_from_vert(_all_verts[i+2]))
			#set_uv(__get_uv_from_vert_and_normal(_all_verts[i+2], _all_norms[i+2]))
			add_vertex(_all_verts[i+2])
		elif vert_count != 0 || area_overlaps_tri(vert0, vert1, vert2):
			var clipped_verts = []
			clip_tri_to_area(_all_verts[i], _all_verts[i+1], _all_verts[i+2], clipped_verts)
			_added_verts =  PoolVector3Array(clipped_verts)
			#_draw_verts(clipped_verts)
			# clipped_verts = double_check_clipped_tris(clipped_verts)
			for v in clipped_verts:
				set_normal(_all_norms[i])
				#set_uv(__get_uv_from_vert_and_normal(v, _all_norms[i]))
				set_uv(get_uv_from_vert(v))
				add_vertex(v)
	
	end()


func to_global_verts(verts : PoolVector3Array) -> PoolVector3Array:  
	var global_verts = []
	for v in verts:
		global_verts.push_back(to_global(v))
	return global_verts


func get_uv_from_vert(vert):
	var uv = Vector2(
		vert.x / projection_extents.x,
		-vert.y / projection_extents.y
	)
	uv = uv * 0.5 + Vector2(0.5, 0.5)
	uv.x = clamp(uv.x, 0.0, 1.0)
	uv.y = clamp(uv.y, 0.0, 1.0)
	return uv


func __get_uv_from_vert_and_normal(vert: Vector3, norm: Vector3) -> Vector2:
	var abs_n = norm.abs()
	var uv: Vector2

	if abs_n.z >= abs_n.x && abs_n.z >= abs_n.y:
		# Use XY plane (Z is dominant)
		uv = Vector2(vert.x / projection_extents.x, -vert.y / projection_extents.y)
	elif abs_n.x >= abs_n.y:
		# Use YZ plane (X is dominant)
		uv = Vector2(-vert.z / projection_extents.z, -vert.y / projection_extents.y)
	else:
		# Use XZ plane (Y is dominant)
		uv = Vector2(-vert.x / projection_extents.x, vert.z / projection_extents.z)

	uv = uv * 0.5 + Vector2(0.5, 0.5)
	uv = Vector2(
		clamp(uv.x, 0.0, 1.0),
		clamp(uv.y, 0.0, 1.0)
	)
	
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
	# Step 1: Check if any edge of the box intersects the triangle.
	# This covers cases where the box is partially or fully inside the triangle.
	if _precomputed_box_edges.empty():
		_precomputed_box_edges = get_box_edges()
	for edge in _precomputed_box_edges:
		if Geometry.segment_intersects_triangle(edge[0], edge[1], vert0, vert1, vert2):
			return true
	
	# Step 2: Check if any edge of the triangle intersects the convex area (box).
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
	var remainders = PoolVector3Array()
	
	var outside = false
	var cur_tri = PoolVector3Array([vert0, vert1, vert2])
	
	for plane in _planes:
		var clipped_poly = Geometry.clip_polygon(cur_tri, plane)
		#### <<Debug
		var clipping_step = null
		if debug:
			clipping_step = ClippingStep.new()
			clipping_step.current_plane = plane
			clipping_step.local_triangle = cur_tri
		#### Debug>>
		if clipped_poly.size() == 3:
			cur_tri = clipped_poly
			#### <<Debug
			if debug:
				clipping_step.next_local_triangle = cur_tri
			#### Debug>>
		elif clipped_poly.size() == 4:
			var extra_tri = PoolVector3Array([clipped_poly[0],clipped_poly[1],clipped_poly[2]])
			remainders.append_array(extra_tri)
			#### <<Debug
			if debug:
				clipping_step.extra_local_triangle = extra_tri
			#### Debug>>
			
			cur_tri = PoolVector3Array([clipped_poly[0], clipped_poly[2], clipped_poly[3]])
			
			#### <<Debug
			if debug:
				clipping_step.next_local_triangle = cur_tri
			#### Debug>>
		else:
			outside = true
			#### <<Debug
			if debug:
				clipping_step.outside = true
			#### Debug>>
		
		#### <<Debug
		# clipping_step.included_verts = PoolVector3Array(returned_verts)
		clipping_replay.push_back(clipping_step)
		#### Debug>>
		
		if outside:
			break
	
	var tris = PoolVector3Array()
	if !outside:
		tris = PoolVector3Array([cur_tri[0], cur_tri[1], cur_tri[2]])
	# Process extra triangles
	for i in range(0, remainders.size(), 3):
		clip_tri_to_area(remainders[i], remainders[i+1], remainders[i+2], returned_verts)
	#### <<Debug
	var clipping_step = null
	if debug:
		clipping_step = ClippingStep.new()
		clipping_step.included_verts = tris
		clipping_replay.push_back(clipping_step)
	#### Debug>>
	
	returned_verts.append_array(Array(tris))


# Not written by me
func _sort_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> PoolVector3Array:
	var points = [a, b, c, d]
	var centroid = (a + b + c + d) / 4.0

	# Compute the normal of the plane
	var normal = ((b - a).cross(c - a)).normalized()

	# Choose arbitrary axes on the plane
	var axis_x = (a - centroid).normalized()
	var axis_y = normal.cross(axis_x).normalized()

	# Create a list of tuples (angle, point)
	var angles = []
	for i in points.size():
		var p = points[i]
		
		var v = p - centroid
		var x = v.dot(axis_x)
		var y = v.dot(axis_y)
		var angle = atan2(y, x)
		angles.append({ "angle": angle, "point": p, "index": i})

	# Sort by angle
	angles.sort_custom(self, "_angle_sort")

	# Return sorted points
	var result := PoolVector3Array()
	var indices := []
	for item in angles:
		result.append(item["point"])
		indices.append(item["index"])
	return result

func _angle_sort(a, b) -> bool:
	return a["angle"] < b["angle"]


func double_check_clipped_tris(tri_arr):
	# Sometimes clipping bugs out and returns tris outside area, this prevents that
	var clipped_verts = []
	if tri_arr.size() % 3 != 0: 
		return PoolVector3Array([])
	for i in range(0, tri_arr.size(), 3):
		var is_in = true
		for j in range(3):
			var vert = tri_arr[i+j]
			var tmp_vert = vert * 0.999 # Move it slightly closer to the center to make it is correctly check if it's inside
			if tmp_vert.z < 0:
				tmp_vert.z += 0.01
			if !area_contains_vert(tmp_vert):
				is_in = false
		if is_in:
			clipped_verts.append(tri_arr[i])
			clipped_verts.append(tri_arr[i+1])
			clipped_verts.append(tri_arr[i+2])
	return PoolVector3Array(clipped_verts)


func init_planes():
	_planes = []
	_planes.append(Plane(Vector3.BACK, projection_extents.z))   # front face
	_planes.append(Plane(Vector3.FORWARD, projection_extents.z))                # back face
	_planes.append(Plane(Vector3.RIGHT, projection_extents.x))  # left face
	_planes.append(Plane(Vector3.LEFT, projection_extents.x))   # right face
	_planes.append(Plane(Vector3.UP, projection_extents.y))     # bottom face
	_planes.append(Plane(Vector3.DOWN, projection_extents.y))   # top face


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
