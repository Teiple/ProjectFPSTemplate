class_name PauseMenu
extends Menu

# Override
static func get_menu_id() -> int:
	return GlobalData.MenuId.PAUSE_MENU


# Override
static func get_menu_pause_option() -> int:
	return GlobalData.MenuPauseOption.PAUSE


func _ready():
	connect_button_event("ResumeButton", "resume")
	connect_button_event("SaveButton", "save")
	connect_button_event("LoadButton", "load")
	connect_button_event("QuitButton", "quit")
	connect_button_event("ReloadWithoutShaderCache", "reload_without_shader_cache")


func connect_button_event(node_unique_name : String, button_name : String):
	var button : Button = get_node_or_null("%%%s" % node_unique_name) as Button
	if button == null:
		push_error("Couldn't find node with unique name '%s'" % node_unique_name)
		return
	
	var method = "_on_%s_button_pressed" % button_name
	if !has_method(method):
		push_error("Missing method %s" % method)
		return
	
	button.connect("pressed", self, method) 


func _on_resume_button_pressed():
	# Pause Menu should always be the first menu to be opened in game
	# So calling back() would make it return to the current game
	back()


func _on_save_button_pressed():
	Global.save_everything()


func _on_load_button_pressed():
	Global.call_deferred("load_everything")
	back()


func _on_quit_button_pressed():
	Global.quit()


func _on_reload_without_shader_cache_button_pressed():
	Global.load_scene("res://src/scenes/world.tscn")
