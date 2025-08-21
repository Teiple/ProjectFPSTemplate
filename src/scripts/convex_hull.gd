class_name ConvexHull

class TriByIds:
	var a := 0
	var b := 0
	var c := 0
	func _init(_a, _b, _c):
		a = _a; b = _b; c = _c;


class Trig:
	var a := Vector3()
	var b := Vector3()
	var c := Vector3()
	func _init(_a, _b, _c):
		a = _a; b = _b; c = _c;
	func get_normal() -> Vector3:
		var ab = b - a
		var ac = c - a
		return -ab.cross(ac).normalized()



class EdgByIds:
	var a := 0
	var b := 0
	func _init(_a, _b):
		a = _a; b = _b;
	func is_equal(verts : Array, e : EdgByIds) -> bool:
		var a_pos = verts[a]
		var b_pos = verts[b]
		var e_a_pos = verts[e.a]
		var e_b_pos = verts[e.b]
		return (a_pos.is_equal_approx(e_a_pos) && b_pos.is_equal_approx(e_b_pos)) || \
		(a_pos.is_equal_approx(e_b_pos) && b_pos.is_equal_approx(e_a_pos))

static func _get_edg_id_in_horizon(verts : Array, e : EdgByIds, horizon : Array) -> int:
	for i in horizon.size():
		if e.is_equal(verts, horizon[i]):
			return i
	return -1


static func _incremental_convex_hull(verts : Array, tris_lst : Array, nw_vert_idx : int):
	var nw_vert = verts[nw_vert_idx]
	# The horizon stores the **edges** surrounding the visible triangles
	var horizon = []
	# Loop through all triangles and check if the new vertex can "see" them
	# If it can, the triangle should be removed
	var tris_lst_size = tris_lst.size()
	for i in range(tris_lst_size-1, -1, -1):
		var tri = tris_lst[i]
		var trig = _to_trig(verts, tri)
		if _can_see(trig, nw_vert):
			# If the edge is not share, it is part of the horizon
			var edgs = [
				EdgByIds.new(tri.a, tri.b),
				EdgByIds.new(tri.b, tri.c),
				EdgByIds.new(tri.c, tri.a),
			]
			for e in edgs:
				var ei = _get_edg_id_in_horizon(verts, e, horizon)
				if ei >= 0:
					# Edge is shared, remove from horizon
					# It will certainly won't get re-added again
					# since one edge can only be shared by 2 triangles in a convex mesh 
					# horizon[ei] = horizon.back()
					horizon.remove(ei)
				else:
					horizon.push_back(e)
			# remove this visible triangle
			tris_lst[i] = tris_lst.back()
			tris_lst.pop_back()
			#tris_lst.remove(i)
			#DebugDraw.draw_point_path(PoolVector3Array([trig.a, trig.b, trig.c, trig.a]), 0.1, Color.green, Color.green, 5.0)
	
	# Form new triangles with the horizon edges
	# The correct order is guaranteed by adding the new vertex as the last vertex
	for e in horizon:
		tris_lst.push_back(TriByIds.new(
			e.a,
			e.b,
			nw_vert_idx
		))
	return


static func _can_see(trig : Trig, p : Vector3) -> bool:
	var n = trig.get_normal()
	var ap = p - trig.a
	return n.dot(ap) > 0.001


static func _to_trig(verts : Array, tri_by_ids : TriByIds) -> Trig:
	return Trig.new(
		verts[tri_by_ids.a],
		verts[tri_by_ids.b],
		verts[tri_by_ids.c]
	)


static func _create_convex_mesh(verts : Array, step : int) -> Array:
	if verts.size() < 4 || step == 0:
		return []
	
	# Form the initial terahedron
	var a = verts[0]
	var b = verts[1]
	var c = verts[2]
	
	var tris_lst = []
	
	var ab = b - a
	var ac = c - a
	var cross_pdct = ab.cross(ac)
	
	var d_idx = -1
	for i in range(3, verts.size()):
		var candidate = verts[i]
		var dot = (candidate - a).dot(cross_pdct)
		if dot < 0:
			# when d is behind abc plane
			d_idx = i
			tris_lst.push_back(TriByIds.new(2, 1, 0)) # cba
			tris_lst.push_back(TriByIds.new(i, 2, 0)) # dca
			tris_lst.push_back(TriByIds.new(1, i, 0)) # bda
			tris_lst.push_back(TriByIds.new(2, i, 1)) # cdb
			break
		elif dot > 0:
			d_idx = i
			# when d is infront of abc plane
			tris_lst.push_back(TriByIds.new(1, 2, 0)) # \bca
			tris_lst.push_back(TriByIds.new(2, i, 0)) # cda
			tris_lst.push_back(TriByIds.new(i, 1, 0)) # dba
			tris_lst.push_back(TriByIds.new(i, 2, 1)) # dcb
			break
	
	if d_idx < 0:
		return []
	
	if step == 1:
		return tris_lst
	
	var build_step = 2
	# Add new vertices and form new convex hull everytime
	for i in range(3, verts.size()):
		if i == d_idx:
			continue
		_incremental_convex_hull(verts, tris_lst, i)
		# For debugging purpose
		if build_step == step:
			return tris_lst
		build_step += 1
	
	return tris_lst


