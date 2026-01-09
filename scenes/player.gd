extends CharacterBody2D

@export var speed = 200.0
@export var dash_speed = 600.0
@export var dash_duration = 0.2
@export var dash_cooldown = 1.0
@export var shoot_cooldown = 1.0
@export var recoil_force = 200.0
@export var melee_lunge_force = 200.0 # Force applied toward swing direction
@export var max_hp = 5

enum WeaponType { SNIPER, MELEE }
var current_weapon_index = 0
var weapons = [
	{ "type": WeaponType.SNIPER, "name": "Sniper" },
	{ "type": WeaponType.MELEE, "name": "Katana" } # User requested versatility, so structure allows easy addition
]

var hp = max_hp
var invulnerability_timer = 0.0

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var shoot_timer = 0.0

var projectile_scene = preload("res://scenes/Projectile.tscn")

func _ready():
	update_hp_ui()
	update_weapon_ui()

func take_damage(amount):
	if invulnerability_timer > 0: return
	
	hp -= amount
	update_hp_ui()
	
	if hp <= 0:
		die()
	else:
		# I-frames
		invulnerability_timer = 1.0
		modulate = Color(1, 0, 0) # Flash red
		
func update_hp_ui():
	if has_node("CanvasLayer/HPLabel"):
		$CanvasLayer/HPLabel.text = "HP: " + str(hp) + "/" + str(max_hp)

func die():
	set_physics_process(false)
	$CanvasLayer/GameOverLabel.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
# ... (rest of physics process is fine, logic uses shoot_cooldown variable)



var knockback_velocity = Vector2.ZERO

func _physics_process(delta):
	# Cooldowns
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if shoot_timer > 0:
		shoot_timer -= delta
		
	# Invulnerability
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			modulate = Color(1, 1, 1) # Reset color
		else:
			# Blink effect
			modulate.a = 0.5 if Engine.get_frames_drawn() % 10 < 5 else 1.0
		
	# Decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000.0 * delta)

	# Dash Input
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash()

	# Weapon Switching
	if Input.is_action_just_pressed("switch_weapon"):
		cycle_weapon()

	# Handle Combat based on Weapon
	handle_combat(delta)

	# Movement
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	else:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if direction != Vector2.ZERO:
			# Look in movement direction by default (overridden by Aim Mode)
			if not Input.is_action_pressed("secondary_attack"):
				rotation = direction.angle()
			
		if Input.is_action_pressed("secondary_attack") and get_current_weapon_type() == WeaponType.SNIPER:
			velocity = direction * (speed * 0.5)
		else:
			velocity = direction * speed
			
	# Apply Knockback
	velocity += knockback_velocity

	move_and_slide()

func cycle_weapon():
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	update_weapon_ui()
	
func update_weapon_ui():
	if has_node("CanvasLayer/WeaponLabel"):
		$CanvasLayer/WeaponLabel.text = "Weapon: " + weapons[current_weapon_index]["name"]

func get_current_weapon_type():
	return weapons[current_weapon_index]["type"]

func handle_combat(_delta):
	var type = get_current_weapon_type()
	var is_aiming = Input.is_action_pressed("secondary_attack")
	
	# Common Aim Logic
	if is_aiming:
		look_at(get_global_mouse_position())
	
	if type == WeaponType.SNIPER:
		if is_aiming:
			# Tracer
			$Line2D.visible = true
			$RayCast2D.force_raycast_update()
			if $RayCast2D.is_colliding():
				$Line2D.points[1] = to_local($RayCast2D.get_collision_point())
			else:
				$Line2D.points[1] = $RayCast2D.target_position
			
			if Input.is_action_pressed("attack") and shoot_timer <= 0:
				shoot_sniper(get_global_mouse_position())
				shoot_timer = shoot_cooldown
		else:
			$Line2D.visible = false
			
	elif type == WeaponType.MELEE:
		$Line2D.visible = false
		
		# Melee Logic
		var slash_line = $MeleeArea/SlashLine
		
		# 1. Update Visual Visibility based on State
		if is_attacking_melee:
			slash_line.visible = true
			slash_line.default_color.a = 1.0
		elif is_aiming and Globals.debug_mode:
			# Aim Highlight (Ghost) - Debug Only
			slash_line.visible = true
			slash_line.default_color.a = 0.3
		else:
			slash_line.visible = false
			
		if Input.is_action_just_pressed("attack") and shoot_timer <= 0:
			# If not aiming, briefly face mouse for the swing
			if not is_aiming:
				look_at(get_global_mouse_position())
				
			slash_melee()
			shoot_timer = 0.4 # Fast cooldown

var is_attacking_melee = false

func slash_melee():
	is_attacking_melee = true
	
	# Enable Hitbox
	$MeleeArea/CollisionPolygon2D.disabled = false
	
	# Apply Lunge (Forward Impulse)
	var forward_dir = Vector2.RIGHT.rotated(rotation)
	knockback_velocity = forward_dir * melee_lunge_force
	
	# Wait for physics to update collision
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Check hits
	var bodies = $MeleeArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			var knockback = (body.global_position - global_position).normalized() * 300
			body.take_damage(10, knockback) # Melee damage
			
	# Cleanup
	await get_tree().create_timer(0.1).timeout
	$MeleeArea/CollisionPolygon2D.disabled = true
	is_attacking_melee = false

func shoot_sniper(target_pos):
	var direction = (target_pos - global_position).normalized()
	
	# Projectile
	var p = projectile_scene.instantiate()
	p.position = global_position + direction * 20.0
	p.direction = direction
	p.rotation = direction.angle()
	get_parent().add_child(p)
	
	# Recoil
	velocity -= direction * recoil_force
	knockback_velocity = -direction * recoil_force

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
