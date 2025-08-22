extends Control

export(String, FILE, "*.tscn") var main_scene_path = ""

onready var _load_main_scene_button = $LoadMainSceneButton
onready var _cache_main_scene_button = $CacheMainSceneButton


func _ready():
	_load_main_scene_button.connect("pressed", self, "_on_load_main_scene_button_pressed")
	_cache_main_scene_button.connect("pressed", self, "_on_cache_main_scene_button_pressed")


func _on_load_main_scene_button_pressed():
	Global.load_scene_async(main_scene_path)


func _process(delta):
	if Global.is_loading_complete():
		Global.load_pending_scene()
