class_name GameStateComponent
extends Component

# Section and label determine how the save data is organized:
# - If section is empty, data is saved at the root level, keyed by label.
# - If section is non-empty and label is empty, data is saved under section.
# - If both are non-empty, data is saved under [section][label].
# - If both are empty, no saving or loading will happen
# WARNING: Do not mix plain data and labeled entries under the same section.
# For example, avoid saving both `save["section"] = {...}` and `save["section"]["label"] = {...}`
# as it will cause one to overwrite the other.

export(GlobalData.SaveSectionId) var save_section_id : int = GlobalData.SaveSectionId.DEFAULT
export var use_label : bool = true

const SERIALIZE_FUNC_NAME := "serialize_state"
const DESERIALIZE_FUNC_NAME := "deserialize_state"


func _ready():
	# Call _ready() in base class first
	._ready()
	add_to_group(GlobalData.Group.SAVEABLE)


static func get_component_name() -> String:
	return "GameStateComponent"


func save_state() -> Dictionary:
	if owner.has_method(SERIALIZE_FUNC_NAME):
		var state = owner.serialize_state()
		return state
	else:
		push_error("Owner node didn't have method '%s'. State won't be saved." % SERIALIZE_FUNC_NAME)
		return {}


func get_label() -> String:
	if use_label:
		return Global.get_game_world().get_path_to(owner) as String
	return ""


func load_state(state : Dictionary):
	if owner.has_method(DESERIALIZE_FUNC_NAME):
		if !state.empty():
			owner.deserialize_state(state)
	else:
		push_error("Owner node didn't have method '%s'. State couldn't be loaded." % DESERIALIZE_FUNC_NAME)
