class_name AnimationOverride
extends Node

export var animation_player_path : NodePath = ""

func _ready():
	var replace_scene_path = GameConfig.get_config_value(GlobalData.ConfigId.ANIMATION_CONFIG, ["animation_player", "saving_directory"], "") \
		+ "/" + GameConfig.get_config_value(GlobalData.ConfigId.ANIMATION_CONFIG, ["animation_player", "saving_name"], "")
	
	if !ResourceLoader.exists(replace_scene_path):
		push_error("Replacer scene path is invalid. AnimationPlayer won't be replaced.")
		return
	
	var replace_scene = ResourceLoader.load(replace_scene_path) as PackedScene
	var replacer = replace_scene.instance()
	var view_model = owner.get_node("ViewModel") as Spatial
	
	var old = view_model.get_node("AnimationPlayer")
	view_model.remove_child(old)
	old.queue_free()
	view_model.add_child(replacer, true)


func get_animation_player() -> AnimationPlayer:
	return get_node(animation_player_path) as AnimationPlayer
