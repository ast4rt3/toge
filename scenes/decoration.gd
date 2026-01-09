extends "res://scenes/env_object.gd"

func _ready():
	super._ready() # Initialize debug state
	
	# Pick random prop (Grid assumption)
	var prop_regions = [
		Rect2(0, 0, 32, 32),
		Rect2(32, 0, 32, 32),
		Rect2(64, 0, 32, 32),
		Rect2(96, 0, 32, 32),
	]
	
	if sprite:
		var region = prop_regions.pick_random()
		sprite.region_rect = region
		
	# Randomize collision?
	# For now, let's keep them constantly non-collidable to prevent blocking corridors.
	$CollisionShape2D.disabled = true
