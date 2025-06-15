class_name Player extends CharacterBody2D

const SPEED : float = 200
var _goal_light_size : float = 0

func _ready() -> void:
	$LightCircle/PointLight2D.scale = Vector2.ZERO

func _process_input():
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

func set_light_area(s : float):
	_goal_light_size = s

func _physics_process(delta : float):
	_process_input()
	move_and_slide()
	
	var _current_scale : float = $LightCircle/PointLight2D.scale.x
	if _current_scale != _goal_light_size:
		var scale_speed = 4 * delta
		if _current_scale < _goal_light_size:
			if _current_scale + scale_speed > _goal_light_size:
				_current_scale = _goal_light_size
			else:
				_current_scale += scale_speed
		else:
			if _current_scale - scale_speed < _goal_light_size:
				_current_scale = _goal_light_size
			else:
				_current_scale -= scale_speed
		$LightCircle/PointLight2D.scale = Vector2(_current_scale, _current_scale)

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
