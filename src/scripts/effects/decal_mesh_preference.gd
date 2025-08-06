tool
class_name DecalMeshPreference
extends MeshInstance

var debug_mat : Material = preload("res://assets/materials/debug_01_mat.tres")

func _ready():
	if !Engine.editor_hint:
		visible = false
		return
	material_override = debug_mat
