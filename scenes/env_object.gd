extends Node2D

@onready var sprite = $Sprite2D
@onready var debug_sprite = $DebugSprite
var has_crack = false

func _ready():
	if has_node("CrackSprite"):
		has_crack = randf() < 0.1
			
	Globals.debug_toggled.connect(_on_debug_toggled)
	_on_debug_toggled(Globals.debug_mode)

func _on_debug_toggled(active):
	if sprite: sprite.visible = not active
	
	if has_node("CrackSprite"):
		# Show crack only if normal mode AND it has a crack
		$CrackSprite.visible = (not active) and has_crack
		
	if debug_sprite: debug_sprite.visible = active

func set_region(rect: Rect2):
	if sprite:
		sprite.region_rect = rect
