extends CharacterBody2D

@export var speed = 200.0
@export var dash_speed = 600.0
@export var dash_duration = 0.2
@export var dash_cooldown = 1.0

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0

func _physics_process(delta):
	# Cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Dash Input
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash()

	# Movement
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	else:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * speed
		
		# Look at mouse
		look_at(get_global_mouse_position())

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
