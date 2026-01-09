extends CharacterBody2D

@export var speed = 200.0
@export var dash_speed = 600.0
@export var dash_duration = 0.2
@export var dash_cooldown = 1.0
@export var shoot_cooldown = 1.0
@export var recoil_force = 200.0

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var shoot_timer = 0.0

var projectile_scene = preload("res://scenes/Projectile.tscn")
# ... (rest of physics process is fine, logic uses shoot_cooldown variable)

func shoot(target_pos):
	var direction = (target_pos - global_position).normalized()
	
	# Projectile
	var p = projectile_scene.instantiate()
	p.position = global_position + direction * 20.0
	p.direction = direction
	p.rotation = direction.angle()
	get_parent().add_child(p)
	
	# Recoil (Knockback on player)
	velocity -= direction * recoil_force
	# We rely on move_and_slide in the next frame or physics process to handle this momentum 
	# if we were adding to velocity. But physics process overrides velocity every frame for movement.
	# To make it feel right, we need to apply an impulse or temporary velocity override.
	# However, since we set velocity in _physics_process based on input, this recoil will be overwritten instantly next frame.
	# Simple fix: Add a short "knockback state" or add to a separate "external_forces" vector that decays?
	# Or just simpler: `position -= direction * 5`? No, physics.
	# Best way for CharacterBody2D without state machine: Temporarily override velocity?
	# Let's add a `knockback_velocity` variable that decays.
	
	knockback_velocity = -direction * recoil_force

var knockback_velocity = Vector2.ZERO

func _physics_process(delta):
	# Cooldowns
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if shoot_timer > 0:
		shoot_timer -= delta
		
	# Decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000.0 * delta)

	# Dash Input
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash()

	# Aiming & Shooting (Require M2)
	var is_aiming = Input.is_action_pressed("secondary_attack")
	
	if is_aiming:
		# Look at mouse
		look_at(get_global_mouse_position())
		
		# Update Tracer
		$Line2D.visible = true
		$RayCast2D.force_raycast_update()
		if $RayCast2D.is_colliding():
			$Line2D.points[1] = to_local($RayCast2D.get_collision_point())
		else:
			$Line2D.points[1] = $RayCast2D.target_position
		
		# Allow Shooting
		if Input.is_action_pressed("attack") and shoot_timer <= 0:
			shoot(get_global_mouse_position())
			shoot_timer = shoot_cooldown
	else:
		$Line2D.visible = false
		
		# Look in move direction if moving
		# var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down") # already defined below
		pass

	# Movement
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	else:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if direction != Vector2.ZERO and not is_aiming:
			rotation = direction.angle()
			
		if is_aiming:
			velocity = direction * (speed * 0.5)
		else:
			velocity = direction * speed
			
	# Apply Knockback
	velocity += knockback_velocity

	move_and_slide()

func start_dash():
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Dash in movement direction, or forward into facing direction if standing still
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		velocity = Vector2.RIGHT.rotated(rotation) * dash_speed
	else:
		velocity = direction * dash_speed

func end_dash():
	is_dashing = false
	velocity = Vector2.ZERO
