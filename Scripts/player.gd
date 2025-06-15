class_name Player extends CharacterBody2D

const SPEED : float = 200

var _terrain : TileMapLayer 
var _goal_light_size : float = 0

func _ready() -> void:
	$LightCircle/PointLight2D.scale = Vector2.ZERO

func _process_input():
	
	var speed = SPEED
	if Input.is_action_pressed("sneak"):
		speed = SPEED / 4
	elif Input.is_action_pressed("walk"):
		speed = SPEED / 2
	
	# Get input (example using Input Map)
	if Input.is_action_pressed("move_right"):
		velocity.x = speed
	elif Input.is_action_pressed("move_left"):
		velocity.x = -speed
	else:
		velocity.x = 0

	if Input.is_action_pressed("move_down"):
		velocity.y = speed
	elif Input.is_action_pressed("move_up"):
		velocity.y = -speed
	else:
		velocity.y = 0

func set_terrain(terrain : TileMapLayer):
	_terrain = terrain

func set_light_area(s : float):
	_goal_light_size = s

func _physics_process(delta : float):
	_process_input()
	var current_pos = position
	move_and_slide()

	# check if we have to rollback the position
	if position != current_pos:
		var cell : Vector2i = _terrain.local_to_map(position)
		var rollback : bool = true
		if _terrain.get_cell_source_id(cell) != -1:
			var tile_data : TileData = _terrain.get_cell_tile_data(cell)
			var water_data = tile_data.get_custom_data("Water")
			if water_data == null || water_data as bool == false:
				rollback = false

		if rollback:
			var cell_x : Vector2i = _terrain.local_to_map(Vector2(position.x, current_pos.y))
			var rollback_x = true
			if _terrain.get_cell_source_id(cell_x) != -1:
				var tile_data : TileData = _terrain.get_cell_tile_data(cell_x)
				var water_data = tile_data.get_custom_data("Water")
				if water_data == null || water_data as bool == false:
					rollback_x = false

			var cell_y : Vector2i = _terrain.local_to_map(Vector2(current_pos.x, position.y))
			var rollback_y = true
			if _terrain.get_cell_source_id(cell_y) != -1:
				var tile_data : TileData = _terrain.get_cell_tile_data(cell_y)
				var water_data = tile_data.get_custom_data("Water")
				if water_data == null || water_data as bool == false:
					rollback_y = false

			if rollback_x:
				position.x = current_pos.x
			if rollback_y:
				position.y = current_pos.y
	
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
