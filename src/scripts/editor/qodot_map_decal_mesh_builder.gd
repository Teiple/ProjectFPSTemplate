tool
class_name QodotMapDecalMeshBuilder
extends QodotMapPostProcess

export var decal_mesh_material : Material = preload("res://assets/materials/debug_02_mat.tres")
export var debug := false
export var margin := 0.01
export var export_save_guard_start : bool = true setget set_export_save_guard_start
export var build_decal_meshes := false setget set_build_decal_meshes
export var export_save_guard_end : bool = true setget set_export_save_guard_end

var _is_saving := false


func set_export_save_guard_start(val):
	if val == false:
		return
	_is_saving = true


func set_export_save_guard_end(val):
	if val == false:
		return
	_is_saving = false


func set_build_decal_meshes(val):
	if !Engine.editor_hint || !is_node_ready() || _is_saving:
		return
	
	var map = _qodot_map
	if map == null:
		return
	
	for body in map.get_children():
		if !(body is StaticBody):
			continue
		
		var bounding_boxes = {}
		
		for collision_shape in body.get_children():
			if !(collision_shape is CollisionShape):
				continue
			
			# Remove previously generated meshes
			var current_mesh_instance = collision_shape.get_node_or_null(GlobalData.Ref.DECAL_MESH_INSTANCE_NAME) as MeshInstance
			if current_mesh_instance != null:
				current_mesh_instance.queue_free()
			
			var new_mesh : Mesh = null
			
			var aabb = AABB()
			
			if collision_shape.shape is BoxShape:
				new_mesh = CubeMesh.new()
				new_mesh.size = 2 * (collision_shape.shape.extents + Vector3.ONE * margin)
				aabb = AABB(collision_shape.position - collision_shape.shape.extents, collision_shape.shape.extents * 2.0)
			
			if collision_shape.shape is ConvexPolygonShape:
				var shape = collision_shape.shape as ConvexPolygonShape
				var vertices = Array(shape.points)
				
				aabb = ConvexHull.create_bounding_box(vertices)
				
				new_mesh = ConvexHull.create_convex_mesh(vertices, margin)
			
			if new_mesh == null:
				continue
			
			aabb.position += body.global_position
			# Assumming collision_shape orientation follows world's
			bounding_boxes[aabb] = collision_shape
			
			# Add mesh instance with new mesh
			var mesh_instance = MeshInstance.new()
			mesh_instance.mesh = new_mesh
			mesh_instance.name = GlobalData.Ref.DECAL_MESH_INSTANCE_NAME
			
			collision_shape.add_child(mesh_instance, true)
			mesh_instance.owner = owner
			
			if decal_mesh_material != null:
				mesh_instance.material_override = decal_mesh_material
			
			mesh_instance.visible = debug
			
			print_debug("Created decal mesh for CollisionShape %s" % collision_shape.name)
		
		var adjacent_lookup = {}
		
		for box_a in bounding_boxes.keys():
			var col_shape = bounding_boxes[box_a]
			col_shape.set_meta(GlobalData.Ref.COLLISION_SHAPE_AABB_META_NAME, box_a)
			print_debug("Set meta AABB for CollisionShape for %s" % col_shape.name)
			for box_b in bounding_boxes.keys():
				if bounding_boxes[box_a] == bounding_boxes[box_b]:
					continue
				if box_a.intersects(box_b) || Utils.is_adjacent(box_a, box_b):
					var neighbour_col_shape_path = col_shape.get_path_to(bounding_boxes[box_b])
					
					if !col_shape.has_meta(GlobalData.Ref.ADJACENT_COLLISION_SHAPES_META_NAME):
						col_shape.set_meta(GlobalData.Ref.ADJACENT_COLLISION_SHAPES_META_NAME, [neighbour_col_shape_path])
						print_debug("Set meta adjacent CollisionShapes for %s" % col_shape.name)
					else:
						col_shape.get_meta(GlobalData.Ref.ADJACENT_COLLISION_SHAPES_META_NAME).push_back(neighbour_col_shape_path)

# Override
func do_stuff():
	set_build_decal_meshes(true)