static func _flatten_tris_list(tris_list : Array) -> Array:
	var id_lst = []
	for tri in tris_list:
		id_lst.push_back(tri.a)
		id_lst.push_back(tri.b)
		id_lst.push_back(tri.c)
	return id_lst


static func _get_arr_verts(verts : Array, tris_lst: Array) -> Array:
	var arr_verts = []
	for tri in tris_lst:
		arr_verts.push_back(verts[tri.a])
		arr_verts.push_back(verts[tri.b])
		arr_verts.push_back(verts[tri.c])
	return arr_verts


static func _get_arr_verts_unique(verts : Array) -> Array:
	var arr_verts = {}
	for vert in verts:
		arr_verts[vec3_to_index(vert)] = vert
	return arr_verts.values()


static func _get_arr_norms(verts : Array, tris_lst : Array) -> Array:
	var arr_norms = []
	for tri in tris_lst:
		var trig = _to_trig(verts, tri)
		var n = trig.get_normal()
		for i in 3:
			arr_norms.push_back(n)
	return arr_norms


static func create_convex_mesh(verts : Array, margin : float = 0.001, step : int = -1) -> Mesh:
	var tris_list = _create_convex_mesh(verts, step)
	
	if tris_list.empty():
		return null
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var arr_verts = _get_arr_verts(verts, tris_list)
	var arr_norms = _get_arr_norms(verts, tris_list)
	grow_verts_along_norms(arr_verts, arr_norms, margin)
	arrays[ArrayMesh.ARRAY_VERTEX] = PoolVector3Array(arr_verts)
	arrays[ArrayMesh.ARRAY_INDEX] = PoolIntArray(range(arr_verts.size()))
	arrays[ArrayMesh.ARRAY_NORMAL] = PoolVector3Array(arr_norms)
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return arr_mesh


static func create_convex_shape(verts : Array, margin : float = 0.001) -> ConvexPolygonShape:
	var tris_list = _create_convex_mesh(verts, -1)
	
	if tris_list.empty():
		return null
	
	var points = []
	
	if abs(margin) > 1e-8:
		var arr_verts = _get_arr_verts(verts, tris_list)
		var arr_norms = _get_arr_norms(verts, tris_list)
		grow_verts_along_norms(arr_verts, arr_norms, margin)
		points = _get_arr_verts_unique(arr_verts)
	else:
		points = _get_arr_verts_unique(verts)
	
	var convex_shape = ConvexPolygonShape.new()
	convex_shape.points = points
	
	return convex_shape


static func grow_verts_along_norms(arr_verts : Array, arr_norms : Array, amount : float):
	# Improved from Mizizizi code, avoid recompue the average normal for the same vertex again
	# ... Don't really know if this is faster thou
	var averaged_normals = {}
	var verts_to_norms = {}
	
	# Collect all normals per unique vertex
	for i in arr_verts.size():
		var index = vec3_to_index(arr_verts[i])
		if !verts_to_norms.has(index):
			verts_to_norms[index] = {}
		var normal = arr_norms[i]
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
	for i in arr_verts.size():
		var index = vec3_to_index(arr_verts[i])
		arr_verts[i] += averaged_normals[index] * amount


static func vec3_to_index(v : Vector3):
	var round_amnt = 1000
	return "(%d,%d,%d)" % [int(v.x * round_amnt), int(v.y * round_amnt), int(v.z * round_amnt)]


static func create_bounding_box(points : Array) -> AABB:
	if points.size() < 2:
		return AABB()
	
	var min_x = points[0].x
	var min_y = points[0].y
	var min_z = points[0].z
	
	var max_x = points[0].x
	var max_y = points[0].y
	var max_z = points[0].z
	
	for i in range(1, points.size()):
		var p = points[i]
		
		if p.x > max_x:
			max_x = p.x
		elif p.x < min_x:
			min_x = p.x
		
		if p.y > max_y:
			max_y = p.y
		elif p.y < min_y:
			min_y = p.y
		
		if p.z > max_z:
			max_z = p.z
		elif p.z < min_z:
			min_z = p.z
	
	return AABB(
		Vector3(min_x, min_y, min_z),
		Vector3(max_x - min_x, max_y - min_y, max_z - min_z))


static func get_centroid(points : Array) -> Vector3:
	if points.empty():
		return Vector3.ZERO
	var centroid = Vector3.ZERO
	for p in points:
		centroid += p
	return centroid / points.size()
