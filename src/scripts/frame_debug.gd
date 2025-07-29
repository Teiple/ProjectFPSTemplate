extends Node
class_name FrameDebug

var is_debugging := false
var next_frame := false

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func _unhandled_key_input(event):
	if event.is_action_pressed("frame_debug"):
		is_debugging = !is_debugging
	if is_debugging && event.is_action_pressed("next_frame"):
		next_frame = true

func _process(delta):
	if is_debugging:
		if next_frame:
			get_tree().paused = false
			next_frame = false
		else:
			get_tree().paused = true
	else:
		get_tree().paused = false
