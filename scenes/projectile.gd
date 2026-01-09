extends Area2D

@export var speed = 1000.0
@export var damage = 10
@export var knockback_force = 400.0

var direction = Vector2.RIGHT

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage, direction * knockback_force)
		queue_free()
	elif body.is_in_group("wall"):
		queue_free()
