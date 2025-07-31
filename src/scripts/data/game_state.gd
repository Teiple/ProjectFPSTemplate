class_name GameState

const SLOT_NEW = -1
const SLOT_LATEST = -1

const SAVE_FILE_PATTERN = "save_%04d.sav"
const SAVE_FILE_SEARCH_PATTERN = "*.sav"
const SAVE_DIRECTORY = "user://saves"
const DEFAULT_SAVE_NAME = "save.sav"

var _save_data : Dictionary = {}


static func load_save_diretory() -> Array:
	_create_dir_if_not_existed()
	var save_files = []
	
	var dir = Directory.new()
	var err = dir.open(SAVE_DIRECTORY)
	if err != OK:
		push_error("Error occured when reading save directory.")
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() && file_name.match(SAVE_FILE_SEARCH_PATTERN):
			save_files.push_back(file_name)
		file_name = dir.get_next()
	
	return save_files


# Save section of type GlobaData.SaveSection
static func load_save(slot_index : int) -> Dictionary:
	var save_file_name = ""
	
	if slot_index == SLOT_LATEST:
		save_file_name = _get_file_name_at_last_slot()
	else:
		save_file_name = _get_file_name_at_slot(slot_index)
	
	if save_file_name == "":
		return {}
	
	var save_file = File.new()
	var save_file_path = SAVE_DIRECTORY + "/" + save_file_name
	var err = save_file.open(save_file_path, File.READ)
	
	if err != OK:
		push_error("Couldn't open file at '%s'" % save_file_path)
		return {}
	
	var save_text = save_file.get_as_text()
	save_file.close()
	
	var parse_result : JSONParseResult = JSON.parse(save_text)
	var data = parse_result.result
	
	if !(data is Dictionary):
		return {}
	
	return data


static func _create_dir_if_not_existed():
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIRECTORY):
		if dir.make_dir_recursive(SAVE_DIRECTORY) != OK:
			push_error("There was an error when trying to make the directory '%s'" % SAVE_DIRECTORY)
			return


static func _get_available_file_name() -> String:
	var save_files = load_save_diretory()
	var new_file_name = SAVE_FILE_PATTERN % save_files.size()
	return new_file_name


static func _get_file_name_at_slot(slot_index : int) -> String:
	if slot_index < 0:
		return ""
	var save_files = load_save_diretory()
	if slot_index >= save_files.size():
		return ""
	var file_name = save_files[slot_index]
	return file_name


static func _get_file_name_at_last_slot() -> String:
	var save_files = load_save_diretory()
	var save_file_count = save_files.size()
	if save_file_count == 0:
		return ""
	var file_name = save_files[save_file_count - 1]
	return file_name


static func write_save(data : Dictionary, slot_index : int):
	_create_dir_if_not_existed()
	
	var save_file_name = ""
	
	if slot_index == SLOT_NEW:
		save_file_name = _get_available_file_name()
	else:
		save_file_name = _get_file_name_at_slot(slot_index)
	
	if save_file_name == "":
		return
	
	var save_file = File.new()
	var save_file_path = SAVE_DIRECTORY + "/" + save_file_name
	
	var err = save_file.open(save_file_path, File.WRITE)
	
	if err != OK:
		push_error("Couldn't open file at '%s'" % save_file_path)
		return {}
	
	var json_text = JSON.print(data, "\t")
	save_file.store_string(json_text)
	save_file.close()
