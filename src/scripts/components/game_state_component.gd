class_name GameStateComponent
extends Component

const SAVEABLE_GROUP := "saveable"
const SERIALIZE_FUNC_NAME := "serialize_state"
const DESERIALIZE_FUNC_NAME := "deserialize_state"


func _ready():
	# Call _ready() in base class first
	._ready()
	add_to_group(SAVEABLE_GROUP)


static func get_component_name() -> String:
	return "GameStateComponent"


# Must override
func save_state():
	if owner.has_method(SERIALIZE_FUNC_NAME):
		var state = owner.serialize_state()
		GameState.write_save(state)
	else:
		push_error("Owner node didn't have method '%s'. State won't be saved." % SERIALIZE_FUNC_NAME)


# Must override
func load_state():
	return
#	if owner.has_method(DESERIALIZE_FUNC_NAME):
#		var state = GameState.load_save()
#		if !state.empty():
#			owner.deserialize_state(state)
#	else:
#		push_error("Owner node didn't have method '%s'. State couldn't be loaded." % DESERIALIZE_FUNC_NAME)
