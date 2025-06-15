class_name Player extends CharacterBody2D

const SPEED : float = 200

func redundant():
	# Get input (example using Input Map)
	if Input.is_action_pressed("move_right"):
		velocity.x = SPEED
	elif Input.is_action_pressed("move_left"):
		velocity.x = -SPEED
	else:
		velocity.x = 0

	if Input.is_action_pressed("move_down"):
		velocity.y = SPEED
	elif Input.is_action_pressed("move_up"):
		velocity.y = -SPEED
	else:
		velocity.y = 0
	
func _physics_process(delta):
	redundant()
	move_and_slide()

	#Example using move_and_collide()
	#var collision = move_and_collide(velocity * delta)
	#if collision:
	#	velocity = velocity.bounce(collision.get_normal()) # Or other collision logic

	# Example of accessing slide collisions
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		print("I collided with ", collision.get_collider().name, " on the ", collision.get_normal())

	#Example of accessing last collision
	#var last_collision = get_last_slide_collision()
	#if last_collision:
	#	print("Last collision normal: ", last_collision.get_normal())
