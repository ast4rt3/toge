extends Node2D

@onready var sprite = $Sprite2D
@onready var debug_sprite = $DebugSprite
var has_crack = false

func _ready():
	if sprite and sprite.region_enabled:
		var r = sprite.region_rect
		# If the selected region is larger than 32x32, pick a random 32x32 sub-region from it
		if r.size.x > 32 or r.size.y > 32:
			var cols = int(r.size.x / 32)
			var rows = int(r.size.y / 32)
			
			if cols > 0 and rows > 0:
				var random_col = randi() % cols
				var random_row = randi() % rows
				
				var new_x = r.position.x + (random_col * 32)
				var new_y = r.position.y + (random_row * 32)
				
				# Update the region to show only one tile
				sprite.region_rect = Rect2(new_x, new_y, 32, 32)

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
