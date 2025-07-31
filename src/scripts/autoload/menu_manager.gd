extends Node


const DEFAULT_PAUSE_OPTION := GlobalData.MenuPauseOption.UNPAUSE
const DEFAULT_FIRST_MENU := GlobalData.MenuId.PAUSE_MENU
const DEFAULT_MOUSE_MODE := Input.MOUSE_MODE_CAPTURED

var _menu_map : Dictionary = {}
var _menu_stack : Array = []


func _ready():
	# Let this node run even when the game tree is paused
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	for i in get_child_count():
		var menu = get_child(i) as Menu
		if menu == null:
			return
		_menu_map[menu.get_menu_id()] = menu
		# Disable all menu on start
		menu.disable_menu()


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if _menu_stack.empty():
			open_menu(DEFAULT_FIRST_MENU)
		else:
			back()


func open_menu(menu_id : int):
	var new_menu = _menu_map.get(menu_id) as Menu
	if new_menu == null:
		return
	
	if _menu_stack.has(new_menu):
		return
	_menu_stack.push_back(new_menu)
	
	# Set mouse mode for the first menu
	if _menu_stack.size() == 1:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	new_menu.enable_menu()
	
	_set_pause(new_menu.get_menu_pause_option())


func back():
	if _menu_stack.empty():
		return
	
	var last_menu = _menu_stack.pop_back() as Menu
	if last_menu == null:
		return
	
	last_menu.disable_menu()
	
	if _menu_stack.empty():
		_set_pause(DEFAULT_PAUSE_OPTION)
		Input.mouse_mode = DEFAULT_MOUSE_MODE
		return
	
	var cur_menu = _menu_stack.back() as Menu
	if cur_menu == null:
		return
	
	_set_pause(cur_menu.get_menu_pause_option())


func _set_pause(pause_option : int):
	match pause_option:
		GlobalData.MenuPauseOption.PAUSE:
			Global.set_tree_pause(true)
		GlobalData.MenuPauseOption.UNPAUSE:
			Global.set_tree_pause(false)
		GlobalData.MenuPauseOption.PRESERVE_CURRENT_STATE:
			# Do nothing
			pass


func current_menu() -> Menu:
	return _menu_stack.back() as Menu
