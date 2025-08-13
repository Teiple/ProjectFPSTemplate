tool
class_name QodotMapDecalMeshBuilder
extends QodotMapPostProcess

const DECAL_MESH_INSTANCE_NAME = "DecalMeshPreference"

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
		
		for collision_shape in body.get_children():
			if !(collision_shape is CollisionShape):
				continue
			
			# Remove previously generated meshes
			var current_mesh_instance = collision_shape.get_node_or_null(DECAL_MESH_INSTANCE_NAME) as MeshInstance
			if current_mesh_instance != null:
				current_mesh_instance.queue_free()
			
			var new_mesh : Mesh = null
			
			if collision_shape.shape is BoxShape:
				new_mesh = CubeMesh.new()
				new_mesh.size = 2 * (collision_shape.shape.extents + Vector3.ONE * margin)
			
			if collision_shape.shape is ConvexPolygonShape:
				var shape = collision_shape.shape as ConvexPolygonShape
				var vertices = Array(shape.points)
				
				new_mesh = ConvexHull.create_convex_mesh(vertices, margin)
			
			if new_mesh == null:
				continue
			
			# Add mesh instance with new mesh
			var mesh_instance = MeshInstance.new()
			mesh_instance.mesh = new_mesh
			mesh_instance.name = DECAL_MESH_INSTANCE_NAME
			
			collision_shape.add_child(mesh_instance, true)
			mesh_instance.owner = owner
			
			if decal_mesh_material != null:
				mesh_instance.material_override = decal_mesh_material
			
			mesh_instance.visible = debug
			
			print_debug("Created decal mesh for CollisionShape %s" % collision_shape.name)


# Override
func do_stuff():
	set_build_decal_meshes(true)
