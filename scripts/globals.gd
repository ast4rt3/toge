extends Node

signal debug_toggled(is_active)

var debug_mode = false

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		debug_mode = !debug_mode
		debug_toggled.emit(debug_mode)
		print("Debug Mode: ", debug_mode)
