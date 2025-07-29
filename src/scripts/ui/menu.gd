class_name Menu
extends Control

# Must override
static func get_menu_pause_option() -> int:
	return GlobalData.MenuPauseOption.PRESERVE_CURRENT_STATE


# Must override
static func get_menu_id() -> int:
	return GlobalData.MenuId.NONE


func disable_menu():
	visible = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


func enable_menu():
	visible = true
	set_process(true)
	set_physics_process(true)
	set_process_input(true)


func back():
	if MenuManager.current_menu() == self:
		MenuManager.back()
