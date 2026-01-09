extends CharacterBody2D

@export var speed = 100.0

enum State { CHASE, RETREAT }
var current_state = State.CHASE
var home_position = Vector2.ZERO

func _ready():
	home_position = global_position

func _physics_process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	
	if current_state == State.CHASE:
		if player:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			check_collisions()
			
	elif current_state == State.RETREAT:
		var direction = (home_position - global_position).normalized()
		var dist = global_position.distance_to(home_position)
		
		# Move faster when retreating
		velocity = direction * (speed * 1.5)
		move_and_slide()
		
		# If back home, idle or resume chase check (only if player is far?)
		if dist < 10.0:
			# For now, just reset to Chase, but maybe wait?
			# If we reset immediately and player is still there, we loop.
			# But player should be far away if they are in safe zone.
			current_state = State.CHASE

func check_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			call_deferred("game_over")
		elif collider.is_in_group("barrier"):
			# Hit safe zone -> Retreat
			current_state = State.RETREAT

func game_over():
	get_tree().reload_current_scene()
