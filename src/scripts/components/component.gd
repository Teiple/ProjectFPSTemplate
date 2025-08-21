class_name Component
extends Spatial

const ARRAY_PREFIX = "arr_"

export var is_unique := true
export var inheritable := false


func _ready():
	if is_unique:
		if !owner.has_meta(get_component_name()):
			owner.set_meta(get_component_name(), self)
		
		if inheritable:
			for inheritance in get_inheritance():
				if !owner.has_meta(inheritance):
					owner.set_meta(inheritance, self)
		
	else:
		var component_array = []
		if !owner.has_meta(get_component_array_name()):
			component_array.push_back(self)
			owner.set_meta(get_component_array_name(), component_array)
		elif owner.get_meta(get_component_array_name()) is Array:
			var arr = owner.get_meta(get_component_array_name())
			if arr is Array:
				arr.push_back(self)
				component_array = arr
		
		if inheritable:
			for inheritance in get_inheritance():
				var array_name = ARRAY_PREFIX + inheritance
				if !owner.has_meta(array_name):
					owner.set_meta(array_name, component_array.duplicate())
				else:
					var inheritance_arr = owner.get_meta(array_name)
					if inheritance_arr is Array && !inheritance_arr.has(self):
						inheritance_arr.push_back(self)


# Must override
static func get_component_name() -> String:
	return "Component"


static func get_component_array_name() -> String:
	return ARRAY_PREFIX + get_component_name()


static func find_component(node : Node, component_name : String) -> Component:
	if !node.has_meta(component_name):
		return null
	return node.get_meta(component_name)


static func find(node : Node, component_name : String) -> Component:
	return find_component(node, component_name)


static func find_component_array(node : Node, component_name : String) -> Array:
	return node.get_meta(ARRAY_PREFIX + component_name) as Array


# Must override if inheritable
static func get_inheritance() -> Array:
	return []
