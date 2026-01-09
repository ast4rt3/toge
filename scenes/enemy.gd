extends CharacterBody2D

@export var speed = 100.0
@export var aggro_range = 150.0
@export var max_hp = 3

var hp = max_hp
var is_dead = false

enum State { IDLE, CHASE, RETREAT }
var current_state = State.IDLE
var home_position = Vector2.ZERO

static var zombie_frames: SpriteFrames

func _ready():
	home_position = global_position
	hp = max_hp
	Globals.debug_toggled.connect(_on_debug_toggled)
	
	if not zombie_frames:
		load_zombie_frames()
	
	$AnimatedSprite2D.sprite_frames = zombie_frames
	$AnimatedSprite2D.play("idle")
	
	# Initial Debug State
	_on_debug_toggled(Globals.debug_mode)

func _on_debug_toggled(active):
	$AnimatedSprite2D.visible = not active
	$DebugSprite.visible = active
	queue_redraw()

func load_zombie_frames():
	zombie_frames = SpriteFrames.new()
	zombie_frames.remove_animation("default")
	
	# Load Idle (1-15)
	zombie_frames.add_animation("idle")
	zombie_frames.set_animation_loop("idle", true)
	zombie_frames.set_animation_speed("idle", 15)
	for i in range(1, 16):
		var path = "res://zombiefiles/png/male/Idle (%d).png" % i
		if ResourceLoader.exists(path):
			zombie_frames.add_frame("idle", load(path))
			
	# Load Walk (1-10)
	zombie_frames.add_animation("walk")
	zombie_frames.set_animation_loop("walk", true)
	zombie_frames.set_animation_speed("walk", 10)
	for i in range(1, 11):
		var path = "res://zombiefiles/png/male/Walk (%d).png" % i
		if ResourceLoader.exists(path):
			zombie_frames.add_frame("walk", load(path))

	# Load Dead (1-12)
	zombie_frames.add_animation("dead")
	zombie_frames.set_animation_loop("dead", false)
	zombie_frames.set_animation_speed("dead", 12)
	for i in range(1, 13):
		var path = "res://zombiefiles/png/male/Dead (%d).png" % i
		if ResourceLoader.exists(path):
			zombie_frames.add_frame("dead", load(path))

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
	
	# Play Dead Animation
	$AnimatedSprite2D.play("dead")
	
	await $AnimatedSprite2D.animation_finished
	
	# Fade out after animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
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
			$AnimatedSprite2D.play("idle")
			if dist_to_player < aggro_range:
				current_state = State.CHASE
		
		State.CHASE:
			$AnimatedSprite2D.play("walk")
			if player:
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * speed
				
				# Flip sprite
				if direction.x != 0:
					$AnimatedSprite2D.flip_h = direction.x < 0
					
				move_and_slide()
				check_collisions()
				
				# Lose aggro if too far (optional, let's say 1.5x range)
				if dist_to_player > aggro_range * 1.5:
					current_state = State.RETREAT
			else:
				current_state = State.RETREAT

		State.RETREAT:
			$AnimatedSprite2D.play("walk")
			var direction = (home_position - global_position).normalized()
			var dist_to_home = global_position.distance_to(home_position)
			
			# Flip sprite
			if direction.x != 0:
				$AnimatedSprite2D.flip_h = direction.x < 0
			
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
			if collider.has_method("take_damage"):
				collider.take_damage(1)
		elif collider.is_in_group("barrier"):
			# Hit safe zone -> Retreat
			current_state = State.RETREAT

# func game_over(): # Removed as it's now handled by Player
# 	get_tree().reload_current_scene()

func _draw():
	if not Globals.debug_mode: return
	
	# Draw aggro range in editor or debug build
	# Yellow circle outline
	draw_circle(Vector2.ZERO, aggro_range, Color(1, 1, 0, 0.1))
	draw_arc(Vector2.ZERO, aggro_range, 0, TAU, 32, Color(1, 1, 0, 0.5), 1.0)
