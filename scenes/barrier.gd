extends Node2D

func _ready():
	_on_debug_toggled(Globals.debug_mode)
	Globals.debug_toggled.connect(_on_debug_toggled)

func _on_debug_toggled(active):
	$Sprite2D.visible = active
