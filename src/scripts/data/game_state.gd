class_name GameState

const SAVE_DIRECTORY = "user://saves"
const DEFAULT_SAVE_NAME = "save.sav"

var _save_data : Dictionary = {}


# Save section of type GlobaData.SaveSection
static func load_save(save_path : String) -> Dictionary:
	var save_file = File.new()
	var save_file_path = save_path
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


static func write_save(data):
	_create_dir_if_not_existed()
	
	var save_file = File.new()
	var save_file_path = SAVE_DIRECTORY + "/" + DEFAULT_SAVE_NAME
	var err = save_file.open(save_file_path, File.WRITE)
	
	if err != OK:
		push_error("Couldn't open file at '%s'" % save_file_path)
		return {}
	
	var json_text = JSON.print(data, "\t")
	save_file.store_string(json_text)
	save_file.close()
