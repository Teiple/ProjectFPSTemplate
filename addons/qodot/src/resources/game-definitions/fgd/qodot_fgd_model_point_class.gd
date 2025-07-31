tool
class_name QodotFGDModelPointClass
extends QodotFGDPointClass

const MODEL_KEY := "model"
const SIZE_KEY := "size"
const GDIGNORE = ".gdignore"

## The game's working path set in Trenchbroom. Optional - if empty, this entity will use the working folder set by QodotProjectConfig.
export(String, DIR, GLOBAL) var trenchbroom_working_folder = ""
## Display model export folder within your Trenchbroom working folder. Optional - if empty, this entity will use the model folder set by QodotProjectConfig.
export var trenchbroom_models_folder := ""
## Scale expression applied to model in Trenchbroom. See https://trenchbroom.github.io/manual/latest/#display-models-for-entities for more info.
export var scale_expression := ""
## Model Point Class can override the 'size' meta property by auto-generating a value from the meshes' AABB. Proper generation requires 'scale_expression' set to a float or Vector3.
## WARNING: Generated size property unlikely to align cleanly to grid!
export var generate_size_property := false
## Will auto-generate a .gdignore file in the model export folder to prevent Godot from importing the display models. Only needs to be generated once.
export var generate_gd_ignore_file := false

func build_def_text() -> String:
	_generate_model()
	return .build_def_text()
	generate_gd_ignore_file = false

func _generate_model():
	if not scene_file:
		return 
	
	var gltf_state := GLTFState.new()
	var path = _get_export_dir()
	var node = _get_node()
	if node == null: return
	if not _create_gltf_file(gltf_state, path, node, generate_gd_ignore_file):
		printerr("could not create gltf file")
		return
	node.queue_free()
	var model_key := MODEL_KEY
	var size_key := SIZE_KEY
	if scale_expression.empty():
		meta_properties[model_key] = '"%s"' % _get_local_path()
	else:
		meta_properties[model_key] = '{"path": "%s", "scale": %s }' % [
			_get_local_path(), 
			scale_expression
		]
	if generate_size_property:
		meta_properties[size_key] = _generate_size_from_aabb(gltf_state.meshes)

func _get_node() -> Spatial:
	var node := scene_file.instance()
	if node is Spatial: return node as Spatial
	node.queue_free()
	printerr("Scene is not of type 'Spatial'")
	return null

func _get_export_dir() -> String:
	var tb_work_dir = _get_working_folder()
	var model_dir = _get_model_folder()
	return tb_work_dir.path_join(model_dir).path_join('%s.glb' % classname)

func _get_local_path() -> String:
	return _get_model_folder() + ('/%s.glb' % classname)

func _get_model_folder() -> String:
#	return (QodotProjectConfig.get_setting(QodotProjectConfig.PROPERTY.TRENCHBROOM_MODELS_FOLDER)
#		if trenchbroom_models_folder.is_empty() 
#		else trenchbroom_models_folder)
	return trenchbroom_models_folder

func _get_working_folder() -> String:
#	return (QodotProjectConfig.get_setting(QodotProjectConfig.PROPERTY.TRENCHBROOM_WORKING_FOLDER)
#		if trenchbroom_working_folder.is_empty()
#		else trenchbroom_working_folder)
	return trenchbroom_working_folder


func _create_gltf_file(gltf_state: GLTFState, path: String, node: Spatial, create_ignore_files: bool) -> bool:
	var error := 0 
	var global_export_path = path
	var gltf_document := GLTFDocument.new()
	gltf_state.create_animations = false
	node.rotate_y(-0.5*PI)
	gltf_document.append_from_scene(node, gltf_state)
	if error != OK:
		printerr("Failed appending to gltf document", error)
		return false

	call_deferred("_save_to_file_system", gltf_document, gltf_state, global_export_path, create_ignore_files)
	return true

func _save_to_file_system(gltf_document: GLTFDocument, gltf_state: GLTFState, path: String, create_ignore_files: bool):
	var error := 0
	var dir := Directory.new()
	error = dir.make_dir_recursive(path.get_base_dir())
	if error != OK:
		printerr("Failed creating dir", error)
		return 

	if create_ignore_files: _create_ignore_files(path.get_base_dir())

	error = gltf_document.write_to_filesystem(gltf_state, path)
	if error != OK:
		printerr("Failed writing to file system", error)
		return 
	print('exported model ', path)

func _create_ignore_files(path: String):
	var error := 0
	var gdIgnore = GDIGNORE
	var file_path = path + "/" + gdIgnore
	var file = File.new()
	if file.file_exists(file_path):
		return
	var err = file.open(file_path, File.WRITE)
	if err != OK:
		return
	file.store_string('')
	file.close()

func _generate_size_from_aabb(meshes: Array) -> AABB:
	var aabb := AABB()
	for mesh in meshes:
		aabb = aabb.merge(mesh.mesh.get_mesh().get_aabb())

	# Reorient the AABB so it matches TrenchBroom's coordinate system
	var size_prop := AABB()
	size_prop.position = Vector3(aabb.position.z, aabb.position.x, aabb.position.y)
	size_prop.size = Vector3(aabb.size.z, aabb.size.x, aabb.size.y)

	# Scale the size bounds to our scale factor
	# Scale factor will need to be set if we decide to auto-generate our bounds
	var scale_factor: Vector3 = Vector3.ONE
	if scale_expression.begins_with('\''):
		var scale_arr := scale_expression.split_floats(' ', false)
		if scale_arr.size() == 3:
			scale_factor *= Vector3(scale_arr[0], scale_arr[1], scale_arr[2])
	elif scale_expression.to_float() > 0:
		scale_factor *= scale_expression.to_float()
	
	size_prop.position *= scale_factor
	size_prop.size *= scale_factor
	size_prop.size += size_prop.position
	## Round the size so it can stay on grid level 1 at least
	for i in 3:
		size_prop.position[i] = round(size_prop.position[i])
		size_prop.size[i] = round(size_prop.size[i])
	return size_prop
