extends CharacterBody2D

@export var speed = 100.0
@export var aggro_range = 150.0
@export var max_hp = 3

var hp = max_hp
var is_dead = false

enum State { IDLE, CHASE, RETREAT }
var current_state = State.IDLE
var home_position = Vector2.ZERO

func _ready():
	home_position = global_position
	hp = max_hp

func take_damage(amount, knockback_vector):
	hp -= amount
	
	# Apply instant knockback
	velocity += knockback_vector
	move_and_slide() # Apply force immediately
	
	# Visual flash
	modulate = Color(10, 10, 10) # Flash white
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	
	if hp <= 0:
		die(knockback_vector)

func die(knockback_vector):
	if is_dead: return
	is_dead = true
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Death Juice: Flash + Fly back + Fade
	modulate = Color(1, 0, 0) # Flash Red
	var tween = create_tween()
	
	# Rotate wildly
	var target_rot = rotation + randf_range(-5, 5)
	
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", target_rot, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5) # Fade out
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_BOUNCE) # Pop up
	
	await tween.finished
	queue_free()

func _physics_process(_delta):
	# Dead logic handled by tween mostly, but friction?
	if is_dead:
		# Slide with remaining velocity (fake friction)
		velocity = velocity.move_toward(Vector2.ZERO, 30.0)
		move_and_slide()
		return
	
	var player = get_tree().get_first_node_in_group("player")
	var dist_to_player = 99999.0
	if player:
		dist_to_player = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			if dist_to_player < aggro_range:
				current_state = State.CHASE
		
		State.CHASE:
			if player:
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * speed
				move_and_slide()
				check_collisions()
				
				# Lose aggro if too far (optional, let's say 1.5x range)
				if dist_to_player > aggro_range * 1.5:
					current_state = State.RETREAT
			else:
				current_state = State.RETREAT

		State.RETREAT:
			var direction = (home_position - global_position).normalized()
			var dist_to_home = global_position.distance_to(home_position)
			
			# Move faster when retreating
			velocity = direction * (speed * 1.5)
			move_and_slide()
			
			if dist_to_home < 5.0:
				current_state = State.IDLE

	queue_redraw() # Request redraw for debug circle

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

func _draw():
	# Draw aggro range in editor or debug build
	# Yellow circle outline
	draw_circle(Vector2.ZERO, aggro_range, Color(1, 1, 0, 0.1))
	draw_arc(Vector2.ZERO, aggro_range, 0, TAU, 32, Color(1, 1, 0, 0.5), 1.0)
