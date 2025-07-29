extends Control

export(String, FILE, "*.tscn") var scene_path = ""

onready var loading : Label = $Loading
onready var hint : Label = $Hint

func _ready():
	hint.visible = false


func _on_Button_pressed():
	if scene_path == "":
		return
	Global.load_scene_async(scene_path)


func _process(delta):
	if Global.is_loading_complete():
		Global.loading_pending_scene()
		call_deferred("set_process", false)
		return
	
	var progress = Global.get_loading_progress()
	var progress_percentage = progress * 100.0
	loading.text = "%.2f%%" % progress_percentage
	if Global.is_loading_complete():
		hint.visible = true
